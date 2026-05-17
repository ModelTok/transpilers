"""Python source -> HIR via libcst.

Initial subset: function defs with int-annotated params, return statements,
binary operations, names, integer literals. Enough for an end-to-end Python ->
Rust slice. Anything outside the subset raises UnsupportedConstruct, which is
the right failure mode: we want the system to know when it's outside its
algorithmic envelope so an LLM hook or a human can take over.
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
        params = [_convert_param(p) for p in node.params.params]
        ret = _annotation_text(node.returns.annotation) if node.returns else None
        fn_body: list[hir.HirNode] = []
        for stmt in node.body.body:
            fn_body.append(_convert(stmt))
        return hir.HirFunction(name=node.name.value, params=params, return_annotation=ret, body=fn_body)

    if isinstance(node, cst.Return):
        return hir.HirReturn(value=_convert(node.value) if node.value else None)

    if isinstance(node, cst.BinaryOperation):
        return hir.HirBinOp(op=_op_symbol(node.operator), left=_convert(node.left), right=_convert(node.right))

    if isinstance(node, cst.Name):
        return hir.HirName(name=node.value)

    if isinstance(node, cst.Integer):
        return hir.HirIntLiteral(value=int(node.value))

    raise UnsupportedConstruct(f"{type(node).__name__}")


def _convert_param(p: cst.Param) -> hir.HirParam:
    ann = _annotation_text(p.annotation.annotation) if p.annotation else None
    return hir.HirParam(name=p.name.value, annotation=ann)


def _annotation_text(node: cst.BaseExpression) -> str:
    if isinstance(node, cst.Name):
        return node.value
    raise UnsupportedConstruct(f"annotation {type(node).__name__}")


def _op_symbol(op: cst.BaseBinaryOp) -> str:
    if isinstance(op, cst.Add):
        return "+"
    if isinstance(op, cst.Subtract):
        return "-"
    if isinstance(op, cst.Multiply):
        return "*"
    if isinstance(op, cst.Divide):
        return "/"
    raise UnsupportedConstruct(f"binary op {type(op).__name__}")
