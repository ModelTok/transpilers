#!/usr/bin/env python3
"""Triage verify rejects: classify each into cpp_compile_fail (with missing
identifiers), mojo_compile_fail (with first error), or numeric_divergence."""
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

FENCE = re.compile(r"```(?:mojo)?\s*\n(.*?)```", re.S)
UNDECL = re.compile(r"error: ‘(\w+)’ was not declared|error: '(\w+)' was not declared")

rows = [json.loads(l) for l in open(sys.argv[1]) if l.strip()]
out = []
for rec in rows:
    if not rec.get("mojo_source"):
        continue  # agent skipped it
    name = rec["function_name"]
    m = FENCE.search(rec["mojo_source"])
    mojo = (m.group(1) if m else rec["mojo_source"]).strip()
    with tempfile.TemporaryDirectory() as td:
        tdp = Path(td)
        cpp_src = f"{bld._CPP_HELPERS}\n{rec['cpp_source']}\nint main(){{return 0;}}\n"
        (tdp / "o.cpp").write_text(cpp_src)
        r = subprocess.run(["g++", "-O0", "-std=c++17", "-DNDEBUG", "-o",
                            str(tdp / "o"), str(tdp / "o.cpp")],
                           capture_output=True, text=True, cwd=td)
        if r.returncode != 0:
            missing = sorted({a or b for a, b in UNDECL.findall(r.stderr)})
            first_err = next((l for l in r.stderr.splitlines() if "error:" in l), "")[:160]
            out.append({"name": name, "class": "cpp_compile_fail",
                        "missing": missing, "err": first_err})
            continue
        (tdp / "k.mojo").write_text(f"{mojo}\n\ndef main():\n    pass\n")
        env = dict(os.environ, MODULAR_HOME=str(bld.MODULAR_HOME),
                   PATH=f"{bld.EPMOJO / 'bin'}:{os.environ.get('PATH', '')}")
        r = subprocess.run([str(bld.MOJO_BIN), "build", "-o", str(tdp / "k"),
                            str(tdp / "k.mojo")], capture_output=True, text=True,
                           env=env, timeout=180)
        if r.returncode != 0:
            first_err = next((l for l in r.stderr.splitlines() if "error" in l), "")[:200]
            out.append({"name": name, "class": "mojo_compile_fail", "err": first_err})
            continue
        out.append({"name": name, "class": "numeric_or_coverage"})

for o in out:
    print(json.dumps(o, ensure_ascii=False))
from collections import Counter
print("\n##", Counter(o["class"] for o in out))
