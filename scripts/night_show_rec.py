#!/usr/bin/env python3
"""Show one record's mojo_source head + cpp_source head."""
import json
import sys

for l in open(sys.argv[1]):
    if not l.strip():
        continue
    r = json.loads(l)
    if r["function_name"] == sys.argv[2]:
        if "mojo_source" in r:
            print(repr(r["mojo_source"][:160]))
            print()
        n = int(sys.argv[3]) if len(sys.argv) > 3 else 700
        print(r["cpp_source"][:n])
        break
