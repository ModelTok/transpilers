#!/usr/bin/env python3
"""Assemble newly verified EnergyPlus C++ -> Mojo pairs into the Alpaca SFT
schema used by data/sft/cpp_mojo/train_translation.jsonl.

- excludes held-out function names (data/sft/cpp_mojo/heldout_names.json)
- excludes near-twins of existing training rows (token-Jaccard >= 0.85 on the
  C++ unit) and exact function_name repeats within the new pool
- emits {instruction, input, system, output} records, system prompt from
  data/sft/cpp_mojo/system.txt, output as a single ```mojo fence

Usage:
    python scripts/night_assemble.py --pairs a.jsonl b.jsonl \
        --out data/sft/cpp_mojo/train_translation_ep_v3.jsonl
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
SFT = REPO / "data" / "sft" / "cpp_mojo"
FENCE_CPP = re.compile(r"```cpp\n(.*?)```", re.S)

INSTRUCTION_TMPL = (
    "Transpile the provided C++ implementation into a functionally equivalent "
    "implementation in Mojo.\n\n```cpp\n{cpp}\n```"
)


def toks(s: str) -> set[str]:
    return set(re.findall(r"[A-Za-z_]\w+", s))


def jac(a: set[str], b: set[str]) -> float:
    return len(a & b) / max(len(a | b), 1)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--pairs", type=Path, nargs="+", required=True)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--jaccard", type=float, default=0.85)
    ap.add_argument("--manifest", type=Path, default=None,
                    help="also write the raw kept pairs (verification metadata)")
    args = ap.parse_args()

    system = (SFT / "system.txt").read_text(encoding="utf-8").strip()
    heldout = set(json.loads((SFT / "heldout_names.json").read_text()))

    train = [json.loads(l) for l in (SFT / "train_translation.jsonl")
             .read_text(encoding="utf-8").splitlines() if l.strip()]
    train_toks = []
    train_names = set()
    for r in train:
        m = FENCE_CPP.search(r["instruction"])
        if m:
            train_toks.append(toks(m.group(1)))
            nm = re.search(r"(\w+)\s*\(", m.group(1))
            if nm:
                train_names.add(nm.group(1))

    pool = []
    for p in args.pairs:
        for l in p.read_text(encoding="utf-8").splitlines():
            if l.strip():
                pool.append(json.loads(l))

    kept, records = [], []
    seen_names: set[str] = set()
    kept_toks: list[set[str]] = []
    drops = {"heldout": 0, "name_dup": 0, "train_twin": 0, "pool_twin": 0}
    for p in pool:
        name = p["function_name"]
        if name in heldout:
            drops["heldout"] += 1
            continue
        if name in seen_names or name in train_names:
            drops["name_dup"] += 1
            continue
        t = toks(p["cpp_source"])
        if any(jac(t, tt) >= args.jaccard for tt in train_toks):
            drops["train_twin"] += 1
            continue
        if any(jac(t, tt) >= args.jaccard for tt in kept_toks):
            drops["pool_twin"] += 1
            continue
        seen_names.add(name)
        kept_toks.append(t)
        kept.append(p)
        records.append({
            "instruction": INSTRUCTION_TMPL.format(cpp=p["cpp_source"].strip()),
            "input": "",
            "system": system,
            "output": "```mojo\n" + p["mojo_source"].strip() + "\n```",
        })

    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("w", encoding="utf-8") as f:
        for r in records:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")
    if args.manifest:
        with args.manifest.open("w", encoding="utf-8") as f:
            for p in kept:
                f.write(json.dumps(p, ensure_ascii=False) + "\n")

    print(f"pool {len(pool)} -> kept {len(kept)}  (drops: {drops})")
    print(f"wrote {len(records)} SFT records -> {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
