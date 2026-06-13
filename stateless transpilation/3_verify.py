#!/usr/bin/env python3
"""Deterministic verifier for the transpiled ports (no LLM).

Flat toolkit. For each port under out/python: import-check, ruff, pytest (if a
test exists). For each out/mojo file: mojo build. Emits verify_report.json with
the skeleton+failure list to feed a `--files <failures> --force` repair pass.

Usage:
  python3 verify_transpiled.py
  python3 verify_transpiled.py --files DataSizing --stage import test
  python3 verify_transpiled.py --python python3 --ruff ruff --mojo mojo
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

BASE = Path(__file__).resolve().parent
PY_OUT, MOJO_OUT, TEST_OUT = BASE / "out" / "python", BASE / "out" / "mojo", BASE / "out" / "tests"


def run(cmd: list[str], timeout: int = 300) -> tuple[bool, str]:
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout, cwd=BASE)
        return p.returncode == 0, (p.stdout + p.stderr)[-1500:]
    except Exception as e:  # noqa: BLE001
        return False, str(e)


def is_skeleton(py: Path) -> bool:
    t = py.read_text(errors="ignore")
    return "__todo__" in t or "Phase-1 C++->Python lift" in t


def verify_file(file, stages, tools) -> dict:
    r: dict = {"file": file, "checks": {}}
    py = PY_OUT / f"{file}.py"
    if not py.exists():
        r["checks"]["exists"] = {"ok": False, "msg": "no python port"}
        return r
    r["skeleton"] = is_skeleton(py)
    if "import" in stages:
        code = (f"import sys,importlib.util as u; s=u.spec_from_file_location('t_{file}',r'{py}'); "
                f"m=u.module_from_spec(s); sys.modules['t_{file}']=m; s.loader.exec_module(m)")
        r["checks"]["import"] = dict(zip(("ok", "msg"), run([tools["python"], "-c", code], 60)))
    if "lint" in stages:
        r["checks"]["lint"] = dict(zip(("ok", "msg"), run([tools["ruff"], "check", str(py)], 60)))
    if "test" in stages and (TEST_OUT / f"test_{file}.py").exists():
        r["checks"]["test"] = dict(zip(("ok", "msg"),
                                       run([tools["python"], "-m", "pytest",
                                            str(TEST_OUT / f"test_{file}.py"), "-q"], 300)))
    if "mojo" in stages:
        mojo = MOJO_OUT / f"{re.sub(r'(?<!^)(?=[A-Z])', '_', file).lower()}.mojo"
        if mojo.exists():
            so = BASE / "out" / "mojo" / f"lib{mojo.stem}.so"
            r["checks"]["mojo_build"] = dict(zip(("ok", "msg"),
                run([tools["mojo"], "build", "--emit", "shared-lib", str(mojo), "-o", str(so)], 300)))
    r["pass"] = bool(r["checks"]) and all(c["ok"] for c in r["checks"].values()) and not r.get("skeleton")
    return r


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--files", nargs="+")
    ap.add_argument("--stage", nargs="+", default=["import", "lint", "test", "mojo"],
                    choices=["import", "lint", "test", "mojo"])
    ap.add_argument("--python", default=sys.executable)
    ap.add_argument("--ruff", default="ruff")
    ap.add_argument("--mojo", default="mojo")
    args = ap.parse_args()
    tools = {"python": args.python, "ruff": args.ruff, "mojo": args.mojo}

    files = args.files or sorted(p.stem for p in PY_OUT.glob("*.py"))
    stages = set(args.stage)
    print(f"verify: {len(files)} files, stages={sorted(stages)}")

    results, failures, skeletons = [], [], []
    for f in files:
        r = verify_file(f, stages, tools)
        results.append(r)
        if r.get("skeleton"):
            skeletons.append(f)
        elif not r.get("pass"):
            failures.append(f)
        bad = [k for k, c in r["checks"].items() if not c["ok"]]
        flag = "SKELETON" if r.get("skeleton") else ("FAIL:" + ",".join(bad) if bad else "ok")
        print(f"  [{flag:<22}] {f}")

    out = {"passed": [r["file"] for r in results if r.get("pass")],
           "skeletons": skeletons, "failures": failures, "detail": results}
    (BASE / "3_verify_report.json").write_text(json.dumps(out, indent=2))
    print(f"\npassed={len(out['passed'])}  skeleton={len(skeletons)}  failed={len(failures)} / {len(files)}")
    if skeletons + failures:
        print("repair:  python3 batch_transpile.py --files "
              + " ".join((skeletons + failures)[:20]) + " --force")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
