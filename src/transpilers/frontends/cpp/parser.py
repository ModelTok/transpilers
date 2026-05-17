"""C++ source -> HIR via libclang.

Initial subset (deliberately C-like C++):
  - free functions with primitive params (int/long/short/char/bool/float/double/void)
  - return, if/else, while, range-based for (C-style with ++)
  - declarations and assignments
  - binary / comparison / logical ops, unary not/neg
  - integer literals, names, calls

Out of scope for the initial slice: classes, templates, references, namespaces,
auto, `std::` types. These are real C++ — the IR doesn't model them yet and we
refuse rather than emit broken code.

Operator extraction uses tokens (not libclang's BinaryOperator extension), so
this works against any reasonably recent libclang.
"""

from __future__ import annotations

import clang.cindex as ci

from transpilers.ir import hir


CursorKind = ci.CursorKind


class UnsupportedConstruct(Exception):
    pass


# C++ types collapsed onto HIR annotation strings consumable by hir_to_mir.
CPP_TYPE_ALIASES: dict[str, str] = {
    "int": "int",
    "long": "int",
    "long long": "int",
    "short": "int",
    "signed int": "int",
    "unsigned int": "int",
    "unsigned long": "int",
    "char": "int",
    "signed char": "int",
    "unsigned char": "int",
    "float": "float",
    "double": "float",
    "long double": "float",
    "bool": "bool",
    "_Bool": "bool",
    "void": "None",
}

INPUT_NAME = "input.cpp"


def parse_cpp(source: str) -> hir.HirModule:
    index = ci.Index.create()
    tu = index.parse(
        INPUT_NAME,
        args=["-std=c++17", "-x", "c++"],
        unsaved_files=[(INPUT_NAME, source)],
        options=ci.TranslationUnit.PARSE_DETAILED_PROCESSING_RECORD,
    )
    _check_diagnostics(tu)
    body: list[hir.HirNode] = []
    for c in tu.cursor.get_children():
        if not _from_input(c):
            continue
        if c.kind == CursorKind.FUNCTION_DECL and c.is_definition():
            body.append(_convert_function(c))
            continue
        if c.kind in (CursorKind.FUNCTION_DECL,):
            # Forward declaration — skip silently.
            continue
        raise UnsupportedConstruct(f"top-level {c.kind.name}")
    return hir.HirModule(source_lang="cpp", body=body)


def _check_diagnostics(tu: ci.TranslationUnit) -> None:
    fatal = [d for d in tu.diagnostics if d.severity >= ci.Diagnostic.Error]
    if fatal:
        msgs = "\n".join(f"  {d.spelling}" for d in fatal[:5])
        raise UnsupportedConstruct(f"libclang parse errors:\n{msgs}")


def _from_input(cursor: ci.Cursor) -> bool:
    return cursor.location.file is not None and cursor.location.file.name == INPUT_NAME


def _convert_function(cursor: ci.Cursor) -> hir.HirFunction:
    params: list[hir.HirParam] = []
    body: list[hir.HirNode] = []
    for c in cursor.get_children():
        if c.kind == CursorKind.PARM_DECL:
            params.append(hir.HirParam(name=c.spelling, annotation=_type_text(c.type)))
        elif c.kind == CursorKind.COMPOUND_STMT:
            body = _convert_compound(c)
    return hir.HirFunction(
        name=cursor.spelling,
        params=params,
        return_annotation=_type_text(cursor.result_type),
        body=body,
    )


def _convert_compound(cursor: ci.Cursor) -> list[hir.HirNode]:
    out: list[hir.HirNode] = []
    for c in cursor.get_children():
        out.extend(_convert_stmt(c))
    return out


def _convert_stmt(cursor: ci.Cursor) -> list[hir.HirNode]:
    kind = cursor.kind
    if kind == CursorKind.RETURN_STMT:
        kids = list(cursor.get_children())
        return [hir.HirReturn(value=_convert_expr(kids[0]) if kids else None)]
    if kind == CursorKind.DECL_STMT:
        out: list[hir.HirNode] = []
        for c in cursor.get_children():
            if c.kind == CursorKind.VAR_DECL:
                out.append(_convert_var_decl(c))
            else:
                raise UnsupportedConstruct(f"decl {c.kind.name}")
        return out
    if kind == CursorKind.IF_STMT:
        return [_convert_if(cursor)]
    if kind == CursorKind.WHILE_STMT:
        return [_convert_while(cursor)]
    if kind == CursorKind.FOR_STMT:
        return _convert_for(cursor)
    if kind == CursorKind.COMPOUND_STMT:
        return _convert_compound(cursor)
    if kind in (CursorKind.BINARY_OPERATOR, CursorKind.COMPOUND_ASSIGNMENT_OPERATOR):
        return [_convert_assignment_stmt(cursor)]
    if kind == CursorKind.UNARY_OPERATOR:
        return [_convert_unary_stmt(cursor)]
    if kind == CursorKind.CALL_EXPR:
        return [_convert_expr(cursor)]
    raise UnsupportedConstruct(f"stmt {kind.name}")


