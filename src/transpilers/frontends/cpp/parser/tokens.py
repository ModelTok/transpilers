"""Token / source-location / operator helpers (leaf utility)."""
from __future__ import annotations

import clang.cindex as ci

CursorKind = ci.CursorKind

def _strip_unexposed(cursor: ci.Cursor) -> ci.Cursor:
    """Recurse past UNEXPOSED_EXPR wrappers libclang inserts for things
    like implicit conversions — they hide the real operator kind."""
    while cursor.kind == CursorKind.UNEXPOSED_EXPR:
        inner = list(cursor.get_children())
        if not inner:
            return cursor
        cursor = inner[0]
    return cursor

COMPARE_OPS = {"==", "!=", "<", "<=", ">", ">="}

ARITH_OPS = {"+", "-", "*", "/", "%"}

LOGICAL_OPS = {"&&", "||"}

ASSIGN_OPS = {"=", "+=", "-=", "*=", "/=", "%=", "&=", "|=", "^=", "<<=", ">>="}

def _decl_name(cursor: ci.Cursor) -> str | None:
    """Find the identifier name behind a DeclRefExpr / nested unwrapping."""
    if cursor.kind == CursorKind.DECL_REF_EXPR:
        return cursor.spelling
    if cursor.kind in (CursorKind.UNEXPOSED_EXPR, CursorKind.PAREN_EXPR):
        kids = list(cursor.get_children())
        if len(kids) == 1:
            return _decl_name(kids[0])
    return None

def _binop_token(cursor: ci.Cursor) -> str:
    """The operator token sits between the two child cursors. We slice
    tokens by their source position to find it.

    BINARY_OPERATOR has no direct `.operator` accessor in older libclang
    bindings; we use tokens for portability."""
    kids = list(cursor.get_children())
    if len(kids) != 2:
        raise UnsupportedConstruct(f"binary operator with {len(kids)} children")
    left_end = kids[0].extent.end
    right_start = kids[1].extent.start
    for tok in cursor.get_tokens():
        loc = tok.location
        if _loc_ge(loc, left_end) and _loc_lt(loc, right_start):
            return tok.spelling
    raise UnsupportedConstruct("could not locate binary-operator token")

def _unary_token(cursor: ci.Cursor) -> str:
    """For a unary op, the operator is either before or after the single
    operand. We pick whichever non-operand token we find first within the
    cursor's extent."""
    kids = list(cursor.get_children())
    if len(kids) != 1:
        raise UnsupportedConstruct(f"unary operator with {len(kids)} children")
    operand = kids[0]
    o_start, o_end = operand.extent.start, operand.extent.end
    for tok in cursor.get_tokens():
        loc = tok.location
        if not (_loc_ge(loc, o_start) and _loc_lt(loc, o_end)):
            return tok.spelling
    raise UnsupportedConstruct("could not locate unary-operator token")

def _loc_ge(a: ci.SourceLocation, b: ci.SourceLocation) -> bool:
    return (a.line, a.column) >= (b.line, b.column)

def _loc_lt(a: ci.SourceLocation, b: ci.SourceLocation) -> bool:
    return (a.line, a.column) < (b.line, b.column)


__all__ = ['_strip_unexposed', 'COMPARE_OPS', 'ARITH_OPS', 'LOGICAL_OPS', 'ASSIGN_OPS', '_decl_name', '_binop_token', '_unary_token', '_loc_ge', '_loc_lt']
