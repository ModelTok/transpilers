#!/usr/bin/env python3
"""Benchmark one-shot transpile vs the escalating-repair loop on a corpus.

Issue #47 acceptance: measurable pass-rate lift on examples/samples/ vs
the one-shot baseline, plus a record of which cases needed frontier-tier
help (the data flywheel's input - see #51).

Usage:
    uv run python scripts/escalating_repair_bench.py examples/samples \\
        --targets rust --output data/escalating_repair_flywheel.jsonl
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

# Path munging so we can import the engine without an editable install.
_SRC = Path(__file__).resolve().parent.parent / "src"
if str(_SRC) not in sys.path:
    sys.path.insert(0, str(_SRC))

from transpilers.llm import TieredLlmClient  # noqa: E402
from transpilers.repair import Flywheel, escalating_repair  # noqa: E402
from transpilers.verify.taxonomy import classify_unit  # noqa: E402


EXT_MAP = {
    "c": "c", "cpp": "cpp", "cs": "csharp", "f90": "fortran",
    "go": "go", "java": "java", "js": "javascript", "py": "python",
    "ts": "typescript", "vb": "vb",
}


def _gather_files(root: Path) -> list[Path]:
    return sorted(
        f for f in root.rglob("*")
        if f.is_file() and EXT_MAP.get(f.suffix.lstrip("."))
    )


def _run_one_shot(text: str, source_lang: str, target: str) -> bool:
    """Run the staged classify_unit driver in no-compile mode.

    Wrapped in a broad try/except — ``classify_unit`` should already catch
    in-pipeline failures and bucket them, but the initial-translate step
    can also raise a pipeline-internal exception we don't want to crash
    the whole benchmark on.
    """
    try:
        rec = classify_unit(
            text, source_lang=source_lang, target=target, compile=False
        )
        return rec.bucket == "ok"
    except Exception:
        return False


def _run_escalating(
    text: str,
    source_lang: str,
    target: str,
    *,
    flywheel: Flywheel | None,
) -> tuple[bool, str | None, int]:
    """Run the escalating-repair loop. Returns (passed, fixing_tier, attempts)."""
    client = TieredLlmClient(
        tiers={},  # CACHED only -> trivial-loop fallback
    )
    try:
        res = escalating_repair(
            text,
            source_lang=source_lang,
            target=target,
            tiered_client=client,
            flywheel=flywheel,
            max_attempts=3,
        )
    except Exception:
        # The benchmark should report a fail, not crash the run. The
        # issue's "refuse-don't-guess" invariant means the loop itself
        # should never raise on bad input; the try/except is a safety
        # net for the benchmark, not the loop.
        return (False, None, 0)
    return (
        res.passed,
        res.fixing_tier.value if res.fixing_tier else None,
        res.attempts,
    )


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("root", type=Path, nargs="?", default=Path("examples/samples"))
    ap.add_argument(
        "--targets",
        default="rust",
        help="comma-separated target languages (default: rust)",
    )
    ap.add_argument(
        "--output",
        type=Path,
        default=Path("data/escalating_repair_flywheel.jsonl"),
        help="flywheel JSONL output path",
    )
    ap.add_argument(
        "--no-flywheel",
        action="store_true",
        help="don't record to the flywheel log",
    )
    ap.add_argument(
        "--limit", type=int, help="process at most N files (smoke runs)"
    )
    args = ap.parse_args(argv)

    targets = [t.strip() for t in args.targets.split(",") if t.strip()]
    files = _gather_files(args.root)
    if args.limit:
        files = files[: args.limit]
    if not files:
        print(f"no supported source files under {args.root}", file=sys.stderr)
        return 1

    flywheel: Flywheel | None = None
    if not args.no_flywheel:
        flywheel = Flywheel(path=args.output)

    print(
        f"Benchmark: one-shot vs escalating-repair on {args.root} "
        f"(targets={targets}, files={len(files)})"
    )
    print()

    rows: dict[tuple[str, str], dict[str, int]] = {}
    flywheel_count = 0
    total_one_shot = 0
    total_escalating = 0
    total = 0
    frontier_fixes = 0

    for f in files:
        source_lang = EXT_MAP[f.suffix.lstrip(".")]
        try:
            text = f.read_text(encoding="utf-8", errors="replace")
        except OSError as exc:
            print(f"  skip {f}: {exc}", file=sys.stderr)
            continue

        for target in targets:
            total += 1
            one_shot_ok = _run_one_shot(text, source_lang, target)
            if one_shot_ok:
                total_one_shot += 1

            passed, fixing_tier, _attempts = _run_escalating(
                text, source_lang, target, flywheel=flywheel
            )
            if passed:
                total_escalating += 1
            if fixing_tier == "frontier":
                frontier_fixes += 1
            flywheel_count = (
                flywheel.count if flywheel is not None else 0
            )

            key = (source_lang, target)
            row = rows.setdefault(
                key, {"total": 0, "one_shot_ok": 0, "escalating_ok": 0}
            )
            row["total"] += 1
            if one_shot_ok:
                row["one_shot_ok"] += 1
            if passed:
                row["escalating_ok"] += 1

    print("| source | target | total | one-shot ok | escalating ok | lift |")
    print("|---|---|---|---|---|---|")
    for (src, tgt), r in sorted(rows.items()):
        lift = r["escalating_ok"] - r["one_shot_ok"]
        print(
            f"| {src} | {tgt} | {r['total']} | {r['one_shot_ok']} | "
            f"{r['escalating_ok']} | {lift:+d} |"
        )

    print()
    print(
        f"Total: {total_one_shot}/{total} one-shot ok; "
        f"{total_escalating}/{total} escalating ok; "
        f"flywheel records: {flywheel_count}; "
        f"frontier fixes: {frontier_fixes}"
    )
    if flywheel is not None and flywheel_count:
        print(f"Flywheel log: {args.output}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
