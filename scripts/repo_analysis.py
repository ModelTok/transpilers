#!/usr/bin/env python3
"""Repo analysis dashboard: transpilation-readiness report.

Usage
-----
    python scripts/repo_analysis.py /path/to/repo [--lang cpp|python] [--output report.json]

The script walks all source files of the given language, counts lines of code,
classifies each file by estimated transpilation difficulty, lists external
dependencies (includes / imports), and detects circular dependencies.

Difficulty tiers (C++)
----------------------
Tier 1 – Easy       : only functions with primitive types
Tier 2 – Medium     : STL containers, standard algorithms
Tier 3 – Hard       : classes, virtual functions
Tier 4 – Very Hard  : templates, raw pointers, RAII, macros

Difficulty tiers (Python)
-------------------------
Tier 1 – Easy       : only functions with primitive-type annotations
Tier 2 – Medium     : list/dict comprehensions, decorators, generators
Tier 3 – Hard       : classes, __dunder__ methods, metaclasses
Tier 4 – Very Hard  : dynamic __getattr__, exec/eval, ctypes, C extensions
"""

from __future__ import annotations

import argparse
import ast
import json
import re
import sys
from pathlib import Path
from typing import NamedTuple


# ---------------------------------------------------------------------------
# LOC counter
# ---------------------------------------------------------------------------

def count_loc(source: str) -> int:
    """Count non-blank, non-comment lines."""
    lines = source.splitlines()
    loc = 0
    in_block_comment = False
    for line in lines:
        stripped = line.strip()
        # C/C++ block comment tracking
        if "/*" in stripped:
            in_block_comment = True
        if "*/" in stripped:
            in_block_comment = False
            continue
        if in_block_comment:
            continue
        # Skip blank lines and line comments
        if not stripped or stripped.startswith("//") or stripped.startswith("#"):
            continue
        loc += 1
    return loc


# ---------------------------------------------------------------------------
# C++ analysis
# ---------------------------------------------------------------------------

_CPP_INCLUDE = re.compile(r'^\s*#\s*include\s*[<"]([^>"]+)[>"]', re.MULTILINE)
_CPP_TEMPLATE = re.compile(r'\btemplate\s*<')
_CPP_RAWPTR = re.compile(r'\b\w+\s*\*\s+\w+')           # type* var
_CPP_CLASS = re.compile(r'\b(class|struct)\s+\w+')
_CPP_VIRTUAL = re.compile(r'\bvirtual\b')
_CPP_MACRO = re.compile(r'^\s*#\s*define\b', re.MULTILINE)
_CPP_STL = re.compile(
    r'\b(vector|map|unordered_map|set|unordered_set|list|deque|queue|'
    r'stack|pair|tuple|string|array|algorithm|sort|find|transform)\b'
)
_CPP_FUNC_DEF = re.compile(r'\b\w[\w:<>*&,\s]*\s+(\w+)\s*\([^)]*\)\s*\{')
_CPP_PRIMITIVE = re.compile(r'\b(int|long|float|double|char|bool|void|uint|size_t)\b')


def _analyse_cpp(source: str) -> tuple[str, list[str]]:
    """Return (difficulty, deps) for a C++ source file."""
    deps = list({m.group(1) for m in _CPP_INCLUDE.finditer(source)})

    has_template = bool(_CPP_TEMPLATE.search(source))
    has_rawptr = bool(_CPP_RAWPTR.search(source))
    has_macro = bool(_CPP_MACRO.search(source))
    has_class = bool(_CPP_CLASS.search(source))
    has_virtual = bool(_CPP_VIRTUAL.search(source))
    has_stl = bool(_CPP_STL.search(source))

    if has_template or has_rawptr or has_macro:
        difficulty = "very_hard"
    elif has_class or has_virtual:
        difficulty = "hard"
    elif has_stl:
        difficulty = "medium"
    else:
        difficulty = "easy"

    return difficulty, deps


# ---------------------------------------------------------------------------
# Python analysis
# ---------------------------------------------------------------------------

_PY_IMPORT = re.compile(r'^\s*(?:import|from)\s+([\w.]+)', re.MULTILINE)
_PY_PRIMITIVE_ANNOTATIONS = re.compile(r':\s*(int|float|str|bool|bytes|None)\b')


def _analyse_python(source: str) -> tuple[str, list[str]]:
    """Return (difficulty, deps) for a Python source file."""
    deps: list[str] = []
    for m in _PY_IMPORT.finditer(source):
        pkg = m.group(1).split(".")[0]
        if pkg not in deps:
            deps.append(pkg)

    try:
        tree = ast.parse(source)
    except SyntaxError:
        return "very_hard", deps

    has_class = False
    has_dunder = False
    has_metaclass = False
    has_exec_eval = False
    has_ctypes = False
    has_decorator = False
    has_comprehension = False
    has_generator = False

    for node in ast.walk(tree):
        if isinstance(node, ast.ClassDef):
            has_class = True
            for kw in node.keywords:
                if kw.arg == "metaclass":
                    has_metaclass = True
        if isinstance(node, ast.FunctionDef):
            if node.name.startswith("__") and node.name.endswith("__"):
                has_dunder = True
            if node.decorator_list:
                has_decorator = True
        if isinstance(node, (ast.ListComp, ast.SetComp, ast.DictComp)):
            has_comprehension = True
        if isinstance(node, ast.GeneratorExp):
            has_generator = True
        if isinstance(node, ast.Call):
            if isinstance(node.func, ast.Name) and node.func.id in ("exec", "eval"):
                has_exec_eval = True

    if "ctypes" in deps or "cffi" in deps:
        has_ctypes = True

    if has_exec_eval or has_ctypes or has_metaclass:
        difficulty = "very_hard"
    elif has_class or has_dunder:
        difficulty = "hard"
    elif has_decorator or has_comprehension or has_generator:
        difficulty = "medium"
    else:
        difficulty = "easy"

    return difficulty, deps


