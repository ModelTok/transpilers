#!/usr/bin/env python3
"""
run_eval.py — Transpilation Benchmark Evaluation Harness

Evaluates LLM-generated translations against the benchmark task set.

Usage:
    python run_eval.py --model gpt-4o --path direct [--tasks 001,002] [--tier 1]
    python run_eval.py --model claude-3-5-sonnet --path python_pivot --output results/

Supported translation paths:
    direct        — C++ → Mojo in one LLM call
    python_pivot  — C++ → Python → Mojo (two LLM calls)
    ir_pivot      — C++ → LLVM IR → Mojo
    ir_python_pivot — C++ → LLVM IR → Python → Mojo

Metrics reported:
    pass@1        — fraction of tasks where generated code passes all test cases
    syntax_ok     — fraction of tasks where generated code is syntactically valid
    tier_breakdown — pass@1 broken down by difficulty tier (1–4)
    concept_breakdown — pass@1 broken down by concept

Output:
    results/<model>_<path>_<date>.json — full per-task results
    results/leaderboard.json — aggregated across all runs
"""

import argparse
import json
import os
import subprocess
import sys
import textwrap
import time
from datetime import datetime
from pathlib import Path
from typing import Any

TASKS_DIR = Path(__file__).parent / "benchmarks" / "tasks"
RESULTS_DIR = Path(__file__).parent / "results"


# ---------------------------------------------------------------------------
# Task loading
# ---------------------------------------------------------------------------

def load_tasks(task_filter: list[str] | None = None, tier_filter: int | None = None) -> list[dict]:
    tasks = []
    for f in sorted(TASKS_DIR.glob("*.json")):
        with open(f, encoding="utf-8") as fh:
            task = json.load(fh)
        if task_filter and task["id"] not in task_filter:
            continue
        if tier_filter and task["tier"] != tier_filter:
            continue
        tasks.append(task)
    return tasks


# ---------------------------------------------------------------------------
# LLM prompt builders
# ---------------------------------------------------------------------------

DIRECT_PROMPT = textwrap.dedent("""\
    Translate the following C++ function to Mojo. Output ONLY the Mojo source code with no explanation,
    no markdown fences, no imports beyond what Mojo requires.

    C++ source:
    ```cpp
    {cpp_source}
    ```

    Mojo translation:
""")

PYTHON_PIVOT_PROMPT_1 = textwrap.dedent("""\
    Translate the following C++ function to idiomatic Python 3. Output ONLY the Python source code.
    No explanation, no markdown fences, no extra imports.

    C++ source:
    ```cpp
    {cpp_source}
    ```

    Python translation:
""")

PYTHON_PIVOT_PROMPT_2 = textwrap.dedent("""\
    Translate the following Python 3 function to Mojo. Use Mojo's type annotations and stdlib.
    Output ONLY the Mojo source code. No explanation, no markdown fences.

    Python source:
    ```python
    {python_source}
    ```

    Mojo translation:
""")

IR_PIVOT_PROMPT_1 = textwrap.dedent("""\
    The following is LLVM IR produced from a C++ function. Translate it to Mojo source code.
    Reconstruct idiomatic high-level constructs where possible.
    Output ONLY the Mojo source code.

    LLVM IR:
    ```llvm
    {llvm_ir}
    ```

    Mojo translation:
""")


# ---------------------------------------------------------------------------
# LLM call stub (replace with real implementation)
# ---------------------------------------------------------------------------

