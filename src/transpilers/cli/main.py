"""End-to-end CLI: source file in, target source out, verified.

Usage:
    transpile <source> [--source python|c] [--target rust|zig]
                       [--verify] [--infer-with-llm]

Source language is inferred from the file extension (.py, .c) unless --source
is given. Target defaults to rust.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from transpilers.backends.rust import emit_rust
from transpilers.backends.zig import emit_zig
from transpilers.frontends.c import parse_c
from transpilers.frontends.python import parse_python
from transpilers.llm import LlmClient, make_llm_inferencer
from transpilers.passes import hir_to_mir, infer_types, mir_to_rust_lir, mir_to_zig_lir
from transpilers.verify import rust_compiles, zig_compiles


FRONTENDS = {
    "python": parse_python,
    "c": parse_c,
}

EXT_TO_SOURCE = {
    ".py": "python",
    ".c": "c",
    ".h": "c",
}

TARGETS = {
    "rust": (mir_to_rust_lir, emit_rust, rust_compiles),
    "zig": (mir_to_zig_lir, emit_zig, zig_compiles),
}


def transpile(source: str, *, source_lang: str = "python", target: str = "rust", llm_fill=None) -> str:
    parse = FRONTENDS[source_lang]
    lower, emit, _ = TARGETS[target]
    hir_mod = parse(source)
    mir_mod = hir_to_mir(hir_mod)
    infer_types(mir_mod, llm_fill=llm_fill)
    return emit(lower(mir_mod))


# Convenience wrappers — kept stable for tests and external callers.
def transpile_python_to_rust(source: str, *, llm_fill=None) -> str:
    return transpile(source, source_lang="python", target="rust", llm_fill=llm_fill)


def transpile_python_to_zig(source: str, *, llm_fill=None) -> str:
    return transpile(source, source_lang="python", target="zig", llm_fill=llm_fill)


def transpile_c_to_rust(source: str, *, llm_fill=None) -> str:
    return transpile(source, source_lang="c", target="rust", llm_fill=llm_fill)


def transpile_c_to_zig(source: str, *, llm_fill=None) -> str:
    return transpile(source, source_lang="c", target="zig", llm_fill=llm_fill)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="transpile")
    parser.add_argument("source", type=Path)
    parser.add_argument("--source", dest="source_lang", choices=sorted(FRONTENDS), default=None)
    parser.add_argument("--target", choices=sorted(TARGETS), default="rust")
    parser.add_argument("--verify", action="store_true", help="invoke target compiler on the emitted source")
    parser.add_argument(
        "--infer-with-llm",
        action="store_true",
        help="when algorithmic inference can't resolve a hole, ask the LLM (requires ANTHROPIC_API_KEY)",
    )
    args = parser.parse_args(argv)

    src_text = args.source.read_text()
    source_lang = args.source_lang or EXT_TO_SOURCE.get(args.source.suffix)
    if source_lang is None:
        print(
            f"can't infer source language from {args.source.suffix!r}; pass --source",
            file=sys.stderr,
        )
        return 2

    llm_fill = make_llm_inferencer(LlmClient()) if args.infer_with_llm else None
    out = transpile(src_text, source_lang=source_lang, target=args.target, llm_fill=llm_fill)
    sys.stdout.write(out)

    if args.verify:
        _, _, verify_fn = TARGETS[args.target]
        result = verify_fn(out)
        if not result.ok:
            sys.stderr.write(f"\n--- {args.target} compiler rejected emitted code ---\n")
            sys.stderr.write(result.stderr)
            return 1
        sys.stderr.write("\n[verify] ok\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
