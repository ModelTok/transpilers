#!/usr/bin/env python3
"""dashboard.py — Rich-based terminal dashboard for LLM telemetry and migration status.

Reads from a results/ directory (default: results/ relative to this script's
parent directory) for translation run JSONs produced by run_eval.py.

Panels
------
  Migration Status    — file/task, source_lang, target_lang, status, tier
  LLM Telemetry       — model, total_calls, total_tokens_in, total_tokens_out,
                        total_cost_usd, avg_latency_ms
  Pass@1 by Tier      — ASCII bar chart
  Recent Errors       — last few failed tasks

Usage
-----
    python scripts/dashboard.py
    python scripts/dashboard.py --results-dir /path/to/results
    python scripts/dashboard.py --watch           # refresh every 5 s
    python scripts/dashboard.py --watch --interval 10  # refresh every 10 s

Falls back gracefully if Rich is not installed (plain text output).
"""

from __future__ import annotations

import argparse
import json
import sys
import time
from datetime import datetime
from pathlib import Path

# ---------------------------------------------------------------------------
# Rich import with graceful fallback
# ---------------------------------------------------------------------------

try:
    from rich.console import Console
    from rich.layout import Layout
    from rich.live import Live
    from rich.panel import Panel
    from rich.table import Table
    from rich.text import Text
    from rich import box as rich_box

    RICH_AVAILABLE = True
except ImportError:
    RICH_AVAILABLE = False

# Root of transpilation-bench (one level up from scripts/)
_BENCH_ROOT = Path(__file__).resolve().parent.parent
_DEFAULT_RESULTS_DIR = _BENCH_ROOT / "results"

# Approximate cost per 1 k tokens (rough defaults; override via env vars if needed).
_COST_PER_1K_IN: dict[str, float] = {
    "gpt-4o":                       0.005,
    "gpt-4o-mini":                  0.00015,
    "claude-3-5-sonnet-20241022":   0.003,
    "claude-opus-4-7":              0.015,
}
_DEFAULT_COST_PER_1K_IN  = 0.003   # fallback
_DEFAULT_COST_PER_1K_OUT = 0.015   # fallback (output is ~5× input for Anthropic)


# ---------------------------------------------------------------------------
# Data loading
# ---------------------------------------------------------------------------

def _load_results(results_dir: Path) -> list[dict]:
    """Load all *_*.json result files from *results_dir* (excluding leaderboard)."""
    jsons: list[dict] = []
    for f in sorted(results_dir.glob("*.json")):
        if f.name == "leaderboard.json":
            continue
        try:
            with open(f, encoding="utf-8-sig") as fh:
                data = json.load(fh)
            data["_source_file"] = f.name
            jsons.append(data)
        except (json.JSONDecodeError, OSError):
            pass
    return jsons


def _compute_telemetry(runs: list[dict]) -> list[dict]:
    """Aggregate per-model telemetry across all runs."""
    model_stats: dict[str, dict] = {}

    for run in runs:
        model = run.get("model", "unknown")
        if model not in model_stats:
            model_stats[model] = {
                "model": model,
                "total_calls": 0,
                "total_tokens_in": 0,
                "total_tokens_out": 0,
                "total_cost_usd": 0.0,
                "total_latency_s": 0.0,
                "latency_count": 0,
            }
        s = model_stats[model]

        for task in run.get("tasks", []):
            meta = task.get("meta", {})
            calls = meta.get("calls", 1)
            latency = meta.get("latency_s", 0.0)
            s["total_calls"] += calls
            s["total_latency_s"] += latency
            if latency > 0:
                s["latency_count"] += 1

            # Rough token estimate from meta (run_eval.py doesn't log tokens directly).
            # Use cpp_source length as a proxy: chars/4 ≈ tokens.
            tokens_in = meta.get("tokens_in", 0)
            tokens_out = meta.get("tokens_out", 0)
            s["total_tokens_in"] += tokens_in
            s["total_tokens_out"] += tokens_out

            # Cost estimate.
            cost_per_k = _COST_PER_1K_IN.get(model, _DEFAULT_COST_PER_1K_IN)
            s["total_cost_usd"] += (tokens_in / 1000) * cost_per_k
            s["total_cost_usd"] += (tokens_out / 1000) * _DEFAULT_COST_PER_1K_OUT

    result = []
    for s in model_stats.values():
        avg_ms = (
            (s["total_latency_s"] / s["latency_count"] * 1000)
            if s["latency_count"] > 0
            else 0.0
        )
        result.append({
            "model": s["model"],
            "total_calls": s["total_calls"],
            "total_tokens_in": s["total_tokens_in"],
            "total_tokens_out": s["total_tokens_out"],
            "total_cost_usd": round(s["total_cost_usd"], 4),
            "avg_latency_ms": round(avg_ms, 1),
        })

    return result


