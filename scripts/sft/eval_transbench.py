#!/usr/bin/env python3
"""Evaluate the fine-tuned model on transpilation-bench (the purpose-built C++->Mojo
benchmark: 40 concept-diverse tasks, 4 difficulty tiers, each with args->expected
tests). Principled, comparable Pass@1 by tier — far better than the ad-hoc ruler.

For each task: prompt the model with cpp_source -> generate Mojo -> for every test,
build `{code}\n\ndef main(): print(name(args))`, compile+run (our Mojo env w/ the
-Xlinker -ldl fix), compare stdout to expected. Pass iff ALL tests match.
"""
import argparse, importlib.util, json, subprocess, sys, tempfile
from collections import Counter, defaultdict
from pathlib import Path
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer

REPO = Path(__file__).resolve().parents[2]; SFT = REPO / "data/sft/cpp_mojo"
BENCH = REPO / "benchmarks/tasks"  # task set moved here from transpilation-bench/benchmarks/tasks
rh = (lambda s: (s.loader.exec_module(__import__('types').ModuleType('rh')) or None))  # placeholder
def _load(n,p):
    s=importlib.util.spec_from_file_location(n,REPO/p); m=importlib.util.module_from_spec(s); sys.modules[n]=m; s.loader.exec_module(m); return m
RH=_load("rh","scripts/sft/run_heldout_eval.py"); DV=_load("dv","scripts/sft/diff_verify.py"); MR=_load("mr","scripts/sft/mojo_repair.py")
SYS=(SFT/"system.txt").read_text()

def mojo_call(code, name, args_lit):
    src = f"{code}\n\ndef main() raises:\n    print({name}({args_lit}))\n"
    with tempfile.TemporaryDirectory() as td:
        t=Path(td); (t/"m.mojo").write_text(src)
        c=subprocess.run([DV.MOJO_BIN,"build","-Xlinker","-ldl",str(t/"m.mojo"),"-o",str(t/"m")],env=DV.MOJO_ENV,capture_output=True,text=True,timeout=150)
        if c.returncode: return None, "compile"
        try: r=subprocess.run([str(t/"m")],env=DV.MOJO_ENV,capture_output=True,text=True,timeout=30)
        except subprocess.TimeoutExpired: return None,"timeout"
        return (r.stdout.strip() if r.returncode==0 else None), ("ok" if r.returncode==0 else "run")

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--model",default="Qwen/Qwen2.5-Coder-1.5B-Instruct")
    ap.add_argument("--adapter",default=str(SFT/"adapter_15b_v2"))
    ap.add_argument("--k",type=int,default=1)
    ap.add_argument("--source",default="cpp_source",choices=["cpp_source","python_reference"])
    args=ap.parse_args()
    SRCLANG={"cpp_source":("C++","cpp"),"python_reference":("Python","python")}[args.source]
    gpu=torch.cuda.is_available(); dev="cuda" if gpu else "cpu"
    tok=AutoTokenizer.from_pretrained(args.model)
    model=AutoModelForCausalLM.from_pretrained(args.model,dtype=(torch.bfloat16 if gpu else torch.float32))
    from peft import PeftModel; model=PeftModel.from_pretrained(model,args.adapter); model.to(dev).eval()
    tasks=sorted(BENCH.glob("*.json"))
    print(f"transpilation-bench: {len(tasks)} tasks | src={args.source} ({SRCLANG[0]}->Mojo) | {args.adapter} pass@{args.k} on {dev}",flush=True)
    bytier=defaultdict(lambda:[0,0]); npass=0; rows=[]
    for tf in tasks:
        d=json.loads(tf.read_text()); name=d["name"]; tier=d["tier"]
        src=d.get(args.source)
        if not src: continue
        instr=f"Transpile the provided {SRCLANG[0]} implementation into a functionally equivalent implementation in Mojo.\n\n```{SRCLANG[1]}\n{src.strip()}\n```"
        prompt=tok.apply_chat_template([{"role":"system","content":SYS},{"role":"user","content":instr}],tokenize=False,add_generation_prompt=True)
        ids=tok(prompt,return_tensors="pt").to(dev)
        ok=False
        for kk in range(args.k):
            with torch.no_grad():
                g=model.generate(**ids,max_new_tokens=1024,do_sample=(kk>0),temperature=0.8,top_p=0.95,pad_token_id=tok.eos_token_id) if kk>0 else model.generate(**ids,max_new_tokens=1024,do_sample=False,pad_token_id=tok.eos_token_id)
            code=RH.extract_code(tok.decode(g[0][ids["input_ids"].shape[1]:],skip_special_tokens=True),"mojo")
            if not code: continue
            for cand in (code, MR.repair_mojo(code)):
                allpass=True
                for test in d["tests"]:
                    al=", ".join(repr(a) for a in test["args"])
                    out,st=mojo_call(cand,name,al)
                    if out is None or out.strip()!=test["expected"].strip(): allpass=False; break
                if allpass: ok=True; break
            if ok: break
        bytier[tier][0]+=ok; bytier[tier][1]+=1; npass+=ok
        print(f"[{d['id']}] T{tier} {d['concept']:24s} {'PASS' if ok else 'fail'}",flush=True)
    print(f"\n=== transpilation-bench (Mojo) pass@{args.k}: {100*npass/len(tasks):.1f}% ({npass}/{len(tasks)}) ===")
    for t in sorted(bytier): p,n=bytier[t]; print(f"  Tier {t}: {p}/{n}")

if __name__=="__main__":
    main()
