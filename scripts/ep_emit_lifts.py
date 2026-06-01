"""Emit the never-refuse lift of every EnergyPlus .cc module to a target tree.

This is the Phase-1 deliverable for the EnergyPlus -> Python migration: a 1:1
mechanical lift of the whole source tree. Each module becomes one Python file;
a manifest records compile-validity (does ast.parse succeed) and TODO-hole
count per module.

Usage:
    uv run python scripts/ep_emit_lifts.py <out_dir>
"""
from __future__ import annotations

import ast
import glob
import json
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))
from transpilers.lift import lift_source  # noqa: E402

EP = "/home/db/EnergyPlus/src"
OBJEXX = "/home/db/EnergyPlus/third_party/ObjexxFCL/src"
INC = [EP, os.path.join(EP, "EnergyPlus"), OBJEXX]


def main() -> None:
    out_dir = sys.argv[1] if len(sys.argv) > 1 else "transpiled/python"
    os.makedirs(out_dir, exist_ok=True)
    files = sorted(glob.glob(os.path.join(EP, "EnergyPlus", "*.cc")))
    manifest = []
    valid = total_loc = total_nodes = total_todo = 0
    for f in files:
        name = os.path.basename(f)[:-3]  # strip .cc
        src = open(f, errors="replace").read()
        loc = src.count("\n") + 1
        try:
            out, st = lift_source(src, name=f, inc=INC)
            nodes, todo = st["nodes"], st["todo"]
        except Exception as e:  # never-refuse should not reach here
            out = f'"""LIFT FAILED: {type(e).__name__}: {e}"""\n'
            nodes = todo = 0
        try:
            ast.parse(out)
            compiles = True
            valid += 1
        except SyntaxError:
            compiles = False
        py = os.path.join(out_dir, name + ".py")
        open(py, "w").write(out)
        manifest.append({"module": name, "src_loc": loc, "py_loc": out.count("\n") + 1,
                         "nodes": nodes, "todo": todo, "valid_python": compiles})
        total_loc += loc; total_nodes += nodes; total_todo += todo

    summary = {
        "modules": len(files),
        "valid_python": valid,
        "valid_pct": round(100 * valid / len(files), 1),
        "src_loc": total_loc,
        "nodes": total_nodes,
        "todo_holes": total_todo,
        "mechanical_pct": round(100 * (1 - total_todo / total_nodes), 2) if total_nodes else 0,
    }
    json.dump({"summary": summary, "modules": manifest},
              open(os.path.join(out_dir, "manifest.json"), "w"), indent=2)
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
