#!/usr/bin/env python3
"""Upgrade the production test from compile-rate to CORRECTNESS-rate.

Reuses the saved model outputs in prod_results.json (no model/GPU needed). For
each fresh EnergyPlus function: build a C++ driver (with ep_oracle.h defining the
domain helpers) that calls the real function on sampled inputs -> reference
outputs; build a Mojo driver (with ep_prelude.mojo) calling the model's
translated function on the SAME inputs; compile+run both; compare numerically.

Tells us how many of the "compiles" are actually FAITHFUL — the number the
migration cares about (compiling != correct).
"""
import json, re, subprocess, tempfile, math
from pathlib import Path
import importlib.util, sys
REPO = Path(__file__).resolve().parents[2]  # scripts/sft/<this file> -> repo root
SFT = REPO / "data/sft/cpp_mojo"
_d = importlib.util.spec_from_file_location("dv", REPO/"scripts/sft/diff_verify.py")
dv = importlib.util.module_from_spec(_d); sys.modules["dv"] = dv; _d.loader.exec_module(dv)
ORACLE = (SFT/"ep_oracle.h").read_text()
PRELUDE = (SFT/"ep_prelude.mojo").read_text()
# probe positives AND negatives/edges — negative inputs expose fmod-vs-`%` and
# sign bugs that a positives-only sample misses (nan-on-both-sides is tolerated).
SAMPLES = [-45.0, -1.0, 0.0, 0.5, 2.5, 30.0, 190.0, 273.15, 310.0, 400.0]

def nargs(sig_or_def, kind):
    if kind == "cpp":
        m = re.search(r"\b[A-Za-z_]\w*\s+(?:[A-Za-z_]\w*::)?\w+\s*\(([^)]*)\)", sig_or_def)
    else:
        m = re.search(r"\bdef\s+\w+\s*\(([^)]*)\)", sig_or_def)
    if not m: return None
    a = m.group(1).strip()
    return 0 if not a else len([x for x in a.split(",") if x.strip()])

def cpp_name(cpp):
    m = re.search(r"\bReal64\s+(?:[A-Za-z_]\w*::)?(\w+)\s*\(", cpp); return m.group(1) if m else None
def mojo_name(mojo):
    m = re.search(r"\bdef\s+(\w+)\s*\(", mojo); return m.group(1) if m else None

def inputs(n, k=8):
    rows = []
    for i in range(k):
        rows.append([SAMPLES[(i+j) % len(SAMPLES)] for j in range(n)])
    return rows

def run_cpp(cpp, name, rows):
    calls = "\n".join('  printf("%.12g\\n", (double)' + name + "(" + ",".join(f"{v}" for v in r) + "));" for r in rows)
    src = ("#include <cstdio>\n#include <algorithm>\n#include <cstdlib>\nusing namespace std;\n"
           + ORACLE + "\n" + cpp + f"\nint main(){{\n{calls}\n return 0;}}\n")
    with tempfile.TemporaryDirectory() as td:
        t = Path(td); (t/"a.cpp").write_text(src)
        if subprocess.run(["g++","-O2","-std=c++17","-o",str(t/"a"),str(t/"a.cpp")],capture_output=True).returncode: return None
        r = subprocess.run([str(t/"a")],capture_output=True,text=True,timeout=20)
        return r.stdout.strip().splitlines() if r.returncode==0 else None

def run_mojo(mojo, name, rows):
    calls = "\n".join("    print(" + name + "(" + ",".join(f"Float64({v})" for v in r) + "))" for r in rows)
    src = PRELUDE + "\n" + mojo + f"\n\ndef main():\n{calls}\n"
    with tempfile.TemporaryDirectory() as td:
        t = Path(td); (t/"m.mojo").write_text(src)
        c = subprocess.run([dv.MOJO_BIN,"build","-Xlinker","-ldl",str(t/"m.mojo"),"-o",str(t/"m")],env=dv.MOJO_ENV,capture_output=True,text=True,timeout=150)
        if c.returncode: return None
        r = subprocess.run([str(t/"m")],env=dv.MOJO_ENV,capture_output=True,text=True,timeout=20)
        return r.stdout.strip().splitlines() if r.returncode==0 else None

def num(s):
    try: return float(s)
    except: return None

def match(ref, out):
    if ref is None or out is None or len(ref) != len(out): return False
    for a, b in zip(ref, out):
        fa, fb = num(a), num(b)
        if fa is not None and fb is not None:
            if math.isnan(fa) and math.isnan(fb): continue
            if abs(fa-fb) <= 1e-6*max(abs(fa),abs(fb),1e-9): continue
            return False
        if a.strip() != b.strip(): return False
    return True

def main():
    res = json.load(open(SFT/"prod_results.json"))
    print(f"{'function':30s} {'compile':14s} correctness")
    correct = comp = 0
    for r in res:
        cn, mn = cpp_name(r["cpp"]), (mojo_name(r["mojo"]) if r["mojo"] else None)
        nc = nargs(r["cpp"], "cpp"); nm = nargs(r["mojo"], "mojo") if r["mojo"] else None
        if r["status"] != "compiles" or not mn or nc != nm:
            print(f"{r['name']:30s} {r['status']:14s} {'— (no compile / sig mismatch)'}")
            continue
        comp += 1
        rows = inputs(nc)
        ref = run_cpp(r["cpp"], cn, rows); out = run_mojo(r["mojo"], mn, rows)
        ok = match(ref, out)
        correct += ok
        detail = "FAITHFUL ✓" if ok else ("ref/build failed" if ref is None or out is None else "WRONG OUTPUT")
        print(f"{r['name']:30s} {'compiles':14s} {detail}")
    print(f"\n=== PRODUCTION CORRECTNESS === {correct}/{comp} compiling functions are numerically faithful "
          f"({correct}/{len(res)} of all fresh functions)")

if __name__ == "__main__":
    main()
