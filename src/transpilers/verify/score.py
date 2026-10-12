"""Graded compile score — how far did the candidate get before it was rejected?

A binary compile gate cannot tell "broke on line 3 of 200" from "broke on
line 198 of 200". This module adds a pure, toolchain-free score that can:

* :func:`first_error_line` pulls the first error's line number out of a
  compiler/interpreter's stderr (``None`` when it cannot be parsed).
* :func:`graded_compile_score` turns that into a number: a clean compile
  scores :data:`CLEAN_SCORE`; a rejection scores
  ``first_error_line / (n_lines + 1)``, so a later first error scores higher.
  An optional length factor discourages truncated or padded output.

The shape of the score follows the graded compile reward described for
CoTran (a published idea, not code); the implementation here is independent.
It is a ranking signal only — nothing in the verify gates depends on it.
"""

from __future__ import annotations

import math
import re

__all__ = [
    "CLEAN_SCORE",
    "first_error_line",
    "graded_compile_score",
    "length_factor",
    "score_compile",
]

# Score of a candidate the compiler accepted. Strictly above any rejection
# score, which is always < 1.
CLEAN_SCORE = 2.0


# --------------------------------------------------------------------------- #
# First-error line extraction
# --------------------------------------------------------------------------- #

# rustc: a header line (``error[E0425]: ...`` / ``warning: ...``) followed by
# `` --> path:LINE:COL``. Only the location after an *error* header counts.
_RUSTC_HEADER_RE = re.compile(r"^(error|warning)(?:\[\w+\])?:")
_RUSTC_LOC_RE = re.compile(r"^\s*-->\s+.+?:(?P<line>\d+):\d+\s*$")

# gcc / clang / mojo: ``path:LINE:COL: error: msg`` (column is optional, and
# gcc says ``fatal error`` for some). Lazy path so Windows ``C:\..`` is fine.
_CC_ERROR_RE = re.compile(r"^.+?:(?P<line>\d+)(?::\d+)?: (?:fatal )?error:")

# gfortran prints the location on its own line (``path:LINE:COL:`` — older
# releases use ``LINE.COL``), then a source snippet, then ``Error: msg``. The
# same header shape precedes warnings, so remember it until the verdict line.
_GFORTRAN_LOC_RE = re.compile(r"^.+?:(?P<line>\d+)[:.]\d+(?:-\d+)?:\s*$")
_GFORTRAN_ERROR_RE = re.compile(r"^(?:Fatal )?Error:")

# Python SyntaxError, both as the interpreter prints it
# (``  File "x.py", line 2``) and as ``verify.python`` reports it
# (``<msg> at line 2``). Only tried when no native-compiler format matched.
_PY_TRACEBACK_RE = re.compile(r'^\s*File ".*", line (?P<line>\d+)')
_PY_VERIFY_RE = re.compile(r" at line (?P<line>\d+)\s*$")


def first_error_line(stderr: str) -> int | None:
    """1-based line of the first *error* in *stderr*, or ``None``.

    Understands rustc, gcc/clang, mojo, gfortran and Python ``SyntaxError``
    output. Warnings and notes are skipped. "First" means first reported, not
    smallest line number. Anything unparseable (no location, an unknown
    format, a missing toolchain message) yields ``None`` rather than a guess.
    """
    if not stderr:
        return None

    rustc_error = False  # last rustc header seen was an `error`
    gfortran_line: int | None = None  # last gfortran location header
    for raw in stderr.splitlines():
        line = raw.rstrip()
        if m := _RUSTC_HEADER_RE.match(line):
            rustc_error = m.group(1) == "error"
            continue
        if rustc_error and (m := _RUSTC_LOC_RE.match(line)):
            return int(m.group("line"))
        if m := _CC_ERROR_RE.match(line):
            return int(m.group("line"))
        if m := _GFORTRAN_LOC_RE.match(line):
            gfortran_line = int(m.group("line"))
            continue
        if gfortran_line is not None and _GFORTRAN_ERROR_RE.match(line):
            return gfortran_line

    for raw in stderr.splitlines():
        line = raw.rstrip()
        if m := _PY_TRACEBACK_RE.match(line) or _PY_VERIFY_RE.search(line):
            return int(m.group("line"))
    return None


# --------------------------------------------------------------------------- #
# Score
# --------------------------------------------------------------------------- #


def length_factor(hyp_len: float, ref_len: float) -> float:
    """Gaussian penalty on length mismatch, in ``(0, 1]``.

    ``exp(-((hyp_len - ref_len) / sigma)**2 / 2)`` with ``sigma = ref_len / 3``:
    1.0 at equal length, about 0.32 when the candidate is half or one and a
    half times the reference, about 0.011 for empty output, and effectively
    zero at three times the reference length. The unit (lines, tokens, characters) is the
    caller's choice, but must be the same for both arguments. A non-positive
    *ref_len* gives no basis for a penalty, so the factor is 1.0.
    """
    if ref_len <= 0:
        return 1.0
    sigma = ref_len / 3
    return math.exp(-(((hyp_len - ref_len) / sigma) ** 2) / 2)


def graded_compile_score(
    *,
    ok: bool,
    n_lines: int,
    error_line: int | None = None,
    hyp_len: float | None = None,
    ref_len: float | None = None,
) -> float:
    """Score one compile attempt; higher is better.

    * ``ok``: :data:`CLEAN_SCORE` (2.0).
    * rejected with a known *error_line*: ``error_line / (n_lines + 1)``, with
      the line clamped into ``[0, n_lines]`` so the score stays below 1.
    * rejected with an unknown line: ``0.0`` (no evidence it got anywhere).

    When both *hyp_len* and *ref_len* are given the result is multiplied by
    :func:`length_factor`; otherwise no length adjustment is made.
    """
    if ok:
        score = CLEAN_SCORE
    elif error_line is None:
        score = 0.0
    else:
        score = min(max(error_line, 0), max(n_lines, 0)) / (max(n_lines, 0) + 1)
    if hyp_len is not None and ref_len is not None:
        score *= length_factor(hyp_len, ref_len)
    return score


def score_compile(
    code: str,
    *,
    ok: bool,
    stderr: str = "",
    ref_code: str | None = None,
) -> float:
    """Convenience wrapper: score *code* from a verify gate's result.

    Line numbers come from :func:`first_error_line` on *stderr*; lengths for
    the optional length factor are line counts of *code* and *ref_code*.
    """
    n_lines = len(code.splitlines())
    return graded_compile_score(
        ok=ok,
        n_lines=n_lines,
        error_line=None if ok else first_error_line(stderr),
        hyp_len=None if ref_code is None else n_lines,
        ref_len=None if ref_code is None else len(ref_code.splitlines()),
    )
