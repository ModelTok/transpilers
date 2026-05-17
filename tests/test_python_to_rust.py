"""End-to-end Python -> Rust pipeline tests. Validates the full HIR/MIR/LIR/emit
flow and that the emitted code compiles with rustc."""

from __future__ import annotations

import shutil
import textwrap

import pytest

from transpilers.cli.main import transpile_python_to_rust
from transpilers.verify import rust_compiles


def _t(src: str) -> str:
    return transpile_python_to_rust(textwrap.dedent(src).lstrip())


def _compile(src: str) -> None:
    out = _t(src)
    if shutil.which("rustc") is None:
        pytest.skip("rustc not installed")
    result = rust_compiles(out)
    assert result.ok, f"rustc failed for:\n{out}\n\nstderr:\n{result.stderr}"


# ---------- baseline ----------

def test_add_emits_expected_rust():
    out = _t("def add(a: int, b: int) -> int:\n    return a + b\n")
    assert "fn add(a: i64, b: i64) -> i64" in out
    assert "return a + b;" in out


def test_muladd_uses_correct_precedence():
    out = _t("def muladd(a: int, b: int, c: int) -> int:\n    return a * b + c\n")
    assert "return a * b + c;" in out


def test_missing_annotation_surfaces_a_hole():
    """Algorithmic path must refuse to invent. The LLM/inference pass is where
    holes get filled; emission of an UnknownT is a bug."""
    with pytest.raises(ValueError, match="unresolved type hole"):
        _t("def f(a, b):\n    return a + b\n")


# ---------- control flow ----------

def test_if_else():
    src = """
    def max2(a: int, b: int) -> int:
        if a > b:
            return a
        else:
            return b
    """
    out = _t(src)
    assert "if a > b {" in out
    assert "} else {" in out


def test_elif_collapses_to_else_if():
    src = """
    def sign(x: int) -> int:
        if x > 0:
            return 1
        elif x < 0:
            return -1
        else:
            return 0
    """
    out = _t(src)
    assert "} else if x < 0i64 {" in out


def test_while_with_mutability_inferred():
    src = """
    def factorial(n: int) -> int:
        result: int = 1
        i: int = 1
        while i <= n:
            result = result * i
            i = i + 1
        return result
    """
    out = _t(src)
    assert "let mut result: i64 = 1i64;" in out
    assert "let mut i: i64 = 1i64;" in out
    assert "while i <= n {" in out
    assert "result = result * i;" in out


def test_for_range_accumulator():
    src = """
    def sum_range(n: int) -> int:
        total: int = 0
        for i in range(n):
            total = total + i
        return total
    """
    out = _t(src)
    assert "let mut total: i64 = 0i64;" in out
    assert "for i in 0i64..n {" in out


def test_for_range_two_args():
    src = """
    def sum_to(a: int, b: int) -> int:
        total: int = 0
        for i in range(a, b):
            total = total + i
        return total
    """
    out = _t(src)
    assert "for i in a..b {" in out


# ---------- expressions ----------

def test_bool_literals_and_comparison():
    src = """
    def is_positive(x: int) -> bool:
        return x > 0
    """
    out = _t(src)
    assert "fn is_positive(x: i64) -> bool" in out
    assert "return x > 0i64;" in out


def test_boolean_ops_translate_to_rust():
    src = """
    def in_range(x: int, lo: int, hi: int) -> bool:
        return x >= lo and x <= hi
    """
    out = _t(src)
    assert "x >= lo && x <= hi" in out


def test_unary_not_and_neg():
    src = """
    def neither(a: bool, b: bool) -> bool:
        return not a and not b
    """
    out = _t(src)
    assert "!a && !b" in out


# ---------- lists ----------

def test_list_literal_and_index_and_len():
    src = """
    def sum_first(xs: list[int]) -> int:
        return xs[0] + xs[1]
    """
    out = _t(src)
    assert "fn sum_first(xs: Vec<i64>) -> i64" in out
    assert "xs[0i64 as usize]" in out


def test_len_with_cast_to_i64():
    src = """
    def total(xs: list[int]) -> int:
        return len(xs)
    """
    out = _t(src)
    assert "xs.len() as i64" in out


def test_iterate_list_by_index():
    src = """
    def sum_list(xs: list[int]) -> int:
        total: int = 0
        for i in range(len(xs)):
            total = total + xs[i]
        return total
    """
    out = _t(src)
    assert "for i in 0i64..xs.len() as i64 {" in out
    assert "xs[i as usize]" in out


# ---------- compile checks: every construct produces real Rust ----------

@pytest.mark.parametrize(
    "src",
    [
        "def add(a: int, b: int) -> int:\n    return a + b\n",
        # if/else
        """
        def max2(a: int, b: int) -> int:
            if a > b:
                return a
            else:
                return b
        """,
        # while + mut
        """
        def factorial(n: int) -> int:
            result: int = 1
            i: int = 1
            while i <= n:
                result = result * i
                i = i + 1
            return result
        """,
        # for-range accumulator
        """
        def sum_range(n: int) -> int:
            total: int = 0
            for i in range(n):
                total = total + i
            return total
        """,
        # lists + len + indexing
        """
        def sum_list(xs: list[int]) -> int:
            total: int = 0
            for i in range(len(xs)):
                total = total + xs[i]
            return total
        """,
        # boolean ops
        """
        def in_range(x: int, lo: int, hi: int) -> bool:
            return x >= lo and x <= hi
        """,
    ],
)
def test_emitted_rust_compiles(src: str):
    _compile(src)
