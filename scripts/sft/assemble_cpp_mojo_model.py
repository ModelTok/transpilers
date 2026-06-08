#!/usr/bin/env python3
"""Assemble the dedicated C++->Mojo model package (first in the 1:1 translator library).

Per the per-model architecture, this model owns exactly ONE direction: C++->Mojo.
No Python, no other targets (those are separate models). Mojo-language data IS in
scope — Mojo is this model's target and the base has ~0% Mojo competency.

Produces data/sft/cpp_mojo/:
  train_translation.jsonl  — 41 C++->Mojo pairs, CodePivot schema, rich <think>
  mojo_acquisition.jsonl   — Mojo-target corpus + docs + skill (teach the language)
  heldout_eval.jsonl       — 14 C++->Mojo verl eval records (regenerated test cases)
  system.txt, sft.yaml, README.md
"""
from __future__ import annotations

import importlib.util, json, sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SFT = REPO / "data/sft/cpp_mojo"
sys.path.insert(0, str(REPO / "src"))
_s = importlib.util.spec_from_file_location("split", REPO / "scripts/sft/build_codepivot_split.py")
split = importlib.util.module_from_spec(_s); sys.modules["split"] = split; _s.loader.exec_module(split)
tcs = sys.modules["tcs"]


def load_reasoning():
    rmap = json.load(open(SFT / "reason_map.json"))
    for f in (SFT / "_reason_out").glob("batch_*.jsonl"):
        for l in f.read_text().splitlines():
            if l.strip():
                r = json.loads(l); rmap[r["fn"]] = r["reasoning"].strip()
    return rmap


def main():
    sysp = tcs.system_prompt()
    (SFT / "system.txt").write_text(sysp)
    reason = load_reasoning()
    train = json.load(open(SFT / "_train_pairs.json"))
    held = json.load(open(SFT / "_held_pairs.json"))

    # --- translation SFT (CodePivot schema, rich reasoning) ---
    rows = []
    missing = 0
    for p in train:
        rz = reason.get(p["fn"])
        if not rz:
            missing += 1
            rz = tcs.reasoning(p["cpp"], p["mojo"], "Mojo")
        instr = ("Transpile the provided C++ implementation into a functionally equivalent "
                 f"implementation in Mojo.\n\n```cpp\n{p['cpp'].strip()}\n```")
        out = f"<think>\n{rz}\n</think>\n<answer>\n```mojo\n{p['mojo'].strip()}\n```\n</answer>"
        rows.append({"instruction": instr, "input": "", "system": sysp, "output": out})
    (SFT / "train_translation.jsonl").write_text("\n".join(json.dumps(r, ensure_ascii=False) for r in rows))

    # --- held-out verl eval (regenerate test cases) ---
    heldrecs = []
    for idx, p in enumerate(held):
        pair = {"cpp_source": p["cpp"], "function_name": p["fn"], "source_file": p["src"],
                "arg_types": p["arg_types"], "ret_type": p["ret"]}
        rec = split.verl_record(pair, "Mojo", "mojo", sysp, idx)
        if rec:
            heldrecs.append(rec)
    (SFT / "heldout_eval.jsonl").write_text("\n".join(json.dumps(r, ensure_ascii=False) for r in heldrecs))

    # --- Mojo-acquisition data (target language; Mojo only), quality-filtered ---
    # Drop junk (<40ch), cap length (giant doc sections blow cutoff_len), dedup,
    # and DOWNSAMPLE the non-idiomatic FFI/address-passing kernels (keep 1 in 4)
    # so the model isn't biased toward emitting int64-address kernels.
    acq, seen, ffi_i = [], set(), 0
    for src in ("mojo_corpus.jsonl", "docs_instruction.jsonl"):
        for l in (REPO / "data/sft" / src).read_text().splitlines():
            if not l.strip():
                continue
            r = json.loads(l)
            out = r["output"].strip()
            if len(out) < 40:
                continue                                  # junk
            out = out[:2500]                              # cap runaway doc sections
            is_ffi = "unsafe_from_address" in out or "ptr: Int" in out
            if is_ffi:
                ffi_i += 1
                if ffi_i % 4 != 0:                        # keep ~1 in 4 FFI kernels
                    continue
            key = out[:200]
            if key in seen:
                continue                                  # near-dup
            seen.add(key)
            acq.append({"instruction": r["instruction"], "input": r.get("input", ""), "output": out})
    (SFT / "mojo_acquisition.json").write_text(json.dumps(acq, indent=1, ensure_ascii=False))

    print(f"C++→Mojo MODEL assembled in {SFT}/")
    print(f"  train_translation.jsonl : {len(rows)} pairs ({len(rows)-missing} rich reasoning, {missing} fallback)")
    print(f"  heldout_eval.jsonl      : {len(heldrecs)}/{len(held)} verl records")
    print(f"  mojo_acquisition.json   : {len(acq)} Mojo-target examples")


if __name__ == "__main__":
    main()
