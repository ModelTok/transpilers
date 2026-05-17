"""End-to-end CLI: source file in, target source out, verified.

Usage:
    transpile <source.py> --target rust [--verify]
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from transpilers.backends.rust import emit_rust
from transpilers.frontends.python import parse_python
from transpilers.passes import hir_to_mir, mir_to_rust_lir
from transpilers.verify import rust_compiles


def transpile_python_to_rust(source: str) -> str:
    hir_mod = parse_python(source)
    mir_mod = hir_to_mir(hir_mod)
    lir_mod = mir_to_rust_lir(mir_mod)
    return emit_rust(lir_mod)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="transpile")
    parser.add_argument("source", type=Path)
    parser.add_argument("--target", choices=["rust"], default="rust")
    parser.add_argument("--verify", action="store_true", help="invoke target compiler on the emitted source")
    args = parser.parse_args(argv)

    src_text = args.source.read_text()
    if args.target != "rust":
        print(f"target {args.target!r} not yet implemented", file=sys.stderr)
        return 2

    rust_source = transpile_python_to_rust(src_text)
    sys.stdout.write(rust_source)

    if args.verify:
        result = rust_compiles(rust_source)
        if not result.ok:
            sys.stderr.write("\n--- rustc rejected emitted code ---\n")
            sys.stderr.write(result.stderr)
            return 1
        sys.stderr.write("\n[verify] ok\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
