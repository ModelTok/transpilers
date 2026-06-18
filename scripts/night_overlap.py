#!/usr/bin/env python3
"""Count overlap between night pairs and existing data/cpp_mojo_pairs.jsonl +
train_translation.jsonl function names."""
import json
import re
import sys

def names(path, key="function_name"):
    out = set()
    for l in open(path, encoding="utf-8"):
        if l.strip():
            r = json.loads(l)
            if key in r:
                out.add(r[key])
            else:
                m = re.search(r"```cpp\n.*?(\w+)\s*\(", r.get("instruction", ""), re.S)
                if m:
                    out.add(m.group(1))
    return out

night = names(sys.argv[1])
old_pairs = names("data/cpp_mojo_pairs.jsonl")
train = names("data/sft/cpp_mojo/train_translation.jsonl")
print(f"night pairs:        {len(night)}")
print(f"existing raw pairs: {len(old_pairs)}  (overlap {len(night & old_pairs)})")
print(f"new vs raw:         {len(night - old_pairs)}")
print(f"new vs train names: {len(night - train)}")
print("sample new:", sorted(night - old_pairs)[:12])
