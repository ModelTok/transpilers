#!/usr/bin/env python3
"""Behavioral verify gate for void/scalar functions with scalar REFERENCE
out-params (C++ `Real64 &x` <-> Mojo `mut x: Float64`).

Same philosophy as build_cpp_mojo_dataset.verify(): compile both sides
standalone, run on sampled inputs, full computational branch coverage on the
C++ body, all outputs (every ref param + the return value, if any) must agree
to rel-err <= 1e-9. Ref params are initialized to the sampled value on BOTH
sides, so in-out and write-only refs are handled identically.

Input records: {function_name, source_file, ret_type, params:[[ctype,name,is_ref]],
                cpp_source, mojo_source}
"""
from __future__ import annotations

import argparse
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
    _p = Path(os.environ["TRANSPILERS_EPMOJO"])
    bld.EPMOJO, bld.MOJO_BIN, bld.MODULAR_HOME = _p, _p / "bin" / "mojo", _p / "share" / "max"
if "#include <array>" not in bld._CPP_HELPERS:
    bld._CPP_HELPERS = "#include <array>\n" + bld._CPP_HELPERS

# void functions use bare `return;` for early exits; an uncovered bare return
# carries no value computation (strictly safer than the constant returns the
# stock filter already tolerates). Extend the trivial-line filter to accept it.
bld._TRIVIAL_RETURN = re.compile(
    r"^\s*(?:return\s*;|return\s+-?[0-9.][0-9.eE+\-]*\s*;|break\s*;|continue\s*;|\}?\s*)$")

FENCE = re.compile(r"```(?:mojo)?\s*\n(.*?)```", re.S)

MOJO_TY = {"Real64": "Float64", "Real32": "Float64", "double": "Float64",
           "float": "Float64", "Nandle": "Float64",
           "int": "Int", "Int": "Int", "Int64": "Int", "long": "Int",
           "unsigned": "Int", "std::size_t": "Int", "size_t": "Int",
           "bool": "Bool"}
CPP_TY = {"Real64": "double", "Real32": "double", "double": "double",
          "float": "double", "Nandle": "double",
          "int": "int", "Int": "int", "Int64": "long long", "long": "long",
          "unsigned": "int", "std::size_t": "int", "size_t": "int",
          "bool": "bool"}


def _run(cmd, **kw):
    return subprocess.run(cmd, capture_output=True, text=True, timeout=300, **kw)


