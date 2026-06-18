#!/usr/bin/env python3
"""Prepare LLM-translation candidates from build_cpp_mojo_dataset --dump-fails.

For each failed candidate, detect calls to functions that already have a
verified (C++, Mojo) pair and bundle them: cpp_source becomes callees+target,
and the callees' verified Mojo is carried in `mojo_callees` so the LLM only
has to translate the entry function. Self-contained failures pass through
unchanged. Candidates whose unknown callees can't be resolved are dropped to
a skip file.

Usage:
    python scripts/night_prep_llm.py --fails fails.jsonl \
        --verified pairs_a.jsonl pairs_b.jsonl \
        --out llm_candidates.jsonl --skipped skipped.jsonl
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

# names defined by the verify-harness preamble or C++/builtins — not callees
KNOWN = {
    "pow_2", "pow_3", "pow_4", "pow_5", "pow_6", "pow_7", "root_4", "root_8",
    "mod", "sign", "max", "min", "abs", "fabs", "sqrt", "exp", "log", "log10",
    "pow", "sin", "cos", "tan", "asin", "acos", "atan", "atan2", "fmod",
    "floor", "ceil", "trunc", "round", "assert", "sizeof", "if", "for",
    "while", "switch", "return", "int", "double", "float", "bool", "long",
    "Real64", "Real32", "Int", "Int64", "static_cast", "cbrt", "copysign",
    "isnan", "isinf", "erf", "erfc", "tanh", "sinh", "cosh", "log1p", "expm1",
}

CALL = re.compile(r"(?<![\w:.])([A-Za-z_]\w*)\s*\(")


def strip_comments(s: str) -> str:
    s = re.sub(r"/\*.*?\*/", " ", s, flags=re.S)
    s = re.sub(r"//[^\n]*", " ", s)
    return s


def unknown_callees(body: str, self_name: str) -> set[str]:
    clean = strip_comments(body)
    # drop the signature line's own name + std:: qualified calls
    clean = re.sub(r"std\s*::\s*\w+", " ", clean)
    out = set()
    for m in CALL.finditer(clean):
        n = m.group(1)
        if n != self_name and n not in KNOWN:
            out.add(n)
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--fails", type=Path, required=True)
    ap.add_argument("--verified", type=Path, nargs="+", required=True)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--skipped", type=Path, default=None)
    args = ap.parse_args()

    vmap = {}
    for vf in args.verified:
        for l in vf.read_text().splitlines():
            if l.strip():
                r = json.loads(l)
                vmap[r["function_name"]] = r

    fails = [json.loads(l) for l in args.fails.read_text().splitlines() if l.strip()]
    out, skipped = [], []
    for rec in fails:
        name = rec["function_name"]
        if name in vmap:        # rescued by another stage already
            continue
        calls = unknown_callees(rec["cpp_source"], name)
        unresolved = {c for c in calls if c not in vmap}
        if unresolved:
            skipped.append({**rec, "unresolved_callees": sorted(unresolved)})
            continue
        if calls:               # bundle: callees first in C++, verified Mojo carried
            callees = sorted(calls)
            cpp_bundle = "\n\n".join(vmap[c]["cpp_source"] for c in callees)
            rec = dict(rec)
            rec["entry_cpp"] = rec["cpp_source"]
            rec["cpp_source"] = cpp_bundle + "\n\n" + rec["entry_cpp"]
            rec["bundled_callees"] = callees
            rec["mojo_callees"] = {c: vmap[c]["mojo_source"] for c in callees}
        out.append(rec)

    with args.out.open("w") as f:
        for r in out:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")
    if args.skipped:
        with args.skipped.open("w") as f:
            for r in skipped:
                f.write(json.dumps(r, ensure_ascii=False) + "\n")
    n_bundle = sum(1 for r in out if "bundled_callees" in r)
    print(f"fails {len(fails)} -> llm candidates {len(out)} "
          f"({n_bundle} bundled, {len(out)-n_bundle} direct), skipped {len(skipped)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
