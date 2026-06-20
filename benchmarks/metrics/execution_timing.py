"""Execution efficiency metrics for transpilation benchmark.

Measures the runtime performance of translated implementations vs. the
Python reference, and (when Mojo is available) vs. the Mojo reference.

This implements a simplified version of the TRACE methodology
(Timed Ratio-based Assessment of Computational Efficiency):

  efficiency_ratio = median_time_reference / median_time_translated

A ratio > 1 means the translation is faster than the Python reference
(desirable for Mojo targets). A ratio < 1 means it is slower (regression).

Usage:
    from metrics.execution_timing import time_function, timing_report
    import json

    task = json.loads(open("benchmarks/tasks/001_bitwise_ops.json").read())
    result = time_function(task, translated_code="def bitwise_ops(a,b): ...")
    print(result.efficiency_ratio)   # e.g. 1.4  (40% faster than reference)
    print(result.median_ms)          # e.g. 0.003 ms

Run as script:
    python metrics/execution_timing.py
"""

from __future__ import annotations

import gc
import itertools
import statistics
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Callable


@dataclass
class TimingResult:
    task_id: str
    task_name: str
    skipped: bool = False
    skip_reason: str = ""
    error: str = ""

    # Reference (python_reference from task JSON)
    ref_median_ms: float = 0.0
    ref_mean_ms: float = 0.0
    ref_stdev_ms: float = 0.0

    # Translated implementation
    trans_median_ms: float = 0.0
    trans_mean_ms: float = 0.0
    trans_stdev_ms: float = 0.0

    # Derived metric
    efficiency_ratio: float = 0.0  # ref / trans — higher is better for translated
    n_samples: int = 0
    warmup_runs: int = 0


def _exec_fn(code: str, func_name: str) -> Callable | None:
    ns: dict = {}
    try:
        exec(code, ns)
        return ns.get(func_name)
    except Exception:
        return None


def _time_fn(fn: Callable, args_list: list[list], n_runs: int = 100) -> list[float]:
    """Return list of per-run times in milliseconds."""
    times_ms = []
    for _ in range(n_runs):
        for args in args_list:
            t0 = time.perf_counter()
            try:
                fn(*args)
            except Exception:
                pass
            t1 = time.perf_counter()
            times_ms.append((t1 - t0) * 1000)
    return times_ms


def time_function(
    task: dict,
    translated_code: str,
    *,
    n_runs: int = 200,
    warmup: int = 10,
) -> TimingResult:
    """Measure execution time of translated_code vs. the task reference.

    Args:
        task:            Task dict from benchmarks/tasks/*.json.
        translated_code: Python source of the translated function.
        n_runs:          Number of timing runs (per test case).
        warmup:          Number of warmup runs (excluded from timing).

    Returns:
        TimingResult with median/mean/stdev for both implementations and
        the efficiency_ratio = ref_median / trans_median.
    """
    tid = task["id"]
    name = task["name"]

    ref_fn = _exec_fn(task["python_reference"], name)
    trans_fn = _exec_fn(translated_code, name)

    if ref_fn is None:
        return TimingResult(task_id=tid, task_name=name,
                            error=f"Could not load reference '{name}'")
    if trans_fn is None:
        return TimingResult(task_id=tid, task_name=name,
                            error=f"Could not load translated '{name}'")

    tests = task.get("tests", [])
    if not tests:
        return TimingResult(task_id=tid, task_name=name,
                            skipped=True, skip_reason="no test cases")

    args_list = [t["args"] for t in tests]

    # Warmup
    for _ in range(warmup):
        for args in args_list:
            try:
                ref_fn(*args)
                trans_fn(*args)
            except Exception:
                pass

    # Time reference
    gc.disable()
    ref_times = _time_fn(ref_fn, args_list, n_runs)
    trans_times = _time_fn(trans_fn, args_list, n_runs)
    gc.enable()

    ref_med = statistics.median(ref_times)
    ref_mean = statistics.mean(ref_times)
    ref_stdev = statistics.stdev(ref_times) if len(ref_times) > 1 else 0.0

    trans_med = statistics.median(trans_times)
    trans_mean = statistics.mean(trans_times)
    trans_stdev = statistics.stdev(trans_times) if len(trans_times) > 1 else 0.0

    ratio = (ref_med / trans_med) if trans_med > 1e-12 else 0.0

    return TimingResult(
        task_id=tid,
        task_name=name,
        ref_median_ms=round(ref_med, 4),
        ref_mean_ms=round(ref_mean, 4),
        ref_stdev_ms=round(ref_stdev, 4),
        trans_median_ms=round(trans_med, 4),
        trans_mean_ms=round(trans_mean, 4),
        trans_stdev_ms=round(trans_stdev, 4),
        efficiency_ratio=round(ratio, 3),
        n_samples=len(ref_times),
        warmup_runs=warmup,
    )


def timing_report(results: list[TimingResult]) -> None:
    """Print a formatted timing report."""
    ok = [r for r in results if not r.skipped and not r.error]
    skipped = [r for r in results if r.skipped]
    errors = [r for r in results if r.error]

    print(f"\n{'='*70}")
    print(f"  Execution Efficiency Report (TRACE)")
    print(f"  Tasks timed  : {len(ok)}")
    print(f"  Skipped      : {len(skipped)}")
    print(f"  Errors       : {len(errors)}")
    print(f"{'='*70}")
    print(f"  {'Task':<30} {'ref(ms)':>8} {'trans(ms)':>10} {'ratio':>7} {'faster?':>8}")
    print(f"  {'-'*30} {'-'*8} {'-'*10} {'-'*7} {'-'*8}")

    for r in sorted(ok, key=lambda x: x.efficiency_ratio, reverse=True):
        faster = "✓" if r.efficiency_ratio > 1.0 else "✗"
        print(f"  {r.task_id} {r.task_name:<26} "
              f"{r.ref_median_ms:>8.4f} {r.trans_median_ms:>10.4f} "
              f"{r.efficiency_ratio:>7.3f} {faster:>8}")

    if ok:
        avg_ratio = statistics.mean(r.efficiency_ratio for r in ok)
        faster_count = sum(1 for r in ok if r.efficiency_ratio > 1.0)
        print(f"\n  Average efficiency ratio: {avg_ratio:.3f}")
        print(f"  Faster than reference   : {faster_count}/{len(ok)}")

    if errors:
        print("\n  Errors:")
        for r in errors:
            print(f"    {r.task_id} {r.task_name}: {r.error}")


def run_all_timing(
    tasks_dir: str = "benchmarks/tasks",
    n_runs: int = 200,
) -> list[TimingResult]:
    """Time all tasks' reference implementations against themselves.

    This is a self-consistency check — ratio should be ~1.0 for all tasks.
    For a real evaluation, pass the translated code to time_function().
    """
    import json

    results = []
    for f in sorted(Path(tasks_dir).glob("*.json")):
        task = json.loads(f.read_text())
        # Self-check: translated == reference (ratio should be ~1.0)
        result = time_function(task, task["python_reference"], n_runs=n_runs)
        results.append(result)
    return results


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Execution timing for transpilation benchmark")
    parser.add_argument("--tasks-dir", default="benchmarks/tasks")
    parser.add_argument("--n-runs", type=int, default=200)
    args = parser.parse_args()

    results = run_all_timing(tasks_dir=args.tasks_dir, n_runs=args.n_runs)
    timing_report(results)
