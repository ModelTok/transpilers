#!/usr/bin/env python3
"""Re-verify LLM-translated C++ -> Mojo candidates through the same behavioral
gate as build_cpp_mojo_dataset.py.

Input: JSONL of {function_name, source_file, cpp_source, mojo_source, ...}
(typically: the --dump-fails output of build_cpp_mojo_dataset.py with a
`mojo_source` filled in by an LLM pass).

A candidate is accepted only if the C++ oracle and the Mojo translation
compile standalone, agree to rel-err <= 1e-9 on the sampled inputs, and the
C++ body reaches full computational branch coverage — identical criteria to
the algorithmic pipeline, so provenance differs but fidelity doesn't.

Usage:
    TRANSPILERS_EPMOJO=... python scripts/verify_llm_pairs.py \
        --in candidates.jsonl --out verified.jsonl [--rejects rejects.jsonl]
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_cpp_mojo_dataset as _bld  # noqa: E402
from build_cpp_mojo_dataset import CppFn, mojo_params, verify  # noqa: E402

# Point the imported verify() at this machine's Mojo toolchain without
# touching build_cpp_mojo_dataset.py (verify reads these module globals).
if os.environ.get("TRANSPILERS_EPMOJO"):
    _p = Path(os.environ["TRANSPILERS_EPMOJO"])
    _bld.EPMOJO = _p
    _bld.MOJO_BIN = _p / "bin" / "mojo"
    _bld.MODULAR_HOME = _p / "share" / "max"

# The stock preamble lacks <array>; several EnergyPlus fns use std::array
# lookup tables. Harness scaffolding only — not part of the training pair.
if "#include <array>" not in _bld._CPP_HELPERS:
    _bld._CPP_HELPERS = "#include <array>\n" + _bld._CPP_HELPERS

_FENCE = re.compile(r"```(?:mojo)?\s*\n(.*?)```", re.S)


def _clean_mojo(s: str) -> str:
    m = _FENCE.search(s)
    return (m.group(1) if m else s).strip()


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--in", dest="inp", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--rejects", type=Path, default=None)
    args = ap.parse_args()

    ok, rejects = [], []
    rows = [json.loads(l) for l in args.inp.read_text().splitlines() if l.strip()]
    for i, rec in enumerate(rows, 1):
        name = rec["function_name"]
        mojo = _clean_mojo(rec.get("mojo_source", ""))
        if not mojo:
            rejects.append({**rec, "reject_reason": "empty_mojo"})
            continue
        fn = CppFn(name=name, ret=rec.get("ret_type", ""),
                   params=[(t, f"a{j}") for j, t in enumerate(rec.get("arg_types", []))],
                   body=rec["cpp_source"], source_file=rec.get("source_file", ""))
        mp = mojo_params(mojo)
        if mp is None or (fn.params and len(mp) != len(fn.params)):
            rejects.append({**rec, "reject_reason": "sig_mismatch"})
            print(f"[{i}/{len(rows)}] {name}: sig_mismatch")
            continue
        vres = verify(fn, mojo, mp)
        if vres is None:
            rejects.append({**rec, "reject_reason": "verify_fail"})
            print(f"[{i}/{len(rows)}] {name}: verify_fail")
            continue
        ok.append({
            "cpp_source": fn.body,
            "mojo_source": mojo,
            "function_name": name,
            "source_file": fn.source_file,
            "n_args": len(mp),
            "arg_types": rec.get("arg_types", []),
            "ret_type": rec.get("ret_type", ""),
            "verification": {"method": "behavioral", **vres},
            "provenance": "energyplus-cpp-llm-generate-verify",
            "direction": "cpp->mojo",
        })
        print(f"[{i}/{len(rows)}] {name}: OK  (finite {vres['samples_finite']}/"
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
