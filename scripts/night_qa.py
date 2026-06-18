#!/usr/bin/env python3
"""Final QA over the assembled SFT files: every record parses, has a non-empty
```cpp fence in the instruction and a non-empty ```mojo fence in the output,
no held-out names, def-count sanity, provenance breakdown from the manifest."""
import json
import re
import sys
from collections import Counter
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
SFT = REPO / "data" / "sft" / "cpp_mojo"
heldout = set(json.loads((SFT / "heldout_names.json").read_text()))

for fname in ("train_translation_ep_v3.jsonl", "train_translation_ep_v3_nocomment.jsonl"):
    path = SFT / fname
    rows = [json.loads(l) for l in path.read_text(encoding="utf-8").splitlines() if l.strip()]
    bad = 0
    for r in rows:
        cpp = re.search(r"```cpp\n(.+?)```", r["instruction"], re.S)
        mojo = re.search(r"```mojo\n(.+?)```", r["output"], re.S)
        name = re.search(r"(\w+)\s*\(", cpp.group(1)) if cpp else None
        assert set(r) == {"instruction", "input", "system", "output"}, r.keys()
        if not cpp or not mojo or not mojo.group(1).strip().startswith(("def ", "from ", "import ")):
            bad += 1
            print(f"  BAD: {fname}: {r['instruction'][:80]}")
        if name and name.group(1) in heldout:
            bad += 1
            print(f"  HELDOUT LEAK: {name.group(1)}")
    print(f"{fname}: {len(rows)} records, {bad} problems")

man = [json.loads(l) for l in (REPO / "data/night/ep_pairs_v3_manifest.jsonl")
       .read_text(encoding="utf-8").splitlines() if l.strip()]
print("\nmanifest provenance:", dict(Counter(m["provenance"] for m in man)))
print("verification method:", dict(Counter(m["verification"]["method"] for m in man)))
print("source files:", len({m["source_file"] for m in man}))
print("with out-params:", sum(1 for m in man if m.get("out_params")))
mr = max(m["verification"]["max_rel_err"] for m in man)
print(f"worst max_rel_err: {mr:.2e}")
