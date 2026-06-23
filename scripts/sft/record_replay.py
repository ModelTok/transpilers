#!/usr/bin/env python3
"""Record/replay verifier — decouple verify-closure from porting order (#65).

To verify a function F whose callees aren't ported yet, we don't port the
callees: we **record** each callee's (args -> return) from the C++ oracle run,
generate a Mojo **replay shim** per callee that looks the return up by arg match,
then compile+run F's Mojo against those shims and compare to F's recorded
outputs. F is verified at closure-depth 1 — dependency order no longer gates
correctness, only the final all-Mojo build.

Item schema (scalar Float64 MVP):
  {
    "name": str,
    "inputs": [[float, ...], ...],          # arg tuples driving F
    "f": {"name","params": n,"cpp": "...F...","mojo": "...F..."},
    "deps": [{"name","params": n,"cpp_impl": "double NAME_impl(...){...}"}]   # params = arity (int)
  }
F's C++/Mojo call the deps by NAME; the recorder wraps NAME around NAME_impl.

Pure codegen/parse functions are unit-tested without the toolchains; the live
verify needs g++ and the Mojo toolchain (MOJO_HOME).
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SFT = REPO / "data/sft/cpp_mojo"
EPMOJO = os.environ.get("MOJO_HOME", "/home/bart/Github/NuMojo/.pixi/envs/default")
MOJO_BIN = f"{EPMOJO}/bin/mojo"
MOJO_ENV = dict(os.environ, MODULAR_HOME=f"{EPMOJO}/share/max", PATH="/usr/bin:/bin:" + f"{EPMOJO}/bin")
CPP_STD = "#include <cstdio>\n#include <cmath>\n#include <algorithm>\n#include <cstdlib>\nusing namespace std;\n"
PRELUDE = (SFT / "ep_prelude.mojo").read_text()


def _fmt(v):
    """Format a float as a valid Mojo/C++ float literal at full precision.

    Used for F's input rows (always Float64 args), so an integer-valued input
    like JSON `2` must still render as `2.0`. Typed dep literals go through
    `_typed_lit`, not here.
    """
    s = f"{float(v):.17g}"
    if not any(c in s for c in ".eEnN"):   # integer-looking -> force float
        s += ".0"
    return s


def _typed_lit(v):
    """Format a recorded dep value as a typed Mojo/C++ literal.

    bool -> Bool literal, int -> Int literal, else full-precision float.
    `bool` is a subclass of `int`, so it MUST be checked first.
    """
    if isinstance(v, bool):                # bool before int (bool < int in Python)
        return "True" if v else "False"
    if isinstance(v, int):
        return str(v)                      # Int literal (no ".0")
    return _fmt(v)


def gen_recorder_cpp(item):
    """C++ that runs F on the inputs, prints F's outputs, logs dep calls."""
    parts = [CPP_STD, (SFT / "ep_oracle.h").read_text(), ""]
    parts.append("static FILE* _fx;")
    for d in item["deps"]:
        n, np = d["name"], int(d["params"])
        parts.append(d["cpp_impl"])                       # defines NAME_impl
        args = ", ".join(f"double a{i}" for i in range(np))
        call = ", ".join(f"a{i}" for i in range(np))
        fmt = "\\t".join(["%s"] + ["%.17g"] * (np + 1))   # name, args..., ret
        logargs = ", ".join([f'"{n}"'] + [f"a{i}" for i in range(np)] + ["_r"])
        parts.append(
            f"double {n}({args}){{ double _r = {n}_impl({call}); "
            f'fprintf(_fx, "{fmt}\\n", {logargs}); return _r; }}'
        )
    parts.append(item["f"]["cpp"])
    body = ["int main(int argc, char** argv){", "  _fx = fopen(argv[1], \"w\");"]
    fn = item["f"]["name"]
    for row in item["inputs"]:
        call = ", ".join(_fmt(x) for x in row)
        body.append(f'  printf("%.17g\\n", {fn}({call}));')
    body += ["  fclose(_fx);", "  return 0;", "}"]
    parts.append("\n".join(body))
    return "\n".join(parts)


def _parse_cell(x):
    """Parse one logged cell: True/False -> bool, else full-precision float.

    Bare integer-looking cells stay floats (the scalar-Float64 default); only
    explicit True/False are treated as the bool type so exact-match applies.
    """
    if x == "True":
        return True
    if x == "False":
        return False
    return float(x)


def parse_fixtures(text):
    """Recorder log -> {dep_name: [(args_tuple, ret), ...]}."""
    fx = {}
    for line in text.splitlines():
        line = line.strip()
        if not line:
            continue
        cells = line.split("\t")
        name, *nums = cells
        vals = [_parse_cell(x) for x in nums]
        fx.setdefault(name, []).append((tuple(vals[:-1]), vals[-1]))
    return fx


def _mojo_type(v):
    """Mojo type name for a recorded value (bool before int; default Float64)."""
    if isinstance(v, bool):
        return "Bool"
    if isinstance(v, int):
        return "Int"
    return "Float64"


def _match_cond(typ, j):
    """Per-arg match condition: exact for Bool/Int, rel-1e-9 for Float64."""
    if typ in ("Bool", "Int"):
        return f"a{j} == k{j}[i]"
    return f"abs(a{j} - k{j}[i]) <= 1e-9 * (1.0 + abs(a{j}))"


