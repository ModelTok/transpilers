#!/usr/bin/env python3
"""Real-EnergyPlus benchmark for the deterministic strict C++->Mojo engine.

For each scalar leaf function in the migration plan, this:
  1. extracts the real C++ body from the oracle (/home/bart/Github/EnergyPlus),
  2. transpiles it with `transpile --target mojo` (strict engine),
  3. compiles the Mojo with the live toolchain (+ ep_prelude shims),
  4. differential-verifies vs the C++ reference on sampled inputs.

Reports a stage-by-stage funnel (extract -> transpile -> mojo-compile -> verify)
and a failure taxonomy, so we can see exactly where the deterministic engine
loses real EnergyPlus functions and target fixes. GPU-free.

Usage: bench_strict_ep.py [N]      # N = max functions (default 40)
"""
from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import tempfile
from collections import Counter
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
EP = Path(os.environ.get("EP_SRC", "/home/bart/Github/EnergyPlus/src/EnergyPlus"))
SFT = REPO / "data/sft/cpp_mojo"
PLAN = json.loads((SFT / "migration_plan.json").read_text())
PRELUDE = (SFT / "ep_prelude.mojo").read_text()
EPMOJO = os.environ.get("MOJO_HOME", "/home/bart/Github/NuMojo/.pixi/envs/default")
MOJO_BIN = f"{EPMOJO}/bin/mojo"
MOJO_ENV = dict(os.environ, MODULAR_HOME=f"{EPMOJO}/share/max", PATH="/usr/bin:/bin:" + f"{EPMOJO}/bin")

# C++ decls so libclang type-checks shim/Constant refs WITHOUT transpiling their
# bodies (the Mojo side gets the real shims from ep_prelude).
# Decls for parsing + REAL constant values (so strict folds them correctly,
# instead of silently emitting 0 for unresolved namespaced constants).
DECLS = """#include <cmath>
#include <algorithm>
typedef double Real64; typedef long long Int64; typedef int Int;
static const double SMALL = 1e-10;
double pow_2(double),pow_3(double),pow_4(double),pow_5(double),pow_6(double),pow_7(double);
double root_4(double),root_8(double),sign(double,double),mod(double,double),radians(double),pvstar(double);
namespace Constant{const double Pi=3.14159265358979324,TwoPi=6.28318530717958648,PiOvr2=1.57079632679489662,Kelvin=273.15,StefanBoltzmann=5.6697e-8,Sigma=5.6697e-8,DegToRad=0.0174532925199432958,RadToDeg=57.2957795130823209,UniversalGasConstant=8314.462175,Gravity=9.807;}
namespace DataPrecisionGlobals{const double EXP_LowerLimit=-20.0,constant_zero=0.0,constant_one=1.0;}
namespace TARCOGParams{const int MMax=100,NMax=100;}
"""
CPP_FULL = ("#include <cstdio>\n#include <cmath>\n#include <algorithm>\n#include <cstdlib>\n"
            "using namespace std;\n" + (SFT / "ep_oracle.h").read_text() + "\n")

SCALAR = re.compile(r"^(?:const\s+)?(?:Real64|double|int|bool|Int64|Int)\b[^,&*]*$")


def strip_comments(t):
    t = re.sub(r"/\*.*?\*/", " ", t, flags=re.S)
    return re.sub(r"//[^\n]*", " ", t)


def find_def(name):
    """Return (body_with_sig, arg_types) for a scalar Real64 fn, or None."""
    sig = re.compile(rf"\bReal64\s+(?:[A-Za-z_]\w*::)?{re.escape(name)}\s*\(([^;{{)]*)\)\s*\{{")
    for f in list(EP.glob("*.cc")) + list(EP.glob("*.hh")):
        txt = strip_comments(f.read_text(errors="ignore"))
        m = sig.search(txt)
        if not m:
            continue
        args = [a.strip() for a in m.group(1).split(",") if a.strip()]
        if not args or not all(SCALAR.match(a) for a in args):
            return None
        i = txt.find("{", m.start())
        d = 0
        for j in range(i, len(txt)):
            if txt[j] == "{":
                d += 1
            elif txt[j] == "}":
                d -= 1
                if d == 0:
                    sig_txt = f"Real64 {name}({m.group(1)})"
                    return sig_txt + " " + txt[i:j + 1], args
    return None


