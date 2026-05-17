"""Python source -> HIR via libcst.

Subset supported:
  - function defs with annotated params and return types
  - simple statements: return, expression
  - control flow: if/elif/else, while, for-in-range
  - assignment: plain, annotated, augmented
  - expressions: binary ops, comparisons, boolean ops, unary not/-
  - literals: int, bool, string
  - lists, subscript indexing, function calls

Anything else raises UnsupportedConstruct. That's the right failure mode —
later passes (algorithmic inference, LLM hooks) handle gaps; the parser must
not silently drop nodes it doesn't understand.
"""

from __future__ import annotations

import libcst as cst

from transpilers.ir import hir


class UnsupportedConstruct(Exception):
    pass


def parse_python(source: str) -> hir.HirModule:
    tree = cst.parse_module(source)
    body = [_convert(stmt) for stmt in tree.body]
    return hir.HirModule(source_lang="python", body=body)


def _convert(node: cst.CSTNode) -> hir.HirNode:
    if isinstance(node, cst.SimpleStatementLine):
        if len(node.body) != 1:
            raise UnsupportedConstruct("compound simple statements")
        return _convert(node.body[0])

    if isinstance(node, cst.FunctionDef):
        return _convert_function(node)

    if isinstance(node, cst.Return):
        return hir.HirReturn(value=_convert(node.value) if node.value else None)

    if isinstance(node, cst.If):
        return _convert_if(node)

    if isinstance(node, cst.While):
        return hir.HirWhile(test=_convert(node.test), body=_convert_block(node.body))

    if isinstance(node, cst.For):
        return _convert_for(node)

    if isinstance(node, cst.Assign):
        if len(node.targets) != 1:
            raise UnsupportedConstruct("multi-target assignment")
        target = node.targets[0].target
        if not isinstance(target, cst.Name):
            raise UnsupportedConstruct(f"assignment target {type(target).__name__}")
        return hir.HirAssign(target=target.value, value=_convert(node.value), annotation=None)

    if isinstance(node, cst.AnnAssign):
        if not isinstance(node.target, cst.Name):
            raise UnsupportedConstruct(f"annotated-assignment target {type(node.target).__name__}")
        if node.value is None:
            raise UnsupportedConstruct("declaration without initializer")
        return hir.HirAssign(
            target=node.target.value,
            value=_convert(node.value),
            annotation=_annotation_text(node.annotation.annotation),
        )

    if isinstance(node, cst.AugAssign):
        if not isinstance(node.target, cst.Name):
            raise UnsupportedConstruct(f"aug-assignment target {type(node.target).__name__}")
        return hir.HirAssign(
            target=node.target.value,
            value=_convert(node.value),
            annotation=None,
            augmented_op=_op_symbol(node.operator),
        )

    if isinstance(node, cst.Expr):
        return _convert(node.value)

    if isinstance(node, cst.BinaryOperation):
        return hir.HirBinOp(op=_op_symbol(node.operator), left=_convert(node.left), right=_convert(node.right))

    if isinstance(node, cst.Comparison):
        if len(node.comparisons) != 1:
            raise UnsupportedConstruct("chained comparison (a < b < c)")
        target = node.comparisons[0]
        return hir.HirCompare(
            op=_cmp_symbol(target.operator),
            left=_convert(node.left),
            right=_convert(target.comparator),
        )

    if isinstance(node, cst.BooleanOperation):
        op = "and" if isinstance(node.operator, cst.And) else "or"
        return hir.HirBoolOp(op=op, left=_convert(node.left), right=_convert(node.right))

    if isinstance(node, cst.UnaryOperation):
        if isinstance(node.operator, cst.Not):
            op = "not"
        elif isinstance(node.operator, cst.Minus):
            op = "-"
        else:
            raise UnsupportedConstruct(f"unary op {type(node.operator).__name__}")
        return hir.HirUnaryOp(op=op, operand=_convert(node.expression))

    if isinstance(node, cst.Name):
        if node.value == "True":
            return hir.HirBoolLiteral(value=True)
        if node.value == "False":
            return hir.HirBoolLiteral(value=False)
        return hir.HirName(name=node.value)

    if isinstance(node, cst.Integer):
        return hir.HirIntLiteral(value=int(node.value))

    if isinstance(node, cst.Float):
        return hir.HirFloatLiteral(value=float(node.value))

    if isinstance(node, cst.SimpleString):
        return hir.HirStringLiteral(value=_unquote(node.value))

    if isinstance(node, cst.Call):
        if not isinstance(node.func, cst.Name):
            raise UnsupportedConstruct(f"call target {type(node.func).__name__}")
        return hir.HirCall(func=node.func.value, args=[_convert(a.value) for a in node.args])

    if isinstance(node, cst.List):
        return hir.HirList(elements=[_convert(e.value) for e in node.elements])

    if isinstance(node, cst.Subscript):
        if len(node.slice) != 1 or not isinstance(node.slice[0].slice, cst.Index):
            raise UnsupportedConstruct("slice / multi-index subscript")
        idx = node.slice[0].slice.value
        return hir.HirSubscript(value=_convert(node.value), index=_convert(idx))

    raise UnsupportedConstruct(f"{type(node).__name__}")


