#!/usr/bin/env python3
"""Evaluate a local HF model (base or LoRA-fine-tuned) on the C++->Mojo held-out.

Loads Qwen2.5-0.5B-Instruct (+ optional --adapter), generates for each held-out
verl prompt, extracts the function from <answer>, and runs it against the
ground_truth test cases via the same compile/exec gate as run_heldout_eval.
Pre-register the base, then compare the fine-tuned model at the SAME size.
"""
import argparse, importlib.util, json, sys
from pathlib import Path
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer

REPO = Path(__file__).resolve().parents[2]
_r = importlib.util.spec_from_file_location("rh", REPO / "scripts/sft/run_heldout_eval.py")
rh = importlib.util.module_from_spec(_r); sys.modules["rh"] = rh; _r.loader.exec_module(rh)
HELD = REPO / "data/sft/cpp_mojo/heldout_eval.jsonl"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", default="Qwen/Qwen2.5-0.5B-Instruct")
    ap.add_argument("--adapter", default=None)
    ap.add_argument("--tag", default="base-0.5b")
    ap.add_argument("--heldout", default=str(HELD))
    args = ap.parse_args()
    held_path = Path(args.heldout)

    _gpu = torch.cuda.is_available()   # ROCm iGPU presents as cuda (run with HSA_OVERRIDE_GFX_VERSION=11.0.0)
    _dev = "cuda" if _gpu else "cpu"
    tok = AutoTokenizer.from_pretrained(args.model)
    model = AutoModelForCausalLM.from_pretrained(args.model, dtype=(torch.bfloat16 if _gpu else torch.float32))
    if args.adapter:
        from peft import PeftModel
        model = PeftModel.from_pretrained(model, args.adapter)
    model.to(_dev).eval()
    print(f"eval device: {_dev}", flush=True)

    recs = [json.loads(l) for l in held_path.read_text().splitlines() if l.strip()]
    results = []
    for i, rec in enumerate(recs, 1):
        ei = rec["extra_info"]; lang = ei["language_full"]; ltag = "mojo" if lang == "Mojo" else "python"
        gt = rec["reward_model"]["ground_truth"]
        prompt = tok.apply_chat_template(rec["prompt"], tokenize=False, add_generation_prompt=True)
        ids = tok(prompt, return_tensors="pt").to(_dev)
        with torch.no_grad():
            gen = model.generate(**ids, max_new_tokens=1024, do_sample=False,
                                 pad_token_id=tok.eos_token_id)
        out = tok.decode(gen[0][ids["input_ids"].shape[1]:], skip_special_tokens=True)
        code = rh.extract_code(out, ltag)
        if not code:
            status, detail = "no_code", ""
        elif lang == "Mojo":
            status, detail = rh.eval_mojo(code, ei["function_name"], gt["inputs"], gt["outputs"], ei["arg_types"])
        else:
            status, detail = rh.eval_python(code, ei["function_name"], gt["inputs"], gt["outputs"], ei["arg_types"])
        results.append({"fn": ei["function_name"], "lang": lang, "status": status, "detail": detail,
                        "code": code or ""})   # persist generation so failures are diagnosable without a rerun
        print(f"[{i}/{len(recs)}] {lang:6s} {ei['function_name']:28s} {status.upper():14s} {detail[:35]}")

    from collections import Counter
    import math as _m
    def _wilson(k, n, z=1.96):   # 95% CI for a proportion, in percent
        if n == 0: return (0.0, 0.0)
        p = k / n; d = 1 + z*z/n
        c = (p + z*z/(2*n)) / d; h = z*_m.sqrt(p*(1-p)/n + z*z/(4*n*n)) / d
        return (100*max(0, c-h), 100*min(1, c+h))
    out_path = REPO / f"data/sft/cpp_mojo/heldout_{args.tag}.json"
    json.dump({"tag": args.tag, "results": results}, open(out_path, "w"), indent=1)
    print(f"\n=== {args.tag} ===")
    for lang in ("Mojo", "Python"):
        rs = [r for r in results if r["lang"] == lang]
        if not rs:
            continue
        n = len(rs); c = Counter(r["status"] for r in rs); np_ = c.get("pass", 0)
        comp = sum(1 for r in rs if r["status"] in ("pass", "wrong_output", "runtime_error"))
        lo, hi = _wilson(np_, n)
        # compile@1 = fraction that compiled+ran at all; exec-match@1 = fraction matching ground truth
        print(f"{lang:7s} exec-match@1 {100*np_/n:5.1f}% ({np_}/{n}) [95%CI {lo:.0f}-{hi:.0f}]  "
              f"compile@1 {100*comp/n:5.1f}% ({comp}/{n})  {dict(c)}")
    print(f"-> {out_path}")


if __name__ == "__main__":
    main()
