#!/usr/bin/env python3
"""Migrate the verified EP pairs' Mojo to latest-Mojo syntax (per the official
modular/skills mojo-syntax skill) and RE-VERIFY every pair through its gate.

Rules applied to mojo_source:
- stdlib imports get the `std.` prefix: `from math import X` -> `from std.math import X`
- prelude functions need no import: pow/abs/min/max/round/divmod are dropped
  from import lists (empty import lines removed)

Gates: records with verification.method == "behavioral" re-verify through
build_cpp_mojo_dataset.verify(); "behavioral-outparam" through
night_verify_outparam.verify_outparam() (params reconstructed from the opout
batch files). Functions that required domain-restricted sampling re-use their
mappers.

Usage:
    TRANSPILERS_EPMOJO=... python scripts/night_migrate_std.py \
        --manifest data/night/ep_pairs_v3_manifest.jsonl \
        --opout data/night/opout_00.jsonl data/night/opout_01.jsonl \
        --out data/night/ep_pairs_v3_std_manifest.jsonl
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_cpp_mojo_dataset as bld
from build_cpp_mojo_dataset import CppFn, mojo_params, verify
import night_verify_outparam as nv  # applies EPMOJO/_CPP_HELPERS/_TRIVIAL_RETURN patches

PRELUDE = {"pow", "abs", "min", "max", "round", "divmod"}
IMPORT = re.compile(r"^from\s+(math|collections|memory|sys|os|pathlib|random|bit|utils)\s+import\s+(.+)$")

# Domain-restricted sampling mappers (C++ UB / unreachable enum outside domain)
MAPPERS = {
    "calculateDayOfYear": lambda r: [int(abs(r[0])) % 12 + 1,
                                     int(abs(r[1])) % 31 + 1, r[2]],
    "isMinuteMultipleOfTimestep": lambda r: [int(abs(r[0])) % 64,
                                             int(abs(r[1])) % 60 + 1],
    "GetPhiThetaIndices": lambda r: [abs(r[0]) % 6.3, abs(r[1]) % 6.3,
                                     0.05 + abs(r[2]) % 3.0, 0.05 + abs(r[3]) % 3.0,
                                     r[4], r[5], r[6], r[7]],
    "film": lambda r: [r[0], r[1], abs(r[2]) % 6.0, int(abs(r[3])) % 2,
                       r[4], int(abs(r[5])) % 5 - 3],
}

_orig_sample = bld._sample_inputs
_cur = {"f": None}


def _patched(params, body, n=120):
    rows = _orig_sample(params, body, n)
    f = _cur["f"]
    return [f(list(r)) for r in rows] if f else rows


bld._sample_inputs = _patched


def migrate_mojo(src: str) -> str:
    out = []
    for line in src.splitlines():
        m = IMPORT.match(line.strip())
        if m:
            mod, names = m.group(1), [n.strip() for n in m.group(2).split(",")]
            keep = [n for n in names if n not in PRELUDE]
            if keep:
                out.append(f"from std.{mod} import {', '.join(keep)}")
            continue
        out.append(line)
    # drop a leading blank left by a removed import
    while out and not out[0].strip():
        out.pop(0)
    return "\n".join(out)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--manifest", type=Path, required=True)
    ap.add_argument("--opout", type=Path, nargs="+", required=True)
    ap.add_argument("--out", type=Path, required=True)
    args = ap.parse_args()

    params_by_name = {}
    for f in args.opout:
        for l in f.read_text(encoding="utf-8").splitlines():
            if l.strip():
                r = json.loads(l)
                params_by_name[r["function_name"]] = r["params"]

    rows = [json.loads(l) for l in args.manifest.read_text(encoding="utf-8")
            .splitlines() if l.strip()]
    out, fails = [], []
    for i, rec in enumerate(rows, 1):
        name = rec["function_name"]
        new_mojo = migrate_mojo(rec["mojo_source"])
        _cur["f"] = MAPPERS.get(name)
        if rec["verification"]["method"] == "behavioral":
            fn = CppFn(name=name, ret=rec.get("ret_type", ""),
                       params=[(t, f"a{j}") for j, t in enumerate(rec["arg_types"])],
                       body=rec["cpp_source"], source_file=rec["source_file"])
            mp = mojo_params(new_mojo)
            vres = verify(fn, new_mojo, mp) if mp is not None else None
        else:
            vrec = {"function_name": name, "ret_type": rec["ret_type"],
                    "params": params_by_name[name], "cpp_source": rec["cpp_source"]}
            vres = nv.verify_outparam(vrec, new_mojo)
        _cur["f"] = None
        if vres is None:
            fails.append(name)
            print(f"[{i}/{len(rows)}] {name}: RE-VERIFY FAIL")
            continue
        nrec = dict(rec)
        nrec["mojo_source"] = new_mojo
        nrec["verification"] = {**rec["verification"], **vres,
                                "syntax": "latest-std-prefix"}
        out.append(nrec)
        changed = "migrated" if new_mojo != rec["mojo_source"] else "unchanged"
        print(f"[{i}/{len(rows)}] {name}: OK ({changed}, max_rel "
              f"{vres['max_rel_err']:.1e})")

    with args.out.open("w", encoding="utf-8") as f:
        for r in out:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")
    print(f"\nmigrated+verified {len(out)}/{len(rows)} -> {args.out}")
    if fails:
        print("FAILED:", fails)
    return 0 if not fails else 1


if __name__ == "__main__":
    raise SystemExit(main())
