"""Tests for the graded compile score (verify/score.py).

Fixture provenance: the rustc and Python strings are real compiler output
(captured from rustc/CPython, paths shortened). The gcc/clang, mojo and
gfortran strings are written from those tools' documented diagnostic formats
and have NOT been checked against a live toolchain here (none installed), so
treat them as realistic fixtures rather than captures.
"""

from __future__ import annotations

import math
import shutil

import pytest

from transpilers.repair import signal_from_compile
from transpilers.verify.python import python_compiles
from transpilers.verify.rust import rust_compiles
from transpilers.verify.score import (
    CLEAN_SCORE,
    first_error_line,
    graded_compile_score,
    length_factor,
    score_compile,
)
from transpilers.verify.taxonomy import classify_unit

# --------------------------------------------------------------------------- #
# first_error_line
# --------------------------------------------------------------------------- #

RUSTC_TYPE_AND_NAME = """\
error[E0308]: mismatched types
 --> lib.rs:2:18
  |
2 |     let x: i32 = "a";
  |            ---   ^^^ expected `i32`, found `&str`
  |            |
  |            expected due to this

error[E0425]: cannot find function `undefined_fn` in this scope
 --> lib.rs:3:13
  |
3 |     let y = undefined_fn();
  |             ^^^^^^^^^^^^ not found in this scope

error: aborting due to 2 previous errors
"""

# A warning is emitted *after* the error here, and one before it below.
RUSTC_WARNING_FIRST = """\
warning: unused variable: `unused`
 --> lib.rs:1:14
  |
1 | fn a() { let unused = 1; }
  |              ^^^^^^ help: if this is intentional, prefix it with an underscore: `_unused`

error: expected expression, found `}`
 --> lib.rs:4:1
  |
4 | }
  | ^ expected expression

error: aborting due to 1 previous error; 1 warning emitted
"""

GCC_ERROR = """\
lib.c: In function 'f':
lib.c:7:12: error: 'y' undeclared (first use in this function)
    7 |     return y;
      |            ^
lib.c:7:12: note: each undeclared identifier is reported only once
"""

GCC_WARNING_THEN_ERROR = """\
lib.c:3:9: warning: unused variable 'u' [-Wunused-variable]
lib.c:9:5: error: expected ';' before '}' token
"""

CLANG_WINDOWS_PATH = (
    "C:\\Temp\\lib.c:12:3: error: use of undeclared identifier 'z'\n  12 |   z = 1;\n"
)

MOJO_ERROR = """\
/tmp/tmpab12/lib.mojo:5:10: error: use of unknown declaration 'foo'
    return foo(x)
           ^~~
mojo: error: failed to parse the provided Mojo source module
"""

GFORTRAN_ERROR = """\
lib.f90:4:12:

    4 |   integer :: x = 
      |            1
Error: Unclassifiable statement at (1)
"""

GFORTRAN_OLD_DOT_FORM = """\
lib.f90:6.9:

      y = z +
         1
Error: Invalid character in name at (1)
"""

GFORTRAN_WARNING_ONLY_THEN_ERROR = """\
lib.f90:2:7:

    2 |   real :: a
      |       1
Warning: Unused variable 'a' declared at (1) [-Wunused-variable]
lib.f90:8:3:

    8 |   foo
      |   1
Error: Unclassifiable statement at (1)
"""

PY_VERIFY_FORMAT = "'(' was never closed at line 2"

PY_TRACEBACK = """\
  File "<emitted>", line 3
    y = (2 +
        ^
SyntaxError: '(' was never closed
"""


@pytest.mark.parametrize(
    ("stderr", "expected"),
    [
        (RUSTC_TYPE_AND_NAME, 2),  # first reported, not the smallest/last
        (RUSTC_WARNING_FIRST, 4),  # warning's `-->` is skipped
        (GCC_ERROR, 7),
        (GCC_WARNING_THEN_ERROR, 9),
        (CLANG_WINDOWS_PATH, 12),
        (MOJO_ERROR, 5),
        (GFORTRAN_ERROR, 4),
        (GFORTRAN_OLD_DOT_FORM, 6),
        (GFORTRAN_WARNING_ONLY_THEN_ERROR, 8),  # warning header must not win
        (PY_VERIFY_FORMAT, 2),
        (PY_TRACEBACK, 3),
    ],
)
def test_first_error_line_per_format(stderr: str, expected: int):
    assert first_error_line(stderr) == expected


@pytest.mark.parametrize(
    "stderr",
    [
        "",
        "no C compiler found on PATH",
        "mojo not found on PATH",
        "no Fortran compiler on PATH",
        "error: aborting due to previous error",  # rustc header, no location
        "lib.c:3:9: warning: unused variable 'u'",  # warning only
        "Error: Cannot open file 'x'",  # gfortran, no location header
        "invalid syntax at line None",  # python verify with lineno None
        "something unexpected",
    ],
)
def test_first_error_line_unparseable_is_none(stderr: str):
    assert first_error_line(stderr) is None


def test_first_error_line_matches_real_python_compile():
    result = python_compiles("x = 1\ny = 2\nz = (3 +\n")
    assert not result.ok
    assert first_error_line(result.stderr) == 3


