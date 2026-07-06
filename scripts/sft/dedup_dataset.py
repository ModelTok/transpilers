#!/usr/bin/env python3
"""Deduplicate the verified diverse pool: drop near-identical C++ units so the
training set is maximally diverse (more distinct examples, fewer repeats).

Greedy within-category dedup on token-Jaccard of the C++ unit. Keeps the FIRST
representative of each near-duplicate cluster; reports what was removed. Writes
verified_dedup.jsonl; leaves verified.jsonl untouched.

Usage: dedup_dataset.py [threshold]   (analyze only if threshold omitted)
"""
import json, re, sys, collections
from pathlib import Path
REPO = Path(__file__).resolve().parents[2]  # scripts/sft/<this file> -> repo root
SRC = REPO / "data/sft/diverse/verified.jsonl"
OUT = REPO / "data/sft/diverse/verified_dedup.jsonl"

def toks(s): return set(re.findall(r"[A-Za-z_]\w+", s))
def jac(a, b): return len(a & b) / max(len(a | b), 1)

pairs = [json.loads(l) for l in SRC.read_text().splitlines() if l.strip()]
for p in pairs:
    p["_t"] = toks(p.get("cpp_unit", ""))

bycat = collections.defaultdict(list)
for p in pairs:
    bycat[p["category"]].append(p)

if len(sys.argv) < 2:   # analysis mode: near-dup counts at several thresholds
    print(f"pool: {len(pairs)} pairs, {len(bycat)} categories")
    for T in (0.6, 0.7, 0.8, 0.9):
        removed = 0
        for cat, ps in bycat.items():
            kept = []
            for p in ps:
                if any(jac(p["_t"], k["_t"]) >= T for k in kept):
                    removed += 1
                else:
                    kept.append(p)
        print(f"  threshold {T}: would remove {removed} near-dups -> {len(pairs)-removed} kept")
    sys.exit(0)

T = float(sys.argv[1])
kept_all = []
rem_by_cat = collections.Counter()
for cat, ps in sorted(bycat.items()):
    kept = []
    for p in ps:
        if any(jac(p["_t"], k["_t"]) >= T for k in kept):
            rem_by_cat[cat] += 1
        else:
            kept.append(p)
    kept_all.extend(kept)
with OUT.open("w") as f:
    for p in kept_all:
        p.pop("_t", None)
        f.write(json.dumps(p, ensure_ascii=False) + "\n")
print(f"dedup @ {T}: {len(pairs)} -> {len(kept_all)}  (removed {len(pairs)-len(kept_all)})")
for c in sorted(rem_by_cat): print(f"  {c:10s} -{rem_by_cat[c]}")
print(f"-> {OUT}")
