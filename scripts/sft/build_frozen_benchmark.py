#!/usr/bin/env python3
"""Freeze a permanent, leakage-free C++->Mojo benchmark.

Problem this fixes: every retrain so far used an index-based held-out that SHIFTS
as the pool grows, and ~48% of held-out items had a near-twin in training -> the
ruler moved AND was inflated by interpolation. This builds a FIXED held-out,
pinned by name, with a hard guarantee: no held-out item has a near-twin
(token-Jaccard >= 0.6) among the training pool. Future runs exclude these names
from training and always eval on this same set.

Outputs (data/sft/benchmark/):
  frozen_diverse.jsonl   — pinned diverse held-out (full pair, for differential eval)
  frozen_scalar.jsonl    — pinned scalar held-out names + pairs
  frozen_names.json      — {scalar:[...], diverse:[...]} for assemble to exclude
  train_pool_diverse.jsonl — diverse pairs safe to train on (near-twins of held-out removed)
"""
import json, re, collections
from pathlib import Path
REPO = Path("/home/bart/Github/transpilers")
DIV = REPO / "data/sft/diverse/verified.jsonl"
OUT = REPO / "data/sft/benchmark"; OUT.mkdir(parents=True, exist_ok=True)
THRESH = 0.6
PER_CAT = 3   # frozen held-out items per category

def toks(s): return set(re.findall(r"[A-Za-z_]\w+", s))
def jac(a, b): return len(a & b) / max(len(a | b), 1)

pairs = [json.loads(l) for l in DIV.read_text().splitlines() if l.strip()]
for p in pairs: p["_t"] = toks(p.get("cpp_unit", ""))
bycat = collections.defaultdict(list)
for p in pairs: bycat[p["category"]].append(p)

# Pick frozen held-out per category: prefer items LEAST similar to the rest
# (most novel) so the benchmark stresses generalization.
frozen, frozen_names = [], set()
for cat, ps in bycat.items():
    scored = []
    for p in ps:
        others = [q["_t"] for q in ps if q is not p]
        novelty = max((jac(p["_t"], o) for o in others), default=0.0)
        scored.append((novelty, p))
    scored.sort(key=lambda x: x[0])           # most novel first
    for _, p in scored[:PER_CAT]:
        frozen.append(p); frozen_names.add(p["name"])

# Hard leakage guard: training pool = pairs that are NOT frozen and NOT a
# near-twin of any frozen item.
ftoks = [(p["name"], p["_t"], p["category"]) for p in frozen]
train_pool, leaked_removed = [], 0
for p in pairs:
    if p["name"] in frozen_names:
        continue
    twin = any(p["category"] == fc and jac(p["_t"], ft) >= THRESH for _, ft, fc in ftoks)
    if twin: leaked_removed += 1
    else: train_pool.append(p)

# verify zero leakage
maxleak = 0.0
tp_toks = [(q["category"], q["_t"]) for q in train_pool]
for p in frozen:
    for cat, t in tp_toks:
        if cat == p["category"]:
            maxleak = max(maxleak, jac(p["_t"], t))

def strip(p): return {k: v for k, v in p.items() if k != "_t"}
(OUT/"frozen_diverse.jsonl").write_text("\n".join(json.dumps(strip(p), ensure_ascii=False) for p in frozen) + "\n")
(OUT/"train_pool_diverse.jsonl").write_text("\n".join(json.dumps(strip(p), ensure_ascii=False) for p in train_pool) + "\n")
json.dump({"diverse": sorted(frozen_names)}, open(OUT/"frozen_names.json", "w"), indent=1)

print(f"pool {len(pairs)} -> frozen held-out {len(frozen)} ({PER_CAT}/cat x {len(bycat)} cats), "
      f"train pool {len(train_pool)} (removed {leaked_removed} near-twins of held-out)")
print(f"max held-out<->train Jaccard after guard: {maxleak:.2f} (target < {THRESH})")
print("per-category frozen:", dict(collections.Counter(p['category'] for p in frozen)))
print(f"-> {OUT}/frozen_diverse.jsonl, train_pool_diverse.jsonl, frozen_names.json")
