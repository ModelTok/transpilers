#!/usr/bin/env python3
"""Evaluate a model on the DIVERSE held-out (differential format).

Each record: {prompt:[system,user(C++ unit)], mojo_driver, cpp_ref_outputs}.
The model produces a Mojo unit; we splice it with the known-good mojo_driver,
compile+run, and compare stdout to cpp_ref_outputs. Measures transpilation across
construct types (classes, templates, strings, maps, ...), not just scalar fns.
"""
import argparse, importlib.util, json, os, subprocess, sys, tempfile
from collections import Counter
from pathlib import Path
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer

REPO = Path(__file__).resolve().parents[2]
_r = importlib.util.spec_from_file_location("rh", REPO / "scripts/sft/run_heldout_eval.py")
rh = importlib.util.module_from_spec(_r); sys.modules["rh"] = rh; _r.loader.exec_module(rh)
_d = importlib.util.spec_from_file_location("dv", REPO / "scripts/sft/diff_verify.py")
dv = importlib.util.module_from_spec(_d); sys.modules["dv"] = dv; _d.loader.exec_module(dv)
_mr = importlib.util.spec_from_file_location("mr", REPO / "scripts/sft/mojo_repair.py")
mr = importlib.util.module_from_spec(_mr); sys.modules["mr"] = mr; _mr.loader.exec_module(mr)
_repair = mr.repair_mojo
HELD = Path(os.environ.get("HELD", str(REPO / "data/sft/cpp_mojo/heldout_diverse.jsonl")))


def run_mojo(mojo_unit, mojo_driver):
    with tempfile.TemporaryDirectory() as td:
        t = Path(td)
        (t/"b.mojo").write_text(mojo_unit + "\n\n" + mojo_driver + "\n")
        try:
            r = subprocess.run([dv.MOJO_BIN,"build","-Xlinker","-ldl",str(t/"b.mojo"),"-o",str(t/"b")],
                               env=dv.MOJO_ENV, capture_output=True, text=True, timeout=150)
        except subprocess.TimeoutExpired:
            return None, "compile_timeout", ""
        if r.returncode != 0:
            errs = [l for l in r.stderr.splitlines() if ": error:" in l and "failed to parse" not in l]
            return None, "compile_error", (errs[0][:120] if errs else "link/parse")   # first SPECIFIC error
        try:
            r = subprocess.run([str(t/"b")], env=dv.MOJO_ENV, capture_output=True, text=True, timeout=30)
        except subprocess.TimeoutExpired:
            return None, "run_timeout", ""   # model emitted a hang/infinite loop
        if r.returncode != 0:
            return None, "runtime_error", (r.stderr.strip().splitlines() or [""])[-1][:120]
        return r.stdout.strip().splitlines(), "ok", ""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", default="Qwen/Qwen2.5-0.5B-Instruct")
    ap.add_argument("--adapter", default=None)
    ap.add_argument("--tag", default="diverse")
    args = ap.parse_args()
    _gpu = torch.cuda.is_available()   # ROCm iGPU presents as cuda (run with HSA_OVERRIDE_GFX_VERSION=11.0.0)
    _dev = "cuda" if _gpu else "cpu"
    tok = AutoTokenizer.from_pretrained(args.model)
    model = AutoModelForCausalLM.from_pretrained(args.model, dtype=(torch.bfloat16 if _gpu else torch.float32))
    if args.adapter:
        from peft import PeftModel
        model = PeftModel.from_pretrained(model, args.adapter)
    model.to(_dev).eval()
    print(f"eval device: {_dev}", flush=True)

    recs = [json.loads(l) for l in HELD.read_text().splitlines() if l.strip()]
    results = []
    for i, rec in enumerate(recs, 1):
        prompt = tok.apply_chat_template(rec["prompt"], tokenize=False, add_generation_prompt=True)
        ids = tok(prompt, return_tensors="pt").to(_dev)
        with torch.no_grad():
            g = model.generate(**ids, max_new_tokens=1024, do_sample=False, pad_token_id=tok.eos_token_id)
        out = tok.decode(g[0][ids["input_ids"].shape[1]:], skip_special_tokens=True)
        code = rh.extract_code(out, "mojo")
        detail = ""; repaired = False
        if not code:
            status = "no_code"
        else:
            mojo_out, st, detail = run_mojo(code, rec["mojo_driver"])
            if st == "compile_error":   # deterministic fixup: add missing math imports, retry once
                fixed = _repair(code)
                if fixed != code:
                    m2, s2, d2 = run_mojo(fixed, rec["mojo_driver"])
                    if s2 == "ok":
                        mojo_out, st, detail, repaired = m2, s2, d2, True
            if st != "ok":
                status = st
            else:
                ref = rec["cpp_ref_outputs"]
                ok = len(mojo_out) == len(ref) and all(
                    _bnorm(a) == _bnorm(b) or (_num(a) is not None and _num(b) is not None and abs(_num(a)-_num(b)) <= 1e-6*max(abs(_num(a)),abs(_num(b)),1e-9))
                    for a, b in zip(ref, mojo_out))
                status = "pass" if ok else "wrong_output"
        results.append({"name": rec["name"], "category": rec["category"], "status": status,
                        "detail": detail, "code": code or "", "repaired": repaired})   # persist for rerun-free diagnosis
        print(f"[{i}/{len(recs)}] {rec['category']:9s} {rec['name']:18s} {status.upper()}{' (repaired)' if repaired else ''}  {detail[:50]}", flush=True)

    json.dump(results, open(REPO/f"data/sft/cpp_mojo/diverse_{args.tag}.json","w"), indent=1)
    c = Counter(r["status"] for r in results)
    np_ = c.get("pass", 0); rep = sum(1 for r in results if r.get("repaired"))
    raw = np_ - rep   # passes the model achieved with no fixup
    print(f"\n=== {args.tag} DIVERSE === pass@1 {100*np_/len(results):.1f}% ({np_}/{len(results)})  "
          f"[raw {100*raw/len(results):.1f}% + repair {rep}]  {dict(c)}")


def _num(s):
    try: return float(_bnorm(s))
    except: return None


def _bnorm(s):   # Mojo prints bools as True/False; C++/ground-truth use 1/0
    s = s.strip()
    return "1" if s == "True" else "0" if s == "False" else s


if __name__ == "__main__":
    main()
