#!/usr/bin/env python3
"""Mix the four SFT sources into one balanced training set.

Weighting rationale (the A/B eval showed doc-prose is the weakest grounding and
faithful translation pairs the most goal-aligned):
  * cpp_mojo  (40)  — faithful C++→Mojo, the exact downstream task. UPWEIGHT ×3.
  * cpp_python(39)  — C-understanding half (verified). UPWEIGHT ×2.
  * mojo_corpus(425)— teaches Mojo surface form (spec→Mojo). ×1.
  * skill     (52)  — curated syntax corrections. ×2.
  * docs      (880) — concept explanations; weakest signal. CAP to keep it from
                      dominating; ×1.

Outputs data/sft/mojo_mix_sft.json (LLaMA-Factory alpaca) + a composition
manifest. Weights are CLI-adjustable.
"""
from __future__ import annotations

import argparse, json, random
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SFT = REPO / "data/sft"


def load_jsonl(p):
    return [json.loads(l) for l in p.read_text().splitlines() if l.strip()]


def cpp_mojo_rows():
    rows = []
    for p in load_jsonl(REPO / "data/cpp_mojo_pairs.jsonl"):
        rows.append({"instruction": "Translate the following EnergyPlus C++ function "
                     "to idiomatic Mojo. Preserve the numerical behavior exactly.",
                     "input": p["cpp_source"].strip(), "output": p["mojo_source"].strip(),
                     "source": "cpp_mojo"})
    return rows


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--w-cpp-mojo", type=int, default=3)
    ap.add_argument("--w-cpp-python", type=int, default=2)
    ap.add_argument("--w-mojo-corpus", type=int, default=1)
    ap.add_argument("--w-skill", type=int, default=2)
    ap.add_argument("--w-docs", type=int, default=1)
    ap.add_argument("--cap-docs", type=int, default=450)
    ap.add_argument("--seed", type=int, default=13)
    ap.add_argument("--out", type=Path, default=SFT / "mojo_mix_sft.json")
    args = ap.parse_args()
    rnd = random.Random(args.seed)

    cpp_mojo = cpp_mojo_rows()
    cpp_python = load_jsonl(SFT / "cpp_python_pairs.jsonl")
    mojo_corpus = load_jsonl(SFT / "mojo_corpus.jsonl")
    docs_instr = load_jsonl(SFT / "docs_instruction.jsonl")
    skill = [r for r in docs_instr if r["source"] == "skill"]
    docs = [r for r in docs_instr if r["source"] == "docs"]
    rnd.shuffle(docs)
    docs = docs[: args.cap_docs]

    def norm(r):
        return {"instruction": r["instruction"], "input": r.get("input", ""),
                "output": r["output"], "source": r["source"]}

    pool = []
    plan = [(cpp_mojo, args.w_cpp_mojo), (cpp_python, args.w_cpp_python),
            (mojo_corpus, args.w_mojo_corpus), (skill, args.w_skill), (docs, args.w_docs)]
    comp = {}
    for rows, w in plan:
        for _ in range(w):
            pool.extend(norm(r) for r in rows)
        if rows:
            comp[rows[0]["source"]] = {"unique": len(rows), "weight": w, "contributed": len(rows) * w}
    rnd.shuffle(pool)

    args.out.write_text(json.dumps([{k: r[k] for k in ("instruction", "input", "output")} for r in pool],
                                   indent=1, ensure_ascii=False))
    manifest = {"total": len(pool), "composition": comp,
                "note": "LLaMA-Factory alpaca format; register as in RUNBOOK."}
    (args.out.parent / "mix_manifest.json").write_text(json.dumps(manifest, indent=2))
    print(f"mixed SFT: {len(pool)} examples -> {args.out}")
    for s, c in comp.items():
        print(f"  {s:14s} unique={c['unique']:4d} ×{c['weight']} = {c['contributed']}")


if __name__ == "__main__":
    main()
