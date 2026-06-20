#!/usr/bin/env python3
"""Closure-aware real-EnergyPlus benchmark for the strict C++->Mojo engine.

Extends bench_strict_ep.py (leaves) up the dependency ladder: for each NON-LEAF
scalar function, transpile it AND its transitive scalar-dep closure, assemble
into one Mojo module, compile, and numeric-verify vs the C++ oracle. This tests
that the engine handles a function whose body calls other (also-transpiled) EP
functions — the realistic migration case, not just self-contained leaves.

GPU-free. Usage: bench_strict_ep_closure.py
"""
from __future__ import annotations

import json
import sys
import tempfile
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import bench_strict_ep as B  # reuse find_def, DECLS, CPP_FULL, PRELUDE, env, sample_rows

PLAN = json.loads((B.SFT / "migration_plan.json").read_text())
NONLEAF = PLAN["nonleaf_deps"]


def closure(name, seen=None):
    """Transitive scalar-dep closure (deps before dependents)."""
    seen = seen if seen is not None else []
    for d in NONLEAF.get(name, []):
        if d not in seen:
            closure(d, seen)
    if name not in seen:
        seen.append(name)
    return seen


def sig_decl(name):
    """`Real64 name(args);` declaration from the oracle definition."""
    got = B.find_def(name)
    if not got:
        return None, None
    body, args = got
    return body.split("{", 1)[0].strip() + ";", args


# math names already imported by ep_prelude.mojo (avoid duplicate-import errors)
PRELUDE_MATH = {"sqrt", "exp", "log", "log10", "sin", "cos", "tan",
                "atan", "atan2", "pow", "floor", "ceil", "trunc"}


def bench_one(target):
    order = closure(target)                       # deps..., target  (topo)
    defs = {n: B.find_def(n) for n in order}
    if any(v is None for v in defs.values()):
        return "skip_extract", None
    target_args = defs[target][1]
    rows = B.sample_rows(len(target_args))
    with tempfile.TemporaryDirectory() as td:
        t = Path(td)
        # --- C++ reference: all closure bodies + driver on target ---
        bodies = "\n".join(defs[n][0] for n in order)
        calls = "\n".join('    printf("%.10g\\n", ' + target + "(" + ",".join(map(str, r)) + "));" for r in rows)
        (t / "a.cpp").write_text(B.CPP_FULL + bodies + f"\nint main(){{\n{calls}\n  return 0;\n}}\n")
        r = B.run(["g++", "-O2", "-std=c++17", "-o", str(t / "a"), str(t / "a.cpp")])
        if r.returncode != 0:
            return "skip_cpp", None
        r = B.run([str(t / "a")])
        if r.returncode != 0:
            return "skip_cpprun", None
        cpp_out = r.stdout.strip().splitlines()
        # --- transpile each function (declaring its EP-fn deps so it parses) ---
        mojo_defs = []
        math_names = set()
        for n in order:
            dep_decls = "".join((sig_decl(d)[0] or "") + "\n" for d in NONLEAF.get(n, []))
            (t / "f.cpp").write_text(B.DECLS + dep_decls + defs[n][0] + "\n")
            r = B.run(["uv", "run", "transpile", str(t / "f.cpp"), "--target", "mojo"], cwd=str(B.REPO))
            if r.returncode != 0 or "def " + n not in r.stdout:
                return "transpile_fail", n
            body_lines = []
            for ln in r.stdout.splitlines():
                if ln.startswith("from std.math import"):
                    math_names.update(x.strip() for x in ln.split("import", 1)[1].split(","))
                elif ln.startswith("from ") or "does not match" in ln or ln.startswith("warning:"):
                    continue
                else:
                    body_lines.append(ln)
            mojo_defs.append("\n".join(body_lines))
        # one combined import of the math names not already in ep_prelude
        extra = sorted(math_names - PRELUDE_MATH)
        imp = f"from std.math import {', '.join(extra)}\n" if extra else ""
        mdrv = "\n".join(f"    print({target}({','.join(map(str, r))}))" for r in rows)
        prog = B.PRELUDE + "\n" + imp + "\n".join(mojo_defs) + f"\n\ndef main() raises:\n{mdrv}\n"
        (t / "b.mojo").write_text(prog)
        r = B.run([B.MOJO_BIN, "build", "-Xlinker", "-ldl", "-Xlinker", "-lm", str(t / "b.mojo"), "-o", str(t / "b")], env=B.MOJO_ENV)
        if r.returncode != 0:
            errs = [ln for ln in r.stderr.splitlines() if ": error:" in ln]
            return "mojo_compile", (errs[0][:90] if errs else "link/parse")
        r = B.run([str(t / "b")], env=B.MOJO_ENV)
        if r.returncode != 0:
            return "mojo_run", None
        mojo_out = r.stdout.strip().splitlines()
    if len(cpp_out) != len(mojo_out):
        return "verify_lines", None
    for a, b in zip(cpp_out, mojo_out):
        try:
            fa, fb = float(a), float(b)
            if (fa != fa and fb != fb) or fa == fb or abs(fa - fb) <= 1e-6 * max(abs(fa), abs(fb), 1e-9):
                continue
        except ValueError:
            if a.strip() == b.strip():
                continue
        return "verify_mismatch", f"{a[:14]}!={b[:14]}"
    return "PASS", f"closure={len(order)}"


def main():
    funnel = Counter()
    for nm in NONLEAF:
        outcome, info = bench_one(nm)
        funnel[outcome] += 1
        print(f"  {outcome:16} {nm}" + (f"  [{info}]" if info else ""))
    considered = sum(v for k, v in funnel.items() if not k.startswith("skip"))
    print(f"\n=== closure (non-leaf) funnel of {len(NONLEAF)} ===")
    for k, v in funnel.items():
        print(f"  {k:16} {v}")
    print(f"\nPASS {funnel['PASS']}/{considered} verifiable")


if __name__ == "__main__":
    main()
