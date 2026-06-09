"""End-to-end CLI: source file in, target source out, verified.

Usage:
    transpile <source> [--source python|c] [--target rust|zig]
                       [--verify] [--fidelity structural|idiomatic]
                       [--infer-with-llm]

Source language is inferred from the file extension (.py, .c) unless --source
is given. Target defaults to rust.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from transpilers.llm import LlmClient, make_llm_inferencer, make_llm_renamer

# Canonical registries live in the stage-decomposed pipeline; re-exported here
# because tests and scripts import them from this module.
from transpilers.pipeline.stages import (  # noqa: F401  (re-exports)
    EXT_TO_SOURCE,
    FRONTENDS,
    TARGETS,
    run_stages,
)


def transpile(
    source: str,
    *,
    source_lang: str = "python",
    target: str = "rust",
    llm_fill=None,
    llm_rename_fill=None,
    ir_hints=None,
) -> str:
    return run_stages(
        source,
        source_lang=source_lang,
        target=target,
        llm_fill=llm_fill,
        llm_rename_fill=llm_rename_fill,
        ir_hints=ir_hints,
    ).output


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


def transpile_cpp_via_python(
    source: str,
    target: str,
    *,
    llm_fill=None,
    ir_hints=None,
) -> tuple[str, str]:
    """Python-as-pivot: C++ → Python (stage 1), Python → <target> (stage 2).

    Returns (python_pivot, final_output) for any supported target (mojo, rust,
    c, zig, go, fortran, python).

    Routing through Python as a shared IR — the "Python-as-pivot" path
    validated by the CodePivot paper (arXiv:2604.18027) — replaces N×M direct
    language pairs with N + M stages. The Python produced in stage 1 is an
    explicit, readable intermediate that can be inspected or edited before the
    second stage converts it to the final target.

    ``ir_hints`` (LLVM-IR-derived type hints) only apply to stage 1, since they
    are extracted from the original C/C++ source.
    """
    python_code = transpile(source, source_lang="cpp", target="python", llm_fill=llm_fill, ir_hints=ir_hints)
    final_code = transpile(python_code, source_lang="python", target=target, llm_fill=llm_fill)
    return python_code, final_code


def transpile_cpp_to_python_to_mojo(source: str, *, llm_fill=None, ir_hints=None) -> tuple[str, str]:
    """Two-stage C++ → Python → Mojo. Thin wrapper over the general pivot,
    kept for backward compatibility. Returns (python_intermediate, mojo_output)."""
    return transpile_cpp_via_python(source, "mojo", llm_fill=llm_fill, ir_hints=ir_hints)


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
    parser.add_argument(
        "--llm-rename",
        action="store_true",
        help="ask the LLM to rename opaque locals (Ghidra `local_10` etc.); requires ANTHROPIC_API_KEY",
    )
    parser.add_argument(
        "--ir-augment",
        action="store_true",
        help=(
            "compile the C/C++ source to LLVM IR and use it to pre-populate type holes "
            "before inference (eliminates most UnknownT without LLM calls; requires clang)"
        ),
    )
    parser.add_argument(
        "--fidelity",
        choices=["structural", "idiomatic"],
        default="structural",
        help=(
            "structural (default): with --verify, additionally check that the output's "
            "module/function/control-flow skeleton is isomorphic to the source's; "
            "idiomatic: skip the skeleton gate, allowing parent-level rewrites. "
            "Applies to the direct path only."
        ),
    )
    parser.add_argument(
        "--path",
        choices=["direct", "python_pivot"],
        default="direct",
        help=(
            "Translation path: 'direct' (default) performs a single-pass translation; "
            "'python_pivot' routes C++ → Python → <target> via Python as a shared IR "
            "(works with any target; requires a C++ source)."
        ),
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="print intermediate output (e.g. the Python stage when using --path python_pivot)",
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
        # Legacy Fortran/C/C++ sources often carry non-UTF-8 bytes (e.g. the
        # © in author headers, latin-1 names), so decode leniently.
        src_input = args.source.read_text(encoding="utf-8", errors="replace")

    # Both LLM-augmented passes share a single client so they hit the same
    # on-disk cache. Lazy-construct so non-LLM runs never touch credentials.
    client = LlmClient() if (args.infer_with_llm or args.llm_rename) else None
    llm_fill = make_llm_inferencer(client) if (client and args.infer_with_llm) else None
    rename_fill = make_llm_renamer(client) if (client and args.llm_rename) else None

    ir_hints = None
    if args.ir_augment and source_lang in ("c", "cpp"):
        from transpilers.passes.ir_preload import extract_ir_types
        ir_hints = extract_ir_types(args.source)

    # ------------------------------------------------------------------
    # Two-stage python_pivot path: C++ → Python → <target>
    # ------------------------------------------------------------------
    if args.path == "python_pivot":
        if source_lang != "cpp":
            print(
                "--path python_pivot requires a C++ source file",
                file=sys.stderr,
            )
            return 2

        python_ir, out = transpile_cpp_via_python(
            src_input, args.target, llm_fill=llm_fill, ir_hints=ir_hints
        )

        if args.verbose:
            sys.stderr.write("--- Python intermediate ---\n")
            sys.stderr.write(python_ir)
            sys.stderr.write("\n--- end Python intermediate ---\n")

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

    # ------------------------------------------------------------------
    # Default direct path
    # ------------------------------------------------------------------
    trace = run_stages(
        src_input,
        source_lang=source_lang,
        target=args.target,
        llm_fill=llm_fill,
        llm_rename_fill=rename_fill,
        ir_hints=ir_hints,
    )
    out = trace.output
    sys.stdout.write(out)

    if args.verify:
        _, _, verify_fn = TARGETS[args.target]
        result = verify_fn(out)
        if not result.ok:
            sys.stderr.write(f"\n--- {args.target} compiler rejected emitted code ---\n")
            sys.stderr.write(result.stderr)
            return 1
        if args.fidelity == "structural":
            from transpilers.verify.structural import check_structural_fidelity

            report = check_structural_fidelity(trace.hir, trace.lir)
            if not report.ok:
                sys.stderr.write("\n--- structural fidelity check failed ---\n")
                sys.stderr.write(report.summary() + "\n")
                return 1
        sys.stderr.write("\n[verify] ok\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
