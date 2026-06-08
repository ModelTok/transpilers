#!/usr/bin/env python3
"""Assemble the 131-pair C++→Mojo training set: 98 scalar + 33 diverse.

Produces (overwriting the cpp_mojo model files so train_05b/eval_05b use them):
  data/sft/cpp_mojo/train_translation.jsonl  — CodePivot schema, scalar+diverse, rich <think>
  data/sft/cpp_mojo/heldout_eval.jsonl       — scalar held-out, verl format (eval_05b)
  data/sft/cpp_mojo/heldout_diverse.jsonl    — diverse held-out, differential format
  (mojo_acquisition.json reused as-is)

Larger held-out (≈32) than the prior 17 → less eval noise.
"""
from __future__ import annotations
import importlib.util, json, subprocess, sys, tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SFT = REPO / "data/sft/cpp_mojo"
sys.path.insert(0, str(REPO / "src"))
def _load(n, p):
    s = importlib.util.spec_from_file_location(n, REPO / p); m = importlib.util.module_from_spec(s)
    sys.modules[n] = m; s.loader.exec_module(m); return m
tcs = _load("tcs", "scripts/sft/to_codepivot_schema.py")
split = _load("split", "scripts/sft/build_codepivot_split.py")
dv = _load("dv", "scripts/sft/diff_verify.py")
sysp = tcs.system_prompt()


def existing_reasoning():
    """{function_name: reasoning} preserved from the current train_translation.jsonl."""
    import re
    rmap = {}
    f = SFT / "train_translation.jsonl"
    if f.exists():
        for l in f.read_text().splitlines():
            if not l.strip(): continue
            r = json.loads(l)
            m = re.search(r'```cpp\n\s*\w[\w:<>]*\s+([A-Za-z_]\w+)\s*\(', r['instruction'])
            t = r['output'].split('<think>')[1].split('</think>')[0].strip() if '<think>' in r['output'] else ''
            if m and t: rmap[m.group(1)] = t
    return rmap


def diverse_reasoning():
    rmap = {}
    for p in (SFT.parent / "diverse/_reason_out").glob("batch_*.jsonl"):
        for l in p.read_text().splitlines():
            if l.strip():
                r = json.loads(l); rmap[r['name']] = r['reasoning'].strip()
    return rmap


# Category-aware <think> for the ~280 diverse pairs that have no hand-written
# reasoning trace — far better training signal than a single generic stub.
_CAT_NOTE = {
    "class":    "a C++ `class` becomes a Mojo `struct` (`@fieldwise_init`, traits in parens); methods that mutate take `mut self`, the constructor takes `out self`",
    "struct":   "a C++ `struct` maps to a Mojo `struct` with `@fieldwise_init`; fields and free helper functions carry over directly",
    "operator": "C++ `operator+/-/*/==/<` overloads become Mojo dunders `__add__`/`__sub__`/`__mul__`/`__eq__`/`__lt__` on the struct",
    "template": "a C++ `template<typename T>` becomes a Mojo parametric function/struct; generic arithmetic uses the `[dt: DType]` + `Scalar[dt]` route, comparison-only generics use a `Comparable & ImplicitlyCopyable` bound",
    "string":   "Mojo `String` is UTF-8: index with `s[byte=i]`, iterate via `s.codepoints()`/`s.codepoint_slices()`, build with `+= String(...)`; predicates return 0/1, not `Bool`",
    "error":    "C++ exceptions/validation map to Mojo `raises` + `raise Error(...)` with `try/except`; the function and `main` are marked `raises`",
    "array":    "C++ `std::vector`/arrays map to Mojo `List` with bracket literals; `min`/`max` are free functions, in-place ops take `mut`, returns transfer with `^`",
    "matrix":   "nested `std::vector` maps to `List[List[Float64]]`; index loops and explicit `Float64(...)` conversions are preserved",
    "map":      "C++ `std::map` maps to Mojo `Dict`; iterate `for e in d.items(): e.key, e.value`; lookups use fixed known keys so output stays deterministic (Dict is unordered)",
    "enum":     "C++ `enum` has no Mojo keyword, so it becomes module-level `comptime` Int constants; the `switch` becomes `if/elif/else`",
    "bitops":   "bitwise `& | ^ ~ << >>` carry over directly; unsigned 64-bit types are used both sides so widths agree",
    "recursion":"the recursive call structure is preserved verbatim; integer division uses `//`",
    "control":  "loops and branches translate directly; `switch` becomes `if/elif/else`, integer division uses `//`",
    "math":     "scalar math maps directly using `from std.math import ...` (intrinsic-backed funcs); `**` for powers, explicit `Float64`/`Int` conversions",
    "numeric":  "a pure scalar numeric routine; arithmetic and `std.math` calls map directly, `**` for powers, with explicit numeric conversions",
    "algo":     "a self-contained algorithm; loop/branch structure and integer (`//`) vs float division are preserved exactly",
}


def diverse_fallback_reason(p):
    cat = p.get("category", "?")
    note = _CAT_NOTE.get(cat, "the construct maps to idiomatic Mojo 1.0")
    return (f"This is a `{cat}` translation. In Mojo 1.0, {note}. The names and control "
            f"flow are kept identical, so behavior matches; this pair was differentially "
            f"verified — both sides compile, run, and produce the same stdout.")


