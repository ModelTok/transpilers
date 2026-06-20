#!/usr/bin/env python3
"""Evaluate the PROCEDURAL (strict) engine on transpilation-bench (40 C++->Mojo
tasks, 4 tiers). Procedural counterpart to eval_transbench.py (which evals the
fine-tuned model). For each task: `transpile --target mojo` the cpp_source, then
for every test build `{code}\\n\\ndef main() raises: print(name(args))`,
compile+run (Mojo env, -ldl -lm), compare stdout to expected. Pass iff ALL tests
match. GPU-free.

Usage: eval_transbench_strict.py
"""
from __future__ import annotations

import json
import re
import os
import subprocess
import tempfile
from collections import Counter, defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
BENCH = REPO / "benchmarks/tasks"
EPMOJO = os.environ.get("MOJO_HOME", "/home/bart/Github/NuMojo/.pixi/envs/default")
MOJO_BIN = f"{EPMOJO}/bin/mojo"
MOJO_ENV = dict(os.environ, MODULAR_HOME=f"{EPMOJO}/share/max", PATH="/usr/bin:/bin:" + f"{EPMOJO}/bin")


def run(c, **k):
    return subprocess.run(c, capture_output=True, text=True, timeout=150, **k)


def lit(a):
    if isinstance(a, bool):
        return "True" if a else "False"
    if isinstance(a, (int, float)):
        return str(a)
    if isinstance(a, str):
        return '"' + a + '"'
    if isinstance(a, list) and a:  # non-empty list -> Mojo list literal (typed by elems)
        inner = [lit(x) for x in a]
        return None if any(x is None for x in inner) else "[" + ", ".join(inner) + "]"
    return None  # empty list / other -> skip (untyped literal)


def eval_task(task, d):
    (d / "f.cpp").write_text(task["cpp_source"] + "\n")
    r = run(["uv", "run", "transpile", str(d / "f.cpp"), "--target", "mojo"], cwd=str(REPO))
    if r.returncode != 0:
        return "transpile_fail"
    mojo = r.stdout
    # real function name = last top-level `def` (task["name"] != fn name sometimes)
    defs = [re.match(r"def (\w+)\(", ln).group(1)
            for ln in mojo.splitlines() if re.match(r"def \w+\(", ln)]
    if not defs:
        return "transpile_fail"
    name = defs[-1]
    for test in task["tests"]:
        args = [lit(a) for a in test["args"]]
        if any(a is None for a in args):
            return "nonscalar_args"
        (d / "m.mojo").write_text(mojo + f"\n\ndef main() raises:\n    print({name}({', '.join(args)}))\n")
        c = run([MOJO_BIN, "build", "-Xlinker", "-ldl", "-Xlinker", "-lm", str(d / "m.mojo"), "-o", str(d / "m")], env=MOJO_ENV)
        if c.returncode != 0:
            return "compile"
        rr = run([str(d / "m")], env=MOJO_ENV)
        if rr.returncode != 0:
            return "run"
        if rr.stdout.strip() != str(test["expected"]).strip():
            return "mismatch"
    return "PASS"


def main():
    funnel = Counter()
    by_tier = defaultdict(lambda: [0, 0])
    for tf in sorted(BENCH.glob("*.json")):
        t = json.loads(tf.read_text())
        tier = t.get("tier", 0)
        by_tier[tier][1] += 1
        with tempfile.TemporaryDirectory() as td:
            outcome = eval_task(t, Path(td))
        funnel[outcome] += 1
        if outcome == "PASS":
            by_tier[tier][0] += 1
        print(f"  {outcome:16} {t['name']} (t{tier})")
    print("\n=== procedural (strict) on transpilation-bench (C++->Mojo) ===")
    for k, v in funnel.most_common():
        print(f"  {k:16} {v}")
    total = sum(funnel.values())
    print(f"\nPASS {funnel['PASS']}/{total}")
    print("by tier (pass/total):", {f"t{k}": f"{v[0]}/{v[1]}" for k, v in sorted(by_tier.items())})


if __name__ == "__main__":
    main()