@pytest.mark.skipif(shutil.which("rustc") is None, reason="rustc not installed")
def test_first_error_line_matches_real_rustc():
    src = (
        'fn a() -> i32 {\n    1\n}\nfn b() -> i32 {\n    let x: i32 = "a";\n    x\n}\n'
    )
    result = rust_compiles(src)
    assert not result.ok
    assert first_error_line(result.stderr) == 5


# --------------------------------------------------------------------------- #
# Score
# --------------------------------------------------------------------------- #


def test_clean_compile_scores_two():
    assert graded_compile_score(ok=True, n_lines=40) == CLEAN_SCORE == 2.0


def test_later_first_error_scores_higher():
    scores = [
        graded_compile_score(ok=False, n_lines=100, error_line=n)
        for n in (1, 10, 50, 100)
    ]
    assert scores == sorted(scores)
    assert len(set(scores)) == len(scores)
    assert scores[0] == pytest.approx(1 / 101)
    # Every rejection scores below a clean pass.
    assert max(scores) < 1.0 < CLEAN_SCORE


def test_unknown_error_line_scores_zero_and_out_of_range_is_clamped():
    assert graded_compile_score(ok=False, n_lines=10, error_line=None) == 0.0
    # Error reported past the end (e.g. in an appended `main` wrapper).
    assert graded_compile_score(ok=False, n_lines=10, error_line=99) == pytest.approx(
        10 / 11
    )
    assert graded_compile_score(ok=False, n_lines=10, error_line=-4) == 0.0


def test_length_factor_equal_length_is_neutral():
    assert length_factor(120, 120) == 1.0
    assert graded_compile_score(
        ok=True, n_lines=120, hyp_len=120, ref_len=120
    ) == pytest.approx(2.0)
    assert graded_compile_score(
        ok=False, n_lines=120, error_line=60, hyp_len=120, ref_len=120
    ) == pytest.approx(60 / 121)


def test_length_factor_penalises_large_mismatch_symmetrically_around_ref():
    # sigma = ref/3, so half / 1.5x length is 1.5 sigma away.
    assert length_factor(50, 100) == pytest.approx(math.exp(-1.125))
    assert length_factor(150, 100) == pytest.approx(math.exp(-1.125))
    assert length_factor(300, 100) < 1e-6  # padded to 3x: effectively zero
    assert 0 < length_factor(0, 100) < 0.02  # empty output: heavily penalised
    # Monotone in distance from the reference.
    assert length_factor(100, 100) > length_factor(90, 100) > length_factor(60, 100)
    # A near-miss with the right length beats a later error at a bad length.
    right_len = graded_compile_score(
        ok=False, n_lines=100, error_line=5, hyp_len=100, ref_len=100
    )
    bad_len = graded_compile_score(
        ok=False, n_lines=100, error_line=90, hyp_len=5, ref_len=100
    )
    assert right_len > bad_len


def test_length_factor_without_usable_reference_is_neutral():
    assert length_factor(10, 0) == 1.0
    assert length_factor(10, -5) == 1.0
    # Only one of the two lengths given: no adjustment.
    assert graded_compile_score(ok=True, n_lines=5, hyp_len=5) == 2.0


def test_score_compile_wrapper_uses_stderr_and_line_counts():
    code = "\n".join(f"line{i}" for i in range(1, 11))  # 10 lines
    assert score_compile(code, ok=True) == 2.0
    assert score_compile(
        code, ok=False, stderr="lib.c:5:1: error: boom"
    ) == pytest.approx(5 / 11)
    assert score_compile(code, ok=False, stderr="unparseable") == 0.0
    # With a reference of the same line count the length factor is neutral.
    assert score_compile(
        code, ok=False, stderr="lib.c:5:1: error: boom", ref_code=code
    ) == pytest.approx(5 / 11)
    # A much longer reference penalises a truncated candidate.
    assert score_compile(code, ok=True, ref_code="\n".join(["x"] * 100)) < 0.1


# --------------------------------------------------------------------------- #
# Wiring: RepairSignal / TaxonomyRecord expose the line
# --------------------------------------------------------------------------- #


def test_signal_from_compile_carries_first_error_line():
    sig = signal_from_compile(RUSTC_TYPE_AND_NAME)
    assert sig.first_error_line == 2
    assert sig.to_prompt_dict()["first_error_line"] == 2


def test_signal_without_parseable_line_defaults_to_none():
    sig = signal_from_compile("error: cannot find value `n`")
    assert sig.first_error_line is None
    assert "first_error_line" not in sig.to_prompt_dict()


def test_taxonomy_record_defaults_first_error_line_to_none():
    from transpilers.verify.taxonomy import TaxonomyRecord

    assert TaxonomyRecord("python", "rust", "ok", "").first_error_line is None


@pytest.mark.skipif(shutil.which("rustc") is None, reason="rustc not installed")
def test_classify_unit_populates_first_error_line_on_compile_failure(monkeypatch):
    from transpilers.pipeline import stages

    def bad_verify(_output):
        return rust_compiles('fn f() -> i32 {\n    "a"\n}\n')

    lower, emit, _ = stages.TARGETS["rust"]
    monkeypatch.setitem(stages.TARGETS, "rust", (lower, emit, bad_verify))
    rec = classify_unit("def f():\n    return 0\n", target="rust")
    assert rec.stage == "compile"
    assert rec.first_error_line == 2
