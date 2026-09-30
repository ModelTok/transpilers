#!/usr/bin/env python3
"""Dependency-boundary inventory for the C++ -> Mojo migration (issues #64, #66).

Scans C++ sources (default: $EP_SRC, the EnergyPlus oracle) and reports, per
module and in total, how often each boundary symbol is used, and whether the
shim layer (data/sft/cpp_mojo/ep_prelude.mojo + psychro_shims.py) covers it:

  * ObjexxFCL array types  (Array1D, Array2D, Array1S, ...)
  * Constant::<name>       (EnergyPlus Constant namespace)
  * libm intrinsics        (sin, pow, sqrt, ... incl. std:: forms)
  * Psychrometric calls    (Psy*)

Static regex scan only: comments and string literals are stripped first, but no
preprocessing or overload resolution is done, so counts are approximate.

  python scripts/sft/boundary_inventory.py [PATH ...] [--json]
"""
from __future__ import annotations

import collections
import json
import os
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
PRELUDE = REPO / "data/sft/cpp_mojo/ep_prelude.mojo"
PSYCHRO = REPO / "scripts/sft/psychro_shims.py"
EXTS = {".cc", ".cpp", ".hh", ".h", ".hpp"}

LIBM = (
    "sin cos tan asin acos atan atan2 sinh cosh tanh exp log log10 log2 pow sqrt "
    "cbrt fabs abs floor ceil fmod round trunc hypot"
).split()

ARRAY_RE = re.compile(r"\b(Array[1-6][DSA](?:_[a-z]+)?|Optional(?:_[a-z]+)?|Reference)\b")
CONST_RE = re.compile(r"\bConstant::(\w+)")
LIBM_RE = re.compile(r"(?<![\w.>])(?:std::)?(" + "|".join(LIBM) + r")\s*\(")
PSY_RE = re.compile(r"\b(Psy\w+)\s*\(")
_COMMENT_RE = re.compile(r'//[^\n]*|/\*.*?\*/|"(?:\\.|[^"\\\n])*"', re.S)


def strip_noise(text: str) -> str:
    """Blank out comments and string literals, preserving newlines."""
    return _COMMENT_RE.sub(lambda m: "\n" * m.group(0).count("\n"), text)


def shim_coverage(prelude: Path = PRELUDE, psychro: Path = PSYCHRO) -> dict[str, set[str]]:
    """What the shim layer currently provides (read from source, not executed)."""
    cov = {"arrays": set(), "constants": set(), "psychro": set()}
    if prelude.is_file():
        src = prelude.read_text(encoding="utf-8", errors="ignore")
        cov["arrays"] = set(re.findall(r"^struct (Array[12]D)\b", src, re.M))
        m = re.search(r"^struct Constant:\n((?:[ \t]+.*\n?)+)", src, re.M)
        if m:
            cov["constants"] = set(re.findall(r"comptime (\w+)\s*=", m.group(1)))
    if psychro.is_file():
        src = psychro.read_text(encoding="utf-8", errors="ignore")
        cov["psychro"] = set(re.findall(r'"?(Psy[A-Z]\w+)', src))
    return cov


def scan_text(text: str) -> dict[str, collections.Counter]:
    text = strip_noise(text)
    return {
        "arrays": collections.Counter(ARRAY_RE.findall(text)),
        "constants": collections.Counter(CONST_RE.findall(text)),
        "libm": collections.Counter(LIBM_RE.findall(text)),
        "psychro": collections.Counter(PSY_RE.findall(text)),
    }


def iter_sources(paths):
    for p in map(Path, paths):
        if p.is_file():
            yield p
        elif p.is_dir():
            for f in sorted(p.rglob("*")):
                if f.suffix in EXTS and f.is_file():
                    yield f


def build_inventory(paths, coverage=None) -> dict:
    coverage = coverage if coverage is not None else shim_coverage()
    kinds = ("arrays", "constants", "libm", "psychro")
    total = {k: collections.Counter() for k in kinds}
    by_module: dict[str, dict[str, collections.Counter]] = {}
    for f in iter_sources(paths):
        found = scan_text(f.read_text(encoding="utf-8", errors="ignore"))
        mod = by_module.setdefault(f.stem, {k: collections.Counter() for k in kinds})
        for k in kinds:
            mod[k].update(found[k])
            total[k].update(found[k])
    unshimmed = {
        "arrays": sorted(a for a in total["arrays"] if a not in coverage["arrays"]),
        "constants": sorted(c for c in total["constants"] if c not in coverage["constants"]),
        "psychro": sorted(p for p in total["psychro"] if p not in coverage["psychro"]),
    }
    return {
        "totals": {k: dict(total[k].most_common()) for k in kinds},
        "by_module": {
            m: {k: dict(v[k].most_common()) for k in kinds if v[k]}
            for m, v in sorted(by_module.items())
        },
        "unshimmed": unshimmed,
        "shimmed": {k: sorted(v) for k, v in coverage.items()},
    }


def render(inv: dict, top: int = 15) -> str:
    out = []
    for k, counts in inv["totals"].items():
        out.append(f"{k}: {len(counts)} distinct, {sum(counts.values())} uses")
        for name, n in list(counts.items())[:top]:
            flag = "" if k == "libm" or name not in inv["unshimmed"].get(k, []) else "  [NO SHIM]"
            out.append(f"  {name:32} {n}{flag}")
    out.append(f"modules scanned: {len(inv['by_module'])}")
    return "\n".join(out)


def main(argv=None) -> int:
    argv = list(sys.argv[1:] if argv is None else argv)
    as_json = "--json" in argv
    paths = [a for a in argv if not a.startswith("--")] or [os.environ.get("EP_SRC", "")]
    paths = [p for p in paths if p]
    if not paths:
        print("no path given and EP_SRC is unset", file=sys.stderr)
        return 2
    inv = build_inventory(paths)
    print(json.dumps(inv, indent=2) if as_json else render(inv))
    return 0


if __name__ == "__main__":
    sys.exit(main())
