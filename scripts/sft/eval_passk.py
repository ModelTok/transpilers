#!/usr/bin/env python3
"""pass@k generate-and-verify on the diverse held-out.

A transpiler doesn't need to be right first try — it needs ONE candidate that
passes the differential-verify gate. For each held-out item, sample K candidates
(greedy first, then temperature) + deterministic repair, and accept the item if
ANY candidate compiles+runs+matches the C++ reference. Reports pass@1 vs pass@k —
the realistic "usable within K tries" rate for actual migration use.
"""
import argparse, importlib.util, json, subprocess, sys, tempfile
from collections import Counter
from pathlib import Path
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer

REPO = Path(__file__).resolve().parents[2]; SFT = REPO / "data/sft/cpp_mojo"
def _load(n, p):
    s = importlib.util.spec_from_file_location(n, REPO/p); m = importlib.util.module_from_spec(s)
    sys.modules[n] = m; s.loader.exec_module(m); return m
rh = _load("rh", "scripts/sft/run_heldout_eval.py")
dv = _load("dv", "scripts/sft/diff_verify.py")
mr = _load("mr", "scripts/sft/mojo_repair.py")
HELD = SFT / "heldout_diverse.jsonl"

def run_mojo(code, driver):
    with tempfile.TemporaryDirectory() as td:
        t = Path(td); (t/"b.mojo").write_text(code + "\n\n" + driver + "\n")
        try:
            c = subprocess.run([dv.MOJO_BIN,"build","-Xlinker","-ldl",str(t/"b.mojo"),"-o",str(t/"b")],env=dv.MOJO_ENV,capture_output=True,text=True,timeout=150)
        except subprocess.TimeoutExpired: return None
        if c.returncode: return None
        try: r = subprocess.run([str(t/"b")],env=dv.MOJO_ENV,capture_output=True,text=True,timeout=30)
        except subprocess.TimeoutExpired: return None
        return r.stdout.strip().splitlines() if r.returncode==0 else None

def _num(s):
    try: return float("1" if s.strip()=="True" else "0" if s.strip()=="False" else s)
    except: return None

def matches(ref, out):
    if out is None or len(out)!=len(ref): return False
    for a,b in zip(ref,out):
        fa,fb=_num(a),_num(b)
        if fa is not None and fb is not None and abs(fa-fb)<=1e-6*max(abs(fa),abs(fb),1e-9): continue
        if a.strip()==b.strip(): continue
        return False
    return True

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", default="Qwen/Qwen2.5-Coder-0.5B-Instruct")
    ap.add_argument("--adapter", default=str(SFT/"adapter_15b_v2"))
    ap.add_argument("--k", type=int, default=5)
    ap.add_argument("--tag", default="passk")
    args = ap.parse_args()
    gpu = torch.cuda.is_available(); dev = "cuda" if gpu else "cpu"
    tok = AutoTokenizer.from_pretrained(args.model)
    model = AutoModelForCausalLM.from_pretrained(args.model, dtype=(torch.bfloat16 if gpu else torch.float32))
    from peft import PeftModel
    model = PeftModel.from_pretrained(model, args.adapter); model.to(dev).eval()
    print(f"pass@{args.k} | {args.adapter} on {dev}", flush=True)

    recs = [json.loads(l) for l in HELD.read_text().splitlines() if l.strip()]
    p1 = pk = 0
    for i, rec in enumerate(recs, 1):
        prompt = tok.apply_chat_template(rec["prompt"], tokenize=False, add_generation_prompt=True)
        ids = tok(prompt, return_tensors="pt").to(dev)
        ref = rec["cpp_ref_outputs"]; first_ok = False; any_ok = False
        for kk in range(args.k):
            with torch.no_grad():
                if kk == 0:
                    g = model.generate(**ids, max_new_tokens=1024, do_sample=False, pad_token_id=tok.eos_token_id)
                else:
                    g = model.generate(**ids, max_new_tokens=1024, do_sample=True, temperature=0.8, top_p=0.95, pad_token_id=tok.eos_token_id)
            out = tok.decode(g[0][ids["input_ids"].shape[1]:], skip_special_tokens=True)
            code = rh.extract_code(out, "mojo")
            if not code: continue
            for variant in (code, mr.repair_mojo(code)):   # raw then repaired
                mo = run_mojo(variant, rec["mojo_driver"])
                if matches(ref, mo):
                    any_ok = True
                    if kk == 0: first_ok = True
                    break
            if any_ok: break
        p1 += first_ok; pk += any_ok
        print(f"[{i}/{len(recs)}] {rec['category']:9s} {rec['name']:18s} pass@1={int(first_ok)} pass@{args.k}={int(any_ok)}", flush=True)
    n = len(recs)
    print(f"\n=== {args.tag} === pass@1 {100*p1/n:.1f}% ({p1}/{n})  pass@{args.k} {100*pk/n:.1f}% ({pk}/{n})")

if __name__ == "__main__":
    main()
