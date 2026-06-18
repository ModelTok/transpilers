#!/usr/bin/env python3
"""Rescue the two UB-blocked candidates with domain-restricted sampling.

- calculateDayOfYear: C++ indexes daysbefore[Month-1] with no bounds check;
  restrict sampling to Month in [1,12], Day in [1,31]. Mojo uses list-literal
  init (the List[Int](...) ctor form doesn't compile on Mojo 1.0).
- isMinuteMultipleOfTimestep: C++ computes minute % numMinutesPerTimestep;
  restrict the divisor to [1,60]. Mojo replicates C++ truncated % via
  minute - (minute // d) * d only when signs match... both args sampled
  non-negative here, so Mojo's floored % agrees with C++ truncated % exactly;
  still translate with explicit truncation idiom for negative-safe fidelity.
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

DAYOFYEAR_MOJO = """\
def calculateDayOfYear(Month: Int, Day: Int, leapYear: Bool) -> Int:
    var daysbefore: List[Int] = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
    var daysbeforeleap: List[Int] = [0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]
    if leapYear:
        return daysbeforeleap[Month - 1] + Day
    return daysbefore[Month - 1] + Day"""

MINUTE_MOJO = """\
def isMinuteMultipleOfTimestep(minute: Int, numMinutesPerTimestep: Int) -> Bool:
    if minute != 0:
        return minute - (minute // numMinutesPerTimestep) * numMinutesPerTimestep == 0
    return True"""

# (name, mojo, sampler) — sampler maps a raw row to an in-domain row
TARGETS = {
    "calculateDayOfYear": (DAYOFYEAR_MOJO,
                           lambda row: [int(abs(row[0])) % 12 + 1,
                                        int(abs(row[1])) % 31 + 1,
                                        row[2]]),
    "isMinuteMultipleOfTimestep": (MINUTE_MOJO,
                                   lambda row: [int(abs(row[0])) % 64,
                                                int(abs(row[1])) % 60 + 1]),
}

_orig_sample = bld._sample_inputs
_current = {"map": None}


def _patched(params, cpp_body, n=120):
    rows = _orig_sample(params, cpp_body, n)
    f = _current["map"]
    return [f(r) for r in rows] if f else rows


bld._sample_inputs = _patched

rows = {json.loads(l)["function_name"]: json.loads(l)
        for l in open(sys.argv[1]) if l.strip()}
out = []
for name, (mojo, mapper) in TARGETS.items():
    rec = rows[name]
    _current["map"] = mapper
    fn = CppFn(name=name, ret=rec.get("ret_type", ""),
               params=[(t, f"a{j}") for j, t in enumerate(rec.get("arg_types", []))],
               body=rec["cpp_source"], source_file=rec.get("source_file", ""))
    mp = mojo_params(mojo)
    vres = verify(fn, mojo, mp)
    _current["map"] = None
    if vres is None:
        print(f"{name}: STILL FAILS")
        continue
    print(f"{name}: OK (finite {vres['samples_finite']}/{vres['samples_total']}, "
          f"max_rel {vres['max_rel_err']:.1e})")
    out.append({
        "cpp_source": fn.body, "mojo_source": mojo, "function_name": name,
        "source_file": fn.source_file, "n_args": len(mp),
        "arg_types": rec.get("arg_types", []), "ret_type": rec.get("ret_type", ""),
        "verification": {"method": "behavioral", **vres,
                         "note": "domain-restricted sampling (C++ UB outside domain)"},
        "provenance": "energyplus-cpp-llm-generate-verify",
        "direction": "cpp->mojo",
    })

with open(sys.argv[2], "w") as f:
    for r in out:
        f.write(json.dumps(r, ensure_ascii=False) + "\n")
print(f"rescued {len(out)} -> {sys.argv[2]}")
