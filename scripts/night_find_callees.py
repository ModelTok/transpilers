#!/usr/bin/env python3
"""Look up verified pairs by function name across pair files."""
import json
import sys

names = set(sys.argv[2].split(","))
for l in open(sys.argv[1]):
    if not l.strip():
        continue
    r = json.loads(l)
    if r["function_name"] in names:
        print("###", r["function_name"])
        print("--- cpp ---")
        print(r["cpp_source"])
        print("--- mojo ---")
        print(r["mojo_source"])
        print()
