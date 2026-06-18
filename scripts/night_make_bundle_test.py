#!/usr/bin/env python3
"""Build the CalcASHRAETARPNatural bundled LLM-candidate for harness testing."""
import json
from pathlib import Path

pairs_file = Path("/mnt/c/Github/transpilers/data/cpp_mojo_pairs.jsonl")
fails_file = Path("/home/amd/night/smoke_fails.jsonl")
out_file = Path("/home/amd/night/llm_test_in.jsonl")

CALLEES = ["CalcASHRAEVerticalWall", "CalcWaltonUnstableHorizontalOrTilt",
           "CalcWaltonStableHorizontalOrTilt"]

by_name = {}
for l in pairs_file.read_text().splitlines():
    if l.strip():
        r = json.loads(l)
        by_name[r["function_name"]] = r

target = json.loads(fails_file.read_text().splitlines()[0])
assert target["function_name"] == "CalcASHRAETARPNatural"

cpp_bundle = "\n\n".join(by_name[c]["cpp_source"] for c in CALLEES)
cpp_bundle += "\n\n" + target["cpp_source"]

# entry def first so the harness reads its signature; imports hoisted to top
mojo_callees = []
imports = set()
for c in CALLEES:
    src = by_name[c]["mojo_source"]
    body = []
    for line in src.splitlines():
        if line.startswith("from ") or line.startswith("import "):
            imports.add(line.strip())
        else:
            body.append(line)
    mojo_callees.append("\n".join(body).strip())

entry_mojo = """\
def CalcASHRAETARPNatural(Tsurf: Float64, Tamb: Float64, cosTilt: Float64) -> Float64:
    var DeltaTemp: Float64 = Tsurf - Tamb
    if DeltaTemp == 0.0 or cosTilt == 0.0:
        return CalcASHRAEVerticalWall(DeltaTemp)
    if (DeltaTemp < 0.0 and cosTilt < 0.0) or (DeltaTemp > 0.0 and cosTilt > 0.0):
        return CalcWaltonUnstableHorizontalOrTilt(DeltaTemp, cosTilt)
    return CalcWaltonStableHorizontalOrTilt(DeltaTemp, cosTilt)"""

mojo_bundle = "\n".join(sorted(imports)) + "\n\n" + entry_mojo + "\n\n" + "\n\n".join(mojo_callees)

rec = dict(target)
rec["cpp_source"] = cpp_bundle
rec["mojo_source"] = mojo_bundle
rec["bundled_callees"] = CALLEES
out_file.write_text(json.dumps(rec, ensure_ascii=False) + "\n")
print(f"wrote bundled candidate -> {out_file}")
