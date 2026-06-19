#!/usr/bin/env python3
"""EP-flavored differential verifier: like diff_verify but prepends the EnergyPlus
domain shims so pairs that USE EP idioms (Real64, pow_N(x), Constant::Pi, sign,
mod, std::pow/exp, ...) compile+run on BOTH sides. The C++ side gets ep_oracle.h
(helper DEFINITIONS); the Mojo side gets ep_prelude.mojo.

This lets us generate training data whose distribution MATCHES real EnergyPlus
code (where the production model currently fails), not just generic C++.

Usage: diff_verify_ep.py <items.jsonl ...>   (DIFF_OUT controls output path)
Item = {name, category, cpp_unit, mojo_unit, cpp_driver, mojo_driver}
"""
from __future__ import annotations
import json, os, subprocess, sys, tempfile
from collections import Counter
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SFT = REPO / "data/sft/cpp_mojo"
OUT = Path(os.environ.get("DIFF_OUT", str(REPO / "data/sft/diverse/verified_ep.jsonl")))
EPMOJO = os.environ.get("MOJO_HOME", "/home/bart/Github/NuMojo/.pixi/envs/default")
MOJO_BIN = f"{EPMOJO}/bin/mojo"
MOJO_ENV = dict(os.environ, MODULAR_HOME=f"{EPMOJO}/share/max", PATH="/usr/bin:/bin:" + f"{EPMOJO}/bin")
ORACLE = (SFT / "ep_oracle.h").read_text()
PRELUDE = (SFT / "ep_prelude.mojo").read_text()
CPP_STD = "#include <cstdio>\n#include <cmath>\n#include <algorithm>\n#include <cstdlib>\nusing namespace std;\n"


def run(cmd, **kw):
    return subprocess.run(cmd, capture_output=True, text=True, timeout=120, **kw)


def verify(item):
    with tempfile.TemporaryDirectory() as td:
        t = Path(td)
        (t/"a.cpp").write_text(CPP_STD + ORACLE + "\n" + item["cpp_unit"] + "\n" + item["cpp_driver"] + "\n")
        r = run(["g++", "-O2", "-std=c++17", "-o", str(t/"a"), str(t/"a.cpp")])
        if r.returncode != 0:
            return False, "cpp_compile"
        r = run([str(t/"a")])
        if r.returncode != 0:
            return False, "cpp_run"
        cpp_out = r.stdout.strip().splitlines()
        if not cpp_out:
            return False, "cpp_no_output"
        (t/"b.mojo").write_text(PRELUDE + "\n" + item["mojo_unit"] + "\n\n" + item["mojo_driver"] + "\n")
        r = run([MOJO_BIN, "build", "-Xlinker", "-ldl", str(t/"b.mojo"), "-o", str(t/"b")], env=MOJO_ENV)
        if r.returncode != 0:
            errs = [l for l in r.stderr.splitlines() if ": error:" in l and "failed to parse" not in l]
            return False, "mojo_compile: " + (errs[0][:50] if errs else "link/parse")
        r = run([str(t/"b")], env=MOJO_ENV)
        if r.returncode != 0:
            return False, "mojo_run"
        mojo_out = r.stdout.strip().splitlines()
    if len(cpp_out) != len(mojo_out):
        return False, f"line_count {len(cpp_out)}!={len(mojo_out)}"
    for a, b in zip(cpp_out, mojo_out):
        a, b = a.strip(), b.strip()
        if a == b:
            continue
        try:
            fa, fb = float(a), float(b)
            if abs(fa-fb)/max(abs(fa), abs(fb), 1e-9) <= 1e-6:
                continue
        except ValueError:
            pass
        return False, f"mismatch '{a[:20]}'!='{b[:20]}'"
    return True, "ok"


def main():
    items = []
    for p in sys.argv[1:]:
        for l in Path(p).read_text().splitlines():
            if l.strip():
                try: items.append(json.loads(l))
                except Exception: pass
    OUT.parent.mkdir(parents=True, exist_ok=True)
    verified, fails = [], Counter()
    for it in items:
        ok, why = verify(it)
        if ok:
            verified.append(it); print(f"  OK   [{it.get('category','?')}] {it.get('name','?')}")
        else:
            fails[why.split(':')[0]] += 1; print(f"  FAIL [{it.get('category','?')}] {it.get('name','?')}: {why}")
    with OUT.open("w") as f:
        for v in verified: f.write(json.dumps(v, ensure_ascii=False) + "\n")
    print(f"\n=== EP-verified {len(verified)}/{len(items)} ===  fails: {dict(fails)}\n-> {OUT}")


if __name__ == "__main__":
    main()
