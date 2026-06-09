#!/usr/bin/env python3
"""Merge leaves_migrated.json into train_translation_v2.jsonl.

Reads the 60 Python->Mojo verified pairs from leaves_migrated.json,
converts them to the Alpaca schema used by train_translation.jsonl
(instruction / input / system / output), dedupes by function name
against the existing training set, and writes the merged file.

Usage:
    python3 scripts/sft/merge_leaves.py
"""
import json, sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
DATA = REPO / "data/sft/cpp_mojo"

TRAIN = DATA / "train_translation.jsonl"
LEAVES = DATA / "leaves_migrated.json"
OUT    = DATA / "train_translation_v2.jsonl"

SYSTEM = (DATA / "system.txt").read_text(encoding="utf-8").strip()

# ── load existing ────────────────────────────────────────────────────────────
existing = []
seen_names: set[str] = set()

with TRAIN.open(encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        obj = json.loads(line)
        existing.append(obj)
        out_text = obj.get("output", "")
        # extract function name from the mojo def line for dedup
        if "def " in out_text:
            fname = out_text.split("def ")[1].split("(")[0].strip()
            seen_names.add(fname)

print(f"Existing pairs  : {len(existing)}")
print(f"Existing fn names (for dedup): {len(seen_names)}")

# ── load leaves ──────────────────────────────────────────────────────────────
with LEAVES.open(encoding="utf-8") as f:
    leaves = json.load(f)

print(f"Leaf entries    : {len(leaves)}")

# ── convert + dedup ──────────────────────────────────────────────────────────
new_pairs = []
skipped = 0

for leaf in leaves:
    name        = leaf["name"]
    source_file = leaf.get("source_file", "unknown")
    mojo        = leaf["mojo"]

    if name in seen_names:
        print(f"  DEDUP: {name}")
        skipped += 1
        continue

    instruction = (
        f"Transpile the provided Python function into a functionally equivalent "
        f"implementation in Mojo.\n\n"
        f"Function `{name}` from `{source_file}`."
    )
    output = f"```mojo\n{mojo}\n```"

    new_pairs.append({
        "instruction": instruction,
        "input": "",
        "system": SYSTEM,
        "output": output,
    })
    seen_names.add(name)

print(f"New pairs added : {len(new_pairs)}  (skipped dedup: {skipped})")
print(f"Total v2 pairs  : {len(existing) + len(new_pairs)}")

# ── write output ─────────────────────────────────────────────────────────────
with OUT.open("w", encoding="utf-8") as f:
    for row in existing:
        f.write(json.dumps(row, ensure_ascii=False) + "\n")
    for row in new_pairs:
        f.write(json.dumps(row, ensure_ascii=False) + "\n")

print(f"Written: {OUT}")
