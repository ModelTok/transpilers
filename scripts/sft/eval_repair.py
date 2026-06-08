#!/usr/bin/env python3
"""Evaluate a local HF model on C++->Mojo held-out WITH a compile-repair loop.

Same generation/eval gate as eval_05b.py, but when the generated Mojo fails with
status 'compile_error', the Mojo compiler error is fed back to the model as a
follow-up user turn and the model regenerates (up to --repair N rounds). We then
report pass@1 WITHOUT repair (first attempt) and WITH repair (final attempt),
plus how many compile_errors were converted into passes.

The pass/fail verdict always comes from rh.eval_mojo / rh.eval_python (the same
canonical gate as eval_05b/run_heldout_eval) so the WITHOUT-repair number is
apples-to-apples with eval_05b. The full compiler stderr used for the repair
prompt is captured separately, only on failures.

Run on iGPU (rocm venv):
  HSA_OVERRIDE_GFX_VERSION=11.0.0 /home/bart/rocm-venv/bin/python -u \
    scripts/sft/eval_repair.py --adapter data/sft/cpp_mojo/adapter_15b_v2 \
    --repair 1 --tag repair-test
"""
import argparse, importlib.util, json, re, subprocess, sys, tempfile
from collections import Counter
from pathlib import Path
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer

REPO = Path(__file__).resolve().parents[2]
_r = importlib.util.spec_from_file_location("rh", REPO / "scripts/sft/run_heldout_eval.py")
rh = importlib.util.module_from_spec(_r); sys.modules["rh"] = rh; _r.loader.exec_module(rh)
HELD = REPO / "data/sft/cpp_mojo/heldout_eval.jsonl"

MAX_NEW_TOKENS = 1024
ERR_CHARS = 1500  # cap compiler error fed back into the repair prompt


def extract_code(text, lang):
    """More robust than rh.extract_code: prefer <answer> + a ```lang fence, then
    any fence, then handle a missing closing fence, then fall back to the largest
    code-looking block (lines that look like Mojo/Python source)."""
    ans = re.search(r"<answer>(.*?)</answer>", text, re.S)
    scope = ans.group(1) if ans else text

    # 1) well-formed fences: ```lang ... ```  then any ``` ... ```
    for pat in (rf"```{lang}\s*\n(.*?)```", r"```[a-zA-Z]*\s*\n(.*?)```"):
        m = re.search(pat, scope, re.S)
        if m and m.group(1).strip():
            return m.group(1).strip()

    # 2) opening fence with NO closing fence -> take everything after it
    m = re.search(r"```[a-zA-Z]*\s*\n(.*)$", scope, re.S)
    if m and m.group(1).strip():
        return _trim_trailing_fence(m.group(1)).strip()

    # 3) no fence at all -> grab the largest contiguous block of code-looking lines
    blk = _largest_code_block(scope)
    return blk if blk else None


def _trim_trailing_fence(s):
    # if a stray closing fence shows up later, cut at it
    idx = s.find("```")
    return s[:idx] if idx != -1 else s


_CODE_RE = re.compile(
    r"^\s*(fn |def |from |import |struct |trait |alias |var |let |@|#|//|return\b|"
    r"if |for |while |else|elif |print\(|main\(|\}|\{)")


def _largest_code_block(text):
    """Largest run of consecutive non-blank lines that look like source code."""
    lines = text.splitlines()
    best, cur = [], []
    def flush():
        nonlocal best, cur
        score = sum(1 for l in cur if _CODE_RE.match(l))
        if score >= 1 and len(cur) > len(best):
            best = cur[:]
    for l in lines:
        if l.strip() == "":
            flush(); cur = []
        else:
            cur.append(l)
    flush()
    # trim leading/trailing prose lines that don't look like code
    while best and not _CODE_RE.match(best[0]):
        best.pop(0)
    while best and not _CODE_RE.match(best[-1]):
        best.pop()
    out = "\n".join(best).strip()
    # only accept if it actually contains a def/fn (a callable to test)
    return out if re.search(r"^\s*(fn|def)\s+\w+\s*\(", out, re.M) else None


def mojo_compile_error(code, fn, inputs, arg_types):
    """Recompile the same source rh.eval_mojo builds and return full stderr.
    Used only when rh.eval_mojo already reported compile_error, to get a richer
    error for the repair prompt than the 60-char truncated detail."""
    name = rh.def_name(code) or fn
    with tempfile.TemporaryDirectory() as td:
        tdp = Path(td)
        calls = "\n".join("    print(" + name + "("
                          + ", ".join(rh.lit(v, t) for v, t in zip(row, arg_types)) + "))"
                          for row in inputs)
        src = f"{code}\n\ndef main():\n{calls}\n"
        (tdp / "k.mojo").write_text(src)
        try:
            cp = subprocess.run([rh.MOJO_BIN, "build", "-Xlinker", "-ldl",
                                 str(tdp / "k.mojo"), "-o", str(tdp / "k")],
                                env=rh.MOJO_ENV, capture_output=True, text=True, timeout=150)
        except subprocess.TimeoutExpired:
            return "compilation timed out"
    err = cp.stderr or cp.stdout or ""
    # prefer the lines around 'error:' if the log is long
    if len(err) > ERR_CHARS:
        elines = [l for l in err.splitlines() if "error:" in l or "note:" in l]
        if elines:
            err = "\n".join(elines)
    return err.strip()[-ERR_CHARS:]


