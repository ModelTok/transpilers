#!/usr/bin/env python3
"""Run the fine-tuned 1.5B (adapter_15b_v2, bilingual no-think) on REAL
energyplus-mojo scalar LEAF functions (Python->Mojo), behind the differential
verify gate. The model drafts the Mojo; we accept ONLY outputs that compile and
reproduce the Python's output on the sampled inputs.

Input: data/sft/cpp_mojo/py_leaves.jsonl (from extract_py_leaves.py).
For each leaf: pass@k generate (greedy + temp) -> extract Mojo -> mirror the
python_driver in Mojo -> compile+run -> compare to the Python driver's stdout
(numeric tol / bool norm). Report per-function + overall yield. Accepted Mojo is
written to data/sft/cpp_mojo/leaves_migrated.json.
"""
import argparse, importlib.util, json, subprocess, sys, tempfile
from pathlib import Path
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer

REPO = Path(__file__).resolve().parents[2]; SFT = REPO / "data/sft/cpp_mojo"
def _load(n, p):
    s = importlib.util.spec_from_file_location(n, REPO / p); m = importlib.util.module_from_spec(s)
    sys.modules[n] = m; s.loader.exec_module(m); return m
RH = _load("rh", "scripts/sft/run_heldout_eval.py")
DV = _load("dv", "scripts/sft/diff_verify.py")
PV = _load("pv", "scripts/sft/py_verify.py")
MR = _load("mr", "scripts/sft/mojo_repair.py")
SYS = (SFT / "system.txt").read_text()


def run_py(unit, driver):
    with tempfile.TemporaryDirectory() as td:
        t = Path(td); (t / "a.py").write_text(unit + "\n\n" + driver + "\n")
        r = subprocess.run([sys.executable, str(t / "a.py")], capture_output=True, text=True, timeout=30)
        return r.stdout.strip().splitlines() if r.returncode == 0 else None


def run_mojo(code, mojo_driver):
    with tempfile.TemporaryDirectory() as td:
        t = Path(td); (t / "b.mojo").write_text(code + "\n\n" + mojo_driver + "\n")
        c = subprocess.run([DV.MOJO_BIN, "build", "-Xlinker", "-ldl", str(t / "b.mojo"), "-o", str(t / "b")],
                           env=DV.MOJO_ENV, capture_output=True, text=True, timeout=150)
        if c.returncode:
            errs = [l for l in c.stderr.splitlines() if ": error:" in l]
            return None, "compile:" + (errs[-1][:60] if errs else "?")
        try:
            r = subprocess.run([str(t / "b")], env=DV.MOJO_ENV, capture_output=True, text=True, timeout=30)
        except subprocess.TimeoutExpired:
            return None, "timeout"
        return (r.stdout.strip().splitlines() if r.returncode == 0 else None), ("ok" if r.returncode == 0 else "run")


def lines_eq(a, b):
    return len(a) == len(b) and all(PV._lines_eq(x, y) for x, y in zip(a, b))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", default="Qwen/Qwen2.5-Coder-1.5B-Instruct")
    ap.add_argument("--adapter", default=str(SFT / "adapter_15b_v2"))
    ap.add_argument("--k", type=int, default=3)
    args = ap.parse_args()
    leaves = [json.loads(l) for l in (SFT / "py_leaves.jsonl").read_text().splitlines() if l.strip()]
    gpu = torch.cuda.is_available(); dev = "cuda" if gpu else "cpu"
    tok = AutoTokenizer.from_pretrained(args.model)
    model = AutoModelForCausalLM.from_pretrained(args.model, dtype=(torch.bfloat16 if gpu else torch.float32))
    from peft import PeftModel; model = PeftModel.from_pretrained(model, args.adapter); model.to(dev).eval()
    print(f"1.5B on {len(leaves)} energyplus-mojo scalar leaves | {args.adapter} | pass@{args.k} | {dev}", flush=True)
    accepted = []; npass = 0
    for i, lf in enumerate(leaves, 1):
        exp = run_py(lf["python_unit"], lf["python_driver"])
        if not exp:
            print(f"[{i}/{len(leaves)}] {lf['name']:28s} SKIP (python oracle failed)", flush=True); continue
        # mirror the python_driver in a Mojo main()
        mojo_driver = "def main():\n" + "\n".join("    " + ln for ln in lf["python_driver"].splitlines())
        instr = ("Transpile the provided Python implementation into a functionally equivalent "
                 f"implementation in Mojo.\n\n```python\n{lf['python_unit'].strip()}\n```")
        prompt = tok.apply_chat_template([{"role": "system", "content": SYS}, {"role": "user", "content": instr}],
                                         tokenize=False, add_generation_prompt=True)
        ids = tok(prompt, return_tensors="pt").to(dev)
        ok = False; detail = ""
        for kk in range(args.k):
            with torch.no_grad():
                g = (model.generate(**ids, max_new_tokens=640, do_sample=False, pad_token_id=tok.eos_token_id)
                     if kk == 0 else
                     model.generate(**ids, max_new_tokens=640, do_sample=True, temperature=0.8, top_p=0.95, pad_token_id=tok.eos_token_id))
            code = RH.extract_code(tok.decode(g[0][ids["input_ids"].shape[1]:], skip_special_tokens=True), "mojo")
            if not code:
                detail = "no_code"; continue
            for cand in (code, MR.repair_mojo(code)):
                out, st = run_mojo(cand, mojo_driver)
                if out is not None and lines_eq(out, exp):
                    ok = True; code = cand; break
                detail = st
            if ok:
                break
        npass += ok
        if ok:
            accepted.append({"name": lf["name"], "source_file": lf["source_file"], "mojo": code})
        print(f"[{i}/{len(leaves)}] {lf['name']:28s} {'VERIFIED' if ok else 'fail ('+detail+')'}", flush=True)
    json.dump(accepted, open(SFT / "leaves_migrated.json", "w"), indent=1)
    print(f"\n=== 1.5B on energyplus-mojo leaves: {npass}/{len(leaves)} VERIFIED (pass@{args.k}) ===")
    print(f"accepted -> {SFT/'leaves_migrated.json'}")


if __name__ == "__main__":
    main()
