"""Declarations prepended to the C++ source before libclang runs, and macro-like unknown types.

The generic preamble stubs the C/C++ standard names libclang would otherwise not resolve; a project
preamble (``$TRANSPILERS_CPP_PREAMBLE`` / ``$TRANSPILERS_CPP_PREAMBLE_FILE``) adds domain typedefs.
"""

from __future__ import annotations

import os as _os
import re as _re

import clang.cindex as ci

_PREAMBLE = """
typedef signed char int8_t; typedef short int16_t; typedef int int32_t;
typedef long long int64_t; typedef unsigned char uint8_t;
typedef unsigned short uint16_t; typedef unsigned int uint32_t;
typedef unsigned long long uint64_t; typedef unsigned long long size_t;
typedef long ssize_t; typedef long ptrdiff_t;
double exp(double); double log(double); double log10(double); double log2(double);
double sqrt(double); double cbrt(double); double pow(double, double);
double sin(double); double cos(double); double tan(double);
double asin(double); double acos(double); double atan(double); double atan2(double, double);
double sinh(double); double cosh(double); double tanh(double);
double fabs(double); double ceil(double); double floor(double); double round(double);
double trunc(double); double fmod(double, double); double hypot(double, double);
double fmin(double, double); double fmax(double, double); double fma(double, double, double);
double max(double, double); double min(double, double);
int max(int, int); int min(int, int); int abs(int); long labs(long);
double clamp(double, double, double); int clamp(int, int, int);
namespace std {
}
"""


def _project_preamble() -> str:
    """Project-specific declarations to prepend (e.g. EnergyPlus `Real64`), so
    domain typedefs resolve without baking them into the general core preamble.
      $TRANSPILERS_CPP_PREAMBLE       — inline declaration text
      $TRANSPILERS_CPP_PREAMBLE_FILE  — path to a declarations file
    """
    inline = _os.environ.get("TRANSPILERS_CPP_PREAMBLE", "")
    path = _os.environ.get("TRANSPILERS_CPP_PREAMBLE_FILE", "")
    if path and _os.path.isfile(path):
        try:
            inline += "\n" + open(path, encoding="utf-8").read()
        except OSError:
            pass
    return ("\n" + inline + "\n") if inline else ""


_PREAMBLE_REAL_MARKER = "// === TRANSPILERS: REAL PREAMBLE BELOW ==="


def _split_project_preamble() -> tuple[str, str]:
    """Split ``_project_preamble()`` into ``(stub_part, real_part)`` at
    ``_PREAMBLE_REAL_MARKER``. ``real_part`` is ``""`` if the preamble has
    no marker (the common case -- most project preambles are parse-only).

    ``real_part`` must land in the final translation unit *after*
    ``PARSER_PREAMBLE`` (the generic std:: shim, also excluded, and itself
    only added later inside ``preprocess_cpp``) and immediately before the
    user's own source -- not where it textually sits in the preamble file,
    right before ``PARSER_PREAMBLE``. ``parse_cpp`` prepends it directly to
    *source* for exactly this reason; see the call site there.
    """
    project = _project_preamble()
    marker_at = project.find(_PREAMBLE_REAL_MARKER)
    if marker_at == -1:
        return project, ""
    return project[:marker_at], project[marker_at:]


def _compute_user_first_line() -> int:
    from .preprocess import PARSER_PREAMBLE

    stub_part, _real_part = _split_project_preamble()
    return len((stub_part + PARSER_PREAMBLE).splitlines())


_UNKNOWN_TYPE_NAME_RE = _re.compile(r"unknown type name '([A-Za-z_][A-Za-z0-9_]*)'")
_SCREAMING_MACRO_RE = _re.compile(r"^[A-Z][A-Z0-9_]*$")
_MACRO_SUFFIX_RE = _re.compile(r"_(EXPORT|IMPORT|API|DLL|DECL)$")


def _macro_like_unknown_types(tu: ci.TranslationUnit) -> set[str]:
    """Names from "unknown type name '...'" diagnostics that look like an
    export / calling-convention macro (``FOO_API``, ``FOO_EXPORT``,
    ``DLLEXPORT``, ``WINAPI``, ``Standard_EXPORT``, ...) rather than a real
    missing type.

    Real-world C++ libraries almost universally gate their public API with
    a macro like this, defined in a header we never see (every #include is
    stripped before libclang runs, by design -- see ``preprocess.py``). Left
    alone, every function/class declaration in the file fails to parse on a
    token that carries no type information at all. SCREAMING_CASE (or a
    SCREAMING_CASE suffix on an otherwise-mixed-case name) is a near-
    universal C/C++ convention for macros and essentially never used for a
    real type name, so treating it as an empty ``-D`` define is safe: it can
    only remove a no-op qualifier, never rename or reinterpret real user
    code.
    """
    names: set[str] = set()
    for d in tu.diagnostics:
        if d.severity < ci.Diagnostic.Error:
            continue
        m = _UNKNOWN_TYPE_NAME_RE.search(d.spelling)
        if not m:
            continue
        name = m.group(1)
        if _SCREAMING_MACRO_RE.match(name) or _MACRO_SUFFIX_RE.search(name):
            names.add(name)
    return names
