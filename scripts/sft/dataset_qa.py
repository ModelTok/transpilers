#!/usr/bin/env python3
"""Quality-assurance audit for the cpp->mojo SFT dataset.

Audits:
  data/sft/cpp_mojo/train_translation.jsonl   (CodePivot SFT, train)
  data/sft/cpp_mojo/heldout_eval.jsonl        (held-out functional eval)
  data/sft/cpp_mojo/mojo_acquisition.json     (mojo-capability acquisition set)

Reports:
  * record counts
  * exact-duplicate and near-duplicate outputs
  * train/heldout leakage (cpp function defined in train also a heldout eval fn)
  * output length distribution (min/median/max, count over the 1280 cutoff)
  * acquisition set: how many examples are non-idiomatic FFI

Lightweight: no GPU, no tokenizer. Token estimates use chars/4.
"""
from __future__ import annotations

import json
import re
import statistics
from collections import defaultdict
from difflib import SequenceMatcher
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "data" / "sft" / "cpp_mojo"
TRAIN = DATA / "train_translation.jsonl"
HELDOUT = DATA / "heldout_eval.jsonl"
ACQ = DATA / "mojo_acquisition.json"

# 1280 is `max_length` in train_05b.py / smoke_train.py: a TOKEN cutoff applied
# by SFTTrainer over the full formatted sequence. We audit char length of the
# `output` field and flag using a chars/4 token estimate against that cutoff.
TOKEN_CUTOFF = 1280
CHARS_PER_TOKEN = 4.0

# difflib similarity threshold for "near duplicate" (after whitespace normalize).
NEAR_DUP_RATIO = 0.90

# Markers of non-idiomatic FFI in the acquisition outputs.
FFI_MARKERS = ("unsafe_from_address", "ptr: Int")

CPP_FENCE_RE = re.compile(r"```cpp\s*\n(.*?)```", re.DOTALL)
# function name = identifier immediately before the first '(' in the cpp body.
FUNC_NAME_RE = re.compile(r"([A-Za-z_]\w*)\s*\(")


def load_jsonl(path: Path) -> list[dict]:
    return [json.loads(l) for l in path.read_text().splitlines() if l.strip()]


def norm_ws(s: str) -> str:
    return " ".join(s.split())


def extract_cpp_func_name(text: str) -> str | None:
    """Return the C++ function name from a ```cpp fenced block, or None."""
    m = CPP_FENCE_RE.search(text)
    if not m:
        return None
    body = m.group(1)
    # The first identifier directly preceding '(' is the function name; this
    # naturally skips multi-word/pointer return types (Real64, bool, int const).
    fm = FUNC_NAME_RE.search(body)
    return fm.group(1) if fm else None


