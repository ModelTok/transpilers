"""C++ frontend tests. Validates the third source language flows through the
shared MIR pipeline. Initial C++ subset is deliberately C-like (no classes,
templates, references, namespaces) — those are real C++ features the IR
doesn't model yet."""

from __future__ import annotations

import shutil
import textwrap

import pytest

from transpilers.cli.main import (
    transpile_cpp_to_c,
    transpile_cpp_to_mojo,
    transpile_cpp_to_rust,
    transpile_cpp_to_zig,
)
from transpilers.verify import c_compiles, mojo_compiles, rust_compiles, zig_compiles


def _rust(src: str) -> str:
    return transpile_cpp_to_rust(textwrap.dedent(src).lstrip())


def _zig(src: str) -> str:
    return transpile_cpp_to_zig(textwrap.dedent(src).lstrip())


def _c(src: str) -> str:
    return transpile_cpp_to_c(textwrap.dedent(src).lstrip())


def _mojo(src: str) -> str:
    return transpile_cpp_to_mojo(textwrap.dedent(src).lstrip())


def _has(name: str) -> bool:
    return shutil.which(name) is not None


# ---------- shape ----------

def test_cpp_add_to_rust():
    out = _rust("int add(int a, int b) { return a + b; }")
    assert "fn add(a: i64, b: i64) -> i64" in out


def test_cpp_to_mojo_shape():
    out = _mojo("int add(int a, int b) { return a + b; }")
    assert "def add(a: Int, b: Int) -> Int:" in out
    assert "return a + b" in out


def test_cpp_bool_handled():
    out = _rust("bool is_positive(int x) { return x > 0; }")
    assert "fn is_positive(x: i64) -> bool" in out


def test_cpp_for_loop_desugars():
    out = _rust(
        """
        int sum_to(int n) {
            int total = 0;
            for (int i = 0; i < n; i++) {
                total = total + i;
            }
            return total;
        }
        """
    )
    assert "while i < n {" in out
    assert "i += 1;" in out


def test_cpp_logical_ops_to_mojo():
    out = _mojo("bool both(bool a, bool b) { return a && b; }")
    assert "return a and b" in out


def test_cpp_long_collapses_to_int():
    out = _rust("long sum(long a, long b) { return a + b; }")
    assert "fn sum(a: i64, b: i64) -> i64" in out


# ---------- C++ → Mojo compile checks ----------

@pytest.mark.skipif(not _has("mojo"), reason="mojo not installed")
@pytest.mark.parametrize(
    "src",
    [
        "int add(int a, int b) { return a + b; }",
        """
        int max2(int a, int b) {
            if (a > b) return a;
            else return b;
        }
        """,
        """
        int factorial(int n) {
            int result = 1;
            int i = 1;
            while (i <= n) {
                result = result * i;
                i = i + 1;
            }
            return result;
        }
        """,
        """
        int sum_to(int n) {
            int total = 0;
            for (int i = 0; i < n; i++) {
                total = total + i;
            }
            return total;
        }
        """,
        """
        bool in_range(int x, int lo, int hi) {
            return x >= lo && x <= hi;
        }
        """,
    ],
)
def test_cpp_to_mojo_compiles(src: str):
    out = _mojo(src)
    result = mojo_compiles(out)
    assert result.ok, f"mojo rejected:\n{out}\n\nstderr:\n{result.stderr}"


# ---------- C++ → Rust compile check ----------

@pytest.mark.skipif(not _has("rustc"), reason="rustc not installed")
def test_cpp_to_rust_compiles():
    out = _rust(
        """
        int factorial(int n) {
            int result = 1;
            int i = 1;
            while (i <= n) {
                result = result * i;
                i = i + 1;
            }
            return result;
        }
        """
    )
    result = rust_compiles(out)
    assert result.ok, result.stderr


# ---------- C++ → Zig compile check ----------

@pytest.mark.skipif(not _has("zig"), reason="zig not installed")
def test_cpp_to_zig_compiles():
    out = _zig("int add(int a, int b) { return a + b; }")
    result = zig_compiles(out)
    assert result.ok, result.stderr


# ---------- C++ → C compile check ----------

@pytest.mark.skipif(not _has("cc") and not _has("gcc") and not _has("clang"), reason="no C compiler")
def test_cpp_to_c_compiles():
    """C++ -> C via the shared MIR — the IR is language-agnostic enough that
    this works for the C-compatible subset."""
    out = _c("int add(int a, int b) { return a + b; }")
    assert "int64_t add(int64_t a, int64_t b)" in out
    result = c_compiles(out)
    assert result.ok, result.stderr


# ---------- refusals ----------

def test_cpp_classes_refused():
    """Classes aren't modeled — refuse rather than silently drop the body.
    The actual surfacing happens via libclang parse errors or the top-level
    cursor kind check; either is acceptable as long as we don't emit code."""
    with pytest.raises(Exception):
        _rust("class Point { public: int x; int y; };")


def test_cpp_template_refused():
    with pytest.raises(Exception):
        _rust("template<typename T> T add(T a, T b) { return a + b; }")
