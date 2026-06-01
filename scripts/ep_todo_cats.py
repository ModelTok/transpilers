"""Aggregate the lifter's TODO-hole snippets across all EnergyPlus modules to
find the most common unsupported constructs (the highest-leverage fixes)."""
from __future__ import annotations

import glob
import os
import re
import sys
from collections import Counter

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))
from transpilers.lift import lift_source  # noqa: E402

EP = "/home/db/EnergyPlus/src"
OBJEXX = "/home/db/EnergyPlus/third_party/ObjexxFCL/src"
INC = [EP, os.path.join(EP, "EnergyPlus"), OBJEXX]

TODO_RE = re.compile(r"#\s*TODO\[?[^\]]*\]?:?\s*(.*)")
cats = Counter()
examples: dict[str, str] = {}
files = sorted(glob.glob(os.path.join(EP, "EnergyPlus", "*.cc")))
total = 0
for f in files:
    src = open(f, errors="replace").read()
    try:
        out, st = lift_source(src, name=f, inc=INC)
    except Exception:
        continue
    for line in out.splitlines():
        m = TODO_RE.search(line)
        if not m:
            continue
        total += 1
        snip = m.group(1).strip()
        # bucket by leading token / shape
        head = re.match(r"[A-Za-z_][A-Za-z0-9_]*|\W+", snip)
        key = head.group(0)[:24] if head else snip[:24]
        cats[key] += 1
        examples.setdefault(key, snip[:90])

print(f"total TODO holes: {total}\n")
for key, n in cats.most_common(30):
    print(f"{n:5d}  {key!r:28}  e.g. {examples[key]}")