def gen_replay_mojo(name, nparams, calls):
    """Generate a Mojo replay shim: match recorded args -> recorded return.

    Per-column types are inferred from the recorded values: Bool/Int columns
    get Bool/Int signatures + exact `==` matching; Float64 columns keep the
    1e-9 relative tolerance. The return type follows the recorded return.
    """
    if not calls:
        sig = ", ".join(f"a{i}: Float64" for i in range(nparams))
        out = [f"def {name}({sig}) raises -> Float64:"]
        out.append(f'    raise Error("{name}: no recorded calls")')
        return "\n".join(out)
    arg_types = [_mojo_type(calls[0][0][i]) for i in range(nparams)]
    ret_type = _mojo_type(calls[0][1])
    sig = ", ".join(f"a{i}: {arg_types[i]}" for i in range(nparams))
    out = [f"def {name}({sig}) raises -> {ret_type}:"]
    for i in range(nparams):
        out.append(f"    var k{i} = [{', '.join(_typed_lit(c[0][i]) for c in calls)}]")
    out.append(f"    var rv = [{', '.join(_typed_lit(c[1]) for c in calls)}]")
    out.append("    for i in range(len(rv)):")
    cond = " and ".join(_match_cond(arg_types[j], j) for j in range(nparams)) or "True"
    out.append(f"        if {cond}:")
    out.append("            return rv[i]")
    out.append(f'    raise Error("{name}: unrecorded args")')
    return "\n".join(out)


def gen_replay_program(item, fixtures):
    """Full Mojo program: prelude + replay shims + F + driver."""
    parts = [PRELUDE, ""]
    for d in item["deps"]:
        parts.append(gen_replay_mojo(d["name"], int(d["params"]), fixtures.get(d["name"], [])))
        parts.append("")
    parts.append(item["f"]["mojo"])
    parts.append("")
    driver = ["def main() raises:"]
    fn = item["f"]["name"]
    for row in item["inputs"]:
        driver.append(f"    print({fn}({', '.join(_fmt(x) for x in row)}))")
    parts.append("\n".join(driver))
    return "\n".join(parts)


def _close(a, b, rel=1e-6):
    if a == b:
        return True
    try:
        fa, fb = float(a), float(b)
    except ValueError:
        return False
    return abs(fa - fb) <= rel * max(abs(fa), abs(fb), 1e-9)


def verify_with_replay(item):
    """Record dep I/O from C++, replay in Mojo, compare F outputs. Returns (ok, why)."""
    with tempfile.TemporaryDirectory() as td:
        t = Path(td)
        (t / "rec.cpp").write_text(gen_recorder_cpp(item))
        r = subprocess.run(["g++", "-O2", "-std=c++17", "-o", str(t / "rec"), str(t / "rec.cpp")],
                           capture_output=True, text=True, timeout=120)
        if r.returncode != 0:
            return False, "cpp_compile: " + (r.stderr.splitlines() or [""])[-1][:80]
        r = subprocess.run([str(t / "rec"), str(t / "fx.tsv")], capture_output=True, text=True, timeout=60)
        if r.returncode != 0:
            return False, "cpp_run"
        cpp_out = r.stdout.strip().splitlines()
        fixtures = parse_fixtures((t / "fx.tsv").read_text())

        (t / "rep.mojo").write_text(gen_replay_program(item, fixtures))
        r = subprocess.run([MOJO_BIN, "build", "-Xlinker", "-ldl", "-Xlinker", "-lm", str(t / "rep.mojo"), "-o", str(t / "rep")],
                           capture_output=True, text=True, timeout=180, env=MOJO_ENV)
        if r.returncode != 0:
            errs = [ln for ln in r.stderr.splitlines() if ": error:" in ln]
            return False, "mojo_compile: " + (errs[0][:80] if errs else "link/parse")
        r = subprocess.run([str(t / "rep")], capture_output=True, text=True, timeout=60, env=MOJO_ENV)
        if r.returncode != 0:
            return False, "mojo_run: " + r.stderr.strip().splitlines()[-1][:80] if r.stderr.strip() else "mojo_run"
        mojo_out = r.stdout.strip().splitlines()

    n_calls = sum(len(v) for v in fixtures.values())
    if len(cpp_out) != len(mojo_out):
        return False, f"line_count {len(cpp_out)}!={len(mojo_out)}"
    for a, b in zip(cpp_out, mojo_out):
        if not _close(a.strip(), b.strip()):
            return False, f"mismatch '{a[:20]}'!='{b[:20]}'"
    return True, f"ok (replayed {n_calls} dep calls across {len(fixtures)} deps)"


def main():
    items = []
    for p in sys.argv[1:]:
        for line in Path(p).read_text().splitlines():
            if line.strip():
                items.append(json.loads(line))
    ok_n = 0
    for it in items:
        ok, why = verify_with_replay(it)
        ok_n += ok
        print(f"  {'OK  ' if ok else 'FAIL'} {it.get('name', '?')}: {why}")
    print(f"\n=== replay-verified {ok_n}/{len(items)} ===")


if __name__ == "__main__":
    main()
