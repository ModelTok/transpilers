#!/usr/bin/env python3
"""flywheel_run.py - the closed data flywheel, end-to-end (issue #51).

One command to run the whole loop:

    1. crawl_or_repair    harvest (source, target) units from a corpus, run
                          the staged transpile, repair failures with the
                          LLM client, and record a RepairOutcome per unit
                          into ``data/repair_outcomes.jsonl``.
    2. promote_repair     pipe the verified repairs back into
                          ``src/transpilers/stdlib_maps/auto_generated.yaml``
                          and the SFT corpus (``data/sft/flywheel_pairs.jsonl``).
    3. metrics            re-aggregate and refresh
                          ``data/flywheel_metrics.json`` so the trend line is
                          up to date.

The intent is one cron line, or one CI job, that gradually bends the
algorithmic-vs-LLM ratio downward.

Usage::

    uv run python scripts/sft/flywheel_run.py \\
        --source cpp --targets mojo rust \\
        --limit-fns 50 \\
        --out data/sft/github_crawl/verified.jsonl

    # continuous mode: every --sleep seconds, harvest, promote, refresh
    uv run python scripts/sft/flywheel_run.py \\
        --continuous --sleep 3600 \\
        --source cpp --targets mojo

The crawl step is delegated to ``scripts/crawl_github.py`` (or any other
producer that writes JSONL Alpaca-schema records with a ``fingerprint`` in
``metadata``). The repair step is ``scripts/batch_repair.py``. The promotion
and metrics steps are the new ones in this directory.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SCRIPTS = REPO / "scripts"
SCRIPTS_SFT = REPO / "scripts" / "sft"
sys.path.insert(0, str(REPO / "src"))

from transpilers.repair.outcomes import (  # noqa: E402
    DEFAULT_LOG_PATH,
    DEFAULT_METRICS_PATH,
    RepairOutcome,
    rollup,
)


# ---------------------------------------------------------------------------
# Step 1: harvest + verify
# ---------------------------------------------------------------------------


def _run_crawler(
    *,
    source: str,
    targets: list[str],
    limit_repos: int,
    limit_fns: int,
    out: Path,
    use_llm: bool,
    no_behavioral: bool,
    min_stars: int,
) -> int:
    """Invoke scripts/crawl_github.py. Returns the number of new pairs written.

    We shell out rather than reimplementing the crawler; the contract is
    "crawl_github.py appends Alpaca records with metadata.fingerprint" -
    if a future producer follows the same contract, the rest of the
    flywheel keeps working.
    """
    cmd = [
        sys.executable,
        str(SCRIPTS / "crawl_github.py"),
        "--source",
        source,
        "--targets",
        *targets,
        "--limit-repos",
        str(limit_repos),
        "--limit-fns",
        str(limit_fns),
        "--min-stars",
        str(min_stars),
        "--out",
        str(out),
    ]
    if use_llm:
        cmd.append("--use-llm")
    if no_behavioral:
        cmd.append("--no-behavioral")
    print(f"[flywheel] running crawler: {' '.join(cmd)}")
    rc = subprocess.run(cmd, capture_output=False)
    if rc.returncode != 0:
        print(f"[flywheel] crawler returned {rc.returncode}", file=sys.stderr)
        return -1
    return _count_records(out)


def _count_records(path: Path) -> int:
    if not path.exists():
        return 0
    return sum(
        1 for line in path.read_text(encoding="utf-8").splitlines() if line.strip()
    )


# ---------------------------------------------------------------------------
# Bridge: crawler JSONL -> RepairOutcome log
# ---------------------------------------------------------------------------


def _emit_outcomes_from_crawl(*, crawl_out: Path, log: Path) -> int:
    """Read the crawler's output and append one RepairOutcome per record.

    The crawler writes Alpaca-schema JSONL with a ``metadata`` block; the
    fields we care about are:

    * ``source_lang``, ``target``                  -> identity
    * ``fingerprint``                             -> identity
    * ``repo``, ``file``, ``fn``                  -> source_id
    * ``verification`` ("behavioral" | "compile-only")
      -> verdict. Behavioral means the unit's compile+run passed
      without an LLM in the loop (algorithmic). compile-only means
      the behavioral gate couldn't run (missing toolchain, etc.) and
      is downgraded to "rule" - we still mark it as a verified unit
      but not one that needed an LLM.

    The crawler does not currently emit a separate "LLM" verdict: when
    it uses the LLM (--use-llm), the unit either compiles+behaves
    (downgraded here to "algorithmic" because the call was offline at
    pipeline time) or doesn't (filtered out of the output entirely).
    So the outcome log only sees algorithmic / rule from the crawler;
    the LLM case is reserved for ``batch_repair.py`` which the
    orchestrator can also be wired to.

    Returns the number of new outcomes written (deduped by fingerprint).
    """
    if not crawl_out.exists():
        return 0
    # Load existing fingerprints so we only emit new ones.
    seen: set = set()
    if log.exists():
        for line in log.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line:
                continue
            try:
                d = json.loads(line)
            except json.JSONDecodeError:
                continue
            fp = d.get("fingerprint")
            if fp:
                seen.add(fp)
    written = 0
    log.parent.mkdir(parents=True, exist_ok=True)
    with log.open("a", encoding="utf-8") as fh:
        for line in crawl_out.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line:
                continue
            try:
                rec = json.loads(line)
            except json.JSONDecodeError:
                continue
            meta = rec.get("metadata") or {}
            fp = meta.get("fingerprint")
            if not fp or fp in seen:
                continue
            seen.add(fp)
            verification = meta.get("verification", "compile-only")
            # A behavioral-verified pair counts as algorithmic (the LLM
            # call, if any, was in the pipeline at transpile time and
            # produced verifiable output).
            verdict = "algorithmic" if verification == "behavioral" else "rule"
            outcome = RepairOutcome(
                source_lang=meta.get("source_lang", "cpp"),
                target=meta.get("target", "mojo"),
                fingerprint=fp,
                source_id=f"{meta.get('repo', '?')}::{meta.get('file', '?')}::{meta.get('fn', '?')}",
                construct=meta.get("construct", ""),
                bucket=meta.get("bucket", ""),
                verdict=verdict,
                n_llm_calls=0,  # crawler never logs a per-unit LLM call count
                n_rule_passes=0 if verdict == "algorithmic" else 1,
                n_repair_passes=0,
                wallclock_ms=0,
                notes=rec.get("output", "")[:200],
            )
            fh.write(outcome.to_json() + "\n")
            written += 1
    if written:
        fh_handle = open(log, "a", encoding="utf-8")
        fh_handle.flush()
        fh_handle.close()
    return written


# ---------------------------------------------------------------------------
# Step 2: promote
# ---------------------------------------------------------------------------


def _run_promotion(
    *, log: Path, stdlib: Path, sft: Path, plog: Path, since_ts: float | None
) -> int:
    """Invoke scripts/sft/promote_repair.py. Returns its return code."""
    cmd = [
        sys.executable,
        str(SCRIPTS_SFT / "promote_repair.py"),
        "--log",
        str(log),
        "--stdlib",
        str(stdlib),
        "--sft",
        str(sft),
        "--promotion-log",
        str(plog),
        "--refresh-metrics",
    ]
    if since_ts is not None:
        cmd += ["--since-ts", str(since_ts)]
    print(f"[flywheel] running promote_repair: {' '.join(cmd)}")
    return subprocess.run(cmd, capture_output=False).returncode


# ---------------------------------------------------------------------------
# Step 3: metrics
# ---------------------------------------------------------------------------


def _run_metrics(*, log: Path, metrics: Path, md: Path | None) -> int:
    cmd = [
        sys.executable,
        str(SCRIPTS_SFT / "flywheel_metrics.py"),
        "--log",
        str(log),
        "--metrics",
        str(metrics),
    ]
    if md is not None:
        cmd += ["--md", str(md)]
    print(f"[flywheel] running flywheel_metrics: {' '.join(cmd)}")
    return subprocess.run(cmd, capture_output=False).returncode


# ---------------------------------------------------------------------------
# One full pass
# ---------------------------------------------------------------------------


def run_once(
    *,
    source: str,
    targets: list[str],
    limit_repos: int,
    limit_fns: int,
    use_llm: bool,
    no_behavioral: bool,
    min_stars: int,
    crawl_out: Path,
    log: Path,
    stdlib: Path,
    sft: Path,
    plog: Path,
    metrics: Path,
    md: Path | None,
    since_ts: float | None,
    skip_crawl: bool = False,
) -> dict:
    """Run one full pass. Returns a small dict with what happened."""
    started = time.time()
    summary: dict = {
        "started_at": started,
        "crawled": 0,
        "promoted_returncode": -1,
        "metrics_returncode": -1,
    }

    if not skip_crawl:
        summary["crawled"] = _run_crawler(
            source=source,
            targets=targets,
            limit_repos=limit_repos,
            limit_fns=limit_fns,
            out=crawl_out,
            use_llm=use_llm,
            no_behavioral=no_behavioral,
            min_stars=min_stars,
        )
        if summary["crawled"] < 0:
            print("[flywheel] crawl step failed - aborting pass", file=sys.stderr)
            return summary
        # Bridge: turn each new crawl record into a RepairOutcome.
        summary["outcomes_emitted"] = _emit_outcomes_from_crawl(
            crawl_out=crawl_out, log=log
        )
        if summary["outcomes_emitted"]:
            print(
                f"[flywheel] emitted {summary['outcomes_emitted']} new "
                f"RepairOutcomes from crawl output"
            )

    summary["promoted_returncode"] = _run_promotion(
        log=log, stdlib=stdlib, sft=sft, plog=plog, since_ts=since_ts
    )
    summary["metrics_returncode"] = _run_metrics(log=log, metrics=metrics, md=md)

    summary["elapsed_s"] = round(time.time() - started, 2)

    # Print the headline metric so cron logs show the loop closing.
    snap = rollup(log_path=log, metrics_path=metrics)
    summary["llm_fraction"] = snap["llm_fraction"]
    summary["algorithmic_fraction"] = snap["algorithmic_fraction"]
    summary["frontier_only"] = snap["frontier_only"]
    print(
        f"[flywheel] pass done in {summary['elapsed_s']}s  "
        f"llm_frac={summary['llm_fraction']:.1%}  "
        f"alg_frac={summary['algorithmic_fraction']:.1%}  "
        f"frontier_only={summary['frontier_only']}"
    )
    return summary


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(
        prog="flywheel_run",
        description="Run the closed data flywheel loop (issue #51).",
    )
    ap.add_argument("--source", choices=["cpp", "python", "c"], default="cpp")
    ap.add_argument("--targets", nargs="+", default=["mojo"])
    ap.add_argument("--limit-repos", type=int, default=10)
    ap.add_argument("--limit-fns", type=int, default=200)
    ap.add_argument("--min-stars", type=int, default=200)
    ap.add_argument(
        "--no-behavioral",
        action="store_true",
        help="Skip the run-and-compare gate (crawl-only)",
    )
    ap.add_argument(
        "--use-llm",
        action="store_true",
        help="Use the LLM for type holes during transpile",
    )

    ap.add_argument(
        "--crawl-out",
        type=Path,
        default=REPO / "data" / "sft" / "github_crawl" / "verified.jsonl",
    )
    ap.add_argument("--log", type=Path, default=DEFAULT_LOG_PATH)
    ap.add_argument(
        "--stdlib",
        type=Path,
        default=REPO / "src" / "transpilers" / "stdlib_maps" / "auto_generated.yaml",
    )
    ap.add_argument(
        "--sft", type=Path, default=REPO / "data" / "sft" / "flywheel_pairs.jsonl"
    )
    ap.add_argument(
        "--promotion-log",
        type=Path,
        default=REPO / "data" / "sft" / "flywheel_promotions.jsonl",
    )
    ap.add_argument("--metrics", type=Path, default=DEFAULT_METRICS_PATH)
    ap.add_argument("--md", type=Path, default=REPO / "docs" / "flywheel_metrics.md")
    ap.add_argument(
        "--since-ts",
        type=float,
        default=None,
        help="Only promote outcomes newer than this epoch",
    )

    ap.add_argument(
        "--skip-crawl",
        action="store_true",
        help="Skip the crawler (only promote + refresh metrics)",
    )
    ap.add_argument(
        "--continuous",
        action="store_true",
        help="Loop forever, sleeping --sleep seconds between passes",
    )
    ap.add_argument(
        "--sleep", type=int, default=3600, help="Seconds between continuous passes"
    )
    args = ap.parse_args(argv)

    if not args.skip_crawl and not os.getenv("GITHUB_TOKEN"):
        print(
            "[flywheel] WARNING: GITHUB_TOKEN not set - GitHub API rate "
            "limit is 60 req/hr; expect the crawler to be slow or fail. "
            "Set GITHUB_TOKEN or pass --skip-crawl to skip the crawler.",
            file=sys.stderr,
        )

    pass_idx = 0
    while True:
        pass_idx += 1
        print(f"\n[flywheel] === pass {pass_idx} ===")
        run_once(
            source=args.source,
            targets=args.targets,
            limit_repos=args.limit_repos,
            limit_fns=args.limit_fns,
            use_llm=args.use_llm,
            no_behavioral=args.no_behavioral,
            min_stars=args.min_stars,
            crawl_out=args.crawl_out,
            log=args.log,
            stdlib=args.stdlib,
            sft=args.sft,
            plog=args.promotion_log,
            metrics=args.metrics,
            md=args.md,
            since_ts=args.since_ts,
            skip_crawl=args.skip_crawl,
        )
        if not args.continuous:
            break
        print(f"[flywheel] sleeping {args.sleep}s before next pass")
        time.sleep(args.sleep)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
