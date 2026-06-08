"""Run the hybrid `transpilers` tool against the benchmark.

This is the algorithmic-pipeline counterpart of `run_eval.py` (which drives
LLMs). It shells out to ``uv run transpile --source cpp --target {python,mojo}``
inside the sibling ``transpilers`` repo, captures the emitted source, and
(for the Python target) executes the bench's test cases against it.

Mojo execution is skipped when the ``mojo`` binary isn't on PATH — we still
record syntactic/transpile success.

Usage:
    python scripts/run_transpilers.py --target python
    python scripts/run_transpilers.py --target both --tier 1
    python scripts/run_transpilers.py --target python --tasks 002,007,008
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path
from typing import Any

HERE = Path(__file__).resolve().parent.parent
TASKS_DIR = HERE / "benchmarks" / "tasks"
RESULTS_DIR = HERE / "results"
TRANSPILERS_DIR = HERE.parent / "transpilers"


def load_tasks(task_filter: list[str] | None, tier_filter: int | None) -> list[dict]:
    tasks = []
    for f in sorted(TASKS_DIR.glob("*.json")):
        task = json.loads(f.read_text(encoding="utf-8"))
        if task_filter and task["id"] not in task_filter:
            continue
        if tier_filter and task["tier"] != tier_filter:
            continue
        tasks.append(task)
    return tasks


def transpile_one(cpp_source: str, target: str, tmp: Path) -> dict:
    """Invoke `uv run transpile` and return {rc, stdout, stderr, elapsed}."""
    cpp_file = tmp / "task.cpp"
    cpp_file.write_text(cpp_source, encoding="utf-8")
    env = os.environ.copy()
    env["PYTHONIOENCODING"] = "utf-8"
    t0 = time.time()
    proc = subprocess.run(
        ["uv", "run", "transpile", str(cpp_file), "--source", "cpp", "--target", target],
        cwd=TRANSPILERS_DIR,
        capture_output=True, text=True, timeout=60, env=env,
    )
    return {
        "rc": proc.returncode,
        "stdout": proc.stdout,
        "stderr": proc.stderr,
        "elapsed_s": round(time.time() - t0, 2),
    }


def run_python_tests(code: str, tests: list[dict]) -> list[dict]:
    """Exec the emitted Python and call its first public function per test."""
    results = []
    try:
        ns: dict[str, Any] = {}
        exec(compile(code, "<emitted>", "exec"), ns)
        fn = next(v for k, v in ns.items()
                  if callable(v) and not k.startswith("_") and getattr(v, "__module__", None) != "builtins")
    except Exception as e:
        return [{"args": t["args"], "expected": t["expected"],
                 "actual": f"LOAD-ERROR: {e}", "passed": False} for t in tests]

    for test in tests:
        args = test["args"]
        try:
            actual = repr(fn(*args))
            passed = actual == test["expected"]
        except Exception as e:
            actual = f"ERROR: {e}"
            passed = False
        results.append({"args": args, "expected": test["expected"],
                        "actual": actual, "passed": passed})
    return results


def run_mojo_tests(code: str, tests: list[dict], task_name: str, tmp: Path) -> list[dict]:
    if shutil.which("mojo") is None:
        return [{"args": t["args"], "expected": t["expected"],
                 "actual": "SKIP: mojo not on PATH", "passed": None} for t in tests]
    results = []
    for i, test in enumerate(tests):
        args_lit = ", ".join(repr(a) for a in test["args"])
        harness = f"{code}\n\nfn main():\n    print({task_name}({args_lit}))\n"
        path = tmp / f"{task_name}_{i}.mojo"
        path.write_text(harness, encoding="utf-8")
        try:
            proc = subprocess.run(["mojo", "run", str(path)],
                                  capture_output=True, text=True, timeout=30)
            actual = proc.stdout.strip()
            passed = actual == test["expected"]
        except Exception as e:
            actual = f"ERROR: {e}"
            passed = False
        results.append({"args": test["args"], "expected": test["expected"],
                        "actual": actual, "passed": passed})
    return results


def check_syntax_python(code: str) -> bool:
    try:
        compile(code, "<string>", "exec")
        return True
    except SyntaxError:
        return False


def evaluate(task: dict, target: str, tmp: Path) -> dict:
    out = transpile_one(task["cpp_source"], target, tmp)
    code = out["stdout"]
    xpile_ok = out["rc"] == 0 and bool(code.strip())

    err_msg = ""
    if not xpile_ok:
        lines = [l for l in (out["stderr"] or out["stdout"]).splitlines() if l.strip()]
        err_msg = lines[-1] if lines else ""

    record: dict = {
        "id": task["id"],
        "name": task["name"],
        "tier": task["tier"],
        "concept": task["concept"],
        "target": target,
        "transpile_ok": xpile_ok,
        "elapsed_s": out["elapsed_s"],
        "emitted": code if xpile_ok else "",
        "transpile_error": err_msg,
    }

    if not xpile_ok:
        record["syntax_ok"] = False
        record["pass_at_1"] = False
        return record

    if target == "python":
        record["syntax_ok"] = check_syntax_python(code)
        if record["syntax_ok"]:
            tests = run_python_tests(code, task["tests"])
            record["tests"] = tests
            record["pass_at_1"] = all(t["passed"] for t in tests)
        else:
            record["pass_at_1"] = False
    else:  # mojo
        tests = run_mojo_tests(code, task["tests"], task["name"], tmp)
        record["tests"] = tests
        record["syntax_ok"] = True
        if all(t["passed"] is None for t in tests):
            record["pass_at_1"] = None
        else:
            record["pass_at_1"] = all(t["passed"] for t in tests)

    return record


def summarize(results: list[dict]) -> dict:
    by_target: dict[str, dict] = {}
    for r in results:
        t = r["target"]
        bucket = by_target.setdefault(t, {
            "total": 0, "transpile_ok": 0, "syntax_ok": 0,
            "pass_at_1": 0, "skipped": 0,
            "tiers": {}, "concepts": {},
        })
        bucket["total"] += 1
        if r["transpile_ok"]:
            bucket["transpile_ok"] += 1
        if r.get("syntax_ok"):
            bucket["syntax_ok"] += 1
        if r.get("pass_at_1") is True:
            bucket["pass_at_1"] += 1
        if r.get("pass_at_1") is None:
            bucket["skipped"] += 1

        tier = str(r["tier"])
        tslot = bucket["tiers"].setdefault(tier, {"total": 0, "passed": 0, "xpile_ok": 0})
        tslot["total"] += 1
        if r["transpile_ok"]:
            tslot["xpile_ok"] += 1
        if r.get("pass_at_1") is True:
            tslot["passed"] += 1
    return by_target


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--target", choices=["python", "mojo", "both"], default="python")
    ap.add_argument("--tasks", help="comma-separated task IDs")
    ap.add_argument("--tier", type=int)
    ap.add_argument("--output", default=None)
    args = ap.parse_args(argv)

    task_ids = args.tasks.split(",") if args.tasks else None
    tasks = load_tasks(task_ids, args.tier)
    targets = ["python", "mojo"] if args.target == "both" else [args.target]
    print(f"[run_transpilers] {len(tasks)} tasks x {len(targets)} targets")

    RESULTS_DIR.mkdir(exist_ok=True)
    tmp = RESULTS_DIR / f".tmp_{int(time.time())}"
    tmp.mkdir(exist_ok=True)

    all_records: list[dict] = []
    for task in tasks:
        for tgt in targets:
            r = evaluate(task, tgt, tmp)
            mark = "OK" if r["transpile_ok"] else "XX"
            pa1 = r.get("pass_at_1")
            pa1_mark = "-" if pa1 is None else ("P" if pa1 else "F")
            print(f"  [{mark}] {r['id']} {r['name']:<28} tier={r['tier']} target={tgt:<6} pass={pa1_mark}")
            all_records.append(r)

    summary = summarize(all_records)
    print("\n=== Summary ===")
    for tgt, s in summary.items():
        print(f"{tgt}: transpile {s['transpile_ok']}/{s['total']}, "
              f"syntax {s['syntax_ok']}/{s['total']}, "
              f"pass@1 {s['pass_at_1']}/{s['total']}"
              + (f" ({s['skipped']} skipped)" if s["skipped"] else ""))
        for tier, t in sorted(s["tiers"].items()):
            print(f"   tier {tier}: xpile {t['xpile_ok']}/{t['total']}, "
                  f"pass@1 {t['passed']}/{t['total']}")

    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    out_path = Path(args.output) if args.output else RESULTS_DIR / f"transpilers_{args.target}_{ts}.json"
    out_path.write_text(json.dumps({
        "tool": "transpilers",
        "target": args.target,
        "timestamp": ts,
        "summary": summary,
        "results": all_records,
    }, indent=2), encoding="utf-8")
    print(f"\nWrote {out_path}")

    shutil.rmtree(tmp, ignore_errors=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
