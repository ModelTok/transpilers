#!/usr/bin/env python3
"""Extract FRESH EnergyPlus C++ functions (not in our training set) for a real
production transpilation test of the best fine-tuned model. Brace-matched bodies,
self-contained scalar signatures, a range of sizes. Writes prod_test_cpp.jsonl."""
import json, re
from pathlib import Path
SRC = Path("/home/bart/Github/EnergyPlus/src/EnergyPlus")
REPO = Path("/home/bart/Github/transpilers")
OUT = REPO / "data/sft/cpp_mojo/prod_test_cpp.jsonl"

train = set()
for fn in ["data/cpp_mojo_pairs.jsonl", "data/cpp_mojo_pairs_bundled.jsonl"]:
    p = REPO / fn
    if p.exists():
        for l in p.read_text().splitlines():
            if l.strip(): train.add(json.loads(l)["function_name"])

# auto-discover scalar functions: `Real64 [Ns::]NAME(<scalar args>)` with a body
SIG = re.compile(r"\bReal64\s+(?:[A-Za-z_]\w*::)?([A-Za-z_]\w+)\s*\(([^;{)]*)\)\s*\{")
SCALAR_ARG = re.compile(r"^(?:Real64|double|int|bool|Int64|Real64 const|double const|int const|bool const|const Real64|const double|const int)\b")

def discover(text):
    names = []
    for m in SIG.finditer(text):
        name, args = m.group(1), m.group(2).strip()
        if not args:  # zero-arg: skip (likely needs state)
            continue
        parts = [a.strip() for a in args.split(",") if a.strip()]
        if all(SCALAR_ARG.match(a) for a in parts):
            names.append(name)
    return names

def extract_body(text, name):
    # match `Real64 [Ns::]name(...)` up to the matching close brace of the body
    m = re.search(rf"\bReal64\s+(?:[A-Za-z_]\w*::)?{re.escape(name)}\s*\(", text)
    if not m: return None
    i = text.find("{", m.start())
    if i < 0: return None
    depth = 0
    for j in range(i, len(text)):
        if text[j] == "{": depth += 1
        elif text[j] == "}":
            depth -= 1
            if depth == 0:
                body = text[m.start():j+1]
                # strip namespace qualifier so it's a free function
                body = re.sub(rf"(Real64\s+)[A-Za-z_]\w*::({re.escape(name)})", r"\1\2", body, count=1)
                return body
    return None

found = {}
for cc in SRC.glob("*.cc"):
    try: txt = cc.read_text(errors="ignore")
    except: continue
    for name in discover(txt):
        if name in found or name in train: continue
        b = extract_body(txt, name)
        if b and 60 < len(b) < 1600 and "EnergyPlusData" not in b and "Array" not in b \
           and "state." not in b and b.count(";") >= 1:
            found[name] = {"function_name": name, "source_file": cc.name, "cpp": b, "len": len(b)}

# pick a spread of sizes: sort by length, sample across the range, cap at 12
vals = sorted(found.values(), key=lambda v: v["len"])
if len(vals) > 12:
    idx = [round(i*(len(vals)-1)/11) for i in range(12)]
    vals = [vals[i] for i in sorted(set(idx))]
with OUT.open("w") as f:
    for v in vals:
        f.write(json.dumps({k: v[k] for k in ("function_name","source_file","cpp")}, ensure_ascii=False) + "\n")
print(f"discovered {len(found)} fresh self-contained scalar fns (excluded {len(train)} trained); selected {len(vals)} spanning sizes:")
for v in vals:
    print(f"  {v['function_name']:34s} [{v['source_file']:28s}] {v['len']} chars")
print(f"-> {OUT}")