def call_llm(model: str, prompt: str) -> str:
    """
    Call the specified LLM model with the given prompt.

    Replace this stub with your actual LLM client.

    Supported model strings:
        gpt-4o, gpt-4o-mini
        claude-3-5-sonnet-20241022, claude-opus-4-7
        qwen2.5-coder-7b-instruct  (via local vLLM / RunPod)
        llm-compiler-13b-ftd       (via local vLLM / RunPod)

    Returns the generated text (stripped).
    """
    # --- OpenAI ---
    if model.startswith("gpt"):
        try:
            from openai import OpenAI
            client = OpenAI()
            resp = client.chat.completions.create(
                model=model,
                messages=[{"role": "user", "content": prompt}],
                temperature=0,
            )
            return resp.choices[0].message.content.strip()
        except ImportError:
            raise RuntimeError("openai package not installed: pip install openai")

    # --- Anthropic ---
    if model.startswith("claude"):
        try:
            import anthropic
            client = anthropic.Anthropic()
            resp = client.messages.create(
                model=model,
                max_tokens=2048,
                messages=[{"role": "user", "content": prompt}],
            )
            return resp.content[0].text.strip()
        except ImportError:
            raise RuntimeError("anthropic package not installed: pip install anthropic")

    # --- Local vLLM (RunPod / local) ---
    if model.startswith("local:"):
        # Expects VLLM_BASE_URL env var pointing to your vLLM OpenAI-compatible endpoint
        endpoint = os.environ.get("VLLM_BASE_URL", "http://localhost:8000")
        model_name = model[len("local:"):]
        try:
            from openai import OpenAI
            client = OpenAI(api_key="local", base_url=f"{endpoint}/v1")
            resp = client.chat.completions.create(
                model=model_name,
                messages=[{"role": "user", "content": prompt}],
                temperature=0,
                max_tokens=2048,
            )
            return resp.choices[0].message.content.strip()
        except ImportError:
            raise RuntimeError("openai package not installed: pip install openai")

    raise ValueError(f"Unknown model: {model}. See call_llm() docstring for supported models.")


# ---------------------------------------------------------------------------
# Translation path runners
# ---------------------------------------------------------------------------

def translate_direct(task: dict, model: str) -> tuple[str, dict]:
    """C++ → Mojo in one LLM call."""
    prompt = DIRECT_PROMPT.format(cpp_source=task["cpp_source"])
    t0 = time.time()
    mojo_code = call_llm(model, prompt)
    elapsed = time.time() - t0
    return mojo_code, {"calls": 1, "latency_s": round(elapsed, 2)}


def translate_python_pivot(task: dict, model: str) -> tuple[str, dict]:
    """C++ → Python → Mojo (two LLM calls)."""
    prompt1 = PYTHON_PIVOT_PROMPT_1.format(cpp_source=task["cpp_source"])
    t0 = time.time()
    python_code = call_llm(model, prompt1)
    t1 = time.time()

    prompt2 = PYTHON_PIVOT_PROMPT_2.format(python_source=python_code)
    mojo_code = call_llm(model, prompt2)
    elapsed = time.time() - t0

    return mojo_code, {
        "calls": 2,
        "latency_s": round(elapsed, 2),
        "intermediate_python": python_code,
    }


