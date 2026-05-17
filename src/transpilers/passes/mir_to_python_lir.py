"""MIR -> Python LIR.

Python is the round-trip target: source → IR → Python. Useful for normalizing
code, refactoring tools, and proving the IR is lossless enough to recover
compilable Python from any source language.

Annotations are emitted when available. Mutability isn't a Python concept,
so all `MirAssign` nodes lower to plain `PyAssign`.
"""

from __future__ import annotations

from transpilers.ir import lir, mir
from transpilers.ir.types import BoolT, FloatT, IntT, ListT, NoneT, StrT, Type, UnknownT


def mir_to_python_lir(module: mir.MirModule) -> lir.PyModule:
    return lir.PyModule(items=[_lower_function(fn) for fn in module.functions])


def _lower_function(fn: mir.MirFunction) -> lir.PyFn:
    params = [(p.name, _py_type(p.ty)) for p in fn.params]
    ret = _py_type(fn.return_type)
    declared: set[str] = {p.name for p in fn.params}
    body = [_lower_stmt(n, declared) for n in fn.body]
    return lir.PyFn(name=fn.name, params=params, return_type=ret, body=body)


def _lower_stmt(node: mir.MirNode, declared: set[str]) -> lir.LirNode:
    if isinstance(node, mir.MirReturn):
        return lir.PyReturn(value=_lower_expr(node.value) if node.value else None)
    if isinstance(node, mir.MirAssign):
        return _lower_assign(node, declared)
    if isinstance(node, mir.MirIf):
        return lir.PyIf(
            test=_lower_expr(node.test),
            body=[_lower_stmt(n, declared) for n in node.body],
            orelse=[_lower_stmt(n, declared) for n in node.orelse],
        )
    if isinstance(node, mir.MirWhile):
        return lir.PyWhile(
            test=_lower_expr(node.test),
            body=[_lower_stmt(n, declared) for n in node.body],
        )
    if isinstance(node, mir.MirForRange):
        return lir.PyForRange(
            target=node.target,
            start=_lower_expr(node.start),
            stop=_lower_expr(node.stop),
            step=_lower_expr(node.step) if node.step else None,
            body=[_lower_stmt(n, declared) for n in node.body],
        )
    return _lower_expr(node)


def _lower_assign(node: mir.MirAssign, declared: set[str]) -> lir.LirNode:
    if node.augmented_op is not None:
        rhs = lir.PyBinOp(op=node.augmented_op, left=lir.PyName(name=node.target), right=_lower_expr(node.value))
        return lir.PyAssign(name=node.target, ty=None, value=rhs)
    # Annotation only on first occurrence; subsequent assignments are bare.
    is_first = node.target not in declared
    declared.add(node.target)
    ty = _py_type(node.ty) if is_first and not isinstance(node.ty, UnknownT) else None
    return lir.PyAssign(name=node.target, ty=ty, value=_lower_expr(node.value))


def _lower_expr(node: mir.MirNode) -> lir.LirNode:
    if isinstance(node, mir.MirBinOp):
        return lir.PyBinOp(op=node.op, left=_lower_expr(node.left), right=_lower_expr(node.right))
    if isinstance(node, mir.MirCompare):
        return lir.PyCompare(op=node.op, left=_lower_expr(node.left), right=_lower_expr(node.right))
    if isinstance(node, mir.MirBoolOp):
        return lir.PyBoolOp(op=node.op, left=_lower_expr(node.left), right=_lower_expr(node.right))
    if isinstance(node, mir.MirUnaryOp):
        return lir.PyUnary(op=node.op, operand=_lower_expr(node.operand))
    if isinstance(node, mir.MirName):
        return lir.PyName(name=node.name)
    if isinstance(node, mir.MirIntLiteral):
        return lir.PyIntLiteral(value=node.value)
    if isinstance(node, mir.MirFloatLiteral):
        return lir.PyFloatLiteral(value=node.value)
    if isinstance(node, mir.MirBoolLiteral):
        return lir.PyBoolLiteral(value=node.value)
    if isinstance(node, mir.MirStringLiteral):
        return lir.PyStringLiteral(value=node.value)
    if isinstance(node, mir.MirCall):
        return lir.PyCall(func=node.func, args=[_lower_expr(a) for a in node.args])
    raise NotImplementedError(f"MIR expr {type(node).__name__}")


def _py_type(ty: Type) -> str:
    if isinstance(ty, IntT):
        return "int"
    if isinstance(ty, FloatT):
        return "float"
    if isinstance(ty, BoolT):
        return "bool"
    if isinstance(ty, StrT):
        return "str"
    if isinstance(ty, NoneT):
        return "None"
    if isinstance(ty, ListT):
        return f"list[{_py_type(ty.elem)}]"
    if isinstance(ty, UnknownT):
        # Python tolerates omitted annotations; emit empty marker the emitter
        # interprets as "no annotation".
        return ""
    raise NotImplementedError(f"type {type(ty).__name__}")
