#!/usr/bin/env python3
"""Behavioral pass-rate alongside compile-rate over a corpus (issue #48).

Compile-rate measures whether emitted code *builds*; behavioral pass-rate
measures whether it *computes the same thing the source does*. This script
reports both, at the smallest runnable boundary (the function), so a target
that compiles but returns wrong answers is no longer counted as a win.

For each ``*.py`` file under <root> it:

  1. transpiles the file to <target> (default: rust),
  2. runs the target's compile gate                       → compile-rate,
  3. for every top-level function with a drivable signature, runs the
     behavioral-equivalence check (source oracle vs target over generated +
     fuzzed inputs)                                        → behavioral-rate.

Functions whose signature the harness cannot drive (objects, **kwargs, …) are
counted as ``unsupported`` and excluded from the behavioral denominator — they
are not silently scored as passes. The split is printed so coverage is honest.

Usage::

    uv run python scripts/behavioral_sweep.py examples/samples/Python \\
        --target rust --limit 40
"""

from __future__ import annotations

import argparse
import ast
import sys
from dataclasses import dataclass, field
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / "src"))

from transpilers.pipeline.stages import TARGETS, run_stages  # noqa: E402
from transpilers.verify.behavioral import (  # noqa: E402
    SUPPORTED_TAGS,
    check_behavioral_equivalence,
    infer_param_tags,
)


@dataclass
class Totals:
    files: int = 0
    compiled: int = 0
    fn_total: int = 0
    fn_supported: int = 0
    fn_behavioral_pass: int = 0
    unsupported_reasons: dict[str, int] = field(default_factory=dict)

    def note_unsupported(self, reason: str) -> None:
        key = reason.split(":")[0][:40]
        self.unsupported_reasons[key] = self.unsupported_reasons.get(key, 0) + 1


def _drivable_functions(source: str) -> list[str]:
    """Top-level functions whose parameters are all drivable tags."""
    try:
        tree = ast.parse(source)
    except SyntaxError:
        return []
    out: list[str] = []
    for node in tree.body:
        if not isinstance(node, ast.FunctionDef):
            continue
        if node.args.vararg or node.args.kwarg or node.args.kwonlyargs:
            continue
        tags = infer_param_tags(source, node.name)
        if tags is None:
            continue
        if all(t in SUPPORTED_TAGS for t in tags):
            out.append(node.name)
    return out


def sweep(root: Path, target: str, limit: int) -> Totals:
    t = Totals()
    _, _, compile_gate = TARGETS[target]
    files = sorted(root.rglob("*.py"))
    if limit:
        files = files[:limit]
    for path in files:
        source = path.read_text(encoding="utf-8", errors="replace")
        t.files += 1
        try:
            target_code = run_stages(source, source_lang="python", target=target).output
        except Exception as exc:  # noqa: BLE001
            print(f"  TRANSPILE-FAIL {path.name}: {type(exc).__name__}: {exc}")
            continue

        if compile_gate(target_code).ok:
            t.compiled += 1

        for fn in _drivable_functions(source):
            t.fn_total += 1
            report = check_behavioral_equivalence(
                source, source_lang="python", target=target,
                target_code=target_code, func_name=fn,
            )
            if not report.supported:
                t.note_unsupported(report.reason)
                continue
            if report.total == 0:
                t.note_unsupported(report.reason or "no-samples")
                continue
            t.fn_supported += 1
            if report.ok:
                t.fn_behavioral_pass += 1
            else:
                first = report.divergences[0] if report.divergences else "?"
                print(f"  DIVERGE {path.name}::{fn} — {first}")
    return t


def _pct(n: int, d: int) -> str:
    return f"{(100.0 * n / d):.0f}%" if d else "n/a"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("root", type=Path)
    ap.add_argument("--target", default="rust", choices=sorted(TARGETS))
    ap.add_argument("--limit", type=int, default=0, help="cap files scanned (0 = all)")
    args = ap.parse_args()

    if not args.root.exists():
        print(f"no such path: {args.root}", file=sys.stderr)
        return 2

    t = sweep(args.root, args.target, args.limit)
    print("\n=== behavioral sweep (python -> {}) ===".format(args.target))
    print(f"files scanned        : {t.files}")
    print(f"compile-rate         : {t.compiled}/{t.files} ({_pct(t.compiled, t.files)})")
    print(f"functions found      : {t.fn_total}")
    print(f"  drivable (scored)  : {t.fn_supported}")
    print(f"  unsupported/skipped: {t.fn_total - t.fn_supported}")
    print(
        f"behavioral pass-rate : {t.fn_behavioral_pass}/{t.fn_supported} "
        f"({_pct(t.fn_behavioral_pass, t.fn_supported)}) "
        f"[of drivable functions]"
    )
    if t.unsupported_reasons:
        print("unsupported breakdown:")
        for reason, n in sorted(t.unsupported_reasons.items(), key=lambda kv: -kv[1]):
            print(f"  {n:4d}  {reason}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