def _migration_rows(runs: list[dict]) -> list[dict]:
    """Flatten all tasks into migration-status rows."""
    rows: list[dict] = []
    for run in runs:
        model = run.get("model", "unknown")
        path = run.get("path", "direct")
        target = run.get("target", "mojo")

        for task in run.get("tasks", []):
            passed = task.get("pass_at_1", False)
            error = task.get("error")
            if error:
                status = "failed"
            elif passed:
                status = "verified"
            else:
                status = "translated"

            rows.append({
                "file": f"{task.get('id', '?')}_{task.get('name', '?')}",
                "source_lang": "cpp",
                "target_lang": target,
                "status": status,
                "tier": task.get("tier", "?"),
                "model": model,
                "path": path,
                "error": task.get("error", ""),
            })
    return rows


def _tier_pass_rates(runs: list[dict]) -> dict[int, tuple[int, int]]:
    """Return {tier: (passed, total)} across all runs."""
    stats: dict[int, list[int]] = {}  # tier -> [passed, total]
    for run in runs:
        for task in run.get("tasks", []):
            t = task.get("tier", 0)
            if t not in stats:
                stats[t] = [0, 0]
            stats[t][1] += 1
            if task.get("pass_at_1"):
                stats[t][0] += 1
    return {t: (v[0], v[1]) for t, v in sorted(stats.items())}


def _recent_errors(runs: list[dict], limit: int = 10) -> list[dict]:
    """Return the most recent failed tasks with error info."""
    errors: list[dict] = []
    for run in runs:
        for task in run.get("tasks", []):
            if task.get("error") or not task.get("pass_at_1", True):
                errors.append({
                    "id": task.get("id", "?"),
                    "name": task.get("name", "?"),
                    "error": task.get("error", "test failure"),
                    "model": run.get("model", "?"),
                })
    return errors[-limit:]


# ---------------------------------------------------------------------------
# ASCII bar chart (no Rich required)
# ---------------------------------------------------------------------------

def _ascii_bar(value: float, width: int = 20) -> str:
    """Return an ASCII progress bar for *value* in [0, 1]."""
    filled = int(round(value * width))
    return "[" + "#" * filled + "." * (width - filled) + "]"


# ---------------------------------------------------------------------------
# Plain-text fallback renderer
# ---------------------------------------------------------------------------

def _render_plain(runs: list[dict], results_dir: Path) -> None:
    if not runs:
        print("\n  No results yet — run run_eval.py to generate data.\n")
        print(f"  Looking in: {results_dir}\n")
        return

    migration = _migration_rows(runs)
    telemetry = _compute_telemetry(runs)
    tier_rates = _tier_pass_rates(runs)
    errors = _recent_errors(runs)

    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"\n{'='*70}")
    print(f"  Transpilation-Bench Dashboard  |  {now}")
    print(f"{'='*70}\n")

    # Migration Status
    print("=== Migration Status ===")
    print(f"{'file':<35} {'src':<6} {'tgt':<6} {'status':<12} {'tier':<5}")
    print("-" * 70)
    for r in migration[-20:]:  # show last 20
        print(
            f"{r['file']:<35} {r['source_lang']:<6} {r['target_lang']:<6} "
            f"{r['status']:<12} {r['tier']:<5}"
        )
    if len(migration) > 20:
        print(f"  ... and {len(migration) - 20} more")
    print()

    # LLM Telemetry
    print("=== LLM Telemetry ===")
    print(f"{'model':<40} {'calls':>6} {'tok_in':>8} {'tok_out':>8} {'cost':>9} {'avg_ms':>8}")
    print("-" * 85)
    for t in telemetry:
        print(
            f"{t['model']:<40} {t['total_calls']:>6} "
            f"{t['total_tokens_in']:>8} {t['total_tokens_out']:>8} "
            f"${t['total_cost_usd']:>8.4f} {t['avg_latency_ms']:>7.1f}"
        )
    print()

    # Pass@1 by Tier
    print("=== Pass@1 by Tier ===")
    for tier, (passed, total) in tier_rates.items():
        rate = passed / total if total else 0.0
        bar = _ascii_bar(rate, width=30)
        print(f"  Tier {tier}: {bar} {rate:.1%}  ({passed}/{total})")
    print()

    # Recent Errors
    if errors:
        print("=== Recent Errors ===")
        for e in errors[-5:]:
            print(f"  [{e['id']}] {e['name']}  ({e['model']})")
            print(f"    {e['error'][:80]}")
        print()


# ---------------------------------------------------------------------------
# Rich renderer
# ---------------------------------------------------------------------------

def _make_migration_table(migration: list[dict]) -> "Table":
    table = Table(
        title="Migration Status",
        box=rich_box.SIMPLE_HEAVY,
        show_lines=False,
        expand=True,
    )
    table.add_column("File / Task", style="cyan", no_wrap=True)
    table.add_column("Src", justify="center")
    table.add_column("Tgt", justify="center")
    table.add_column("Status", justify="center")
    table.add_column("Tier", justify="center")

    status_colors = {
        "pending":    "yellow",
        "translated": "blue",
        "verified":   "green",
        "failed":     "red",
    }

    for row in migration[-25:]:
        color = status_colors.get(row["status"], "white")
        table.add_row(
            row["file"],
            row["source_lang"],
            row["target_lang"],
            Text(row["status"], style=color),
            str(row["tier"]),
        )
    return table


