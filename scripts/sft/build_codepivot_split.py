#!/usr/bin/env python3
"""Split the verified pairs into a held-out eval + training SFT, both in
CodePivot's original schema.

  * Training: CodePivot SFT records {instruction, input, system, output}
    (held-out EXCLUDED) — for LLaMA-Factory.
  * Held-out: CodePivot verl eval records {data_source, prompt:[system,user],
    ability, reward_model:{ground_truth:{inputs,outputs}}, extra_info} — the
    clean, uncontaminated, shape-matched eval the advisor flagged as blocking.
    Test cases (inputs/outputs) are regenerated from each function's cpp_source
    via the C++ oracle, function-level (args -> scalar; extra_info.eval_mode).

Deterministic split (every Nth by sorted name). Read-only on source repos.
Emits data/sft/codepivot/{train_*.jsonl, heldout_eval.jsonl, heldout_names.json}.
"""
from __future__ import annotations

import importlib.util, json, subprocess, sys, tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SFTDIR = REPO / "data/sft/codepivot"

# reuse helpers
sys.path.insert(0, str(REPO / "src"))
_b = importlib.util.spec_from_file_location("bcm", REPO / "scripts/build_cpp_mojo_dataset.py")
bcm = importlib.util.module_from_spec(_b); sys.modules["bcm"] = bcm; _b.loader.exec_module(bcm)
_t = importlib.util.spec_from_file_location("tcs", REPO / "scripts/sft/to_codepivot_schema.py")
tcs = importlib.util.module_from_spec(_t); sys.modules["tcs"] = tcs; _t.loader.exec_module(tcs)

HOLDOUT_EVERY = 4          # 1 in 4 -> ~10 of 40 / ~10 of 39
SAMPLES = 20               # test cases per held-out function

_TYPE_MAP = {"Real64": "Float64", "double": "Float64", "float": "Float64", "Nandle": "Float64",
             "Real32": "Float64", "int": "Int", "Int": "Int", "Int64": "Int", "long": "Int",
             "bool": "Bool"}


def gen_testcases(cpp_source: str, name: str, arg_types: list[str]):
    """Sample inputs, run the compiled C++ oracle, return (inputs, outputs) or None."""
    params = [(f"a{i}", _TYPE_MAP.get(t, "Float64")) for i, t in enumerate(arg_types)]
    rows = bcm._sample_inputs(params, cpp_source)[:SAMPLES]
    with tempfile.TemporaryDirectory() as td:
        tdp = Path(td)
        calls = "\n".join(
            f'  printf("%.15g\\n", (double){name}('
            + ", ".join(bcm._fmt_lit(v, t)[0] for v, (n, t) in zip(row, params)) + "));"
            for row in rows)
        src = f"{bcm._CPP_HELPERS}\n{cpp_source}\nint main(){{\n{calls}\n return 0;}}\n"
        (tdp / "o.cpp").write_text(src)
        r = bcm._run(["g++", "-O2", "-std=c++17", "-o", str(tdp / "o"), str(tdp / "o.cpp")])
        if r.returncode != 0:
            return None
        r = bcm._run([str(tdp / "o")])
        if r.returncode != 0:
            return None
        outs = r.stdout.split()
    if len(outs) != len(rows):
        return None
    inputs, outputs = [], []
    for row, o in zip(rows, outs):
        try:
            fo = float(o)
        except ValueError:
            continue
        if fo != fo or abs(fo) == float("inf"):
            continue
        inputs.append([int(v) if t in ("Int", "Bool") else v for v, (n, t) in zip(row, params)])
        outputs.append(fo)
    return (inputs, outputs) if len(inputs) >= 4 else None


