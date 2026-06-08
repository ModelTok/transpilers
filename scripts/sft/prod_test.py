#!/usr/bin/env python3
"""Production reality-check: run the best fine-tuned model on FRESH, unseen real
EnergyPlus C++ functions and record whether the generated Mojo compiles. No
ground truth (these aren't in any pair set) -> compile is the objective signal;
faithfulness is judged by review. Saves prod_results.json with the generated code.
"""
import argparse, importlib.util, json, subprocess, sys, tempfile
from pathlib import Path
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer

REPO = Path(__file__).resolve().parents[2]
SFT = REPO / "data/sft/cpp_mojo"
_r = importlib.util.spec_from_file_location("rh", REPO/"scripts/sft/run_heldout_eval.py")
rh = importlib.util.module_from_spec(_r); sys.modules["rh"] = rh; _r.loader.exec_module(rh)
_d = importlib.util.spec_from_file_location("dv", REPO/"scripts/sft/diff_verify.py")
dv = importlib.util.module_from_spec(_d); sys.modules["dv"] = dv; _d.loader.exec_module(dv)
PRELUDE = (SFT/"ep_prelude.mojo").read_text()
SYS = (SFT/"system.txt").read_text()

def compiles(code):
    # try standalone first, then with the EP prelude prepended
    for variant, src in (("standalone", code), ("with_prelude", PRELUDE + "\n" + code)):
        with tempfile.TemporaryDirectory() as td:
            t = Path(td); (t/"m.mojo").write_text(src + "\n\ndef main():\n    pass\n")
            r = subprocess.run([dv.MOJO_BIN,"build","-Xlinker","-ldl",str(t/"m.mojo"),"-o",str(t/"m")],
                               env=dv.MOJO_ENV, capture_output=True, text=True, timeout=150)
            if r.returncode == 0:
                return variant, ""
            errs = [l for l in r.stderr.splitlines() if ": error:" in l and "failed to parse" not in l]
            last_err = errs[0][:140] if errs else "link/parse"
    return None, last_err

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", default="Qwen/Qwen2.5-Coder-0.5B-Instruct")
    ap.add_argument("--adapter", default=str(SFT/"adapter_coder507"))
    args = ap.parse_args()
    gpu = torch.cuda.is_available(); dev = "cuda" if gpu else "cpu"
    tok = AutoTokenizer.from_pretrained(args.model)
    model = AutoModelForCausalLM.from_pretrained(args.model, dtype=(torch.bfloat16 if gpu else torch.float32))
    from peft import PeftModel
    model = PeftModel.from_pretrained(model, args.adapter); model.to(dev).eval()
    print(f"model {args.adapter} on {dev}", flush=True)

    recs = [json.loads(l) for l in (SFT/"prod_test_cpp.jsonl").read_text().splitlines() if l.strip()]
    results = []
    for i, rec in enumerate(recs, 1):
        instr = f"Transpile the provided C++ implementation into a functionally equivalent implementation in Mojo.\n\n```cpp\n{rec['cpp'].strip()}\n```"
        msgs = [{"role":"system","content":SYS},{"role":"user","content":instr}]
        prompt = tok.apply_chat_template(msgs, tokenize=False, add_generation_prompt=True)
        ids = tok(prompt, return_tensors="pt").to(dev)
        with torch.no_grad():
            g = model.generate(**ids, max_new_tokens=1600, do_sample=False, pad_token_id=tok.eos_token_id)
        out = tok.decode(g[0][ids["input_ids"].shape[1]:], skip_special_tokens=True)
        code = rh.extract_code(out, "mojo")
        if not code:
            status, variant, err = "no_code", None, ""
        else:
            variant, err = compiles(code)
            status = "compiles" if variant else "compile_error"
        results.append({"name": rec["function_name"], "source_file": rec["source_file"],
                        "cpp": rec["cpp"], "mojo": code or "", "status": status,
                        "compile_variant": variant, "error": err})
        print(f"[{i}/{len(recs)}] {rec['function_name']:34s} {status}{(' ('+variant+')') if variant else ''}  {err[:60]}", flush=True)
    json.dump(results, open(SFT/"prod_results.json","w"), indent=1)
    nc = sum(1 for r in results if r["status"]=="compiles")
    print(f"\n=== PRODUCTION TEST === {nc}/{len(results)} compiled  -> {SFT/'prod_results.json'}")

if __name__ == "__main__":
    main()