def verify_outparam(rec: dict, mojo: str) -> dict | None:
    params = rec["params"]            # [[ctype, name, is_ref], ...]
    ret = rec["ret_type"]
    name = rec["function_name"]
    # cpp_prepend: file-local constants the fn needs to compile standalone;
    # they become part of the training pair's C++ input too.
    body = rec.get("cpp_prepend", "") + rec["cpp_source"]
    mparams = [(nm, MOJO_TY[t]) for t, nm, _r in params]
    samples = bld._sample_inputs(mparams, body)

    n_out = sum(1 for *_x, r in params if r) + (ret != "void")

    with tempfile.TemporaryDirectory() as td:
        tdp = Path(td)
        header = f"{bld._CPP_HELPERS}\n"
        fn_first_line = header.count("\n") + 1
        blocks = []
        for i, row in enumerate(samples):
            decls, args, prints = [], [], []
            for v, (ctype, pname, is_ref) in zip(row, params):
                cl, _ml = bld._fmt_lit(v, MOJO_TY[ctype])
                if is_ref:
                    decls.append(f"{CPP_TY[ctype]} r{len(args)} = {cl};")
                    args.append(f"r{len(args)}")
                    prints.append(f"(double)r{len(args)-1}")
                else:
                    args.append(cl)
            call = f"{name}({', '.join(args)})"
            if ret != "void":
                decls.append(f"double rv = (double){call};")
                prints.append("rv")
            else:
                decls.append(f"{call};")
            fmt = " ".join(["%.15g"] * len(prints))
            blocks.append("  { " + " ".join(decls)
                          + f' printf("%d {fmt}\\n", {i}, {", ".join(prints)}); }}')
        cpp_src = (f"{header}{body}\nint main(){{\n" + "\n".join(blocks)
                   + "\n  return 0;\n}\n")
        (tdp / "oracle.cpp").write_text(cpp_src)
        dbg = os.environ.get("NIGHT_DEBUG")
        r = _run(["g++", "-O0", "-std=c++17", "-DNDEBUG", "--coverage",
                  "-o", str(tdp / "oracle"), str(tdp / "oracle.cpp")], cwd=td)
        if r.returncode != 0:
            if dbg:
                print(f"DBG {name}: g++ fail\n{r.stderr[:1200]}")
            return None
        r = _run([str(tdp / "oracle")], cwd=td)
        if r.returncode != 0:
            if dbg:
                print(f"DBG {name}: oracle run rc={r.returncode}")
            return None
        cpp_out = {}
        for ln in r.stdout.splitlines():
            ps = ln.split()
            if len(ps) == 1 + len([p for p in params if p[2]]) + (ret != "void"):
                cpp_out[ps[0]] = ps[1:]

        cov_ok, cov_hit, cov_miss, risky = bld._coverage_ok(
            tdp, "oracle.cpp", fn_first_line, body.count("\n") + 1)
        if not cov_ok:
            if dbg:
                print(f"DBG {name}: coverage fail hit={cov_hit} risky={risky[:4]}")
            return None

        mlines = []
        for i, row in enumerate(samples):
            decls, args, prints = [], [], []
            k = 0
            for v, (ctype, pname, is_ref) in zip(row, params):
                _cl, ml = bld._fmt_lit(v, MOJO_TY[ctype])
                if is_ref:
                    vn = f"r{k}_{i}"
                    decls.append(f"    var {vn}: {MOJO_TY[ctype]} = {ml}")
                    args.append(vn)
                    prints.append(vn)
                    k += 1
                else:
                    args.append(ml)
            call = f"{name}({', '.join(args)})"
            if ret != "void":
                decls.append(f"    var rv_{i} = {call}")
                prints.append(f"rv_{i}")
            else:
                decls.append(f"    {call}")
            mlines.extend(decls)
            mlines.append(f"    print({i}, {', '.join(prints)})")
        mojo_src = f"{mojo}\n\ndef main():\n" + "\n".join(mlines) + "\n"
        (tdp / "k.mojo").write_text(mojo_src)
        env = dict(os.environ, MODULAR_HOME=str(bld.MODULAR_HOME),
                   PATH=f"{bld.EPMOJO / 'bin'}:{os.environ.get('PATH', '')}")
        r = _run([str(bld.MOJO_BIN), "run", str(tdp / "k.mojo")], env=env)
        if r.returncode != 0:
            if dbg:
                errs = [l for l in r.stderr.splitlines() if "error" in l][:4]
                print(f"DBG {name}: mojo fail {errs}")
            return None
        mojo_out = {}
        for ln in r.stdout.splitlines():
            ps = ln.split()
            if len(ps) >= 2 and ps[0].isdigit():
                mojo_out[ps[0]] = ["1" if x == "True" else "0" if x == "False" else x
                                   for x in ps[1:]]

    if not cpp_out:
        return None
    finite = 0
    max_rel = 0.0
    for idx, avals in cpp_out.items():
        bvals = mojo_out.get(idx)
        if bvals is None or len(bvals) != len(avals):
            continue
        row_finite = True
        for a, b in zip(avals, bvals):
            try:
                fa, fb = float(a), float(b)
            except ValueError:
                return None
            if fa != fa or fb != fb or abs(fa) == float("inf") or abs(fb) == float("inf"):
                row_finite = False
                continue
            denom = max(abs(fa), abs(fb), 1e-9)
            rel = abs(fa - fb) / denom
            max_rel = max(max_rel, rel)
            if rel > 1e-9:
                if os.environ.get("NIGHT_DEBUG"):
                    print(f"DBG {name}: MISMATCH idx={idx} cpp={avals} mojo={bvals}")
                return None
        if row_finite:
            finite += 1
    if finite < 4:
        return None
    return {"samples_total": len(cpp_out), "samples_finite": finite,
            "max_rel_err": max_rel,
            "cpp_lines_covered": cov_hit, "cpp_lines_uncovered": cov_miss,
            "branch_coverage": "full" if cov_miss == 0 else "computation-full",
            "n_outputs": n_out}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--in", dest="inp", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--rejects", type=Path, default=None)
    args = ap.parse_args()

    rows = [json.loads(l) for l in args.inp.read_text().splitlines() if l.strip()]
    ok, rejects = [], []
    for i, rec in enumerate(rows, 1):
        name = rec["function_name"]
        raw = rec.get("mojo_source", "")
        m = FENCE.search(raw)
        mojo = (m.group(1) if m else raw).strip()
        if not mojo:
            rejects.append({**rec, "reject_reason": "empty_mojo"})
            continue
        vres = verify_outparam(rec, mojo)
        if vres is None:
            rejects.append({**rec, "reject_reason": "verify_fail"})
            print(f"[{i}/{len(rows)}] {name}: verify_fail")
            continue
        ok.append({
            "cpp_source": rec.get("cpp_prepend", "") + rec["cpp_source"],
            "mojo_source": mojo,
            "function_name": name, "source_file": rec.get("source_file", ""),
            "n_args": len(rec["params"]),
            "arg_types": [p[0] for p in rec["params"]],
            "out_params": [p[1] for p in rec["params"] if p[2]],
            "ret_type": rec["ret_type"],
            "verification": {"method": "behavioral-outparam", **vres},
            "provenance": "energyplus-cpp-llm-generate-verify",
            "direction": "cpp->mojo",
        })
        print(f"[{i}/{len(rows)}] {name}: OK (finite {vres['samples_finite']}/"
              f"{vres['samples_total']}, max_rel {vres['max_rel_err']:.1e})")

    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("w") as f:
        for p in ok:
            f.write(json.dumps(p, ensure_ascii=False) + "\n")
    if args.rejects:
        with args.rejects.open("w") as f:
            for r in rejects:
                f.write(json.dumps(r, ensure_ascii=False) + "\n")
    print(f"\nverified {len(ok)}/{len(rows)} -> {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
