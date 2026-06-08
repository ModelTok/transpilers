#!/usr/bin/env python3
"""End-to-end EnergyPlus C++ -> Mojo migration tool.

For each input C++ function: generate K Mojo candidates with the fine-tuned model
(greedy + temperature) + deterministic repair, then VERIFY each against the C++
reference (differential: same inputs, same outputs within 1e-6, EP shims in scope).
Emit the FIRST candidate that verifies as accepted, verified Mojo — nothing that
fails the gate is ever accepted. This is the safe migration loop: the 0.5B is a
draft generator; the verifier is the trust boundary.

Input  : a JSONL of {function_name, cpp} (e.g. prod_test_cpp.jsonl, or extract more
         with prod_extract.py).
Output : data/sft/cpp_mojo/migrated.jsonl  {name, accepted: bool, mojo, tries}
         + a summary of how many real functions were safely migrated.
"""
import argparse, importlib.util, json, re, subprocess, sys, tempfile
from pathlib import Path
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer

REPO = Path(__file__).resolve().parents[2]; SFT = REPO / "data/sft/cpp_mojo"
def _load(n,p):
    s=importlib.util.spec_from_file_location(n,REPO/p); m=importlib.util.module_from_spec(s); sys.modules[n]=m; s.loader.exec_module(m); return m
rh=_load("rh","scripts/sft/run_heldout_eval.py"); dv=_load("dv","scripts/sft/diff_verify.py"); mr=_load("mr","scripts/sft/mojo_repair.py")
dc=_load("dc","scripts/sft/dep_context.py")   # deterministic dependency-context injection
fs=_load("fs","scripts/sft/few_shot.py")       # TF-IDF few-shot example retrieval
ORACLE=(SFT/"ep_oracle.h").read_text(); PRELUDE=(SFT/"ep_prelude.mojo").read_text(); SYS=(SFT/"system.txt").read_text()
SAMPLES=[-45.0,-1.0,0.0,0.5,2.5,30.0,190.0,273.15,310.0,400.0]

def nargs(sig,kind):
    pat = r"\bReal64\s+(?:\w+::)?\w+\s*\(([^)]*)\)" if kind=="cpp" else r"\bdef\s+\w+\s*\(([^)]*)\)"
    m=re.search(pat,sig);
    if not m: return None
    a=m.group(1).strip(); return 0 if not a else len([x for x in a.split(",") if x.strip()])
def cname(c): m=re.search(r"\bReal64\s+(?:\w+::)?(\w+)\s*\(",c); return m.group(1) if m else None
def mname(m_): x=re.search(r"\bdef\s+(\w+)\s*\(",m_); return x.group(1) if x else None
def rows(n,k=8): return [[SAMPLES[(i+j)%len(SAMPLES)] for j in range(n)] for i in range(k)]
def _num(s):
    try: return float("1" if s.strip()=="True" else "0" if s.strip()=="False" else s)
    except: return None

def cpp_ref(cpp,name,rs):
    calls="\n".join('  printf("%.12g\\n",(double)'+name+"("+",".join(str(v) for v in r)+"));" for r in rs)
    src="#include <cstdio>\n#include <cmath>\n#include <algorithm>\n#include <cstdlib>\nusing namespace std;\n"+ORACLE+"\n"+cpp+f"\nint main(){{\n{calls}\n return 0;}}\n"
    with tempfile.TemporaryDirectory() as td:
        t=Path(td); (t/"a.cpp").write_text(src)
        if subprocess.run(["g++","-O2","-std=c++17","-o",str(t/"a"),str(t/"a.cpp")],capture_output=True).returncode: return None
        r=subprocess.run([str(t/"a")],capture_output=True,text=True,timeout=20); return r.stdout.strip().splitlines() if r.returncode==0 else None

def mojo_run(code,name,rs):
    calls="\n".join("    print("+name+"("+",".join(f"Float64({v})" for v in r)+"))" for r in rs)
    src=PRELUDE+"\n"+code+f"\n\ndef main():\n{calls}\n"
    with tempfile.TemporaryDirectory() as td:
        t=Path(td); (t/"m.mojo").write_text(src)
        if subprocess.run([dv.MOJO_BIN,"build","-Xlinker","-ldl",str(t/"m.mojo"),"-o",str(t/"m")],env=dv.MOJO_ENV,capture_output=True,text=True,timeout=150).returncode: return None
        try: r=subprocess.run([str(t/"m")],env=dv.MOJO_ENV,capture_output=True,text=True,timeout=20)
        except subprocess.TimeoutExpired: return None
        return r.stdout.strip().splitlines() if r.returncode==0 else None

