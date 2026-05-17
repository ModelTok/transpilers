"""End-to-end CLI: source file in, target source out, verified.

Usage:
    transpile <source.py> [--target rust|zig] [--verify] [--infer-with-llm]
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from transpilers.backends.rust import emit_rust
from transpilers.backends.zig import emit_zig
from transpilers.frontends.python import parse_python
from transpilers.llm import LlmClient, make_llm_inferencer
from transpilers.passes import hir_to_mir, infer_types, mir_to_rust_lir, mir_to_zig_lir
from transpilers.verify import rust_compiles, zig_compiles


def _to_mir(source: str, llm_fill=None):
    hir_mod = parse_python(source)
    mir_mod = hir_to_mir(hir_mod)
    infer_types(mir_mod, llm_fill=llm_fill)
    return mir_mod


def transpile_python_to_rust(source: str, *, llm_fill=None) -> str:
    return emit_rust(mir_to_rust_lir(_to_mir(source, llm_fill)))


def transpile_python_to_zig(source: str, *, llm_fill=None) -> str:
    return emit_zig(mir_to_zig_lir(_to_mir(source, llm_fill)))


TARGETS = {
    "rust": (transpile_python_to_rust, rust_compiles),
    "zig": (transpile_python_to_zig, zig_compiles),
}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="transpile")
    parser.add_argument("source", type=Path)
    parser.add_argument("--target", choices=sorted(TARGETS), default="rust")
    parser.add_argument("--verify", action="store_true", help="invoke target compiler on the emitted source")
    parser.add_argument(
        "--infer-with-llm",
        action="store_true",
        help="when algorithmic inference can't resolve a hole, ask the LLM (requires ANTHROPIC_API_KEY)",
    )
    args = parser.parse_args(argv)

    src_text = args.source.read_text()
    transpile_fn, verify_fn = TARGETS[args.target]

    llm_fill = make_llm_inferencer(LlmClient()) if args.infer_with_llm else None
    out = transpile_fn(src_text, llm_fill=llm_fill)
    sys.stdout.write(out)

    if args.verify:
        result = verify_fn(out)
        if not result.ok:
            sys.stderr.write(f"\n--- {args.target} compiler rejected emitted code ---\n")
            sys.stderr.write(result.stderr)
            return 1
        sys.stderr.write("\n[verify] ok\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
