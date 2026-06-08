#!/usr/bin/env python3
"""Produce prompt-matched ruler variants so each adapter is evaluated at ITS OWN
trained prompt (old = verbose+think system; new = lean code-only system). This
keeps the adapter the only variable and avoids a train/test prompt mismatch.

Existing:
  heldout_diverse.jsonl        — C++ ruler, VERBOSE prompt (old model's native)
  heldout_diverse_py.jsonl     — Python ruler, LEAN prompt (new model's native)

Produces:
  heldout_diverse_cpp_lean.jsonl   — C++ ruler, LEAN prompt   (new model's native)
  heldout_diverse_py_verbose.jsonl — Python ruler, VERBOSE prompt (old model's native)
"""
from __future__ import annotations
import json
from pathlib import Path

SFT = Path(__file__).resolve().parents[2] / "data/sft/cpp_mojo"
LEAN = (SFT / "system.txt").read_text().strip()
VERBOSE = (SFT / "system.think.txt").read_text().strip()


def swap_system(src, dst, new_sys):
    rows = [json.loads(l) for l in (SFT / src).read_text().splitlines() if l.strip()]
    for r in rows:
        r["prompt"][0]["content"] = new_sys
    (SFT / dst).write_text("\n".join(json.dumps(r, ensure_ascii=False) for r in rows) + "\n")
    print(f"{dst}: {len(rows)} records")


swap_system("heldout_diverse.jsonl", "heldout_diverse_cpp_lean.jsonl", LEAN)
swap_system("heldout_diverse_py.jsonl", "heldout_diverse_py_verbose.jsonl", VERBOSE)