REPAIR_TMPL = ("That Mojo failed to compile with:\n{err}\n\n"
               "Fix it; output only the corrected Mojo in a ```mojo fence.")


def generate(model, tok, messages):
    prompt = tok.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
    ids = tok(prompt, return_tensors="pt").to(model.device)
    with torch.no_grad():
        gen = model.generate(**ids, max_new_tokens=MAX_NEW_TOKENS, do_sample=False,
                             pad_token_id=tok.eos_token_id)
    return tok.decode(gen[0][ids["input_ids"].shape[1]:], skip_special_tokens=True)


def eval_code(code, lang, ei, gt):
    if not code:
        return "no_code", ""
    if lang == "Mojo":
        return rh.eval_mojo(code, ei["function_name"], gt["inputs"], gt["outputs"], ei["arg_types"])
    return rh.eval_python(code, ei["function_name"], gt["inputs"], gt["outputs"], ei["arg_types"])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", default="Qwen/Qwen2.5-0.5B-Instruct")
    ap.add_argument("--adapter", default=None)
    ap.add_argument("--tag", default="repair-0.5b")
    ap.add_argument("--heldout", default=str(HELD))
    ap.add_argument("--repair", type=int, default=1, help="max compile-repair rounds")
    ap.add_argument("--limit", type=int, default=0, help="only first N records (smoke test)")
    args = ap.parse_args()
    held_path = Path(args.heldout)

    tok = AutoTokenizer.from_pretrained(args.model)
    model = AutoModelForCausalLM.from_pretrained(args.model, dtype=torch.float32)
    if args.adapter:
        from peft import PeftModel
        model = PeftModel.from_pretrained(model, args.adapter)
    model.eval()

    recs = [json.loads(l) for l in held_path.read_text().splitlines() if l.strip()]
    if args.limit:
        recs = recs[:args.limit]
    results = []
    for i, rec in enumerate(recs, 1):
        ei = rec["extra_info"]; lang = ei["language_full"]
        ltag = "mojo" if lang == "Mojo" else "python"
        gt = rec["reward_model"]["ground_truth"]
        messages = list(rec["prompt"])

        out = generate(model, tok, messages)
        code = extract_code(out, ltag)
        status, detail = eval_code(code, lang, ei, gt)
        first_status = status
        rounds = 0

        # compile-repair loop (only Mojo ever yields compile_error)
        while (status == "compile_error" and rounds < args.repair):
            rounds += 1
            err = mojo_compile_error(code, ei["function_name"], gt["inputs"], ei["arg_types"])
            messages = messages + [
                {"role": "assistant", "content": out},
                {"role": "user", "content": REPAIR_TMPL.format(err=err)},
            ]
            out = generate(model, tok, messages)
            code = extract_code(out, ltag)
            status, detail = eval_code(code, lang, ei, gt)

        results.append({
            "fn": ei["function_name"], "lang": lang,
            "first_status": first_status, "status": status,
            "detail": detail, "repair_rounds": rounds,
        })
        rep = f"  [repair x{rounds}: {first_status}->{status}]" if rounds else ""
        print(f"[{i}/{len(recs)}] {lang:6s} {ei['function_name']:28s} "
              f"{status.upper():14s} {detail[:30]}{rep}")

    out_path = REPO / f"data/sft/cpp_mojo/heldout_{args.tag}.json"
    json.dump({"tag": args.tag, "repair": args.repair, "results": results},
              open(out_path, "w"), indent=1)

    print(f"\n=== {args.tag}  (repair={args.repair}) ===")
    for lang in ("Mojo", "Python"):
        rs = [r for r in results if r["lang"] == lang]
        if not rs:
            continue
        n = len(rs)
        pass_no = sum(1 for r in rs if r["first_status"] == "pass")
        pass_yes = sum(1 for r in rs if r["status"] == "pass")
        converted = sum(1 for r in rs
                        if r["first_status"] == "compile_error" and r["status"] == "pass")
        c_first = Counter(r["first_status"] for r in rs)
        print(f"{lang:7s} pass@1 no-repair {100*pass_no/n:5.1f}% ({pass_no}/{n})  "
              f"with-repair {100*pass_yes/n:5.1f}% ({pass_yes}/{n})  "
              f"converted {converted}  first={dict(c_first)}")
    print(f"-> {out_path}")


if __name__ == "__main__":
    main()