def sample_rows(nargs, k=5):
    base = [0.7, 1.5, 3.0, 7.0, 12.0, 0.3, 9.0, 21.0]
    return [[base[(r + c) % len(base)] for c in range(nargs)] for r in range(k)]


def run(cmd, **kw):
    return subprocess.run(cmd, capture_output=True, text=True, timeout=120, **kw)


def bench_one(name):
    got = find_def(name)
    if not got:
        return "skip_extract", None
    body, args = got
    n = len(args)
    rows = sample_rows(n)
    with tempfile.TemporaryDirectory() as td:
        t = Path(td)
        # --- C++ reference ---
        calls = "\n".join('    printf("%.10g\\n", ' + name + "(" + ",".join(map(str, r)) + "));" for r in rows)
        (t / "a.cpp").write_text(CPP_FULL + body + f"\nint main(){{\n{calls}\n  return 0;\n}}\n")
        r = run(["g++", "-O2", "-std=c++17", "-o", str(t / "a"), str(t / "a.cpp")])
        if r.returncode != 0:
            return "skip_cpp", None
        r = run([str(t / "a")])
        if r.returncode != 0:
            return "skip_cpprun", None
        cpp_out = r.stdout.strip().splitlines()
        # --- strict transpile ---
        (t / "f.cpp").write_text(DECLS + body + "\n")
        r = run(["uv", "run", "transpile", str(t / "f.cpp"), "--target", "mojo"], cwd=str(REPO))
        if r.returncode != 0 or "def " + name not in r.stdout:
            return "transpile_fail", None
        mojo_fn = r.stdout
        # --- mojo compile + run ---
        mdrv = "\n".join(f"    print({name}({','.join(map(str, r))}))" for r in rows)
        (t / "b.mojo").write_text(PRELUDE + "\n" + mojo_fn + f"\n\ndef main() raises:\n{mdrv}\n")
        r = run([MOJO_BIN, "build", "-Xlinker", "-ldl", "-Xlinker", "-lm",
                 str(t / "b.mojo"), "-o", str(t / "b")], env=MOJO_ENV)  # -lm: asin/acos/cbrt
        if r.returncode != 0:
            errs = [ln for ln in r.stderr.splitlines() if ": error:" in ln]
            return "mojo_compile", (errs[0][:90] if errs else "link/parse")
        r = run([str(t / "b")], env=MOJO_ENV)
        if r.returncode != 0:
            return "mojo_run", None
        mojo_out = r.stdout.strip().splitlines()
    # --- compare ---
    if len(cpp_out) != len(mojo_out):
        return "verify_lines", None
    for a, b in zip(cpp_out, mojo_out):
        try:
            fa, fb = float(a), float(b)
            # both NaN or both same inf == same behavior (domain edge); accept
            if (fa != fa and fb != fb) or fa == fb:
                continue
            if abs(fa - fb) <= 1e-6 * max(abs(fa), abs(fb), 1e-9):
                continue
        except ValueError:
            if a.strip() == b.strip():
                continue
        return "verify_mismatch", f"{a[:14]}!={b[:14]}"
    return "PASS", None


def main():
    limit = int(sys.argv[1]) if len(sys.argv) > 1 else 40
    leaves = PLAN["layers_full"][0][:limit]
    funnel = Counter()
    detail = []
    for nm in leaves:
        outcome, info = bench_one(nm)
        funnel[outcome] += 1
        mark = "PASS" if outcome == "PASS" else outcome
        detail.append((nm, mark, info))
        print(f"  {mark:16} {nm}" + (f"  [{info}]" if info else ""))
    considered = sum(v for k, v in funnel.items() if not k.startswith("skip"))
    print(f"\n=== strict-engine real-EP funnel (of {len(leaves)} leaves) ===")
    for k in ["skip_extract", "skip_cpp", "skip_cpprun", "transpile_fail", "mojo_compile", "mojo_run", "verify_lines", "verify_mismatch", "PASS"]:
        if funnel[k]:
            print(f"  {k:16} {funnel[k]}")
    print(f"\nPASS {funnel['PASS']}/{considered} verifiable  ({funnel['PASS']}/{len(leaves)} of all leaves)")


if __name__ == "__main__":
    main()
