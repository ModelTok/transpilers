#!/usr/bin/env python3
"""Build the Python->Mojo IN-DISTRIBUTION held-out ruler: the exact 54 frozen
diverse functions, but with the PYTHON unit as the prompt (the analog of the C++
frozen ruler eval_diverse.py uses). This is where the Python-pair training should
show its win — transpilation-bench is out-of-distribution and capacity-bound for
both source languages (C++ 37.5% / Python 42.5%), whereas the C++ frozen ruler is
72%.

For each frozen-54 record that has a verified python_unit: run the C++ side to get
ground-truth outputs, and emit an eval_diverse-format record whose prompt asks the
model to transpile the python_unit. Compare generated Mojo (spliced into the same
mojo_driver) against these outputs.

Output: data/sft/cpp_mojo/heldout_diverse_py.jsonl  (run via HELD=... eval_diverse.py)
"""
from __future__ import annotations
import importlib.util, json, subprocess, sys, tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SFT = REPO / "data/sft/cpp_mojo"
FROZEN = REPO / "data/sft/benchmark/frozen_diverse.jsonl"
PYV = REPO / "data/sft/diverse/py_verified.jsonl"


def _load(n, p):
    s = importlib.util.spec_from_file_location(n, REPO / p); m = importlib.util.module_from_spec(s)
    sys.modules[n] = m; s.loader.exec_module(m); return m


dv = _load("dv", "scripts/sft/diff_verify.py")


def cpp_outputs(cpp_unit, cpp_driver):
    with tempfile.TemporaryDirectory() as td:
        t = Path(td)
        (t / "a.cpp").write_text(dv.CPP_PRE + cpp_unit + "\n" + cpp_driver + "\n")
        r = dv.run(["g++", "-O2", "-std=c++17", "-o", str(t / "a"), str(t / "a.cpp")])
        if r.returncode != 0:
            return None
        r = dv.run([str(t / "a")])
        if r.returncode != 0:
            return None
        return r.stdout.strip().splitlines() or None


def main():
    sysp = (SFT / "system.txt").read_text().strip()
    frozen = [json.loads(l) for l in FROZEN.read_text().splitlines() if l.strip()]
    pyv = {json.loads(l)["name"]: json.loads(l) for l in PYV.read_text().splitlines() if l.strip()}
    out = []; skipped = 0
    for fr in frozen:
        name = fr["name"]
        p = pyv.get(name)
        if not p or not p.get("python_unit"):
            skipped += 1; continue   # no verified Python source for this frozen fn
        ref = cpp_outputs(fr["cpp_unit"], fr["cpp_driver"])
        if not ref:
            skipped += 1; continue
        instr = ("Transpile the provided Python implementation into a functionally equivalent "
                 f"implementation in Mojo.\n\n```python\n{p['python_unit'].strip()}\n```")
        out.append({"name": name, "category": fr.get("category", "?"),
                    "prompt": [{"role": "system", "content": sysp},
                               {"role": "user", "content": instr}],
                    "mojo_driver": fr["mojo_driver"], "cpp_ref_outputs": ref})
    (SFT / "heldout_diverse_py.jsonl").write_text(
        "\n".join(json.dumps(r, ensure_ascii=False) for r in out) + "\n")
    print(f"python ruler: {len(out)} records ({skipped} skipped: no verified python / cpp ref)")
    print(f"-> {SFT/'heldout_diverse_py.jsonl'}")


if __name__ == "__main__":
    main()
