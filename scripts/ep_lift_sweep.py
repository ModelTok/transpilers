"""Sweep the never-refuse lifter across all EnergyPlus .cc modules.

For each module: lift C++ -> Python, record node count, TODO-hole count, and
whether it crashed. Emits a ranked table so we can pick the next batch of
fully-mechanical (0-TODO) modules to land.
"""
from __future__ import annotations

import glob
import json
import os
import sys
import time

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))

from transpilers.lift import lift_source  # noqa: E402

EP = "/home/db/EnergyPlus/src"
OBJEXX = "/home/db/EnergyPlus/third_party/ObjexxFCL/src"
INC = [EP, os.path.join(EP, "EnergyPlus"), OBJEXX]

files = sorted(glob.glob(os.path.join(EP, "EnergyPlus", "*.cc")))
rows = []
for i, f in enumerate(files):
    name = os.path.basename(f)
    src = open(f, errors="replace").read()
    loc = src.count("\n") + 1
    t0 = time.time()
    try:
        out, st = lift_source(src, name=f, inc=INC)
        nodes, todo = st["nodes"], st["todo"]
        pct = 100.0 * (1 - todo / nodes) if nodes else 0.0
        rows.append({"file": name, "loc": loc, "nodes": nodes, "todo": todo,
                     "mech_pct": round(pct, 1), "dt": round(time.time() - t0, 1),
                     "err": None})
    except Exception as e:  # never-refuse should not crash; record if it does
        rows.append({"file": name, "loc": loc, "nodes": 0, "todo": 0,
                     "mech_pct": 0.0, "dt": round(time.time() - t0, 1),
                     "err": f"{type(e).__name__}: {e}"[:120]})
    print(f"[{i+1}/{len(files)}] {name}: {rows[-1]['mech_pct']}% "
          f"({rows[-1]['todo']}/{rows[-1]['nodes']} TODO) {rows[-1]['dt']}s"
          + (f"  ERR {rows[-1]['err']}" if rows[-1]['err'] else ""), flush=True)

out_json = os.path.join(os.path.dirname(__file__), "ep_lift_sweep.json")
json.dump(rows, open(out_json, "w"), indent=2)

ok = [r for r in rows if r["err"] is None]
crashed = [r for r in rows if r["err"]]
total_loc = sum(r["loc"] for r in rows)
perfect = [r for r in ok if r["todo"] == 0]
print("\n==== SUMMARY ====")
print(f"files            : {len(rows)}")
print(f"total LOC        : {total_loc:,}")
print(f"crashed          : {len(crashed)}")
print(f"0-TODO (perfect) : {len(perfect)}  ({sum(r['loc'] for r in perfect):,} LOC)")
if ok:
    wsum = sum(r["mech_pct"] * r["loc"] for r in ok) / max(1, sum(r["loc"] for r in ok))
    print(f"LOC-weighted mech: {wsum:.1f}%")
print(f"\nwrote {out_json}")
