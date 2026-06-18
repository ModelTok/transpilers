#!/usr/bin/env python3
"""Emit a comment-stripped variant of assembled SFT records: same verified
pairs, but the C++ inside the instruction has comments removed (a second
training view — the lift pipeline often feeds uncommented code).

Reads the raw-pairs manifest (cpp_source/mojo_source records), not the SFT
file, so stripping happens on clean code.
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
SFT = REPO / "data" / "sft" / "cpp_mojo"

INSTRUCTION_TMPL = (
    "Transpile the provided C++ implementation into a functionally equivalent "
    "implementation in Mojo.\n\n```cpp\n{cpp}\n```"
)


def strip_comments(s: str) -> str:
    s = re.sub(r"/\*.*?\*/", "", s, flags=re.S)
    s = re.sub(r"//[^\n]*", "", s)
    s = re.sub(r"[ \t]+\n", "\n", s)          # trailing ws
    s = re.sub(r"\n{3,}", "\n\n", s)          # collapse blank-line runs
    return s.strip()


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--manifest", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    args = ap.parse_args()

    system = (SFT / "system.txt").read_text(encoding="utf-8").strip()
    n = 0
    with args.out.open("w", encoding="utf-8") as f:
        for l in args.manifest.read_text(encoding="utf-8").splitlines():
            if not l.strip():
                continue
            p = json.loads(l)
            cpp = strip_comments(p["cpp_source"])
            if not cpp:
                continue
            rec = {
                "instruction": INSTRUCTION_TMPL.format(cpp=cpp),
                "input": "",
                "system": system,
                "output": "```mojo\n" + p["mojo_source"].strip() + "\n```",
            }
            f.write(json.dumps(rec, ensure_ascii=False) + "\n")
            n += 1
    print(f"wrote {n} comment-stripped records -> {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
