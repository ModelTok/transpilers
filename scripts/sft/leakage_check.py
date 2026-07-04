#!/usr/bin/env python3
"""Quantify held-out leakage: how many held-out items have a near-twin in the
training set (token-Jaccard on the C++ unit). High overlap => the eval measures
interpolation, not generalization."""
import json, re
from pathlib import Path
REPO = Path(__file__).resolve().parents[2]  # scripts/sft/<this file> -> repo root
SFT = REPO / "data/sft/cpp_mojo"
FENCE = re.compile(r"```cpp\n(.*?)```", re.S)

def toks(s): return set(re.findall(r"[A-Za-z_]\w+", s))

def cpp_of(instr_or_content):
    m = FENCE.search(instr_or_content)
    return m.group(1) if m else ""

train = [json.loads(l) for l in (SFT/"train_translation.jsonl").read_text().splitlines() if l.strip()]
tr_tok = [toks(cpp_of(r["instruction"])) for r in train]
tr_tok = [t for t in tr_tok if t]

held = [json.loads(l) for l in (SFT/"heldout_diverse.jsonl").read_text().splitlines() if l.strip()]
rows = []
for h in held:
    ht = toks(cpp_of(h["prompt"][1]["content"]))
    best = max((len(ht & t)/max(len(ht | t), 1) for t in tr_tok), default=0.0)
    rows.append((h["name"], h["category"], best))
rows.sort(key=lambda x: -x[2])
leaked = sum(1 for _,_,b in rows if b >= 0.6)
print(f"held-out diverse: {len(held)} | near-twin in train (Jaccard>=0.6): {leaked} ({100*leaked/len(held):.0f}%)")
print(f"  >=0.7: {sum(1 for _,_,b in rows if b>=0.7)}   >=0.5: {sum(1 for _,_,b in rows if b>=0.5)}   <0.4 (novel): {sum(1 for _,_,b in rows if b<0.4)}")
print("most-leaked:")
for n,c,b in rows[:10]: print(f"  {b:.2f}  {c:9s} {n}")
print("most-novel:")
for n,c,b in rows[-6:]: print(f"  {b:.2f}  {c:9s} {n}")
