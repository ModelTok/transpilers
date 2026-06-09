"""Stage-decomposed transpilation pipeline.

The canonical frontend / target registries live here, together with
``run_stages`` — the single-pass pipeline that keeps every intermediate
artifact (HIR, MIR, LIR, emitted text) instead of collapsing straight to a
string. Two consumers need the intermediates:

* the structural-fidelity verifier (``transpilers.verify.structural``)
  compares the source HIR skeleton against the target LIR skeleton;
* the failure taxonomy (``transpilers.verify.taxonomy``) attributes a
  failure to the exact stage that raised.

``transpilers.cli.main`` re-exports ``FRONTENDS`` / ``EXT_TO_SOURCE`` /
``TARGETS`` for backward compatibility and implements ``transpile`` as
``run_stages(...).output``.
"""

from __future__ import annotations

from dataclasses import dataclass

from transpilers.backends.c import emit_c
from transpilers.backends.fortran import emit_fortran
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
from transpilers.ir.hir import HirModule
from transpilers.ir.lir.base import LirNode
from transpilers.ir.mir import MirModule
from transpilers.passes import (
    hir_to_mir,
    infer_types,
    llm_rename,
    mir_to_c_lir,
    mir_to_fortran_lir,
    mir_to_go_lir,
    mir_to_mojo_lir,
    mir_to_python_lir,
    mir_to_rust_lir,
    mir_to_zig_lir,
)
from transpilers.verify import (
    c_compiles,
    fortran_compiles,
    go_compiles,
    mojo_compiles,
    python_compiles,
    rust_compiles,
    zig_compiles,
)

__all__ = [
    "EXT_TO_SOURCE",
    "FRONTENDS",
    "STAGES",
    "TARGETS",
    "StageTrace",
    "run_stages",
]


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
    "fortran": (mir_to_fortran_lir, emit_fortran, fortran_compiles),
}

# Pipeline stage names, in execution order. The taxonomy records which stage
# a failure came from; keep these strings stable — they are reporting keys.
STAGES = ("parse", "hir-to-mir", "infer-types", "lower", "emit", "compile", "run")


@dataclass
class StageTrace:
    """Every intermediate artifact of one source→target transpilation."""

    source_lang: str
    target: str
    hir: HirModule
    mir: MirModule
    lir: LirNode
    output: str


def run_stages(
    source: str,
    *,
    source_lang: str = "python",
    target: str = "rust",
    llm_fill=None,
    llm_rename_fill=None,
    ir_hints=None,
) -> StageTrace:
    """Run the full pipeline, returning all intermediate artifacts.

    Raises whatever the failing stage raises — callers that need failure
    attribution should drive the stages via ``transpilers.verify.taxonomy``.
    """
    parse = FRONTENDS[source_lang]
    lower, emit, _ = TARGETS[target]
    hir_mod = parse(source)
    mir_mod = hir_to_mir(hir_mod)
    infer_types(mir_mod, llm_fill=llm_fill, ir_hints=ir_hints)
    if llm_rename_fill is not None:
        llm_rename(mir_mod, llm_fill=llm_rename_fill)
    lir_mod = lower(mir_mod)
    return StageTrace(
        source_lang=source_lang,
        target=target,
        hir=hir_mod,
        mir=mir_mod,
        lir=lir_mod,
        output=emit(lir_mod),
    )
