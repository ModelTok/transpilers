#!/usr/bin/env python3
"""flywheel_metrics.py - print the algorithmic-vs-LLM ratio + trend (issue #51).

Reads the persistent repair-outcomes log, computes the flywheel's north-star
metric (``llm_fraction`` = share of *passing* units that needed an LLM) and
emits:

* A short text report (default, prints to stdout).
* A markdown rollup (with ``--md out.md``) - the README badge source.
* A JSON snapshot refreshed in-place (default, written to
  ``data/flywheel_metrics.json``).

Trend bins are 50-outcome windows; on a healthy loop the LLM fraction should
decrease monotonically as frontier repairs get promoted into algorithmic
emitters.

Usage::

    uv run python scripts/sft/flywheel_metrics.py              # text
    uv run python scripts/sft/flywheel_metrics.py --md out.md  # + markdown
    uv run python scripts/sft/flywheel_metrics.py --json out.json
    uv run python scripts/sft/flywheel_metrics.py --trend-only
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

# Make the package importable when run from anywhere in the repo.
REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "src"))

from transpilers.repair.outcomes import (  # noqa: E402
    DEFAULT_LOG_PATH,
    DEFAULT_METRICS_PATH,
    rollup,
)


def _fmt_pct(x: float) -> str:
    return f"{100.0 * x:5.1f}%"


def render_text(snap: dict) -> str:
    """A short human-readable report of the flywheel state."""
    lines: list[str] = []
    lines.append("=" * 64)
    lines.append("  Data Flywheel - algorithmic-vs-LLM ratio (issue #51)")
    lines.append("=" * 64)
    lines.append("")
    lines.append(f"  Total outcomes       : {snap['total']}")
    lines.append(f"  Passed               : {snap['passed']}")
    if snap["total"] == 0:
        lines.append("")
        lines.append("  (no outcomes yet - run scripts/batch_repair.py or")
        lines.append("   scripts/crawl_github.py to start populating the log)")
        lines.append("")
        return "\n".join(lines)

    lines.append("")
    lines.append("  By verdict:")
    for verdict, n in sorted(snap["by_verdict"].items(), key=lambda kv: -kv[1]):
        lines.append(f"    {verdict:<16} {n:>6}")
    lines.append("")
    lines.append("  Headline metrics (over passing units):")
    lines.append(f"    algorithmic_fraction   {_fmt_pct(snap['algorithmic_fraction'])}")
    lines.append(f"    llm_fraction           {_fmt_pct(snap['llm_fraction'])}")
    lines.append(f"    frontier_only (queue)  {snap['frontier_only']:>6}")
    lines.append(f"    n_llm_calls (lifetime) {snap['n_llm_calls']:>6}")
    lines.append("")

    by_src = snap["by_source_lang"]
    if by_src:
        lines.append("  By source language:")
        for src, counts in sorted(by_src.items()):
            total = sum(counts.values())
            passed = sum(counts.get(v, 0) for v in ("algorithmic", "rule", "llm"))
            llm = counts.get("llm", 0)
            frac = (llm / passed) if passed else 0.0
            lines.append(
                f"    {src:<12} total={total:>5}  pass={passed:>5}  "
                f"llm_frac={_fmt_pct(frac)}"
            )
        lines.append("")

    by_tgt = snap["by_target"]
    if by_tgt:
        lines.append("  By target language:")
        for tgt, counts in sorted(by_tgt.items()):
            total = sum(counts.values())
            passed = sum(counts.get(v, 0) for v in ("algorithmic", "rule", "llm"))
            llm = counts.get("llm", 0)
            frac = (llm / passed) if passed else 0.0
            lines.append(
                f"    {tgt:<12} total={total:>5}  pass={passed:>5}  "
                f"llm_frac={_fmt_pct(frac)}"
            )
        lines.append("")

    trend = snap["trend"]
    if trend:
        lines.append(f"  LLM fraction over time ({len(trend)} bins, 50 outcomes/bin):")
        width = 40
        for i, b in enumerate(trend):
            bar = "#" * int(round(b["llm_fraction"] * width))
            lines.append(
                f"    bin {i + 1:>3} "
                f"({b['total']:>3} units, {b['passed']:>3} pass): "
                f"{_fmt_pct(b['llm_fraction'])} {bar}"
            )
        lines.append("")
        # North-star signal
        if len(trend) >= 2:
            first = trend[0]["llm_fraction"]
            last = trend[-1]["llm_fraction"]
            delta = last - first
            arrow = "v" if delta < 0 else "^" if delta > 0 else "="
            lines.append(
                f"  Trend: bin1 {arrow} bin{len(trend)}  "
                f"({_fmt_pct(first)} -> {_fmt_pct(last)}, "
                f"delta={_fmt_pct(delta)})"
            )
            if delta < 0:
                lines.append(
                    "    [good] LLM dependence is falling - promotions are working."
                )
            elif delta > 0:
                lines.append(
                    "    [warn] LLM dependence is RISING. "
                    "Promote more frontier repairs into stdlib_maps/."
                )
            else:
                lines.append("    [flat] Trend is flat - no change in LLM dependence.")
            lines.append("")

    return "\n".join(lines)


def render_markdown(snap: dict) -> str:
    """Markdown rollup, suitable for the README badge."""
    lines: list[str] = []
    lines.append("# Data Flywheel metrics (issue #51)")
    lines.append("")
    if snap["total"] == 0:
        lines.append("_No repair outcomes recorded yet._")
        return "\n".join(lines)
    lines.append(f"- **Total outcomes**: {snap['total']}")
    lines.append(
        f"- **Passed**: {snap['passed']} "
        f"({_fmt_pct(snap['passed'] / snap['total'])} of total)"
    )
    lines.append(f"- **Algorithmic + rule**: {_fmt_pct(snap['algorithmic_fraction'])}")
    lines.append(
        f"- **LLM-needed**: {_fmt_pct(snap['llm_fraction'])} "
        f"<- *the metric the loop is trying to lower*"
    )
    lines.append(f"- **Frontier-only in queue**: {snap['frontier_only']}")
    lines.append(f"- **Total LLM calls**: {snap['n_llm_calls']}")
    lines.append("")

    by_tgt = snap["by_target"]
    if by_tgt:
        lines.append("## By target")
        lines.append("")
        lines.append("| target | pass | llm_fraction | frontier_only |")
        lines.append("|---|---|---|---|")
        for tgt, counts in sorted(by_tgt.items()):
            passed = sum(counts.get(v, 0) for v in ("algorithmic", "rule", "llm"))
            llm = counts.get("llm", 0)
            frac = (llm / passed) if passed else 0.0
            fo = counts.get("llm", 0)  # frontier count is a subset of LLM here
            lines.append(f"| {tgt} | {passed} | {_fmt_pct(frac)} | {fo} |")
        lines.append("")

    trend = snap["trend"]
    if len(trend) >= 2:
        first = trend[0]["llm_fraction"]
        last = trend[-1]["llm_fraction"]
        delta = last - first
        verdict = "improving" if delta < 0 else "worsening" if delta > 0 else "flat"
        lines.append(
            f"## Trend: {verdict} (bin1 {first:.1%} -> bin{len(trend)} {last:.1%})"
        )
        lines.append("")
        lines.append("```")
        for i, b in enumerate(trend):
            bar = "#" * int(round(b["llm_fraction"] * 40))
            lines.append(f"bin {i + 1:>3}: {b['llm_fraction']:5.1%} {bar}")
        lines.append("```")
    return "\n".join(lines)


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(
        prog="flywheel_metrics",
        description="Print the algorithmic-vs-LLM ratio + trend (issue #51).",
    )
    ap.add_argument(
        "--log", type=Path, default=DEFAULT_LOG_PATH, help="Repair outcomes log (JSONL)"
    )
    ap.add_argument(
        "--metrics",
        type=Path,
        default=DEFAULT_METRICS_PATH,
        help="Where to write the JSON snapshot",
    )
    ap.add_argument(
        "--md",
        type=Path,
        default=None,
        help="Also write a markdown rollup to this file",
    )
    ap.add_argument(
        "--json",
        type=Path,
        default=None,
        help="Write the JSON snapshot here (overrides --metrics)",
    )
    ap.add_argument(
        "--trend-only",
        action="store_true",
        help="Print only the trend table, not the full report",
    )
    ap.add_argument(
        "--quiet",
        action="store_true",
        help="Don't print the text report (useful for cron jobs)",
    )
    args = ap.parse_args(argv)

    # Always refresh the JSON snapshot so downstream tools see the latest.
    snap = rollup(log_path=args.log, metrics_path=args.metrics)
    if args.json is not None:
        args.json.write_text(
            json.dumps(snap, indent=2, sort_keys=True), encoding="utf-8"
        )

    if args.md is not None:
        args.md.write_text(render_markdown(snap) + "\n", encoding="utf-8")

    if args.quiet:
        return 0

    if args.trend_only:
        # Tiny trend-only view
        trend = snap["trend"]
        if not trend:
            print("(no trend bins yet)")
        for i, b in enumerate(trend):
            print(
                f"bin {i + 1:>3}: llm_frac={b['llm_fraction']:6.1%}  "
                f"total={b['total']:>3}  passed={b['passed']:>3}"
            )
    else:
        print(render_text(snap))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