def _make_telemetry_table(telemetry: list[dict]) -> "Table":
    table = Table(
        title="LLM Telemetry",
        box=rich_box.SIMPLE_HEAVY,
        show_lines=False,
        expand=True,
    )
    table.add_column("Model", style="magenta")
    table.add_column("Calls", justify="right")
    table.add_column("Tok In", justify="right")
    table.add_column("Tok Out", justify="right")
    table.add_column("Cost USD", justify="right")
    table.add_column("Avg ms", justify="right")

    for t in telemetry:
        table.add_row(
            t["model"],
            str(t["total_calls"]),
            str(t["total_tokens_in"]),
            str(t["total_tokens_out"]),
            f"${t['total_cost_usd']:.4f}",
            f"{t['avg_latency_ms']:.1f}",
        )
    return table


def _make_tier_chart(tier_rates: dict) -> "Panel":
    lines: list[str] = []
    for tier, (passed, total) in tier_rates.items():
        rate = passed / total if total else 0.0
        bar = _ascii_bar(rate, width=30)
        lines.append(f"Tier {tier}: {bar} {rate:.1%}  ({passed}/{total})")

    if not lines:
        lines = ["No tier data available."]

    return Panel(
        "\n".join(lines),
        title="Pass@1 by Tier",
        border_style="blue",
        expand=True,
    )


def _make_errors_panel(errors: list[dict]) -> "Panel":
    if not errors:
        text = "No recent errors."
    else:
        parts = []
        for e in errors[-6:]:
            parts.append(f"[bold red][{e['id']}][/bold red] {e['name']}  ({e['model']})")
            parts.append(f"  [dim]{e['error'][:90]}[/dim]")
        text = "\n".join(parts)

    return Panel(
        text,
        title="Recent Errors",
        border_style="red",
        expand=True,
    )


def _render_rich(runs: list[dict], results_dir: Path, console: "Console") -> None:
    if not runs:
        console.print(
            Panel(
                f"[yellow]No results yet — run run_eval.py to generate data.[/yellow]\n\n"
                f"Looking in: [cyan]{results_dir}[/cyan]",
                title="Transpilation-Bench Dashboard",
                border_style="yellow",
            )
        )
        return

    migration = _migration_rows(runs)
    telemetry = _compute_telemetry(runs)
    tier_rates = _tier_pass_rates(runs)
    errors = _recent_errors(runs)

    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    console.rule(f"[bold]Transpilation-Bench Dashboard[/bold]  |  {now}")
    console.print()
    console.print(_make_migration_table(migration))
    console.print()
    console.print(_make_telemetry_table(telemetry))
    console.print()
    console.print(_make_tier_chart(tier_rates))
    console.print()
    console.print(_make_errors_panel(errors))
    console.print()


# ---------------------------------------------------------------------------
# Watch mode
# ---------------------------------------------------------------------------

def _watch_rich(results_dir: Path, interval: int) -> None:
    console = Console()
    try:
        with Live(console=console, refresh_per_second=1, screen=True) as live:
            while True:
                from io import StringIO
                buf = Console(file=StringIO(), force_terminal=True, width=console.width)
                runs = _load_results(results_dir)
                _render_rich(runs, results_dir, buf)
                live.update(buf.file.getvalue())  # type: ignore[arg-type]
                time.sleep(interval)
    except KeyboardInterrupt:
        pass


def _watch_plain(results_dir: Path, interval: int) -> None:
    try:
        while True:
            runs = _load_results(results_dir)
            _render_plain(runs, results_dir)
            print(f"\n  [Refreshing every {interval}s — Ctrl+C to quit]\n")
            time.sleep(interval)
    except KeyboardInterrupt:
        pass


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="dashboard",
        description="Rich terminal dashboard for LLM telemetry and migration status (Issue #29).",
    )
    parser.add_argument(
        "--results-dir",
        type=Path,
        default=_DEFAULT_RESULTS_DIR,
        help=f"Directory containing run_eval.py output JSONs (default: {_DEFAULT_RESULTS_DIR}).",
    )
    parser.add_argument(
        "--watch",
        action="store_true",
        help="Refresh the dashboard every --interval seconds.",
    )
    parser.add_argument(
        "--interval",
        type=int,
        default=5,
        help="Refresh interval in seconds when --watch is set (default: 5).",
    )
    args = parser.parse_args(argv)

    results_dir: Path = args.results_dir

    if args.watch:
        if RICH_AVAILABLE:
            _watch_rich(results_dir, args.interval)
        else:
            _watch_plain(results_dir, args.interval)
        return 0

    # Single render.
    runs = _load_results(results_dir)

    if RICH_AVAILABLE:
        console = Console()
        _render_rich(runs, results_dir, console)
    else:
        print("Note: Rich not installed (pip install rich). Using plain text output.", file=sys.stderr)
        _render_plain(runs, results_dir)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
