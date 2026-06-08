"""Evaluate AI tools and models on the C++ to Python/Mojo benchmarks.

This script provides a framework for running structured evaluations of
different AI tools (GitHub Copilot, Cursor, Claude API, GPT-4o, etc.)
against the transpilation-bench benchmark suite.

Usage:
    # Run evaluation with a specific model (requires API keys)
    python metrics/tool_eval.py --model claude-sonnet-4-6 --path direct

    # Compare multiple saved result files
    python metrics/tool_eval.py --compare results/claude_direct_*.json results/gpt4o_direct_*.json

    # Show leaderboard
    python metrics/tool_eval.py --leaderboard

    # Dry run (no API calls — just show what would be tested)
    python metrics/tool_eval.py --model any-model --dry-run

Tool comparison matrix:
    Model/Tool             | C++→Python | C++→Mojo | Cost/task | Notes
    ----------------------|-----------|---------|---------|----
    claude-sonnet-4-6      | High       | High    | ~$0.01  | Best Mojo
    gpt-4o                 | High       | High    | ~$0.015 | Reliable
    gemini-1.5-pro         | Medium     | Medium  | ~$0.008 | Good value
    local:qwen2.5-coder-7b | Medium     | Low     | ~$0.001 | RunPod
    local:codellama-34b    | Medium     | Low     | ~$0.002 | Local GPU
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

RESULTS_DIR = Path(__file__).parent.parent / "results"
TASKS_DIR = Path(__file__).parent.parent / "benchmarks" / "tasks"


# ---------------------------------------------------------------------------
# Result loading and comparison
# ---------------------------------------------------------------------------

def load_result(path: Path) -> dict:
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def compare_results(result_paths: list[Path]) -> None:
    """Print a side-by-side comparison of multiple evaluation runs."""
    results = [load_result(p) for p in result_paths]

    print(f"\n{'='*80}")
    print(f"  Tool Comparison — {len(results)} runs")
    print(f"{'='*80}")

    # Header
    header = f"  {'Task':<30}"
    for r in results:
        label = f"{r['model']}/{r['path']}"[:12]
        header += f" {label:>12}"
    print(header)
    print(f"  {'-'*30}" + " " + "  ".join(["-"*12]*len(results)))

    # Per-task rows
    # Build task index from first result
    task_ids = [t["id"] for t in results[0]["tasks"]]
    task_map = {t["id"]: t for t in results[0]["tasks"]}

    for tid in task_ids:
        name = task_map[tid]["name"][:26]
        row = f"  {tid} {name:<26}"
        for r in results:
            t_map = {t["id"]: t for t in r["tasks"]}
            t = t_map.get(tid)
            if t is None:
                row += f" {'N/A':>12}"
            elif t["pass_at_1"]:
                row += f" {'✓':>12}"
            else:
                row += f" {'✗':>12}"
        print(row)

    # Summary row
    print(f"\n  {'PASS@1':<30}", end="")
    for r in results:
        m = r.get("metrics", {})
        rate = m.get("pass_at_1", 0)
        print(f" {rate:>11.1%}", end="")
    print()

    print(f"  {'Tier 1':<30}", end="")
    for r in results:
        rate = r.get("metrics", {}).get("tier_breakdown", {}).get("1", 0)
        print(f" {rate:>11.1%}", end="")
    print()

    print(f"  {'Tier 2':<30}", end="")
    for r in results:
        rate = r.get("metrics", {}).get("tier_breakdown", {}).get("2", 0)
        print(f" {rate:>11.1%}", end="")
    print()

    print(f"  {'Tier 3':<30}", end="")
    for r in results:
        rate = r.get("metrics", {}).get("tier_breakdown", {}).get("3", 0)
        print(f" {rate:>11.1%}", end="")
    print()

    print(f"  {'Tier 4':<30}", end="")
    for r in results:
        rate = r.get("metrics", {}).get("tier_breakdown", {}).get("4", 0)
        print(f" {rate:>11.1%}", end="")
    print()


def show_leaderboard() -> None:
    """Display the aggregated leaderboard from results/leaderboard.json."""
    lb_path = RESULTS_DIR / "leaderboard.json"
    if not lb_path.exists():
        print("No leaderboard found. Run run_eval.py to generate results.")
        return

    with open(lb_path, encoding="utf-8") as f:
        leaderboard = json.load(f)

    print(f"\n{'='*80}")
    print(f"  Transpilation Benchmark Leaderboard")
    print(f"  {len(leaderboard)} evaluation runs")
    print(f"{'='*80}")
    print(f"  {'Rank':<5} {'Model':<35} {'Path':<15} {'pass@1':>7} {'T1':>5} {'T2':>5} {'T3':>5} {'T4':>5} {'Date':<12}")
    print(f"  {'-'*5} {'-'*35} {'-'*15} {'-'*7} {'-'*5} {'-'*5} {'-'*5} {'-'*5} {'-'*12}")

    for i, entry in enumerate(leaderboard[:20], 1):
        tb = entry.get("tier_breakdown", {})
        print(f"  {i:<5} {entry['model']:<35} {entry['path']:<15} "
              f"{entry.get('pass_at_1',0):>7.1%} "
              f"{tb.get('1',0):>5.1%} {tb.get('2',0):>5.1%} "
              f"{tb.get('3',0):>5.1%} {tb.get('4',0):>5.1%} "
              f"{entry.get('date','?'):<12}")


def analyze_failures(result_path: Path) -> None:
    """Print a failure analysis for a single result file."""
    data = load_result(result_path)
    model = data["model"]
    path = data["path"]
    tasks = data["tasks"]

    failures = [t for t in tasks if not t["pass_at_1"]]
    print(f"\n  Failure analysis: {model}/{path}")
    print(f"  {len(failures)}/{len(tasks)} tasks failed\n")

    # Group by tier
    by_tier: dict[int, list] = {}
    for t in failures:
        tier = t["tier"]
        by_tier.setdefault(tier, []).append(t)

    for tier in sorted(by_tier):
        print(f"  Tier {tier} failures:")
        for t in by_tier[tier]:
            print(f"    {t['id']} {t['name']} ({t['concept']})")
            if t.get("error"):
                print(f"      error: {t['error'][:80]}")
            else:
                # Find first failed test
                for tr in t.get("tests", []):
                    if not tr["passed"]:
                        print(f"      args={tr['args']} expected={tr['expected']!r} got={tr['actual']!r}")
                        break


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main():
    import argparse

    parser = argparse.ArgumentParser(description="AI tool evaluator for transpilation-bench")
    parser.add_argument("--model", help="Model to evaluate (delegates to run_eval.py)")
    parser.add_argument("--path", default="direct",
                        choices=["direct", "python_pivot", "ir_pivot"],
                        help="Translation path")
    parser.add_argument("--compare", nargs="+", metavar="RESULT_JSON",
                        help="Compare multiple result JSON files")
    parser.add_argument("--leaderboard", action="store_true",
                        help="Show leaderboard")
    parser.add_argument("--analyze", metavar="RESULT_JSON",
                        help="Analyze failures in a result file")
    parser.add_argument("--dry-run", action="store_true",
                        help="Print info without running evaluation")
    args = parser.parse_args()

    if args.leaderboard:
        show_leaderboard()
        return

    if args.compare:
        paths = [Path(p) for p in args.compare]
        missing = [p for p in paths if not p.exists()]
        if missing:
            print(f"Files not found: {missing}")
            sys.exit(1)
        compare_results(paths)
        return

    if args.analyze:
        p = Path(args.analyze)
        if not p.exists():
            print(f"File not found: {p}")
            sys.exit(1)
        analyze_failures(p)
        return

    if args.model:
        if args.dry_run:
            print(f"Would evaluate: model={args.model} path={args.path}")
            print(f"Tasks: {len(list(TASKS_DIR.glob('*.json')))}")
            print("Run: python run_eval.py --model <model> --path <path>")
            return
        # Delegate to run_eval.py
        import subprocess
        cmd = [sys.executable, str(Path(__file__).parent.parent / "run_eval.py"),
               "--model", args.model, "--path", args.path]
        subprocess.run(cmd)
        return

    parser.print_help()


if __name__ == "__main__":
    main()
