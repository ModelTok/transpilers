#!/usr/bin/env python3
"""Convert verified C++->Mojo pairs into LLaMA-Factory alpaca SFT format.

Reads `data/cpp_mojo_pairs.jsonl` (output of build_cpp_mojo_dataset.py) and
emits `data/cpp_mojo_sft.json` — a list of {instruction, input, output} records
that drops into the same LLaMA-Factory pipeline as the CodePivot SFT split
(register it in data/dataset_info.json; see training/qwen2.5-coder-3b/RUNBOOK.md).

Every record here is behaviorally verified (C++ and Mojo produce the same
outputs on sampled inputs), so the supervision signal is faithful — unlike a
mined dataset built from energyplus-mojo's spec-driven kernels.

Usage:
    uv run python scripts/cpp_mojo_to_sft.py \
        --pairs data/cpp_mojo_pairs.jsonl --out data/cpp_mojo_sft.json
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

INSTRUCTION = (
    "Translate the following EnergyPlus C++ function to idiomatic Mojo. "
    "Preserve the numerical behavior exactly. Emit only the Mojo function."
)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--pairs", type=Path, default=Path("data/cpp_mojo_pairs.jsonl"))
    ap.add_argument("--out", type=Path, default=Path("data/cpp_mojo_sft.json"))
    args = ap.parse_args()

    records = []
    for line in args.pairs.read_text().splitlines():
        line = line.strip()
        if not line:
            continue
        p = json.loads(line)
        records.append(
            {
                "instruction": INSTRUCTION,
                "input": p["cpp_source"].strip(),
                "output": p["mojo_source"].strip(),
            }
        )

    args.out.write_text(json.dumps(records, indent=2, ensure_ascii=False))
    print(f"wrote {len(records)} SFT records -> {args.out}")
    print("\nRegister in LLaMA-Factory data/dataset_info.json as:")
    print('  "cpp_mojo_sft": { "file_name": "cpp_mojo_sft.json",')
    print('    "columns": { "prompt": "instruction", "query": "input", "response": "output" } }')
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
