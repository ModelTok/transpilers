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

from transpilers.backends.c import emit_c
from transpilers.backends.go import emit_go
from transpilers.backends.mojo import emit_mojo
from transpilers.backends.python import emit_python
from transpilers.backends.rust import emit_rust
from transpilers.backends.zig import emit_zig
from transpilers.frontends.asm import parse_asm
from transpilers.frontends.c import parse_c
from transpilers.frontends.cpp import parse_cpp
from transpilers.frontends.csharp import parse_csharp
from transpilers.frontends.fortran import parse_fortran
from transpilers.frontends.go import parse_go
from transpilers.frontends.java import parse_java
from transpilers.frontends.javascript import parse_javascript
from transpilers.frontends.python import parse_python
from transpilers.frontends.typescript import parse_typescript
from transpilers.frontends.vb import parse_vb
from transpilers.llm import LlmClient, make_llm_inferencer
from transpilers.passes import (
    hir_to_mir,
    infer_types,
    mir_to_c_lir,
    mir_to_go_lir,
    mir_to_mojo_lir,
    mir_to_python_lir,
    mir_to_rust_lir,
    mir_to_zig_lir,
)
from transpilers.verify import (
    c_compiles,
    go_compiles,
    mojo_compiles,
    python_compiles,
    rust_compiles,
    zig_compiles,
)


FRONTENDS = {
    "python": parse_python,
    "c": parse_c,
    "cpp": parse_cpp,
    "java": parse_java,
    "csharp": parse_csharp,
    "typescript": parse_typescript,
    "javascript": parse_javascript,
    "fortran": parse_fortran,
    "go": parse_go,
    "vb": parse_vb,
    "asm": parse_asm,
}

EXT_TO_SOURCE = {
    ".py": "python",
    ".c": "c",
    ".h": "c",
    ".cpp": "cpp",
    ".cc": "cpp",
    ".cxx": "cpp",
    ".hpp": "cpp",
    ".hh": "cpp",
    ".java": "java",
    ".cs": "csharp",
    ".ts": "typescript",
    ".js": "javascript",
    ".mjs": "javascript",
    ".f90": "fortran",
    ".f95": "fortran",
    ".f03": "fortran",
    ".f": "fortran",
    ".go": "go",
    ".vb": "vb",
    ".vbs": "vb",
    ".asm": "asm",
    ".s": "asm",
    ".S": "asm",
}

TARGETS = {
    "rust": (mir_to_rust_lir, emit_rust, rust_compiles),
    "zig": (mir_to_zig_lir, emit_zig, zig_compiles),
    "c": (mir_to_c_lir, emit_c, c_compiles),
    "mojo": (mir_to_mojo_lir, emit_mojo, mojo_compiles),
    "go": (mir_to_go_lir, emit_go, go_compiles),
    "python": (mir_to_python_lir, emit_python, python_compiles),
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


def transpile_python_to_c(source: str, *, llm_fill=None) -> str:
    return transpile(source, source_lang="python", target="c", llm_fill=llm_fill)


def transpile_c_to_c(source: str, *, llm_fill=None) -> str:
    return transpile(source, source_lang="c", target="c", llm_fill=llm_fill)


def transpile_python_to_mojo(source: str, *, llm_fill=None) -> str:
    return transpile(source, source_lang="python", target="mojo", llm_fill=llm_fill)


def transpile_c_to_mojo(source: str, *, llm_fill=None) -> str:
    return transpile(source, source_lang="c", target="mojo", llm_fill=llm_fill)


def transpile_cpp_to_mojo(source: str, *, llm_fill=None) -> str:
    return transpile(source, source_lang="cpp", target="mojo", llm_fill=llm_fill)


def transpile_cpp_to_rust(source: str, *, llm_fill=None) -> str:
    return transpile(source, source_lang="cpp", target="rust", llm_fill=llm_fill)


def transpile_cpp_to_zig(source: str, *, llm_fill=None) -> str:
    return transpile(source, source_lang="cpp", target="zig", llm_fill=llm_fill)


def transpile_cpp_to_c(source: str, *, llm_fill=None) -> str:
    return transpile(source, source_lang="cpp", target="c", llm_fill=llm_fill)


# Convenience wrappers for the new frontends. Targets are picked at the call
# site; tests assemble the pairs they need.
def transpile_java(source: str, target: str = "rust", *, llm_fill=None) -> str:
    return transpile(source, source_lang="java", target=target, llm_fill=llm_fill)


def transpile_csharp(source: str, target: str = "rust", *, llm_fill=None) -> str:
    return transpile(source, source_lang="csharp", target=target, llm_fill=llm_fill)


def transpile_typescript(source: str, target: str = "rust", *, llm_fill=None) -> str:
    return transpile(source, source_lang="typescript", target=target, llm_fill=llm_fill)


def transpile_javascript(source: str, target: str = "rust", *, llm_fill=None) -> str:
    return transpile(source, source_lang="javascript", target=target, llm_fill=llm_fill)


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

    source_lang = args.source_lang or EXT_TO_SOURCE.get(args.source.suffix)
    if source_lang is None:
        # Binaries with no extension fall through here — default to asm so
        # the staged-Ghidra path picks them up.
        if not args.source.suffix:
            source_lang = "asm"
        else:
            print(
                f"can't infer source language from {args.source.suffix!r}; pass --source",
                file=sys.stderr,
            )
            return 2

    # Asm frontend takes a path string (not text content), since the input
    # may be a non-UTF-8 binary that read_text would reject.
    if source_lang == "asm":
        src_input = str(args.source)
    else:
        src_input = args.source.read_text()

    llm_fill = make_llm_inferencer(LlmClient()) if args.infer_with_llm else None
    out = transpile(src_input, source_lang=source_lang, target=args.target, llm_fill=llm_fill)
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
