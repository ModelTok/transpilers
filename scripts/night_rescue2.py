#!/usr/bin/env python3
"""Last-mile rescue for two specific rejects:

- CalcWindSurfaceTheta: Mojo 1.0 has no math.fmod; emulate C++ std::fmod
  exactly via floored % with a sign correction (both ops are IEEE-exact).
- OutdoorDryBulbGrad: numerics agreed everywhere but the `return LowGradient`
  branch was never sampled (needs DryBulbTemp < LowerBound < UpperBound, which
  independent column draws happened to miss). Append one targeted row.
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_cpp_mojo_dataset as bld
from build_cpp_mojo_dataset import CppFn, mojo_params, verify

if os.environ.get("TRANSPILERS_EPMOJO"):
    p = Path(os.environ["TRANSPILERS_EPMOJO"])
    bld.EPMOJO, bld.MOJO_BIN, bld.MODULAR_HOME = p, p / "bin" / "mojo", p / "share" / "max"
if "#include <array>" not in bld._CPP_HELPERS:
    bld._CPP_HELPERS = "#include <array>\n" + bld._CPP_HELPERS

WIND_MOJO = """\
def CalcWindSurfaceTheta(WindDir: Float64, SurfAzimuth: Float64) -> Float64:
    var windDir: Float64 = WindDir % 360.0
    if windDir != 0.0 and WindDir < 0.0:
        windDir -= 360.0
    var surfAzi: Float64 = SurfAzimuth % 360.0
    if surfAzi != 0.0 and SurfAzimuth < 0.0:
        surfAzi -= 360.0
    var theta: Float64 = abs(windDir - surfAzi)
    if theta > 180.0:
        return abs(theta - 360.0)
    return theta"""

# DryBulbTemp < LowerBound < UpperBound -> exercises `return LowGradient`
EXTRA_5ARG_ROW = [0.0, 5.0, 1.0, 3.0, 2.0]

_orig_sample = bld._sample_inputs


def _patched(params, cpp_body, n=120):
    rows = _orig_sample(params, cpp_body, n)
    if len(params) == 5:
        rows.append(list(EXTRA_5ARG_ROW))
    return rows


bld._sample_inputs = _patched
# verify() resolved _sample_inputs at module load; patch its global namespace
verify.__globals__["_sample_inputs"] = _patched

rows = {json.loads(l)["function_name"]: json.loads(l)
        for l in open(sys.argv[1]) if l.strip()}
out = []
for name, mojo in (("CalcWindSurfaceTheta", WIND_MOJO),
                   ("OutdoorDryBulbGrad", None)):
    rec = rows[name]
    if mojo is None:
        mojo = rec["mojo_source"].strip()
    fn = CppFn(name=name, ret=rec.get("ret_type", ""),
               params=[(t, f"a{j}") for j, t in enumerate(rec.get("arg_types", []))],
               body=rec["cpp_source"], source_file=rec.get("source_file", ""))
    mp = mojo_params(mojo)
    vres = verify(fn, mojo, mp)
    if vres is None:
        print(f"{name}: STILL FAILS")
        continue
    print(f"{name}: OK (finite {vres['samples_finite']}/{vres['samples_total']}, "
          f"max_rel {vres['max_rel_err']:.1e})")
    out.append({
        "cpp_source": fn.body, "mojo_source": mojo, "function_name": name,
        "source_file": fn.source_file, "n_args": len(mp),
        "arg_types": rec.get("arg_types", []), "ret_type": rec.get("ret_type", ""),
        "verification": {"method": "behavioral", **vres},
        "provenance": "energyplus-cpp-llm-generate-verify",
        "direction": "cpp->mojo",
    })

with open(sys.argv[2], "w") as f:
    for r in out:
        f.write(json.dumps(r, ensure_ascii=False) + "\n")
print(f"rescued {len(out)} -> {sys.argv[2]}")