def faithful(ref,out):
    if ref is None or out is None or len(ref)!=len(out): return False
    import math
    for a,b in zip(ref,out):
        fa,fb=_num(a),_num(b)
        if fa is not None and fb is not None:
            if math.isnan(fa) and math.isnan(fb): continue
            if abs(fa-fb)<=1e-6*max(abs(fa),abs(fb),1e-9): continue
            return False
        if a.strip()!=b.strip(): return False
    return True

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--model",default="Qwen/Qwen2.5-Coder-0.5B-Instruct")
    ap.add_argument("--adapter",default=str(SFT/"adapter_15b_v2"))
    ap.add_argument("--inputs",default=str(SFT/"prod_test_cpp.jsonl"))
    ap.add_argument("--k",type=int,default=5)
    ap.add_argument("--fewshot",type=int,default=0,help="prepend N retrieved few-shot examples")
    args=ap.parse_args()
    gpu=torch.cuda.is_available(); dev="cuda" if gpu else "cpu"
    tok=AutoTokenizer.from_pretrained(args.model)
    model=AutoModelForCausalLM.from_pretrained(args.model,dtype=(torch.bfloat16 if gpu else torch.float32))
    from peft import PeftModel; model=PeftModel.from_pretrained(model,args.adapter); model.to(dev).eval()
    print(f"migrate | {args.adapter} | pass@{args.k} | {dev}",flush=True)
    recs=[json.loads(l) for l in Path(args.inputs).read_text().splitlines() if l.strip()]
    out=[]; accepted=0
    for i,rec in enumerate(recs,1):
        cpp=rec["cpp"]; cn=cname(cpp); nc=nargs(cpp,"cpp"); rs=rows(nc or 1)
        ref=cpp_ref(cpp,cn,rs)
        try: ctx=dc.context_for(cpp)
        except Exception: ctx=""
        ctxblock=(f"These symbols are already in scope — call them directly, do not redefine:\n{ctx}\n\n" if ctx else "")
        fsblock=fs.fewshot_block(cpp, args.fewshot) if args.fewshot else ""
        instr=f"Transpile the provided C++ implementation into a functionally equivalent implementation in Mojo.\n\n{fsblock}{ctxblock}```cpp\n{cpp.strip()}\n```"
        prompt=tok.apply_chat_template([{"role":"system","content":SYS},{"role":"user","content":instr}],tokenize=False,add_generation_prompt=True)
        ids=tok(prompt,return_tensors="pt").to(dev)
        acc=None; tries=0
        for kk in range(args.k):
            tries=kk+1
            with torch.no_grad():
                g=model.generate(**ids,max_new_tokens=1600,do_sample=(kk>0),temperature=0.8,top_p=0.95,pad_token_id=tok.eos_token_id) if kk>0 else model.generate(**ids,max_new_tokens=1600,do_sample=False,pad_token_id=tok.eos_token_id)
            code=rh.extract_code(tok.decode(g[0][ids["input_ids"].shape[1]:],skip_special_tokens=True),"mojo")
            if not code: continue
            for cand in (code,mr.repair_mojo(code)):
                mn=mname(cand)
                if mn and nargs(cand,"mojo")==nc and ref is not None and faithful(ref,mojo_run(cand,mn,rs)):
                    acc=cand; break
            if acc: break
        out.append({"name":rec["function_name"],"accepted":acc is not None,"tries":tries,"mojo":acc or ""})
        accepted+=acc is not None
        print(f"[{i}/{len(recs)}] {rec['function_name']:30s} {'ACCEPTED (try '+str(tries)+')' if acc else 'rejected'}",flush=True)
    json.dump(out,open(SFT/"migrated.json","w"),indent=1)
    print(f"\n=== MIGRATION === {accepted}/{len(recs)} functions safely migrated (verified Mojo) at pass@{args.k} -> {SFT/'migrated.json'}")

if __name__=="__main__":
    main()
