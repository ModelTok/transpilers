"""Verify emitted Python source by compiling it via the host interpreter."""

from __future__ import annotations

from dataclasses import dataclass


@dataclass
class CompileResult:
    ok: bool
    stderr: str


def python_compiles(source: str) -> CompileResult:
    """Use Python's builtin `compile()` to byte-compile. That validates syntax
    and basic name-resolution-time concerns without running the code."""
    try:
        compile(source, "<emitted>", "exec")
    except SyntaxError as e:
        return CompileResult(ok=False, stderr=f"{e.msg} at line {e.lineno}")
    return CompileResult(ok=True, stderr="")
