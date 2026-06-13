#!/usr/bin/env python3
"""promote_repair.py - close the data flywheel (issue #51).

Read every RepairOutcome in ``data/repair_outcomes.jsonl`` and PIPE the
behaviorally-verified ones back into:

* ``src/transpilers/stdlib_maps/auto_generated.yaml``  - new source->target
  mappings harvested from frontier-only repairs (the LLM told us what API
  the missing construct needed).
* ``data/sft/flywheel_pairs.jsonl``                    - Alpaca-schema training
  records; the LLM's output becomes the ``output`` field. Frontier-only
  repairs are weighted higher; they are the rarest, most informative samples.

Priority order (the acceptance criterion "prioritize cases only frontier+repair
could solve"):

    1. frontier-only (verdict=="llm" AND n_rule_passes==0)   <- highest value
    2. llm-with-rule-help  (verdict=="llm" AND n_rule_passes>0)
    3. rule-only           (verdict=="rule")
    4. algorithmic          (verdict=="algorithmic")          <- already cheap
                                                            to retrain on, but
                                                            still recorded for
                                                            the corpus balance.

The script is idempotent: every promoted pair carries the source fingerprint
in its metadata, and previously-promoted fingerprints are skipped on re-runs.
Run it as a cron job, or chain it after ``flywheel_run.py``.

Usage::

    uv run python scripts/sft/promote_repair.py
    uv run python scripts/sft/promote_repair.py --since-ts 1700000000
    uv run python scripts/sft/promote_repair.py --std-only          # only stdlib_maps
    uv run python scripts/sft/promote_repair.py --sft-only          # only the SFT corpus
    uv run python scripts/sft/promote_repair.py --dry-run           # print plan, write nothing
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
from collections import Counter
from pathlib import Path
from typing import Iterable

# Make the package importable when run from anywhere in the repo.
REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "src"))

from transpilers.repair.outcomes import (  # noqa: E402
    DEFAULT_LOG_PATH,
    RepairOutcome,
    RepairTracker,
    rollup,
)

# Default output locations
STDLIB_MAP_PATH = REPO / "src" / "transpilers" / "stdlib_maps" / "auto_generated.yaml"
SFT_OUT_PATH = REPO / "data" / "sft" / "flywheel_pairs.jsonl"
PROMOTION_LOG_PATH = REPO / "data" / "sft" / "flywheel_promotions.jsonl"


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _priority(o: RepairOutcome) -> int:
    """Sort key: frontier-only first, then llm-with-rule, then rule, then alg."""
    if o.is_frontier_only:
        return 0
    if o.verdict == "llm":
        return 1
    if o.verdict == "rule":
        return 2
    if o.verdict == "algorithmic":
        return 3
    return 4


def _section_name(source_lang: str, target: str) -> str:
    """The YAML section name in stdlib_maps/auto_generated.yaml."""
    src = "cpp" if source_lang in ("cpp", "c") else "python"
    return f"{src}_to_{target}"


# ---------------------------------------------------------------------------
# Tiny YAML roundtrip - we only need the shape gen_stdlib_maps.py writes
# ---------------------------------------------------------------------------


def _load_yaml(path: Path) -> dict:
    """Hand-rolled parser matching the format gen_stdlib_maps.py writes.

    The file is small (<200 entries) and shaped like::

        cpp_to_python:
          "std::sort": ["sorted", "list.sort"]
          ...

    PyYAML is not required; this routine handles exactly that shape.
    """
    if not path.exists():
        return {}
    result: dict = {}
    section = ""
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.rstrip()
        if not line or line.lstrip().startswith("#"):
            continue
        m_sec = re.match(r"^([A-Za-z_][A-Za-z0-9_]*):\s*$", line)
        if m_sec:
            section = m_sec.group(1)
            result.setdefault(section, {})
            continue
        m_ent = re.match(r'^\s+"([^"]+)":\s*\[(.*)\]\s*$', line)
        if m_ent and section:
            key = m_ent.group(1)
            values = re.findall(r'"([^"]*)"', m_ent.group(2))
            result[section][key] = values
    return result


def _dump_yaml(path: Path, mapping: dict, *, header: str) -> None:
    """Inverse of :func:`_load_yaml`; writes a stable, sorted file."""
    lines = [header, ""]
    for section in sorted(mapping):
        lines.append(f"{section}:")
        for key in sorted(mapping[section]):
            vals = ", ".join(f'"{v}"' for v in mapping[section][key])
            lines.append(f'  "{key}": [{vals}]')
        lines.append("")
    path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")


# ---------------------------------------------------------------------------
# Idempotency: a small JSONL log of every (fingerprint, target) we have
# already promoted. Re-runs skip these.
# ---------------------------------------------------------------------------


def _load_already_promoted(promotion_log: Path) -> set:
    seen: set = set()
    if not promotion_log.exists():
        return seen
    for line in promotion_log.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            d = json.loads(line)
        except json.JSONDecodeError:
            continue
        fp = d.get("fingerprint")
        tgt = d.get("target")
        if fp and tgt:
            seen.add((fp, tgt))
    return seen


def _record_promotion(
    promotion_log: Path, *, fingerprint: str, target: str, kind: str, payload: dict
) -> None:
    promotion_log.parent.mkdir(parents=True, exist_ok=True)
    rec = {
        "fingerprint": fingerprint,
        "target": target,
        "kind": kind,
        "ts": time.time(),
        **payload,
    }
    with promotion_log.open("a", encoding="utf-8") as fh:
        fh.write(json.dumps(rec, ensure_ascii=False, sort_keys=True) + "\n")


# ---------------------------------------------------------------------------
# 1. stdlib_maps: extract source->target mappings from frontier-only repairs
# ---------------------------------------------------------------------------


def promote_stdlib_maps(
    outcomes: Iterable,
    *,
    stdlib_path: Path = STDLIB_MAP_PATH,
    promotion_log: Path = PROMOTION_LOG_PATH,
    dry_run: bool = False,
) -> dict:
    """Append source->target mappings harvested from *outcomes* into the YAML.

    Only frontier-only (LLM-only) repairs are eligible. A mapping is added
    only if the source key is in the ``construct``/``notes`` fields of the
    outcome (these are filled by the repair loop) and the target side has
    a recognisable replacement token.

    Returns a counter of how many entries were added per (source_lang, target).
    """
    mapping = _load_yaml(stdlib_path)
    added: Counter = Counter()
    seen = _load_already_promoted(promotion_log)

    for o in outcomes:
        if not o.is_frontier_only:
            continue
        src_key = (o.construct or "").strip()
        if not src_key:
            continue
        if not src_key.startswith("std::") and not re.match(r"^[a-zA-Z_]\w*$", src_key):
            continue
        target_token = (o.notes or "").strip()
        if not target_token:
            continue
        if (o.fingerprint, o.target) in seen:
            continue
        section = _section_name(o.source_lang, o.target)
        mapping.setdefault(section, {}).setdefault(src_key, [])
        if target_token not in mapping[section][src_key]:
            if not dry_run:
                mapping[section][src_key].append(target_token)
                _record_promotion(
                    promotion_log,
                    fingerprint=o.fingerprint,
                    target=o.target,
                    kind="stdlib_map",
                    payload={
                        "section": section,
                        "key": src_key,
                        "added_value": target_token,
                    },
                )
            added[(o.source_lang, o.target)] += 1

    if not dry_run and added:
        header = (
            "# auto_generated.yaml - generated by scripts/gen_stdlib_maps.py\n"
            "# + flywheel-pipeline (issue #51). DO NOT EDIT BY HAND.\n"
            "#\n"
            "# 'flywheel' entries below were promoted by\n"
            "# scripts/sft/promote_repair.py from behaviorally-verified\n"
            "# frontier-only repairs (LLM was the only thing that made the\n"
            "# unit pass). Run `python scripts/sft/promote_repair.py` to\n"
            "# refresh; ``data/flywheel_metrics.json`` tracks the ratio.\n"
        )
        _dump_yaml(stdlib_path, mapping, header=header)

    return dict(added)


# ---------------------------------------------------------------------------
# 2. SFT corpus: write Alpaca-schema training records for every passing
#    repair (priority-weighted: frontier > llm > rule > algorithmic).
# ---------------------------------------------------------------------------


def _build_sft_record(
    o: RepairOutcome, *, source_code: str, target_code: str, weight: int
) -> dict:
    """Format one RepairOutcome as an Alpaca training record.

    ``weight`` is the LLaMA-Factory mix weight - higher for rarer /
    more-informative cases. Frontier-only gets weight 4 (vs the typical
    weight 1-2 for normal SFT pairs).
    """
    lang_name = {"cpp": "C++", "python": "Python", "c": "C"}.get(
        o.source_lang, o.source_lang
    )
    target_name = o.target.capitalize()
    metadata = {
        "source_lang": o.source_lang,
        "target": o.target,
        "fingerprint": o.fingerprint,
        "verdict": o.verdict,
        "n_llm_calls": o.n_llm_calls,
        "n_rule_passes": o.n_rule_passes,
        "frontier_only": o.is_frontier_only,
        "weight": weight,
        "source_id": o.source_id,
        "bucket": o.bucket,
        "construct": o.construct,
        "ts": o.ts,
    }
    return {
        "instruction": (
            f"Transpile the provided {lang_name} implementation into a "
            f"functionally equivalent implementation in {target_name}.\n\n"
            f"```{o.source_lang}\n{source_code.strip()}\n```"
        ),
        "input": "",
        "output": target_code.strip(),
        "metadata": metadata,
    }


def promote_sft_corpus(
    outcomes: Iterable,
    *,
    sft_path: Path = SFT_OUT_PATH,
    promotion_log: Path = PROMOTION_LOG_PATH,
    source_lookup: dict | None = None,
    target_lookup: dict | None = None,
    dry_run: bool = False,
) -> dict:
    """Append SFT training records for every *passing* outcome.

    Because the persistent log stores fingerprints but not source/target
    bodies, this routine accepts two optional lookup dicts:

    * ``source_lookup[fingerprint] -> source code``
    * ``target_lookup[(fingerprint, target)] -> verified target code``

    The crawler and batch_repair scripts can populate these before calling.
    When a lookup is missing the record is silently skipped (better than
    writing an empty example into the SFT corpus).
    """
    if source_lookup is None:
        source_lookup = {}
    if target_lookup is None:
        target_lookup = {}

    sft_path.parent.mkdir(parents=True, exist_ok=True)
    added: Counter = Counter()
    seen = _load_already_promoted(promotion_log)
    new_records: list = []

    for o in sorted(outcomes, key=_priority):
        if not o.is_pass:
            continue
        if (o.fingerprint, o.target) in seen:
            continue
        src = source_lookup.get(o.fingerprint)
        tgt = target_lookup.get((o.fingerprint, o.target))
        if not src or not tgt:
            continue
        weight = 1
        if o.is_frontier_only:
            weight = 4
        elif o.verdict == "llm":
            weight = 3
        elif o.verdict == "rule":
            weight = 2
        rec = _build_sft_record(o, source_code=src, target_code=tgt, weight=weight)
        new_records.append(rec)
        added[o.verdict] += 1
        if not dry_run:
            _record_promotion(
                promotion_log,
                fingerprint=o.fingerprint,
                target=o.target,
                kind="sft_record",
                payload={"verdict": o.verdict, "weight": weight},
            )

    if not dry_run and new_records:
        with sft_path.open("a", encoding="utf-8") as fh:
            for r in new_records:
                fh.write(json.dumps(r, ensure_ascii=False, sort_keys=True) + "\n")

    return dict(added)


# ---------------------------------------------------------------------------
# Main / CLI
# ---------------------------------------------------------------------------


def _load_outcomes(log_path, since_ts):
    """Read every outcome from the log; optionally filter by ``since_ts``."""
    with RepairTracker(log_path=log_path, create_dirs=False) as t:
        out = list(t.iter_log())
    if since_ts is None:
        return out
    return [o for o in out if o.ts >= since_ts]


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(
        prog="promote_repair",
        description="Pipe verified repairs into stdlib_maps/ and the SFT corpus (issue #51).",
    )
    ap.add_argument(
        "--log", type=Path, default=DEFAULT_LOG_PATH, help="Repair outcomes log (JSONL)"
    )
    ap.add_argument(
        "--since-ts",
        type=float,
        default=None,
        help="Only promote outcomes with ts >= this epoch",
    )
    ap.add_argument(
        "--stdlib",
        type=Path,
        default=STDLIB_MAP_PATH,
        help="Target stdlib_maps YAML to update",
    )
    ap.add_argument(
        "--sft",
        type=Path,
        default=SFT_OUT_PATH,
        help="Target SFT pairs JSONL to update",
    )
    ap.add_argument(
        "--promotion-log",
        type=Path,
        default=PROMOTION_LOG_PATH,
        help="Idempotency log (skip already-promoted fingerprints)",
    )
    ap.add_argument(
        "--std-only",
        action="store_true",
        help="Only run the stdlib_maps promotion step",
    )
    ap.add_argument(
        "--sft-only", action="store_true", help="Only run the SFT corpus promotion step"
    )
    ap.add_argument(
        "--dry-run", action="store_true", help="Print what would happen, write nothing"
    )
    ap.add_argument(
        "--refresh-metrics",
        action="store_true",
        help="Also call rollup() at the end to refresh the metrics file",
    )
    args = ap.parse_args(argv)

    # Per-run path overrides
    stdlib_path = args.stdlib
    sft_path = args.sft
    promotion_log = args.promotion_log

    outcomes = _load_outcomes(args.log, args.since_ts)
    if not outcomes:
        print(f"[promote_repair] no outcomes in {args.log}", file=sys.stderr)
        return 0

    n_pass = sum(1 for o in outcomes if o.is_pass)
    n_frontier = sum(1 for o in outcomes if o.is_frontier_only)
    print(
        f"[promote_repair] {len(outcomes)} outcomes: "
        f"{n_pass} pass, {n_frontier} frontier-only"
    )

    std_added = {}
    if not args.sft_only:
        std_added = promote_stdlib_maps(
            outcomes,
            stdlib_path=stdlib_path,
            promotion_log=promotion_log,
            dry_run=args.dry_run,
        )
        if std_added:
            print(
                f"[promote_repair] stdlib_maps: added {sum(std_added.values())} entries"
            )
            for (src, tgt), n in std_added.items():
                print(f"   {src} -> {tgt}: +{n}")
        else:
            print(
                "[promote_repair] stdlib_maps: no new frontier-only entries to promote"
            )

    sft_added = {}
    if not args.std_only:
        sft_added = promote_sft_corpus(
            outcomes,
            sft_path=sft_path,
            promotion_log=promotion_log,
            dry_run=args.dry_run,
        )
        if sft_added:
            print(f"[promote_repair] SFT corpus: added {sum(sft_added.values())} pairs")
            for verdict, n in sft_added.items():
                print(f"   verdict={verdict}: +{n}")
        else:
            print(
                "[promote_repair] SFT corpus: nothing to add (no lookups or all seen)"
            )

    if args.refresh_metrics and not args.dry_run:
        snap = rollup()
        print(
            f"[promote_repair] metrics: {snap['passed']} passed, "
            f"{snap['llm_fraction']:.1%} LLM, "
            f"{snap['frontier_only']} frontier-only in queue"
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
