#!/usr/bin/env python3
"""Rebuild the translation training set as CODE-ONLY (no <think>), covering BOTH
source languages (C++ and Python) for the single Mojo-target model.

User directive: the model should read code and write code — no reasoning tokens.
So every training output becomes just a ```mojo fenced block, and the system
prompt (data/sft/cpp_mojo/system.txt, already rewritten lean) no longer asks for
<think>/<answer>.

Inputs:
  data/sft/cpp_mojo/train_translation.think.jsonl  — the prior C++->Mojo set (with <think>)
  data/sft/diverse/py_verified.jsonl               — verified python_unit -> mojo_unit pairs

Output:
  data/sft/cpp_mojo/train_translation.jsonl        — code-only, C++ + Python, lean system

Python pairs are leakage-filtered against the transpilation-bench python_reference
held-out eval. Idempotent: always rebuilt from the .think backup + py_verified.
"""
from __future__ import annotations
import json, os, re, sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SFT = REPO / "data/sft/cpp_mojo"
PYV = Path(os.environ.get("PYV", str(REPO / "data/sft/diverse/py_verified.jsonl")))
BENCH = REPO / "benchmarks/transpilation-bench/benchmarks/tasks"
LEAK_J = float(os.environ.get("LEAK_J", "0.6"))

MOJO_FENCE = re.compile(r"```mojo\s*\n(.*?)```", re.S)


def mojo_only(code: str) -> str:
    """output = just the fenced mojo block."""
    return f"```mojo\n{code.strip()}\n```"


def extract_mojo(output: str) -> str | None:
    m = MOJO_FENCE.search(output)
    return m.group(1).strip() if m else None


def toks(s):
    return set(re.findall(r"[A-Za-z_]\w+", s.lower()))


def bench_refs():
    out = []
    for tf in sorted(BENCH.glob("*.json")):
        d = json.loads(tf.read_text())
        if d.get("python_reference"):
            out.append(toks(d["python_reference"]))
    return out


def jacc(a, b):
    return len(a & b) / max(len(a | b), 1)


def main():
    sysp = (SFT / "system.txt").read_text().strip()
    think = SFT / "train_translation.think.jsonl"
    if not think.exists():
        sys.exit("missing train_translation.think.jsonl backup")

    rows = []
    # --- C++ pairs: strip <think>, keep code-only, lean system ---
    cpp_n = 0
    for l in think.read_text().splitlines():
        if not l.strip():
            continue
        r = json.loads(l)
        code = extract_mojo(r["output"])
        if not code:
            continue
        rows.append({"instruction": r["instruction"], "input": "", "system": sysp,
                     "output": mojo_only(code)})
        cpp_n += 1

    # --- Python pairs: verified, held-out-excluded, leakage-filtered, code-only ---
    frozen = set()
    fz = REPO / "data/sft/benchmark/frozen_diverse.jsonl"
    if fz.exists():
        frozen = {json.loads(l)["name"] for l in fz.read_text().splitlines() if l.strip()}
    py_n = dropped = held = 0
    if PYV.exists():
        refs = bench_refs()
        for l in PYV.read_text().splitlines():
            if not l.strip():
                continue
            p = json.loads(l)
            pu, mu = p.get("python_unit"), p.get("mojo_unit")
            if not pu or not mu:
                continue
            if p.get("name") in frozen:   # reserved for the Python in-distribution ruler
                held += 1
                continue
            if any(jacc(toks(pu), r) >= LEAK_J for r in refs):
                dropped += 1
                continue
            instr = ("Transpile the provided Python implementation into a functionally equivalent "
                     f"implementation in Mojo.\n\n```python\n{pu.strip()}\n```")
            rows.append({"instruction": instr, "input": "", "system": sysp,
                         "output": mojo_only(mu)})
            py_n += 1
    else:
        print(f"WARN: {PYV} not found — emitting C++-only (rerun after py_verify)")

    (SFT / "train_translation.jsonl").write_text(
        "\n".join(json.dumps(r, ensure_ascii=False) for r in rows) + "\n")
    print(f"code-only train set: {cpp_n} C++ + {py_n} Python = {len(rows)} rows "
          f"({held} python held out as frozen ruler, {dropped} dropped as leakage J>={LEAK_J})")
    print(f"-> {SFT/'train_translation.jsonl'}")


if __name__ == "__main__":
    main()