def cpp_ref_outputs(cpp_unit, cpp_driver):
    with tempfile.TemporaryDirectory() as td:
        t = Path(td)
        (t/"a.cpp").write_text(dv.CPP_PRE + cpp_unit + "\n" + cpp_driver + "\n")
        if subprocess.run(["g++","-O2","-std=c++17","-o",str(t/"a"),str(t/"a.cpp")],capture_output=True).returncode: return None
        r = subprocess.run([str(t/"a")],capture_output=True,text=True,timeout=30)
        return r.stdout.strip().splitlines() if r.returncode == 0 else None


def main():
    scal_reason = existing_reasoning()
    div_reason = diverse_reasoning()

    # --- scalar pairs (98 + bundled), dedup by name ---
    scalar = {}
    for fn in ["data/cpp_mojo_pairs.jsonl", "data/cpp_mojo_pairs_bundled.jsonl"]:
        fp = REPO / fn
        if fp.exists():
            for l in fp.read_text().splitlines():
                if l.strip():
                    p = json.loads(l); scalar.setdefault(p['function_name'], p)
    scalar = sorted(scalar.values(), key=lambda x: x['function_name'])
    import os
    FROZEN = os.environ.get("FROZEN") == "1"   # use the permanent leakage-free benchmark
    BM = SFT.parent / "benchmark"
    s_held = [p for i,p in enumerate(scalar) if i%4==0]; s_tr=[p for i,p in enumerate(scalar) if i%4!=0]
    if FROZEN and (BM/"frozen_diverse.jsonl").exists():
        d_tr = sorted([json.loads(l) for l in (BM/"train_pool_diverse.jsonl").read_text().splitlines() if l.strip()], key=lambda x: x['name'])
        d_held = sorted([json.loads(l) for l in (BM/"frozen_diverse.jsonl").read_text().splitlines() if l.strip()], key=lambda x: x['name'])
        diverse = d_tr + d_held
        print(f"[FROZEN] scalar={len(scalar)} diverse train={len(d_tr)} held={len(d_held)}")
    else:
        diverse = sorted([json.loads(l) for l in (SFT.parent/"diverse/verified.jsonl").read_text().splitlines() if l.strip()],
                         key=lambda x: x['name'])
        print(f"scalar={len(scalar)} diverse={len(diverse)} total={len(scalar)+len(diverse)}")
        d_held = [p for i,p in enumerate(diverse) if i%3==0]; d_tr=[p for i,p in enumerate(diverse) if i%3!=0]
    # leakage guard: drop held-out scalar whose name is a bundled helper in any train cpp
    import re
    train_def=set()
    for p in s_tr:
        for m in re.finditer(r'(?:Real64|double|float|int|Int|bool|Nandle)\s+([A-Za-z_]\w+)\s*\(', p['cpp_source']):
            train_def.add(m.group(1))
    s_held=[p for p in s_held if p['function_name'] not in train_def]

    # --- TRAIN records (CodePivot schema) ---
    rows = []
    for p in s_tr:
        rz = scal_reason.get(p['function_name']) or tcs.reasoning(p['cpp_source'], p['mojo_source'], "Mojo")
        instr = f"Transpile the provided C++ implementation into a functionally equivalent implementation in Mojo.\n\n```cpp\n{p['cpp_source'].strip()}\n```"
        rows.append({"instruction":instr,"input":"","system":sysp,
                     "output":f"<think>\n{rz}\n</think>\n<answer>\n```mojo\n{p['mojo_source'].strip()}\n```\n</answer>"})
    for p in d_tr:
        rz = div_reason.get(p['name']) or diverse_fallback_reason(p)
        instr = f"Transpile the provided C++ implementation into a functionally equivalent implementation in Mojo.\n\n```cpp\n{p['cpp_unit'].strip()}\n```"
        rows.append({"instruction":instr,"input":"","system":sysp,
                     "output":f"<think>\n{rz}\n</think>\n<answer>\n```mojo\n{p['mojo_unit'].strip()}\n```\n</answer>"})
    (SFT/"train_translation.jsonl").write_text("\n".join(json.dumps(r,ensure_ascii=False) for r in rows))

    # --- scalar held-out (verl) ---
    hrecs=[]
    for i,p in enumerate(s_held):
        pair={"cpp_source":p['cpp_source'],"function_name":p['function_name'],"source_file":p.get('source_file','?'),
              "arg_types":p['arg_types'],"ret_type":p['ret_type']}
        r=split.verl_record(pair,"Mojo","mojo",sysp,i)
        if r: hrecs.append(r)
    (SFT/"heldout_eval.jsonl").write_text("\n".join(json.dumps(r,ensure_ascii=False) for r in hrecs))

    # --- diverse held-out (differential: cpp ref outputs + mojo driver) ---
    drecs=[]
    for p in d_held:
        ref=cpp_ref_outputs(p['cpp_unit'],p['cpp_driver'])
        if not ref: continue
        instr=f"Transpile the provided C++ implementation into a functionally equivalent implementation in Mojo.\n\n```cpp\n{p['cpp_unit'].strip()}\n```"
        drecs.append({"name":p['name'],"category":p['category'],"prompt":[{"role":"system","content":sysp},{"role":"user","content":instr}],
                      "mojo_driver":p['mojo_driver'],"cpp_ref_outputs":ref,"eval_mode":"diverse_differential"})
    (SFT/"heldout_diverse.jsonl").write_text("\n".join(json.dumps(r,ensure_ascii=False) for r in drecs))

    print(f"TRAIN: {len(rows)} ({len(s_tr)} scalar + {len(d_tr)} diverse)")
    print(f"HELD-OUT scalar(verl): {len(hrecs)}  |  diverse(differential): {len(drecs)}")


if __name__ == "__main__":
    main()
