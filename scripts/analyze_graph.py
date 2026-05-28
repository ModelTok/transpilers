#!/usr/bin/env python3
"""CLI: build a directed call graph from source files and emit a JSON report.

Usage
-----
    python scripts/analyze_graph.py path/to/dir --lang cpp --output graph.json
    python scripts/analyze_graph.py path/to/dir --lang python
    python scripts/analyze_graph.py path/to/dir --lang cpp --translated src/utils.cpp

Options
-------
--lang          Source language: cpp (default) or python.
--output        Where to save the graph JSON (default: graph.json).
--translated    Comma-separated list of already-translated function names;
                used to produce a migration progress report.
--order         Print topological ordering of functions to stdout.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

# Allow running as a script without installing the package.
_REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(_REPO_ROOT / "src"))

from transpilers.graph.code_graph import (
    build_graph,
    migration_report,
    save_graph,
    topological_order,
)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="analyze_graph",
        description="Build a directed call graph from source files.",
    )
    parser.add_argument("path", type=Path, help="Source directory or file to analyse.")
    parser.add_argument(
        "--lang",
        choices=["cpp", "python"],
        default="cpp",
        help="Source language (default: cpp).",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("graph.json"),
        help="Output path for the JSON graph (default: graph.json).",
    )
    parser.add_argument(
        "--translated",
        default="",
        help="Comma-separated list of already-translated function names.",
    )
    parser.add_argument(
        "--order",
        action="store_true",
        help="Print topological order of functions to stdout.",
    )
    args = parser.parse_args(argv)

    if not args.path.exists():
        print(f"Error: path does not exist: {args.path}", file=sys.stderr)
        return 1

    print(f"Building call graph from {args.path} (lang={args.lang}) …", file=sys.stderr)
    G = build_graph(args.path, lang=args.lang)
    print(
        f"  {G.number_of_nodes()} nodes, {G.number_of_edges()} edges", file=sys.stderr
    )

    save_graph(G, args.output)
    print(f"Graph saved to {args.output}", file=sys.stderr)

    translated: set[str] = {
        name.strip() for name in args.translated.split(",") if name.strip()
    }
    report = migration_report(G, translated)

    summary = {
        "path": str(args.path),
        "lang": args.lang,
        "graph_file": str(args.output),
        "nodes": G.number_of_nodes(),
        "edges": G.number_of_edges(),
        "migration": report,
    }
    print(json.dumps(summary, indent=2))

    if args.order:
        print("\nTopological order (callees first):", file=sys.stderr)
        for func in topological_order(G):
            print(f"  {func}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
