#!/usr/bin/env python3
"""Dependency-ordered migration planner for EnergyPlus -> Mojo.

The production test showed the limiter on real code is DEPENDENCY CLOSURE, not
translation skill: a function calling sibling EP functions (Le, pvstar) can't be
verified in isolation. So migrate in dependency order — leaf scalar functions
first. This scans EnergyPlus, finds scalar functions, builds the call graph among
them, and reports:
  * the LEAF FRONTIER — self-contained scalar fns whose only calls are shim
    helpers (pow_N/sign/mod/Constant) or std math => migratable + verifiable NOW
  * how many more unlock per dependency layer.

GPU-free. Output: data/sft/cpp_mojo/migration_plan.json
"""
import json, re
from pathlib import Path
EP = Path("/home/bart/Github/EnergyPlus/src/EnergyPlus")
OUT = Path("/home/bart/Github/transpilers/data/sft/cpp_mojo/migration_plan.json")

SIG = re.compile(r"\bReal64\s+(?:[A-Za-z_]\w*::)?([A-Za-z_]\w+)\s*\(([^;{)]*)\)\s*\{")
SCALAR_ARG = re.compile(r"^(?:const\s+)?(?:Real64|double|int|bool|Int64|Int)\b[^,&*]*$")
SHIM = {"pow_2","pow_3","pow_4","pow_5","pow_6","pow_7","root_4","root_8","sign","mod",
        "min","max","abs","fabs","exp","log","log10","sqrt","pow","floor","ceil","trunc","atan","atan2"}
KW = {"if","for","while","return","sizeof","switch","else","do"}

def extract_body(text, name):
    m = re.search(rf"\bReal64\s+(?:[A-Za-z_]\w*::)?{re.escape(name)}\s*\(", text)
    if not m: return None
    i = text.find("{", m.start())
    if i < 0: return None
    depth = 0
    for j in range(i, len(text)):
        if text[j] == "{": depth += 1
        elif text[j] == "}":
            depth -= 1
            if depth == 0: return text[i:j+1]
    return None

# 1) discover all scalar Real64 functions across EnergyPlus
funcs = {}   # name -> {file, scalar_args, body}
allnames = set()
for cc in sorted(EP.glob("*.cc")):
    try: txt = cc.read_text(errors="ignore")
    except Exception: continue
    for m in SIG.finditer(txt):
        name, args = m.group(1), m.group(2).strip()
        allnames.add(name)
        parts = [a.strip() for a in args.split(",") if a.strip()]
        scalar = bool(parts) and all(SCALAR_ARG.match(a) for a in parts)
        funcs.setdefault(name, {"file": cc.name, "scalar": scalar})

# 2) for scalar fns, extract body + find which OTHER EP functions they call
scalar_fns = {n: v for n, v in funcs.items() if v["scalar"]}
for cc in sorted(EP.glob("*.cc")):
    try: txt = cc.read_text(errors="ignore")
    except Exception: continue
    for n in list(scalar_fns):
        if scalar_fns[n].get("deps") is not None: continue
        if scalar_fns[n]["file"] != cc.name: continue
        body = extract_body(txt, n)
        if body is None: continue
        called = set(re.findall(r"\b([A-Za-z_]\w+)\s*\(", body)) - KW - {n}
        ep_deps = (called & allnames) - SHIM           # calls to other EP functions
        non_self = ("Array" in body) or ("state." in body) or ("EnergyPlusData" in body)
        scalar_fns[n]["deps"] = sorted(ep_deps)
        scalar_fns[n]["leaf"] = (len(ep_deps) == 0) and not non_self

# 3) layers: leaf = no EP-fn deps; layer k = all deps already in earlier layers
done = {n for n, v in scalar_fns.items() if v.get("leaf")}
layers = [sorted(done)]
remaining = {n: set(v.get("deps", [])) & set(scalar_fns) for n, v in scalar_fns.items() if n not in done and v.get("deps") is not None}
while True:
    nxt = sorted(n for n, d in remaining.items() if d <= done)
    nxt = [n for n in nxt if n not in done]
    if not nxt: break
    layers.append(nxt); done |= set(nxt)
    for n in nxt: remaining.pop(n, None)

leaf = layers[0]
plan = {"scalar_fns_total": len(scalar_fns),
        "leaf_frontier_count": len(leaf),
        "leaf_frontier_sample": leaf[:40],
        "layer_sizes": [len(l) for l in layers],
        "still_blocked": len(remaining)}
OUT.write_text(json.dumps(plan, indent=1))
print(f"scalar EP functions discovered: {len(scalar_fns)}")
print(f"LEAF FRONTIER (self-contained, migratable+verifiable NOW): {len(leaf)}")
print(f"dependency layers unlock: {plan['layer_sizes'][:8]}{'...' if len(layers)>8 else ''}")
print(f"still blocked (depend on Array/state or uncovered fns): {len(remaining)}")
print(f"sample leaf frontier: {leaf[:15]}")
print(f"-> {OUT}")
