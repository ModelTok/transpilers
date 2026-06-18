#!/usr/bin/env python3
"""List candidate records compactly."""
import json
import sys

for l in open(sys.argv[1]):
    if l.strip():
        r = json.loads(l)
        n_out = sum(1 for p in r["params"] if p[2]) if "params" in r else "-"
        print(f'{r["function_name"]:42s} ret={r["ret_type"]:7s} '
              f'params={len(r.get("params", []))} out={n_out}  {r["source_file"]}')
