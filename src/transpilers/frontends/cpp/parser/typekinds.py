"""Classify libclang types and expressions as integral or floating."""

from __future__ import annotations

import clang.cindex as ci

CursorKind = ci.CursorKind
_TypeKind = ci.TypeKind
_INTEGRAL_KINDS = frozenset(
    getattr(_TypeKind, k)
    for k in (
        "BOOL",
        "CHAR_U",
        "UCHAR",
        "CHAR16",
        "CHAR32",
        "USHORT",
        "UINT",
        "ULONG",
        "ULONGLONG",
        "UINT128",
        "CHAR_S",
        "SCHAR",
        "WCHAR",
        "SHORT",
        "INT",
        "LONG",
        "LONGLONG",
        "INT128",
        "ENUM",
    )
    if getattr(_TypeKind, k, None) is not None
)
_FLOATING_KINDS = frozenset(
    getattr(_TypeKind, k)
    for k in ("FLOAT", "DOUBLE", "LONGDOUBLE", "FLOAT128")
    if getattr(_TypeKind, k, None) is not None
)


def _is_integral_type(t) -> bool:
    try:
        return t.get_canonical().kind in _INTEGRAL_KINDS
    except Exception:
        return False


def _is_floating_type(t) -> bool:
    try:
        return t.get_canonical().kind in _FLOATING_KINDS
    except Exception:
        return False


def _operand_is_floating(cursor) -> bool:
    cur = cursor
    for _ in range(8):
        if _is_floating_type(cur.type):
            return True
        if cur.kind not in (CursorKind.UNEXPOSED_EXPR, CursorKind.PAREN_EXPR):
            break
        kids = [k for k in cur.get_children() if k.kind != CursorKind.TYPE_REF]
        if not kids:
            break
        cur = kids[-1]
    return _is_floating_type(cur.type)
