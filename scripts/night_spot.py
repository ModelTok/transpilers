#!/usr/bin/env python3
"""Spot-check: print the Mojo output of records that have imports."""
import json
import sys

shown = 0
for l in open(sys.argv[1], encoding="utf-8"):
    r = json.loads(l)
    if "from std." in r["output"] and shown < 2:
        print(r["output"][:500])
        print("=" * 40)
        shown += 1
