"""MIR -> Go LIR."""

from __future__ import annotations

from transpilers.ir import lir, mir
from transpilers.ir.types import BoolT, FloatT, IntT, ListT, NoneT, StrT, Type, UnknownT


def mir_to_go_lir(module: mir.MirModule) -> lir.GoModule:
    return lir.GoModule(items=[_lower_function(fn) for fn in module.functions])


def _lower_function(fn: mir.MirFunction) -> lir.GoFn:
    params = [(p.name, _go_type(p.ty)) for p in fn.params]
    ret = _go_type(fn.return_type)
    declared: set[str] = {p.name for p in fn.params}
    body = [_lower_stmt(n, declared) for n in fn.body]
    return lir.GoFn(name=fn.name, params=params, return_type=ret, body=body)


def _lower_stmt(node: mir.MirNode, declared: set[str]) -> lir.LirNode:
    if isinstance(node, mir.MirReturn):
        return lir.GoReturn(value=_lower_expr(node.value) if node.value else None)
    if isinstance(node, mir.MirAssign):
        return _lower_assign(node, declared)
    if isinstance(node, mir.MirIf):
        return lir.GoIf(
            test=_lower_expr(node.test),
            body=[_lower_stmt(n, declared) for n in node.body],
            orelse=[_lower_stmt(n, declared) for n in node.orelse],
        )
    if isinstance(node, mir.MirWhile):
        return lir.GoWhile(
            test=_lower_expr(node.test),
            body=[_lower_stmt(n, declared) for n in node.body],
        )
    if isinstance(node, mir.MirForRange):
        return lir.GoForRange(
            target=node.target,
            start=_lower_expr(node.start),
            stop=_lower_expr(node.stop),
            step=_lower_expr(node.step) if node.step else None,
            body=[_lower_stmt(n, declared) for n in node.body],
        )
    return _lower_expr(node)


def _lower_assign(node: mir.MirAssign, declared: set[str]) -> lir.LirNode:
    if node.augmented_op is not None:
        rhs = lir.GoBinOp(op=node.augmented_op, left=lir.GoName(name=node.target), right=_lower_expr(node.value))
        return lir.GoReassign(name=node.target, value=rhs)
    if node.target in declared:
        return lir.GoReassign(name=node.target, value=_lower_expr(node.value))
    declared.add(node.target)
    return lir.GoDecl(
        name=node.target,
        ty=_go_type(node.ty) if not isinstance(node.ty, UnknownT) else "int64",
        value=_lower_expr(node.value),
    )


def _lower_expr(node: mir.MirNode) -> lir.LirNode:
    if isinstance(node, mir.MirBinOp):
        if _is_string_concat(node):
            raise NotImplementedError(
                "string concatenation in Go works on string values directly; the IR "
                "needs a `+` lowering that respects Go's string semantics — not "
                "yet supported"
            )
        return lir.GoBinOp(op=node.op, left=_lower_expr(node.left), right=_lower_expr(node.right))
    if isinstance(node, mir.MirCompare):
        return lir.GoCompare(op=node.op, left=_lower_expr(node.left), right=_lower_expr(node.right))
    if isinstance(node, mir.MirBoolOp):
        op = "&&" if node.op == "and" else "||"
        return lir.GoBoolOp(op=op, left=_lower_expr(node.left), right=_lower_expr(node.right))
    if isinstance(node, mir.MirUnaryOp):
        op = "!" if node.op == "not" else "-"
        return lir.GoUnary(op=op, operand=_lower_expr(node.operand))
    if isinstance(node, mir.MirName):
        return lir.GoName(name=node.name)
    if isinstance(node, mir.MirIntLiteral):
        return lir.GoIntLiteral(value=node.value)
    if isinstance(node, mir.MirBoolLiteral):
        return lir.GoBoolLiteral(value=node.value)
    if isinstance(node, mir.MirStringLiteral):
        return lir.GoStringLiteral(value=node.value)
    if isinstance(node, mir.MirCall):
        if node.func == "len":
            # Go's `len(x)` is a builtin returning `int` — emit as a direct call.
            return lir.GoCall(func="len", args=[_lower_expr(a) for a in node.args])
        return lir.GoCall(func=node.func, args=[_lower_expr(a) for a in node.args])
    raise NotImplementedError(f"MIR expr {type(node).__name__}")


def _is_string_concat(node: mir.MirBinOp) -> bool:
    return (
        node.op == "+"
        and isinstance(getattr(node.left, "ty", None), StrT)
        and isinstance(getattr(node.right, "ty", None), StrT)
    )


def _go_type(ty: Type) -> str:
    if isinstance(ty, IntT):
        return f"{'int' if ty.signed else 'uint'}{ty.bits}"
    if isinstance(ty, FloatT):
        return f"float{ty.bits}"
    if isinstance(ty, BoolT):
        return "bool"
    if isinstance(ty, StrT):
        return "string"
    if isinstance(ty, NoneT):
        # Go uses no return type for void functions, not `void` — emit empty
        # string and let the emitter handle the void-return case.
        return ""
    if isinstance(ty, ListT):
        return f"[]{_go_type(ty.elem)}"
    if isinstance(ty, UnknownT):
        raise ValueError(f"unresolved type hole: {ty.hint}")
    raise NotImplementedError(f"type {type(ty).__name__}")
