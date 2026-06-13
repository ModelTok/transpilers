#!/usr/bin/env python3
"""Transpilation benchmark — compare models on the one-shot stateless transpile task.

Runs the SAME prompt used by 2_transpile.py (imported, not duplicated) for a fixed
set of "good example" files against one or more OpenRouter models, and reports
objective per-(model,file) metrics:

  - latency, prompt/completion tokens, cost (from OpenRouter usage)
  - did it emit BOTH required blocks (out/python/*.py + out/mojo/*.mojo)?
  - py_compiles: does the generated Python parse (compile())?  <- objective quality
  - py_lines / mojo_lines, and whether the model punted with __todo__ placeholders

Outputs are written under bench_out/<model-slug>/ so the benchmark NEVER touches
the real out/ tree or 1_manifest.json. A summary table + bench_out/report.json
are produced at the end.

Usage:
  python3 3_benchmark.py                       # default files + default models
  python3 3_benchmark.py --models "nvidia/nemotron-3-ultra-550b-a55b:free" \
      "deepseek/deepseek-v4-flash"
  python3 3_benchmark.py --files Interpolation2D BSDFLayer --workers 2
"""

from __future__ import annotations

import argparse
import concurrent.futures as cf
import importlib
import json
import re
import sys
import time
from pathlib import Path

BASE = Path(__file__).resolve().parent
sys.path.insert(0, str(BASE))
T = importlib.import_module("2_transpile")  # reuse build_prompt / call_openrouter / regex

BENCH_OUT = BASE / "bench_out"

# 3 good example files: real .cc+.hh modules, moderate size, varied flavor —
# numerical algorithm / physics class / manager-factory OOP.
DEFAULT_FILES = ["Interpolation2D", "BSDFLayer", "GroundTemperatureModelManager"]
DEFAULT_MODELS = [
    "nvidia/nemotron-3-ultra-550b-a55b:free",
    "deepseek/deepseek-v4-flash",
]

_FENCE_OPEN = re.compile(r"^```[a-zA-Z]*\n")
_FENCE_CLOSE = re.compile(r"\n```\s*$")


def slug(model: str) -> str:
    return re.sub(r"[^a-zA-Z0-9._-]", "_", model)


def parse_blocks(text: str) -> dict[str, str]:
    """Extract <<<FILE path>>> ... <<<END>>> blocks, stripping code fences."""
    out = {}
    for m in T.FILE_BLOCK.finditer(text):
        body = _FENCE_CLOSE.sub("", _FENCE_OPEN.sub("", m.group("body")))
        out[m.group("path").strip()] = body.rstrip() + "\n"
    return out


def py_compiles(src: str) -> bool:
    try:
        compile(src, "<bench>", "exec")
        return True
    except SyntaxError:
        return False


def bench_one(file: str, model: str, timeout: int) -> dict:
    rec = {"file": file, "model": model}
    try:
        prompt = T.build_prompt(file)
        rec["prompt_chars"] = len(prompt)
        if not prompt.strip():
            return {**rec, "status": "no-source"}
        t0 = time.monotonic()
        text, meta = T.call_openrouter(prompt, model, timeout, None)
        rec["latency_s"] = round(time.monotonic() - t0, 1)
    except Exception as e:  # noqa: BLE001
        return {**rec, "status": f"error: {type(e).__name__}: {str(e)[:200]}"}

    usage = meta.get("usage") or {}
    rec["cost_usd"] = meta.get("cost_usd") or 0.0
    rec["prompt_tokens"] = usage.get("prompt_tokens")
    rec["completion_tokens"] = usage.get("completion_tokens")

    blocks = parse_blocks(text)
    py = next((b for p, b in blocks.items() if p.endswith(".py")), None)
    mojo = next((b for p, b in blocks.items() if p.endswith(".mojo")), None)

    # persist raw output + parsed ports for inspection (isolated from real out/)
    d = BENCH_OUT / slug(model)
    d.mkdir(parents=True, exist_ok=True)
    (d / f"{file}.raw.txt").write_text(text, encoding="utf-8")
    if py:
        (d / f"{file}.py").write_text(py, encoding="utf-8")
    if mojo:
        (d / f"{file}.mojo").write_text(mojo, encoding="utf-8")

    rec["n_blocks"] = len(blocks)
    rec["has_py"] = py is not None
    rec["has_mojo"] = mojo is not None
    rec["py_lines"] = py.count("\n") if py else 0
    rec["mojo_lines"] = mojo.count("\n") if mojo else 0
    rec["py_compiles"] = py_compiles(py) if py else False
    rec["has_todo"] = bool(py and "__todo__" in py) or bool(mojo and "__todo__" in mojo)
    rec["status"] = "ok" if (py and mojo) else ("partial" if (py or mojo) else "no-blocks")
    return rec


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--files", nargs="+", default=DEFAULT_FILES)
    ap.add_argument("--models", nargs="+", default=DEFAULT_MODELS)
    ap.add_argument("--workers", type=int, default=3)
    ap.add_argument("--timeout", type=int, default=600)
    args = ap.parse_args()

    jobs = [(f, m) for m in args.models for f in args.files]
    print(f"benchmark: {len(args.files)} files x {len(args.models)} models = {len(jobs)} runs")
    print(f"  files : {', '.join(args.files)}")
    print(f"  models: {', '.join(args.models)}\n")

    BENCH_OUT.mkdir(exist_ok=True)
    results = []
    with cf.ThreadPoolExecutor(max_workers=args.workers) as ex:
        futs = {ex.submit(bench_one, f, m, args.timeout): (f, m) for f, m in jobs}
        for fut in cf.as_completed(futs):
            r = fut.result()
            results.append(r)
            print(f"  [{r['status']:<22}] {r['model'].split('/')[-1]:<28} {r['file']:<28} "
                  f"{r.get('latency_s','?')}s  py_ok={r.get('py_compiles','?')}  "
                  f"toks={r.get('completion_tokens','?')}", flush=True)

    (BENCH_OUT / "report.json").write_text(json.dumps(results, indent=2))

    # per-model aggregate table
    print("\n=== summary by model ===")
    hdr = f"{'model':<46} {'ok/n':>6} {'py_compiles':>12} {'avg_lat':>9} {'tot_tok':>9} {'cost$':>9}"
    print(hdr)
    print("-" * len(hdr))
    for m in args.models:
        rs = [r for r in results if r["model"] == m]
        ok = sum(1 for r in rs if r["status"] == "ok")
        pyc = sum(1 for r in rs if r.get("py_compiles"))
        lats = [r["latency_s"] for r in rs if "latency_s" in r]
        avg_lat = round(sum(lats) / len(lats), 1) if lats else 0
        tot_tok = sum((r.get("completion_tokens") or 0) for r in rs)
        cost = sum((r.get("cost_usd") or 0.0) for r in rs)
        print(f"{m:<46} {ok:>3}/{len(rs):<2} {pyc:>9}/{len(rs):<2} {avg_lat:>8}s "
              f"{tot_tok:>9,} {cost:>9.5f}")
    print(f"\noutputs + raw responses: {BENCH_OUT}")
    print(f"full report: {BENCH_OUT / 'report.json'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
