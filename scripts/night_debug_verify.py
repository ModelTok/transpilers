#!/usr/bin/env python3
"""Replay the verify() pipeline verbosely for one candidate to see WHERE it fails."""
from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_cpp_mojo_dataset as bld

if os.environ.get("TRANSPILERS_EPMOJO"):
    p = Path(os.environ["TRANSPILERS_EPMOJO"])
    bld.EPMOJO, bld.MOJO_BIN, bld.MODULAR_HOME = p, p / "bin" / "mojo", p / "share" / "max"

if "#include <array>" not in bld._CPP_HELPERS:
    bld._CPP_HELPERS = "#include <array>\n" + bld._CPP_HELPERS

name = sys.argv[2]
rec = None
for l in open(sys.argv[1]):
    r = json.loads(l)
    if r["function_name"] == name:
        rec = r
        break
assert rec, f"{name} not found"

FENCE = re.compile(r"```(?:mojo)?\s*\n(.*?)```", re.S)
m = FENCE.search(rec["mojo_source"])
mojo = (m.group(1) if m else rec["mojo_source"]).strip()
mp = bld.mojo_params(mojo)
print("mojo_params:", mp)

fn = bld.CppFn(name=name, ret=rec.get("ret_type", ""),
               params=[(t, f"a{j}") for j, t in enumerate(rec.get("arg_types", []))],
               body=rec["cpp_source"], source_file=rec.get("source_file", ""))

samples = bld._sample_inputs([(n, t) for n, t in mp], fn.body)
td = tempfile.mkdtemp()
tdp = Path(td)
header = f"{bld._CPP_HELPERS}\n"
cpp_calls = "\n".join(
    f'  printf("%d %.15g\\n", {i}, (double){fn.name}('
    + ", ".join(bld._fmt_lit(v, t)[0] for v, (n, t) in zip(row, mp)) + "));"
    for i, row in enumerate(samples))
cpp_src = f"{header}{fn.body}\nint main(){{\n{cpp_calls}\n  return 0;\n}}\n"
(tdp / "oracle.cpp").write_text(cpp_src)
r = subprocess.run(["g++", "-O0", "-std=c++17", "-DNDEBUG", "--coverage",
                    "-o", str(tdp / "oracle"), str(tdp / "oracle.cpp")],
                   capture_output=True, text=True, cwd=td)
print("== g++ rc:", r.returncode)
print(r.stderr[:2000])
if r.returncode == 0:
    rr = subprocess.run([str(tdp / "oracle")], capture_output=True, text=True, cwd=td)
    print("== oracle run rc:", rr.returncode, "lines:", len(rr.stdout.splitlines()))
    cov = bld._coverage_ok(tdp, "oracle.cpp", header.count("\n") + 1,
                           fn.body.count("\n") + 1)
    print("== coverage:", cov[:3], "risky:", cov[3][:5])

mojo_calls = "\n".join(
    f'    print({i}, {fn.name}('
    + ", ".join(bld._fmt_lit(v, t)[1] for v, (n, t) in zip(row, mp)) + "))"
    for i, row in enumerate(samples))
mojo_src = f"{mojo}\n\ndef main():\n{mojo_calls}\n"
(tdp / "k.mojo").write_text(mojo_src)
env = dict(os.environ, MODULAR_HOME=str(bld.MODULAR_HOME),
           PATH=f"{bld.EPMOJO / 'bin'}:{os.environ.get('PATH', '')}")
r = subprocess.run([str(bld.MOJO_BIN), "run", str(tdp / "k.mojo")],
                   capture_output=True, text=True, env=env, timeout=180)
print("== mojo rc:", r.returncode)
print(r.stderr[:3000])
if r.returncode == 0:
    print("mojo lines:", len(r.stdout.splitlines()))
    # first numeric mismatch
    rr2 = subprocess.run([str(tdp / "oracle")], capture_output=True, text=True, cwd=td)
    cpp_out = {p[0]: p[1] for p in (ln.split() for ln in rr2.stdout.splitlines()) if len(p) == 2}
    mojo_out = {}
    for ln in r.stdout.splitlines():
        p = ln.split()
        if len(p) == 2 and p[0].isdigit():
            mojo_out[p[0]] = "1" if p[1] == "True" else "0" if p[1] == "False" else p[1]
    shown = 0
    for idx, a in cpp_out.items():
        b = mojo_out.get(idx)
        if b is None:
            continue
        fa, fb = float(a), float(b)
        if fa != fa or fb != fb or abs(fa) == float("inf") or abs(fb) == float("inf"):
            continue
        denom = max(abs(fa), abs(fb), 1e-9)
        if abs(fa - fb) / denom > 1e-9 and shown < 5:
            print(f"MISMATCH idx={idx} cpp={a} mojo={b} args={samples[int(idx)]}")
            shown += 1
    if not shown:
        print("no mismatches found (?)")
print("tmpdir:", td)
