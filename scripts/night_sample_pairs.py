#!/usr/bin/env python3
"""Print sample Mojo translations from the verified pairs (style reference)."""
import json
import sys

rows = [json.loads(l) for l in open(sys.argv[1])]
shown = 0
for r in rows:
    if "from math import" in r["mojo_source"] and "exp" in r["mojo_source"]:
        print(r["mojo_source"])
        print("=" * 40)
        shown += 1
        break
for r in rows:
    if "while" in r["mojo_source"] or "for " in r["mojo_source"]:
        print(r["mojo_source"])
        print("=" * 40)
        break
