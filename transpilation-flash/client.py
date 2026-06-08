"""Client for the transpilation-flash endpoint.

Can be used in two modes:
    1. Remote (deployed Flash endpoint):
       RUNPOD_API_KEY=xxx python client.py --endpoint-id ep-xxx --cpp "int add(int a, int b) { return a+b; }"

    2. Local tunnel (vLLM running on pod, SSH tunnel on :8000):
       python client.py --local --cpp "int add(int a, int b) { return a+b; }"

Bench integration:
    python client.py --bench --tasks 002,007,008 --target python --repair 2
"""

from __future__ import annotations

import argparse
import asyncio
import json
import os
import sys
from pathlib import Path


async def _call_remote(endpoint_id: str, payload: dict) -> dict:
    from runpod_flash import Endpoint
    ep = Endpoint(id=endpoint_id)
    job = await ep.run(payload)
    await job.wait()
    return job.output


async def _call_local(payload: dict, base_url: str = "http://localhost:8000/v1") -> dict:
    """Call the transpilation logic directly using the local vLLM tunnel.
    Imports worker.py's transpile function and patches the env."""
    os.environ["VLLM_BASE_URL"] = base_url
    os.environ.setdefault("MODEL_NAME", "deepseek-ai/DeepSeek-V4-Flash")

    # Import the function directly (skips Flash runtime overhead)
    sys.path.insert(0, str(Path(__file__).parent))
    from worker import transpile as _transpile_fn

    # Extract the underlying coroutine (bypass @Endpoint decorator in local mode)
    import inspect
    fn = _transpile_fn.__wrapped__ if hasattr(_transpile_fn, "__wrapped__") else _transpile_fn
    if inspect.iscoroutinefunction(fn):
        return await fn(payload)
    return fn(payload)


async def _bench_run(
    tasks_filter: list[str] | None,
    target: str,
    path: str,
    repair: int,
    endpoint_id: str | None,
    local_url: str | None,
) -> None:
    bench_dir = Path(__file__).parent.parent / "transpilation-bench"
    tasks_dir = bench_dir / "benchmarks" / "tasks"
    if not tasks_dir.exists():
        print(f"Bench not found at {bench_dir}", file=sys.stderr)
        sys.exit(1)

    tasks = []
    for f in sorted(tasks_dir.glob("*.json")):
        t = json.loads(f.read_text(encoding="utf-8"))
        if tasks_filter and t["id"] not in tasks_filter:
            continue
        tasks.append(t)

    print(f"Running {len(tasks)} tasks via Flash | target={target} path={path} repair={repair}")
    results = []
    for task in tasks:
        payload = {
            "cpp_source": task["cpp_source"],
            "target": target,
            "path": path,
            "repair_passes": repair,
            "tests": task.get("tests", []),
            "task_name": task["name"],
        }
        try:
            if local_url:
                result = await _call_local(payload, local_url)
            else:
                result = await _call_remote(endpoint_id, payload)
        except Exception as e:
            result = {"error": str(e), "pass_at_1": False, "code": ""}

        pa1 = result.get("pass_at_1")
        mark = "P" if pa1 is True else ("-" if pa1 is None else "F")
        err = result.get("error", "")[:60] if result.get("error") else ""
        print(f"  [{mark}] {task['id']} {task['name']:<28} tier={task['tier']}"
              + (f"  {err}" if err else ""))
        results.append({"id": task["id"], "name": task["name"], "tier": task["tier"],
                        **result})

    passed = sum(1 for r in results if r.get("pass_at_1") is True)
    total = len(results)
    print(f"\npass@1: {passed}/{total}  ({100*passed/total:.1f}%)")

    out = bench_dir / "results" / f"flash_deepseek_{target}_{path}.json"
    out.parent.mkdir(exist_ok=True)
    out.write_text(json.dumps({"results": results, "summary": {"passed": passed, "total": total}},
                               indent=2), encoding="utf-8")
    print(f"Wrote {out}")


def main() -> None:
    ap = argparse.ArgumentParser(description="Transpilation Flash client")
    ap.add_argument("--endpoint-id", help="Deployed Flash endpoint ID")
    ap.add_argument("--local", action="store_true", help="Use local vLLM tunnel (localhost:8000)")
    ap.add_argument("--local-url", default="http://localhost:8000/v1")
    ap.add_argument("--cpp", help="C++ source to transpile (single call)")
    ap.add_argument("--target", default="python", choices=["python", "mojo"])
    ap.add_argument("--path", default="direct", choices=["direct", "python_pivot"])
    ap.add_argument("--repair", type=int, default=1, help="Repair loop passes")
    ap.add_argument("--bench", action="store_true", help="Run transpilation-bench")
    ap.add_argument("--tasks", help="Comma-separated bench task IDs (e.g. 002,007)")
    args = ap.parse_args()

    if not args.endpoint_id and not args.local:
        ap.error("Provide --endpoint-id (deployed) or --local (SSH tunnel)")

    async def run() -> None:
        if args.bench:
            tasks_filter = args.tasks.split(",") if args.tasks else None
            await _bench_run(
                tasks_filter=tasks_filter,
                target=args.target,
                path=args.path,
                repair=args.repair,
                endpoint_id=args.endpoint_id,
                local_url=args.local_url if args.local else None,
            )
        elif args.cpp:
            payload = {"cpp_source": args.cpp, "target": args.target,
                       "path": args.path, "repair_passes": args.repair}
            if args.local:
                result = await _call_local(payload, args.local_url)
            else:
                result = await _call_remote(args.endpoint_id, payload)
            print(f"\n--- {args.target} ({args.path}) ---")
            print(result.get("code", ""))
            if result.get("error"):
                print(f"ERROR: {result['error']}", file=sys.stderr)
        else:
            ap.error("Provide --cpp SOURCE or --bench")

    asyncio.run(run())


if __name__ == "__main__":
    main()
