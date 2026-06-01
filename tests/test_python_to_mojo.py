"""Python -> Mojo pipeline tests. Mojo's syntax is closest to Python of any
target, so emission is mostly verbatim — except `def` (Mojo) vs `def` (Python)
with type annotations required, `var` declarations for locals, and explicit
typed signatures."""

from __future__ import annotations

import shutil
import textwrap

import pytest

from transpilers.cli.main import transpile_python_to_mojo
from transpilers.verify import mojo_compiles


def _m(src: str) -> str:
    return transpile_python_to_mojo(textwrap.dedent(src).lstrip())


def _has_mojo() -> bool:
    return shutil.which("mojo") is not None


def test_mojo_basic_emission():
    out = _m("def add(a: int, b: int) -> int:\n    return a + b\n")
    assert "def add(a: Int, b: Int) -> Int:" in out
    assert "return a + b" in out


def test_mojo_var_for_local_declaration():
    out = _m(
        """
        def factorial(n: int) -> int:
            result: int = 1
            i: int = 1
            while i <= n:
                result = result * i
                i = i + 1
            return result
        """
    )
    assert "var result: Int = 1" in out
    assert "var i: Int = 1" in out
    assert "while i <= n:" in out


def test_mojo_for_range():
    out = _m(
        """
        def sum_to(n: int) -> int:
            total: int = 0
            for i in range(n):
                total = total + i
            return total
        """
    )
    assert "for i in range(0, n):" in out


def test_mojo_bool_type():
    out = _m("def gt(a: int, b: int) -> bool:\n    return a > b\n")
    assert "-> Bool:" in out


def test_mojo_math_import_is_idiomatic():
    """cmath intrinsics use `from math import <names>` (bare calls), not the
    non-idiomatic `import math` + module-qualified `math.sqrt`."""
    import tempfile
    from transpilers.levels import transpile_level

    p = tempfile.mktemp(suffix=".cpp")
    with open(p, "w") as f:
        f.write("double f(double x){ return std::sqrt(x) + std::exp(x); }")
    out = transpile_level("file", p, target="mojo", engine="strict")[0].output
    assert "from math import exp, sqrt" in out
    assert "math.sqrt" not in out and "import math\n" not in out
    assert "sqrt(x)" in out


def test_mojo_inferred_unannotated_python():
    """Algorithmic inference still drives the Mojo target — same MIR."""
    out = _m(
        """
        def add_one(x):
            return x + 1
        """
    )
    assert "def add_one(x: Int) -> Int:" in out


@pytest.mark.skipif(not _has_mojo(), reason="mojo not installed")
@pytest.mark.parametrize(
    "src",
    [
        "def add(a: int, b: int) -> int:\n    return a + b\n",
        """
        def max2(a: int, b: int) -> int:
            if a > b:
                return a
            else:
                return b
        """,
        """
        def factorial(n: int) -> int:
            result: int = 1
            i: int = 1
            while i <= n:
                result = result * i
                i = i + 1
            return result
        """,
        """
        def sum_to(n: int) -> int:
            total: int = 0
            for i in range(n):
                total = total + i
            return total
        """,
    ],
)
def test_python_to_mojo_compiles(src: str):
    out = _m(src)
    result = mojo_compiles(out)
    assert result.ok, f"mojo rejected:\n{out}\n\nstderr:\n{result.stderr}"
