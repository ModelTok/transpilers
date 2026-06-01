"""Honest metric: does each lifted EnergyPlus module produce *valid Python*?

TODO-hole count understates breakage (a 0-TODO module can still have syntax
errors). This compiles every lifted module with the `ast` parser and reports
the true pass rate plus the first error per failing file."""
from __future__ import annotations

import ast
import glob
import json
import os
import re
import sys
from collections import Counter

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))
from transpilers.lift import lift_source  # noqa: E402

EP = "/home/db/EnergyPlus/src"
OBJEXX = "/home/db/EnergyPlus/third_party/ObjexxFCL/src"
INC = [EP, os.path.join(EP, "EnergyPlus"), OBJEXX]

files = sorted(glob.glob(os.path.join(EP, "EnergyPlus", "*.cc")))
ok = 0
fails = []
cats = Counter()
for f in files:
    name = os.path.basename(f)
    src = open(f, errors="replace").read()
    try:
        out, _ = lift_source(src, name=f, inc=INC)
    except Exception as e:
        fails.append((name, 0, f"LIFT-CRASH {type(e).__name__}"))
        cats["LIFT-CRASH"] += 1
        continue
    try:
        ast.parse(out)
        ok += 1
    except SyntaxError as e:
        line = (out.splitlines()[e.lineno - 1].strip()[:80]
                if e.lineno and e.lineno <= len(out.splitlines()) else "")
        fails.append((name, e.lineno, line))
        # bucket the failing line shape
        if re.search(r"\([^()]*\)\s*[-+*/%]?=[^=]", line):
            cats["assign-to-call(LHS)"] += 1
        elif " = " in line and (line.startswith("if ") or line.startswith("while ") or line.startswith("elif ")):
            cats["assign-in-condition"] += 1
        elif line.endswith("="):
            cats["dangling-="] += 1
        else:
            cats["other"] += 1

print(f"VALID PYTHON: {ok}/{len(files)} modules  ({100*ok/len(files):.0f}%)")
print(f"failing: {len(fails)}\n")
print("failure categories:")
for k, n in cats.most_common():
    print(f"  {n:4d}  {k}")
print("\nfirst 15 failures:")
for name, ln, line in fails[:15]:
    print(f"  {name}:{ln}  {line}")
json.dump([{"file": n, "line": l, "src": s} for n, l, s in fails],
          open(os.path.join(os.path.dirname(__file__), "ep_compile_fails.json"), "w"), indent=2)