def find_near_dups(outputs: list[str], bucket: bool = False
                   ) -> list[tuple[int, int, float]]:
    """Near-duplicate pairs by difflib ratio >= NEAR_DUP_RATIO on normalized text.

    For small sets (e.g. the 54-record train set) all O(n^2) pairs are compared
    so the result is exhaustive. For large sets (the 1163-record acquisition set)
    pass bucket=True: only pairs whose normalized lengths are within ~15% are
    compared (length-bucket + ratio prefilter) to keep it lightweight.
    """
    normed = [norm_ws(o) for o in outputs]
    n = len(normed)

    if bucket:
        buckets: dict[int, list[int]] = defaultdict(list)
        for i, s in enumerate(normed):
            buckets[len(s) // 100].append(i)
        cand_pairs = []
        seen: set[tuple[int, int]] = set()
        for b, idxs in buckets.items():
            group = idxs + buckets.get(b + 1, [])
            for ai in range(len(group)):
                for bi in range(ai + 1, len(group)):
                    key = (min(group[ai], group[bi]), max(group[ai], group[bi]))
                    if key not in seen:
                        seen.add(key)
                        cand_pairs.append(key)
    else:
        cand_pairs = [(i, j) for i in range(n) for j in range(i + 1, n)]

    pairs: list[tuple[int, int, float]] = []
    for i, j in cand_pairs:
        a, c = normed[i], normed[j]
        if a == c:
            continue  # exact dup, reported separately
        lo, hi = sorted((len(a), len(c)))
        if hi == 0 or lo / hi < 0.80:
            continue  # too different in length to reach the ratio threshold
        ratio = SequenceMatcher(None, a, c).ratio()
        if ratio >= NEAR_DUP_RATIO:
            pairs.append((i, j, ratio))
    return sorted(pairs, key=lambda p: -p[2])


def dist(vals: list[int]) -> dict:
    vals_sorted = sorted(vals)
    return {
        "min": vals_sorted[0],
        "median": int(statistics.median(vals_sorted)),
        "max": vals_sorted[-1],
        "mean": int(statistics.mean(vals_sorted)),
    }


def hr(title: str) -> None:
    print("\n" + "=" * 70)
    print(title)
    print("=" * 70)


def main() -> None:
    train = load_jsonl(TRAIN)
    heldout = load_jsonl(HELDOUT)
    acq = json.loads(ACQ.read_text())

    print("#" * 70)
    print("# cpp->mojo SFT DATASET QA REPORT")
    print("#" * 70)

    # ---- record counts ------------------------------------------------------
    hr("RECORD COUNTS")
    print(f"train_translation.jsonl : {len(train)}")
    print(f"heldout_eval.jsonl      : {len(heldout)}")
    print(f"mojo_acquisition.json   : {len(acq)}")

    # ---- exact & near duplicate outputs (train) -----------------------------
    hr("DUPLICATE OUTPUTS (train_translation.jsonl)")
    train_outputs = [r["output"] for r in train]
    exact: dict[str, list[int]] = defaultdict(list)
    for i, o in enumerate(train_outputs):
        exact[o].append(i)
    exact_groups = {k: v for k, v in exact.items() if len(v) > 1}
    n_exact_dup_records = sum(len(v) - 1 for v in exact_groups.values())
    print(f"exact-duplicate output groups : {len(exact_groups)}  "
          f"(redundant records: {n_exact_dup_records})")
    for v in list(exact_groups.values())[:5]:
        names = [extract_cpp_func_name(train[i]["instruction"]) for i in v]
        print(f"   rows {v} -> {names}")

    near = find_near_dups(train_outputs)
    print(f"near-duplicate pairs (norm-ws difflib ratio >= {NEAR_DUP_RATIO}): "
          f"{len(near)}")
    for i, j, ratio in near[:8]:
        ni = extract_cpp_func_name(train[i]["instruction"])
        nj = extract_cpp_func_name(train[j]["instruction"])
        print(f"   {ratio:.3f}  row {i}({ni})  ~  row {j}({nj})")

    # ---- train/heldout leakage ---------------------------------------------
    hr("TRAIN / HELDOUT LEAKAGE")
    train_funcs: dict[str, list[int]] = defaultdict(list)
    for i, r in enumerate(train):
        name = extract_cpp_func_name(r.get("instruction", ""))
        if name:
            train_funcs[name].append(i)
    heldout_funcs = {}
    for i, r in enumerate(heldout):
        name = (r.get("extra_info") or {}).get("function_name")
        if name:
            heldout_funcs[name] = i
        else:
            # fallback: pull from the cpp fence in the user prompt
            for m in r.get("prompt", []):
                if m.get("role") == "user":
                    fn = extract_cpp_func_name(m.get("content", ""))
                    if fn:
                        heldout_funcs[fn] = i

    leaked = sorted(set(train_funcs) & set(heldout_funcs))
    print(f"train cpp functions     : {len(train_funcs)}")
    print(f"heldout eval functions  : {len(heldout_funcs)}")
    print(f"LEAKED (in both)        : {len(leaked)}")
    for name in leaked:
        print(f"   !! {name}  (train rows {train_funcs[name]}, "
              f"heldout row {heldout_funcs[name]})")
    if not leaked:
        print("   clean: no train cpp function appears in the heldout eval set.")

    # ---- output length distribution + truncation risk (train) ---------------
    hr("OUTPUT LENGTH DISTRIBUTION + TRUNCATION RISK (train)")
    lens = [len(o) for o in train_outputs]
    d = dist(lens)
    print(f"output chars  min/median/mean/max : "
          f"{d['min']} / {d['median']} / {d['mean']} / {d['max']}")

    # The 1280 cutoff is `max_length` in train_05b.py / smoke_train.py: a TOKEN
    # cap SFTTrainer applies to the FULL formatted sequence
    # (system + instruction + input + output). Right-truncation (tokenizer
    # default) drops the END of the sequence -> the mojo answer. So a record
    # over the cutoff is trained on a TRUNCATED answer = corrupted labels.
    def seq_chars(r: dict) -> int:
        return (len(r.get("system", "")) + len(r.get("instruction", ""))
                + len(r.get("input", "")) + len(r.get("output", "")))

    seq_tok_est = [seq_chars(r) / CHARS_PER_TOKEN for r in train]
    sd = dist([int(t) for t in seq_tok_est])
    over = [i for i, t in enumerate(seq_tok_est) if t > TOKEN_CUTOFF]
    print(f"full-seq est. tokens (chars/4)    : "
          f"min {sd['min']} / median {sd['median']} / max {sd['max']}")
    print(f"1280 = max_length TOKEN cap (train_05b.py) over the FULL sequence "
          f"(system+instruction+input+output).")
    print(f"records est. OVER {TOKEN_CUTOFF} tokens (answer tail truncated "
          f"under right-truncation): {len(over)} / {len(train)}")
    if over:
        print(f"   -> these records likely train on a truncated mojo answer "
              f"(corrupted labels).")
    print(f"   (system field is constant ~{len(train[0].get('system','')):d} "
          f"chars ~{int(len(train[0].get('system',''))/CHARS_PER_TOKEN)} tok, "
          f"present in every sequence.)")
    longest = max(range(len(lens)), key=lambda i: lens[i])
    print(f"   longest output: row {longest} "
          f"({extract_cpp_func_name(train[longest]['instruction'])}) "
          f"= {lens[longest]} chars (~{int(lens[longest]/CHARS_PER_TOKEN)} tok)")

    # ---- acquisition set: non-idiomatic FFI ---------------------------------
    hr("ACQUISITION SET FFI AUDIT (mojo_acquisition.json)")
    acq_outputs = [r.get("output", "") for r in acq]
    ffi = [i for i, o in enumerate(acq_outputs)
           if any(m in o for m in FFI_MARKERS)]
    by_marker = {m: sum(1 for o in acq_outputs if m in o) for m in FFI_MARKERS}
    acq_lens = [len(o) for o in acq_outputs]
    da = dist(acq_lens)
    print(f"acquisition records       : {len(acq)}")
    print(f"output chars min/med/max  : {da['min']} / {da['median']} / {da['max']}")
    print(f"non-idiomatic FFI examples: {len(ffi)}  "
          f"({100*len(ffi)/len(acq):.1f}%)")
    for m, c in by_marker.items():
        print(f"   contains {m!r:24}: {c}")

    # acquisition exact + near dups (near-dup surfaces templated/batch-kernel
    # redundancy that exact-match misses; bucketed for the 1163-record set).
    acq_exact: dict[str, int] = defaultdict(int)
    for o in acq_outputs:
        acq_exact[o] += 1
    acq_dup = sum(v - 1 for v in acq_exact.values() if v > 1)
    print(f"acquisition exact-dup outputs (redundant records): {acq_dup}")
    acq_near = find_near_dups(acq_outputs, bucket=True)
    print(f"acquisition near-dup pairs (ratio >= {NEAR_DUP_RATIO}): {len(acq_near)}")
    if acq_near:
        involved = sorted({i for p in acq_near for i in p[:2]})
        print(f"   records involved in >=1 near-dup pair: {len(involved)}")
        for i, j, ratio in acq_near[:5]:
            print(f"   {ratio:.3f}  acq[{i}]  ~  acq[{j}]")

    hr("END OF REPORT")


if __name__ == "__main__":
    main()
