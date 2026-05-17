"""End-to-end Python -> Rust slice. Validates the full HIR/MIR/LIR/emit pipeline
and that the emitted code compiles with rustc."""

from __future__ import annotations

import shutil

import pytest

from transpilers.cli.main import transpile_python_to_rust
from transpilers.verify import rust_compiles


def test_add_emits_expected_rust():
    src = "def add(a: int, b: int) -> int:\n    return a + b\n"
    out = transpile_python_to_rust(src)
    assert "fn add(a: i64, b: i64) -> i64" in out
    assert "return a + b;" in out


def test_muladd_uses_correct_precedence():
    src = "def muladd(a: int, b: int, c: int) -> int:\n    return a * b + c\n"
    out = transpile_python_to_rust(src)
    assert "return a * b + c;" in out


@pytest.mark.skipif(shutil.which("rustc") is None, reason="rustc not installed")
def test_emitted_rust_compiles():
    src = "def add(a: int, b: int) -> int:\n    return a + b\n"
    out = transpile_python_to_rust(src)
    result = rust_compiles(out)
    assert result.ok, result.stderr


def test_missing_annotation_surfaces_a_hole():
    """Algorithmic path must refuse to invent. A later LLM/inference pass is
    where the hole gets filled — emission of an UnknownT is a bug."""
    src = "def f(a, b):\n    return a + b\n"
    with pytest.raises(ValueError, match="unresolved type hole"):
        transpile_python_to_rust(src)