def translate_ir_pivot(task: dict, model: str) -> tuple[str, dict]:
    """C++ → LLVM IR (via clang) → Mojo."""
    # Write C++ to temp file and compile to IR
    cpp_file = Path("/tmp/bench_task.cpp")
    ir_file = Path("/tmp/bench_task.ll")
    cpp_file.write_text(task["cpp_source"])

    result = subprocess.run(
        ["clang", "-S", "-emit-llvm", "-O0", "-o", str(ir_file), str(cpp_file)],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        raise RuntimeError(f"clang failed: {result.stderr}")

    llvm_ir = ir_file.read_text()
    prompt = IR_PIVOT_PROMPT_1.format(llvm_ir=llvm_ir)
    t0 = time.time()
    mojo_code = call_llm(model, prompt)
    elapsed = time.time() - t0

    return mojo_code, {
        "calls": 1,
        "latency_s": round(elapsed, 2),
        "ir_lines": len(llvm_ir.splitlines()),
    }


TRANSLATORS = {
    "direct": translate_direct,
    "python_pivot": translate_python_pivot,
    "ir_pivot": translate_ir_pivot,
}


# ---------------------------------------------------------------------------
# Test runner: execute generated Python via exec() (Python reference path)
# For Mojo, execute via `mojo run` subprocess.
# ---------------------------------------------------------------------------

def run_python_tests(code: str, tests: list[dict]) -> list[dict]:
    results = []
    for test in tests:
        args = test["args"]
        expected = test["expected"]
        try:
            ns: dict[str, Any] = {}
            exec(code, ns)
            # Find the first callable in the namespace
            fn = next(v for v in ns.values() if callable(v) and not v.__name__.startswith("_"))
            actual = repr(fn(*args))
            passed = actual == expected
        except Exception as e:
            actual = f"ERROR: {e}"
            passed = False
        results.append({"args": args, "expected": expected, "actual": actual, "passed": passed})
    return results


def run_mojo_tests(mojo_code: str, tests: list[dict], task_name: str) -> list[dict]:
    """
    Execute Mojo code via `mojo run`. Requires mojo in PATH.
    Writes a harness that calls the function and prints the result.
    """
    results = []
    for i, test in enumerate(tests):
        args = test["args"]
        expected = test["expected"]

        # Build a simple Mojo main that calls the function with literal args
        args_str = ", ".join(repr(a) for a in args)
        harness = f"{mojo_code}\n\nfn main():\n    let result = {task_name}({args_str})\n    print(result)\n"

        tmp = Path(f"/tmp/bench_{task_name}_{i}.mojo")
        tmp.write_text(harness)

        try:
            result = subprocess.run(
                ["mojo", "run", str(tmp)],
                capture_output=True, text=True, timeout=30
            )
            actual = result.stdout.strip()
            passed = actual == expected
        except subprocess.TimeoutExpired:
            actual = "ERROR: timeout"
            passed = False
        except FileNotFoundError:
            actual = "ERROR: mojo not in PATH"
            passed = False
        except Exception as e:
            actual = f"ERROR: {e}"
            passed = False

        results.append({"args": args, "expected": expected, "actual": actual, "passed": passed})

    return results


def check_syntax_python(code: str) -> bool:
    try:
        compile(code, "<string>", "exec")
        return True
    except SyntaxError:
        return False


# ---------------------------------------------------------------------------
# Metrics
# ---------------------------------------------------------------------------

def compute_metrics(task_results: list[dict]) -> dict:
    total = len(task_results)
    if total == 0:
        return {}

    passed_all = sum(1 for r in task_results if r["pass_at_1"])
    syntax_ok = sum(1 for r in task_results if r.get("syntax_ok", True))

    # Tier breakdown
    tier_stats: dict[int, dict] = {}
    for r in task_results:
        t = r["tier"]
        tier_stats.setdefault(t, {"total": 0, "passed": 0})
        tier_stats[t]["total"] += 1
        if r["pass_at_1"]:
            tier_stats[t]["passed"] += 1

    tier_breakdown = {
        str(t): round(v["passed"] / v["total"], 3)
        for t, v in sorted(tier_stats.items())
    }

    # Concept breakdown
    concept_stats: dict[str, dict] = {}
    for r in task_results:
        c = r["concept"]
        concept_stats.setdefault(c, {"total": 0, "passed": 0})
        concept_stats[c]["total"] += 1
        if r["pass_at_1"]:
            concept_stats[c]["passed"] += 1

    concept_breakdown = {
        c: round(v["passed"] / v["total"], 3)
        for c, v in sorted(concept_stats.items())
    }

    return {
        "total_tasks": total,
        "pass_at_1": round(passed_all / total, 3),
        "syntax_ok_rate": round(syntax_ok / total, 3),
        "tier_breakdown": tier_breakdown,
        "concept_breakdown": concept_breakdown,
    }


# ---------------------------------------------------------------------------
# Main evaluation loop
# ---------------------------------------------------------------------------

def evaluate(model: str, path: str, tasks: list[dict], target: str = "python") -> list[dict]:
    """
    Run the full evaluation loop.

    target: "python"  — run python_reference through exec() (always works, no Mojo needed)
            "mojo"    — run translated Mojo through `mojo run` subprocess
    """
    translator = TRANSLATORS[path]
    task_results = []

    for i, task in enumerate(tasks):
        print(f"  [{i+1}/{len(tasks)}] {task['id']} {task['name']} (tier {task['tier']})...", end=" ", flush=True)

        try:
            translated_code, meta = translator(task, model)
        except Exception as e:
            print(f"SKIP (translation error: {e})")
            task_results.append({
                "id": task["id"],
                "name": task["name"],
                "tier": task["tier"],
                "concept": task["concept"],
                "pass_at_1": False,
                "syntax_ok": False,
                "error": str(e),
                "tests": [],
                "meta": {},
            })
            continue

        # Syntax check (Python proxy — always available)
        syntax_ok = check_syntax_python(translated_code) if target == "python" else True

        # Test execution
        if target == "python":
            test_results = run_python_tests(translated_code, task["tests"])
        else:
            test_results = run_mojo_tests(translated_code, task["tests"], task["name"])

        passed = all(r["passed"] for r in test_results)
        print("PASS" if passed else "FAIL")

        task_results.append({
            "id": task["id"],
            "name": task["name"],
            "tier": task["tier"],
            "concept": task["concept"],
            "pass_at_1": passed,
            "syntax_ok": syntax_ok,
            "translated_code": translated_code,
            "tests": test_results,
            "meta": meta,
        })

    return task_results


# ---------------------------------------------------------------------------
# Leaderboard update
# ---------------------------------------------------------------------------

def update_leaderboard(result_path: Path, metrics: dict, model: str, path: str) -> None:
    lb_path = RESULTS_DIR / "leaderboard.json"
    leaderboard = []
    if lb_path.exists():
        with open(lb_path, encoding="utf-8") as f:
            leaderboard = json.load(f)

    entry = {
        "model": model,
        "path": path,
        "date": datetime.now().strftime("%Y-%m-%d"),
        "result_file": str(result_path.name),
        **metrics,
    }
    leaderboard.append(entry)
    leaderboard.sort(key=lambda x: x.get("pass_at_1", 0), reverse=True)

    with open(lb_path, "w", encoding="utf-8") as f:
        json.dump(leaderboard, f, indent=2)
    print(f"\n  Leaderboard updated: {lb_path}")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Transpilation Benchmark Evaluation Harness",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("--model", required=True,
                        help="LLM model ID (gpt-4o, claude-3-5-sonnet-20241022, local:qwen2.5-coder-7b)")
    parser.add_argument("--path", default="direct",
                        choices=list(TRANSLATORS),
                        help="Translation path (default: direct)")
    parser.add_argument("--target", default="python", choices=["python", "mojo"],
                        help="Execution target for test runner (default: python)")
    parser.add_argument("--tasks", default=None,
                        help="Comma-separated task IDs to evaluate (default: all)")
    parser.add_argument("--tier", type=int, default=None, choices=[1, 2, 3, 4],
                        help="Filter by difficulty tier")
    parser.add_argument("--output", default=None,
                        help="Output directory (default: results/)")
    parser.add_argument("--dry-run", action="store_true",
                        help="Print prompts only, do not call LLM")
    args = parser.parse_args()

    # Resolve output dir
    out_dir = Path(args.output) if args.output else RESULTS_DIR
    out_dir.mkdir(parents=True, exist_ok=True)

    # Load tasks
    task_filter = [t.strip() for t in args.tasks.split(",")] if args.tasks else None
    tasks = load_tasks(task_filter=task_filter, tier_filter=args.tier)
    if not tasks:
        print("No tasks matched the filter.")
        sys.exit(1)

    print(f"\n{'='*60}")
    print(f"  Model : {args.model}")
    print(f"  Path  : {args.path}")
    print(f"  Target: {args.target}")
    print(f"  Tasks : {len(tasks)}")
    print(f"{'='*60}\n")

    if args.dry_run:
        for task in tasks[:3]:
            print(f"--- {task['id']} {task['name']} ---")
            prompt = DIRECT_PROMPT.format(cpp_source=task["cpp_source"])
            print(prompt[:500])
            print("...")
        sys.exit(0)

    # Run evaluation
    task_results = evaluate(args.model, args.path, tasks, target=args.target)

    # Compute metrics
    metrics = compute_metrics(task_results)

    print(f"\n{'='*60}")
    print(f"  pass@1           : {metrics['pass_at_1']:.1%}")
    print(f"  syntax_ok_rate   : {metrics['syntax_ok_rate']:.1%}")
    print(f"  tier breakdown   : {metrics['tier_breakdown']}")
    print(f"{'='*60}\n")

    # Save results
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    safe_model = args.model.replace("/", "_").replace(":", "_")
    result_path = out_dir / f"{safe_model}_{args.path}_{timestamp}.json"

    output = {
        "model": args.model,
        "path": args.path,
        "target": args.target,
        "timestamp": timestamp,
        "metrics": metrics,
        "tasks": task_results,
    }
    with open(result_path, "w", encoding="utf-8") as f:
        json.dump(output, f, indent=2)

    print(f"  Results saved : {result_path}")
    update_leaderboard(result_path, metrics, args.model, args.path)


if __name__ == "__main__":
    main()
