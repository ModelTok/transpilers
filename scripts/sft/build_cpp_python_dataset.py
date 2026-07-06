#!/usr/bin/env python3
"""SFT source 3: behaviorally-verified C++ -> Python pairs from EnergyPlus.

Auxiliary direction (cleaner, higher-volume than C++->Mojo): teaches the model
the C++-understanding half. Same generate-and-verify discipline as the Mojo
pipeline — reuses its extractor, threshold-aware sampler, C++ oracle, and gcov
branch-coverage gate — but the target side is Python, verified by exec + numeric
comparison against the compiled C++ oracle.

Emits data/sft/cpp_python_pairs.jsonl.
"""
from __future__ import annotations

import importlib.util, json, os, subprocess, sys, tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "src"))

# reuse the Mojo pipeline's building blocks
_spec = importlib.util.spec_from_file_location("bcm", REPO / "scripts/build_cpp_mojo_dataset.py")
bcm = importlib.util.module_from_spec(_spec); sys.modules["bcm"] = bcm; _spec.loader.exec_module(bcm)

OUT = REPO / "data/sft/cpp_python_pairs.jsonl"


def transpile_py(fn) -> str | None:
    os.environ["TRANSPILERS_CPP_PREAMBLE_FILE"] = str(bcm.PREAMBLE_FILE)
    from transpilers.cli.main import transpile
    try:
        py = transpile(fn.body, source_lang="cpp", target="python")
    except Exception:
        return None
    return py.strip() or None


def verify_py(fn, py_code, mparams) -> dict | None:
    samples = bcm._sample_inputs([(n, t) for n, t in mparams], fn.body)
    # --- C++ oracle (with coverage), same as the Mojo pipeline ---
    with tempfile.TemporaryDirectory() as td:
        tdp = Path(td)
        calls = "\n".join(
            f'  printf("%.15g\\n", (double){fn.name}('
            + ", ".join(bcm._fmt_lit(v, t)[0] for v, (n, t) in zip(row, mparams)) + "));"
            for row in samples)
        header = f"{bcm._CPP_HELPERS}\n"
        fn_first = header.count("\n") + 1
        (tdp / "o.cpp").write_text(f"{header}{fn.body}\nint main(){{\n{calls}\n return 0;}}\n")
        r = bcm._run(["g++", "-O0", "-std=c++17", "--coverage", "-o", str(tdp/"o"), str(tdp/"o.cpp")], cwd=str(tdp))
        if r.returncode != 0:
            return None
        r = bcm._run([str(tdp/"o")], cwd=str(tdp))
        if r.returncode != 0:
            return None
        cpp_out = r.stdout.split()
        ok, hit, miss, risky = bcm._coverage_ok(tdp, "o.cpp", fn_first, bcm._body_line_span(fn))
        if not ok:
            return None
    # --- Python target: exec + call ---
    # Inject the ObjexxFCL/<cmath> helpers the C++ bodies call (the Python
    # backend leaves pow_2(...)/exp(...) as bare names) so the verified Python
    # runs standalone — same semantics as _CPP_HELPERS on the oracle side.
    import math
    ns: dict = {k: getattr(math, k) for k in
                ("exp", "log", "log10", "log2", "sqrt", "sin", "cos", "tan",
                 "asin", "acos", "atan", "atan2", "sinh", "cosh", "tanh",
                 "floor", "ceil", "trunc", "fabs", "fmod", "hypot", "pow")}
    ns.update({"pow_2": lambda x: x*x, "pow_3": lambda x: x**3, "pow_4": lambda x: x**4,
               "pow_5": lambda x: x**5, "pow_6": lambda x: x**6, "pow_7": lambda x: x**7,
               "mod": math.fmod, "sign": lambda a, b: math.copysign(abs(a), b),
               "min": min, "max": max, "abs": abs})
    try:
        exec(py_code, ns)
    except Exception:
        return None
    fnpy = ns.get(fn.name)
    if not callable(fnpy):
        return None
    finite = 0; max_rel = 0.0
    for row, a in zip(samples, cpp_out):
        args = [int(v) if t in ("Int", "int") else (bool(v) if t in ("Bool", "bool") else v)
                for v, (n, t) in zip(row, mparams)]
        try:
            pv = float(fnpy(*args)); fa = float(a)
        except Exception:
            return None
        if fa != fa or pv != pv or abs(fa) == float("inf") or abs(pv) == float("inf"):
            continue
        rel = abs(fa - pv) / max(abs(fa), abs(pv), 1e-9)
        max_rel = max(max_rel, rel)
        if rel > 1e-9:
            return None
        finite += 1
    if finite < 4:
        return None
    return {"samples_finite": finite, "max_rel_err": max_rel,
            "cpp_lines_covered": hit, "cpp_lines_uncovered": miss,
            "branch_coverage": "full" if miss == 0 else "computation-full"}


# Python param signature parser (def f(a: float, b: int) -> ...)
import re
_PYSIG = re.compile(r"def\s+\w+\(([^)]*)\)")


def py_params(code):
    m = _PYSIG.search(code)
    if not m:
        return None
    out = []
    for part in m.group(1).split(","):
        part = part.strip()
        if not part:
            continue
        nm = part.split(":")[0].strip()
        out.append((nm, "float"))
    return out


def main():
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("--ep-src", type=Path, default=Path(os.environ.get("EP_SRC", "/home/bart/Github/EnergyPlus/src/EnergyPlus")))
    ap.add_argument("--limit", type=int, default=0)
    args = ap.parse_args()

    fns = bcm.extract_fns(args.ep_src)
    if args.limit:
        fns = fns[: args.limit]
    print(f"candidates: {len(fns)}")
    pairs = []; stats = {"transpile_fail": 0, "sig_fail": 0, "verify_fail": 0, "ok": 0}
    for i, fn in enumerate(fns, 1):
        py = transpile_py(fn)
        if not py:
            stats["transpile_fail"] += 1; continue
        pp = py_params(py)
        if pp is None or len(pp) != len(fn.params):
            stats["sig_fail"] += 1; continue
        v = verify_py(fn, py, pp)
        if v is None:
            stats["verify_fail"] += 1; continue
        stats["ok"] += 1
        pairs.append({
            "instruction": "Translate the following EnergyPlus C++ function to "
                           "idiomatic Python. Preserve the numerical behavior exactly.",
            "input": fn.body, "output": py, "source": "cpp_python",
            "function_name": fn.name, "source_file": fn.source_file,
            "verification": {"method": "behavioral", **v},
        })
        print(f"[{i}/{len(fns)}] {fn.name}: OK (finite {v['samples_finite']}, rel {v['max_rel_err']:.0e})")
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("w") as f:
        for p in pairs:
            f.write(json.dumps(p, ensure_ascii=False) + "\n")
    print(f"\nC++→Python: {stats['ok']} verified  (tp_fail={stats['transpile_fail']} "
          f"sig_fail={stats['sig_fail']} verify_fail={stats['verify_fail']})")
    print(f"  -> {OUT}")


if __name__ == "__main__":
    main()
