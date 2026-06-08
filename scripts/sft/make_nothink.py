#!/usr/bin/env python3
"""Create a no-reasoning (no-<think>) training variant of the cpp->mojo SFT set.

Reads  data/sft/cpp_mojo/train_translation.jsonl   (CodePivot schema)
Writes data/sft/cpp_mojo/train_translation_nothink.jsonl

Each record's `output` has its <think>...</think> block removed, keeping only the
<answer>```mojo ... ```</answer> part. The `system` field's format instruction is
rewritten so the model is told to emit ONLY the answer code, with no reasoning.

A no-reasoning model is ~4x faster at inference; this enables a later A/B test.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "data" / "sft" / "cpp_mojo" / "train_translation.jsonl"
DST = ROOT / "data" / "sft" / "cpp_mojo" / "train_translation_nothink.jsonl"

THINK_RE = re.compile(r"<think>.*?</think>\s*", re.DOTALL)


def strip_think(output: str) -> str:
    """Remove the <think>...</think> block (if any), keeping the <answer> part."""
    return THINK_RE.sub("", output, count=1).lstrip()


def rewrite_system(system: str) -> str:
    """Drop the chain-of-thought instruction from the system prompt.

    The original system prompt instructs the model to first emit an internal
    monologue inside <think>...</think> and then an <answer>...</answer> block.
    For the no-think variant we replace that trailing instruction with one that
    asks for only the <answer> block (no reasoning).
    """
    # The reasoning directive in the original begins with a sentence like
    # "... you provide well-reasoned and detailed responses by first thinking
    # through the reasoning process as an internal monologue ...". Cut from the
    # start of that sentence so no chain-of-thought instruction remains.
    marker = "you provide well-reasoned"
    idx = system.find(marker)
    if idx == -1:
        # Fallback: cut at the structured-format sentence.
        marker2 = "Provide your response in the following structured format"
        idx = system.find(marker2)
    new_tail = (
        "you respond with only the transpiled code and no reasoning, commentary, "
        "or explanation. "
        "Provide your response in the following structured format: "
        "<answer>\n```{language}\n{code}\n```\n</answer>. In the section enclosed "
        "by <answer> and </answer> tags, ensure that only the transpiled code is "
        "included in accordance with the given format, such as ```mojo\n{code}\n```."
    )
    if idx == -1:
        # Could not find the format instruction; append the new directive.
        return system.rstrip() + "\n" + new_tail
    return system[:idx].rstrip() + " " + new_tail


def main() -> None:
    if not SRC.exists():
        raise SystemExit(f"missing source: {SRC}")

    records = [json.loads(line) for line in SRC.read_text().splitlines() if line.strip()]

    out_lines = []
    total_old = 0
    total_new = 0
    had_think = 0
    for r in records:
        old_out = r["output"]
        new_out = strip_think(old_out)
        if "<think>" in old_out:
            had_think += 1
        total_old += len(old_out)
        total_new += len(new_out)
        new_rec = {
            "instruction": r.get("instruction", ""),
            "input": r.get("input", ""),
            "system": rewrite_system(r.get("system", "")),
            "output": new_out,
        }
        out_lines.append(json.dumps(new_rec, ensure_ascii=False))

    DST.write_text("\n".join(out_lines) + "\n")

    # Verify the file we just wrote is valid JSONL.
    verified = 0
    for line in DST.read_text().splitlines():
        if line.strip():
            json.loads(line)
            verified += 1

    n = len(records)
    avg_reduction = (total_old - total_new) / n if n else 0.0
    print(f"records:                {n}")
    print(f"records with <think>:   {had_think}")
    print(f"avg output reduction:   {avg_reduction:.1f} chars  "
          f"({total_old/n:.1f} -> {total_new/n:.1f} avg chars)")
    print(f"total chars removed:    {total_old - total_new}")
    print(f"wrote:                  {DST}")
    print(f"valid JSONL lines:      {verified}/{n}  "
          f"({'OK' if verified == n else 'MISMATCH'})")


if __name__ == "__main__":
    main()