def _convert_var_decl(cursor: ci.Cursor) -> hir.HirNode:
    annotation = _type_text(cursor.type)
    kids = list(cursor.get_children())
    init = _convert_expr(kids[-1]) if kids else hir.HirIntLiteral(value=0)
    return hir.HirAssign(target=cursor.spelling, value=init, annotation=annotation)


def _convert_if(cursor: ci.Cursor) -> hir.HirNode:
    kids = list(cursor.get_children())
    if len(kids) < 2:
        raise UnsupportedConstruct("malformed if")
    cond = _convert_expr(kids[0])
    body = _convert_stmt(kids[1])
    orelse: list[hir.HirNode] = []
    if len(kids) >= 3:
        orelse = _convert_stmt(kids[2])
    return hir.HirIf(test=cond, body=body, orelse=orelse)


def _convert_while(cursor: ci.Cursor) -> hir.HirNode:
    kids = list(cursor.get_children())
    cond = _convert_expr(kids[0])
    body = _convert_stmt(kids[1]) if len(kids) > 1 else []
    return hir.HirWhile(test=cond, body=body)


def _convert_for(cursor: ci.Cursor) -> list[hir.HirNode]:
    """C-style for desugars at the frontend: init; while(cond) { body; step; }."""
    kids = list(cursor.get_children())
    # libclang's FOR_STMT children layout, in order:
    #   init (DECL_STMT or expression, may be omitted),
    #   cond (expression, may be omitted),
    #   step (expression, may be omitted),
    #   body (statement).
    # Missing parts simply aren't present; we use heuristics to detect.
    *headers, body_node = kids if kids else (None,)
    init_part: ci.Cursor | None = None
    cond_part: ci.Cursor | None = None
    step_part: ci.Cursor | None = None
    if len(headers) == 3:
        init_part, cond_part, step_part = headers
    elif len(headers) == 2:
        init_part, cond_part = headers
    elif len(headers) == 1:
        cond_part = headers[0]
    out: list[hir.HirNode] = []
    if init_part is not None:
        out.extend(_convert_stmt(init_part))
    cond = _convert_expr(cond_part) if cond_part is not None else hir.HirBoolLiteral(value=True)
    inner = _convert_stmt(body_node)
    if step_part is not None:
        inner.extend(_convert_stmt(step_part))
    out.append(hir.HirWhile(test=cond, body=inner))
    return out


# ---------- expressions ----------

def _convert_expr(cursor: ci.Cursor) -> hir.HirNode:
    kind = cursor.kind
    if kind == CursorKind.INTEGER_LITERAL:
        token = next(cursor.get_tokens(), None)
        if token is None:
            raise UnsupportedConstruct("integer literal without tokens")
        return hir.HirIntLiteral(value=int(token.spelling.rstrip("uUlL"), 0))
    if kind == CursorKind.FLOATING_LITERAL:
        token = next(cursor.get_tokens(), None)
        if token is None:
            raise UnsupportedConstruct("float literal without tokens")
        return hir.HirFloatLiteral(value=float(token.spelling.rstrip("fFlL")))
    if kind == CursorKind.CXX_BOOL_LITERAL_EXPR:
        token = next(cursor.get_tokens(), None)
        return hir.HirBoolLiteral(value=token is not None and token.spelling == "true")
    if kind == CursorKind.STRING_LITERAL:
        token = next(cursor.get_tokens(), None)
        if token is None:
            raise UnsupportedConstruct("string literal without tokens")
        return hir.HirStringLiteral(value=token.spelling[1:-1])
    if kind == CursorKind.DECL_REF_EXPR:
        return hir.HirName(name=cursor.spelling)
    if kind == CursorKind.UNEXPOSED_EXPR or kind == CursorKind.PAREN_EXPR:
        # Pass through to the single child — libclang often wraps real exprs.
        kids = list(cursor.get_children())
        if len(kids) == 1:
            return _convert_expr(kids[0])
    if kind == CursorKind.BINARY_OPERATOR:
        return _convert_binop(cursor)
    if kind == CursorKind.UNARY_OPERATOR:
        return _convert_unary_expr(cursor)
    if kind == CursorKind.CALL_EXPR:
        return _convert_call(cursor)
    if kind == CursorKind.COMPOUND_ASSIGNMENT_OPERATOR:
        # Inside an expression context (rare in our subset); reuse the stmt
        # form which produces the right HirAssign.
        raise UnsupportedConstruct("compound assignment as expression")
    raise UnsupportedConstruct(f"expr {kind.name}")


COMPARE_OPS = {"==", "!=", "<", "<=", ">", ">="}
ARITH_OPS = {"+", "-", "*", "/", "%"}
LOGICAL_OPS = {"&&", "||"}
ASSIGN_OPS = {"=", "+=", "-=", "*=", "/=", "%="}