def _convert_function(fn: cst.FunctionDef) -> hir.HirFunction:
    params = [_convert_param(p) for p in fn.params.params]
    ret = _annotation_text(fn.returns.annotation) if fn.returns else None
    body = _convert_block(fn.body)
    return hir.HirFunction(name=fn.name.value, params=params, return_annotation=ret, body=body)


def _convert_param(p: cst.Param) -> hir.HirParam:
    ann = _annotation_text(p.annotation.annotation) if p.annotation else None
    return hir.HirParam(name=p.name.value, annotation=ann)


def _convert_block(body: cst.BaseSuite) -> list[hir.HirNode]:
    if not isinstance(body, cst.IndentedBlock):
        raise UnsupportedConstruct("non-indented block")
    return [_convert(stmt) for stmt in body.body]


def _convert_if(node: cst.If) -> hir.HirIf:
    test = _convert(node.test)
    body = _convert_block(node.body)
    orelse: list[hir.HirNode] = []
    if node.orelse is not None:
        if isinstance(node.orelse, cst.If):
            # elif → nested HirIf
            orelse = [_convert_if(node.orelse)]
        elif isinstance(node.orelse, cst.Else):
            orelse = _convert_block(node.orelse.body)
        else:
            raise UnsupportedConstruct(f"if orelse {type(node.orelse).__name__}")
    return hir.HirIf(test=test, body=body, orelse=orelse)


def _convert_for(node: cst.For) -> hir.HirFor:
    if not isinstance(node.target, cst.Name):
        raise UnsupportedConstruct(f"for target {type(node.target).__name__}")
    if node.orelse is not None:
        raise UnsupportedConstruct("for-else clause")
    return hir.HirFor(target=node.target.value, iter=_convert(node.iter), body=_convert_block(node.body))


def _annotation_text(node: cst.BaseExpression) -> str:
    if isinstance(node, cst.Name):
        return node.value
    if isinstance(node, cst.Subscript):
        base = _annotation_text(node.value)
        parts = []
        for s in node.slice:
            if not isinstance(s.slice, cst.Index):
                raise UnsupportedConstruct("non-index subscript in annotation")
            parts.append(_annotation_text(s.slice.value))
        return f"{base}[{', '.join(parts)}]"
    raise UnsupportedConstruct(f"annotation {type(node).__name__}")


def _op_symbol(op: cst.BaseBinaryOp | cst.BaseAugOp) -> str:
    table = {
        cst.Add: "+", cst.Subtract: "-", cst.Multiply: "*", cst.Divide: "/",
        cst.Modulo: "%",
        cst.AddAssign: "+", cst.SubtractAssign: "-",
        cst.MultiplyAssign: "*", cst.DivideAssign: "/",
    }
    for kls, sym in table.items():
        if isinstance(op, kls):
            return sym
    raise UnsupportedConstruct(f"op {type(op).__name__}")


def _cmp_symbol(op: cst.BaseCompOp) -> str:
    table = {
        cst.Equal: "==", cst.NotEqual: "!=",
        cst.LessThan: "<", cst.LessThanEqual: "<=",
        cst.GreaterThan: ">", cst.GreaterThanEqual: ">=",
    }
    for kls, sym in table.items():
        if isinstance(op, kls):
            return sym
    raise UnsupportedConstruct(f"comparison {type(op).__name__}")


def _unquote(literal: str) -> str:
    # libcst's SimpleString.value includes the surrounding quotes; strip them.
    # Real escape handling lives in a future pass — current subset is exact-text.
    if literal.startswith(("'''", '"""')):
        return literal[3:-3]
    return literal[1:-1]