# ---------------------------------------------------------------------------
# Circular dependency detection
# ---------------------------------------------------------------------------

def _detect_circular_deps(
    file_deps: dict[str, list[str]],
    file_stems: set[str],
) -> list[list[str]]:
    """Detect cycles among project-internal files.

    *file_deps* maps file stem → list of dependency names.
    *file_stems* is the set of all file stems in the project.

    Returns a list of cycles (each cycle is a list of stems).
    """
    # Build adjacency restricted to in-project deps
    graph: dict[str, list[str]] = {stem: [] for stem in file_stems}
    for stem, deps in file_deps.items():
        for dep in deps:
            dep_stem = dep.split("/")[-1].replace(".h", "").replace(".hpp", "")
            if dep_stem in file_stems and dep_stem != stem:
                graph[stem].append(dep_stem)

    # Tarjan-style DFS for cycle detection
    visited: set[str] = set()
    in_stack: set[str] = set()
    stack: list[str] = []
    cycles: list[list[str]] = []

    def _dfs(node: str) -> None:
        visited.add(node)
        in_stack.add(node)
        stack.append(node)
        for neighbour in graph.get(node, []):
            if neighbour not in visited:
                _dfs(neighbour)
            elif neighbour in in_stack:
                # Found a cycle — extract it from the stack
                idx = stack.index(neighbour)
                cycle = stack[idx:]
                cycles.append(cycle[:])
        stack.pop()
        in_stack.discard(node)

    for stem in file_stems:
        if stem not in visited:
            _dfs(stem)

    return cycles


# ---------------------------------------------------------------------------
# Main analysis entry point
# ---------------------------------------------------------------------------

class _FileStats(NamedTuple):
    path: str
    loc: int
    difficulty: str
    deps: list[str]


def analyse_repo(repo: Path, lang: str) -> dict:
    """Walk *repo*, analyse every source file, and return a report dict."""
    extensions = {
        "cpp": {".cpp", ".cc", ".cxx", ".hpp", ".hh", ".h"},
        "python": {".py"},
    }.get(lang, {".py"})

    analyser = _analyse_cpp if lang == "cpp" else _analyse_python

    files: list[_FileStats] = []
    difficulty_counts: dict[str, int] = {
        "easy": 0, "medium": 0, "hard": 0, "very_hard": 0
    }
    total_loc = 0

    file_stems: set[str] = set()
    file_deps_map: dict[str, list[str]] = {}

    for fp in sorted(repo.rglob("*")):
        if fp.suffix not in extensions:
            continue
        try:
            source = fp.read_text(errors="replace")
        except OSError:
            continue

        loc = count_loc(source)
        difficulty, deps = analyser(source)
        rel_path = str(fp.relative_to(repo))

        files.append(_FileStats(path=rel_path, loc=loc, difficulty=difficulty, deps=deps))
        difficulty_counts[difficulty] = difficulty_counts.get(difficulty, 0) + 1
        total_loc += loc

        stem = fp.stem
        file_stems.add(stem)
        file_deps_map[stem] = deps

    cycles = _detect_circular_deps(file_deps_map, file_stems)

    return {
        "repo": str(repo),
        "lang": lang,
        "total_files": len(files),
        "total_loc": total_loc,
        "difficulty": difficulty_counts,
        "circular_dependencies": cycles,
        "files": [
            {
                "path": f.path,
                "loc": f.loc,
                "difficulty": f.difficulty,
                "deps": f.deps,
            }
            for f in files
        ],
    }


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="repo_analysis",
        description="Analyse a source repo for transpilation readiness.",
    )
    parser.add_argument("repo", type=Path, help="Root directory of the repository.")
    parser.add_argument(
        "--lang",
        choices=["cpp", "python"],
        default="cpp",
        help="Source language (default: cpp).",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Write JSON report to this file (default: stdout).",
    )
    args = parser.parse_args(argv)

    if not args.repo.exists() or not args.repo.is_dir():
        print(f"Error: {args.repo} is not a directory.", file=sys.stderr)
        return 1

    report = analyse_repo(args.repo, args.lang)
    json_str = json.dumps(report, indent=2)

    if args.output:
        args.output.write_text(json_str)
        print(f"Report written to {args.output}", file=sys.stderr)
    else:
        print(json_str)

    # Print a brief summary to stderr
    print(
        f"\nSummary: {report['total_files']} files, "
        f"{report['total_loc']} LOC  "
        f"[easy={report['difficulty']['easy']} "
        f"medium={report['difficulty']['medium']} "
        f"hard={report['difficulty']['hard']} "
        f"very_hard={report['difficulty']['very_hard']}]",
        file=sys.stderr,
    )
    if report["circular_dependencies"]:
        print(
            f"  Circular dependencies detected: {len(report['circular_dependencies'])}",
            file=sys.stderr,
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