def _convert_binop(cursor: ci.Cursor) -> hir.HirNode:
    op = _binop_token(cursor)
    kids = list(cursor.get_children())
    left = _convert_expr(kids[0])
    right = _convert_expr(kids[1])
    if op in COMPARE_OPS:
        return hir.HirCompare(op=op, left=left, right=right)
    if op in LOGICAL_OPS:
        return hir.HirBoolOp(op="and" if op == "&&" else "or", left=left, right=right)
    if op in ARITH_OPS:
        return hir.HirBinOp(op=op, left=left, right=right)
    raise UnsupportedConstruct(f"binary op {op!r}")


def _convert_assignment_stmt(cursor: ci.Cursor) -> hir.HirNode:
    """A BINARY_OPERATOR (or COMPOUND_ASSIGNMENT_OPERATOR) at statement position
    that uses `=` / `+=` / `-=` / etc."""
    op = _binop_token(cursor)
    if op not in ASSIGN_OPS:
        # Bare expression statement — rare in our subset; raise to surface it.
        raise UnsupportedConstruct(f"expression statement with op {op!r}")
    kids = list(cursor.get_children())
    lhs = kids[0]
    rhs = _convert_expr(kids[1])
    target = _decl_name(lhs)
    if target is None:
        raise UnsupportedConstruct(f"assignment target {lhs.kind.name}")
    aug = None if op == "=" else op[:-1]
    return hir.HirAssign(target=target, value=rhs, annotation=None, augmented_op=aug)


def _convert_unary_expr(cursor: ci.Cursor) -> hir.HirNode:
    op = _unary_token(cursor)
    kids = list(cursor.get_children())
    if op == "!":
        return hir.HirUnaryOp(op="not", operand=_convert_expr(kids[0]))
    if op == "-":
        return hir.HirUnaryOp(op="-", operand=_convert_expr(kids[0]))
    raise UnsupportedConstruct(f"unary op {op!r} as expression")


def _convert_unary_stmt(cursor: ci.Cursor) -> hir.HirNode:
    """`i++` / `i--` as a statement."""
    op = _unary_token(cursor)
    if op not in ("++", "--"):
        raise UnsupportedConstruct(f"unary stmt {op!r}")
    kids = list(cursor.get_children())
    target = _decl_name(kids[0])
    if target is None:
        raise UnsupportedConstruct(f"++/-- on {kids[0].kind.name}")
    sign = "+" if op == "++" else "-"
    return hir.HirAssign(
        target=target,
        value=hir.HirIntLiteral(value=1),
        annotation=None,
        augmented_op=sign,
    )


def _convert_call(cursor: ci.Cursor) -> hir.HirNode:
    kids = list(cursor.get_children())
    if not kids:
        raise UnsupportedConstruct("call with no callee")
    callee = kids[0]
    name = _decl_name(callee) or callee.spelling
    if not name:
        raise UnsupportedConstruct(f"call target {callee.kind.name}")
    args = [_convert_expr(a) for a in kids[1:]]
    return hir.HirCall(func=name, args=args)


def _decl_name(cursor: ci.Cursor) -> str | None:
    """Find the identifier name behind a DeclRefExpr / nested unwrapping."""
    if cursor.kind == CursorKind.DECL_REF_EXPR:
        return cursor.spelling
    if cursor.kind in (CursorKind.UNEXPOSED_EXPR, CursorKind.PAREN_EXPR):
        kids = list(cursor.get_children())
        if len(kids) == 1:
            return _decl_name(kids[0])
    return None


# ---------- operator-token extraction ----------

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


# ---------- type text ----------

def _type_text(t: ci.Type) -> str:
    spelling = t.spelling
    # Strip cv-qualifiers and references for the alias lookup.
    cleaned = spelling.replace("const ", "").replace("volatile ", "").strip()
    if cleaned in CPP_TYPE_ALIASES:
        return CPP_TYPE_ALIASES[cleaned]
    # Best-effort fallback: collapse on the canonical kind.
    kind = t.kind
    INTEGER_KINDS = {
        ci.TypeKind.INT, ci.TypeKind.LONG, ci.TypeKind.LONGLONG,
        ci.TypeKind.SHORT, ci.TypeKind.SCHAR, ci.TypeKind.UCHAR,
        ci.TypeKind.CHAR_S, ci.TypeKind.CHAR_U,
        ci.TypeKind.UINT, ci.TypeKind.ULONG, ci.TypeKind.ULONGLONG, ci.TypeKind.USHORT,
    }
    if kind in INTEGER_KINDS:
        return "int"
    if kind in (ci.TypeKind.FLOAT, ci.TypeKind.DOUBLE, ci.TypeKind.LONGDOUBLE):
        return "float"
    if kind == ci.TypeKind.BOOL:
        return "bool"
    if kind == ci.TypeKind.VOID:
        return "None"
    raise UnsupportedConstruct(f"C++ type {spelling!r} (kind={kind.name})")