def verl_record(pair, tgt, lang_tag, sysprompt, idx):
    instr = (f"Transpile the provided C++ implementation into a functionally equivalent "
             f"implementation in {tgt}.\n\n```cpp\n{pair['cpp_source'].strip()}\n```")
    tc = gen_testcases(pair["cpp_source"], pair["function_name"], pair["arg_types"])
    if tc is None:
        return None
    inputs, outputs = tc
    return {
        "data_source": f"energyplus_cpp2{lang_tag}",
        "prompt": [{"role": "system", "content": sysprompt},
                   {"role": "user", "content": instr}],
        "ability": "code_transpilation",
        "reward_model": {"style": "rule", "ground_truth": {"inputs": inputs, "outputs": outputs}},
        "extra_info": {"index": idx, "function_name": pair["function_name"],
                       "source_file": pair["source_file"], "src_language": "cpp",
                       "language_full": tgt, "arg_types": pair["arg_types"],
                       "ret_type": pair["ret_type"], "eval_mode": "function_scalar",
                       "split": "test"},
    }


def main():
    SFTDIR.mkdir(parents=True, exist_ok=True)
    sysprompt = tcs.system_prompt()
    (SFTDIR / "system.txt").write_text(sysprompt)

    cpp_mojo = [json.loads(l) for l in (REPO / "data/cpp_mojo_pairs.jsonl").read_text().splitlines() if l.strip()]
    cpp_py_raw = [json.loads(l) for l in (REPO / "data/sft/cpp_python_pairs.jsonl").read_text().splitlines() if l.strip()]
    # normalize cpp_python to expose cpp_source/function_name/arg_types like cpp_mojo
    cpp_py = [{"cpp_source": p["input"], "mojo_source": p["output"],
               "function_name": p["function_name"], "source_file": p["source_file"],
               "arg_types": [], "ret_type": "Real64"} for p in cpp_py_raw]
    # recover arg_types for python pairs from the matching cpp_mojo by name, else infer from sig
    byname = {p["function_name"]: p["arg_types"] for p in cpp_mojo}
    import re
    for p in cpp_py:
        if p["function_name"] in byname:
            p["arg_types"] = byname[p["function_name"]]
        else:
            m = re.search(r"\(([^)]*)\)", p["mojo_source"])
            p["arg_types"] = ["float"] * len([a for a in (m.group(1).split(",") if m else []) if a.strip()])

    held_names = set()
    heldout_recs = []
    train = {"mojo": [], "python": []}
    idx = 0
    for tag, tgt, ltag, pairs in [("mojo", "Mojo", "mojo", cpp_mojo), ("python", "Python", "python", cpp_py)]:
        ps = sorted(pairs, key=lambda x: x["function_name"])
        for i, p in enumerate(ps):
            if i % HOLDOUT_EVERY == 0:                      # held-out
                rec = verl_record(p, tgt, ltag, sysprompt, idx); idx += 1
                if rec:
                    heldout_recs.append(rec); held_names.add((tgt, p["function_name"]))
                    continue                                # excluded from train
            train[tag].append(tcs.record(p["cpp_source"], p["mojo_source"], tgt, ltag, sysprompt))

    (SFTDIR / "train_cpp_mojo_sft.jsonl").write_text("\n".join(json.dumps(r, ensure_ascii=False) for r in train["mojo"]))
    (SFTDIR / "train_cpp_python_sft.jsonl").write_text("\n".join(json.dumps(r, ensure_ascii=False) for r in train["python"]))
    (SFTDIR / "heldout_eval.jsonl").write_text("\n".join(json.dumps(r, ensure_ascii=False) for r in heldout_recs))
    (SFTDIR / "heldout_names.json").write_text(json.dumps(sorted(f"{t}:{n}" for t, n in held_names), indent=1))

    print(f"held-out eval (verl): {len(heldout_recs)} records -> heldout_eval.jsonl")
    print(f"  (mojo held {sum(1 for t,_ in held_names if t=='Mojo')}, python held {sum(1 for t,_ in held_names if t=='Python')})")
    print(f"train SFT: cpp_mojo {len(train['mojo'])}, cpp_python {len(train['python'])}  (held-out excluded)")
    print(f"  -> {SFTDIR}/")


if __name__ == "__main__":
    main()
