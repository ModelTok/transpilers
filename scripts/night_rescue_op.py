#!/usr/bin/env python3
"""Domain-restricted rescue for the last 3 out-param rejects.

- GetPhiThetaIndices: dPhi/dTheta must be positive (0 -> div-by-zero ->
  double->int overflow UB in C++); phi/theta are angles in [0, 2pi].
- film: ibc selects a correlation: {-2,-1,0,+default}; iwd is 0/1; ws is a
  wind speed — restrict to realistic spreads so every case body is exercised.
- CalcIBesselFunc: the ErrorCode=1 path needs BessFuncOrd < 0; stock int
  sampling is non-negative.
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_cpp_mojo_dataset as bld
import night_verify_outparam as nv

MAPPERS = {
    "GetPhiThetaIndices": lambda r: [abs(r[0]) % 6.3, abs(r[1]) % 6.3,
                                     0.05 + abs(r[2]) % 3.0, 0.05 + abs(r[3]) % 3.0,
                                     r[4], r[5], r[6], r[7]],
    "film": lambda r: [r[0], r[1], abs(r[2]) % 6.0, int(abs(r[3])) % 2,
                       r[4], int(abs(r[5])) % 5 - 3],
    # spread BessFuncArg across all four error domains: normal, negative
    # (EC=2), tiny (EC=3 underflow at ord>=5), >90 (EC=4 overflow guard)
    "CalcIBesselFunc": lambda r: [
        [abs(r[0]) % 3.0,
         -(abs(r[0]) % 3.0) - 0.1,
         (abs(r[0]) % 3.0) * 1e-6,
         91.0 + abs(r[0]) % 30.0][int(abs(r[1] * 7)) % 4],
        int(abs(r[1])) % 8 - 1, r[2], r[3]],
}

_orig = bld._sample_inputs
_cur = {"f": None}


def _patched(params, body, n=120):
    rows = _orig(params, body, n)
    f = _cur["f"]
    return [f(list(r)) for r in rows] if f else rows


bld._sample_inputs = _patched

rows = [json.loads(l) for l in open(sys.argv[1]) if l.strip()]
ok = []
for rec in rows:
    name = rec["function_name"]
    if name not in MAPPERS:
        continue
    _cur["f"] = MAPPERS[name]
    mojo = rec["mojo_source"].strip()
    vres = nv.verify_outparam(rec, mojo)
    _cur["f"] = None
    if vres is None:
        print(f"{name}: STILL FAILS")
        continue
    print(f"{name}: OK (finite {vres['samples_finite']}/{vres['samples_total']}, "
          f"max_rel {vres['max_rel_err']:.1e})")
    vres["note"] = "domain-restricted sampling (C++ UB / unreachable enum outside domain)"
    ok.append({
        "cpp_source": rec.get("cpp_prepend", "") + rec["cpp_source"],
        "mojo_source": mojo, "function_name": name,
        "source_file": rec.get("source_file", ""),
        "n_args": len(rec["params"]),
        "arg_types": [p[0] for p in rec["params"]],
        "out_params": [p[1] for p in rec["params"] if p[2]],
        "ret_type": rec["ret_type"],
        "verification": {"method": "behavioral-outparam", **vres},
        "provenance": "energyplus-cpp-llm-generate-verify",
        "direction": "cpp->mojo",
    })

with open(sys.argv[2], "w") as f:
    for r in ok:
        f.write(json.dumps(r, ensure_ascii=False) + "\n")
print(f"rescued {len(ok)} -> {sys.argv[2]}")
