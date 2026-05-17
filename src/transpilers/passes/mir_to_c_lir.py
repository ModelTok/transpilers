"""MIR -> C LIR.

C has no mut/const split — every variable is mutable. Mutability inference
is therefore irrelevant; declarations always emit the bare `<ty> <name> =
<value>;` form. For-range uses native C syntax. Strings are literals only;
concat raises (would need allocator-aware emission, same as Zig).
"""

from __future__ import annotations

from transpilers.ir import lir, mir
from transpilers.ir.types import BoolT, FloatT, IntT, ListT, NoneT, StrT, Type, UnknownT


def mir_to_c_lir(module: mir.MirModule) -> lir.CModule:
    return lir.CModule(items=[_lower_function(fn) for fn in module.functions])


def _lower_function(fn: mir.MirFunction) -> lir.CFn:
    params = [(p.name, _c_type(p.ty)) for p in fn.params]
    ret = _c_type(fn.return_type)
    declared: set[str] = {p.name for p in fn.params}
    body = [_lower_stmt(n, declared) for n in fn.body]
    return lir.CFn(name=fn.name, params=params, return_type=ret, body=body)


def _lower_stmt(node: mir.MirNode, declared: set[str]) -> lir.LirNode:
    if isinstance(node, mir.MirReturn):
        return lir.CReturn(value=_lower_expr(node.value) if node.value else None)
    if isinstance(node, mir.MirAssign):
        return _lower_assign(node, declared)
    if isinstance(node, mir.MirIf):
        return lir.CIf(
            test=_lower_expr(node.test),
            body=[_lower_stmt(n, declared) for n in node.body],
            orelse=[_lower_stmt(n, declared) for n in node.orelse],
        )
    if isinstance(node, mir.MirWhile):
        return lir.CWhile(
            test=_lower_expr(node.test),
            body=[_lower_stmt(n, declared) for n in node.body],
        )
    if isinstance(node, mir.MirForRange):
        return lir.CForRange(
            target=node.target,
            start=_lower_expr(node.start),
            stop=_lower_expr(node.stop),
            step=_lower_expr(node.step) if node.step else None,
            body=[_lower_stmt(n, declared) for n in node.body],
        )
    return _lower_expr(node)


def _lower_assign(node: mir.MirAssign, declared: set[str]) -> lir.LirNode:
    if node.augmented_op is not None:
        rhs = lir.CBinOp(op=node.augmented_op, left=lir.CName(name=node.target), right=_lower_expr(node.value))
        return lir.CReassign(name=node.target, value=rhs)
    if node.target in declared:
        return lir.CReassign(name=node.target, value=_lower_expr(node.value))
    declared.add(node.target)
    ty = _c_type(node.ty) if not isinstance(node.ty, UnknownT) else "int64_t"
    return lir.CDecl(name=node.target, ty=ty, value=_lower_expr(node.value))


def _lower_expr(node: mir.MirNode) -> lir.LirNode:
    if isinstance(node, mir.MirBinOp):
        if _is_string_concat(node):
            raise NotImplementedError(
                "string concatenation in C requires allocator-aware emission "
                "(snprintf or asprintf), not yet supported"
            )
        return lir.CBinOp(op=node.op, left=_lower_expr(node.left), right=_lower_expr(node.right))
    if isinstance(node, mir.MirCompare):
        return lir.CCompare(op=node.op, left=_lower_expr(node.left), right=_lower_expr(node.right))
    if isinstance(node, mir.MirBoolOp):
        op = "&&" if node.op == "and" else "||"
        return lir.CBoolOp(op=op, left=_lower_expr(node.left), right=_lower_expr(node.right))
    if isinstance(node, mir.MirUnaryOp):
        op = "!" if node.op == "not" else "-"
        return lir.CUnary(op=op, operand=_lower_expr(node.operand))
    if isinstance(node, mir.MirName):
        return lir.CName(name=node.name)
    if isinstance(node, mir.MirIntLiteral):
        return lir.CIntLiteral(value=node.value)
    if isinstance(node, mir.MirBoolLiteral):
        return lir.CBoolLiteral(value=node.value)
    if isinstance(node, mir.MirStringLiteral):
        return lir.CStringLiteral(value=node.value)
    if isinstance(node, mir.MirCall):
        # `len(x)` and `range(...)` aren't C builtins. range() is handled at
        # MirForRange; len() of a slice has no zero-cost C equivalent in our
        # subset. Surface that gap rather than fake it.
        if node.func == "len":
            raise NotImplementedError("len() in C requires a slice/length protocol; not yet supported")
        return lir.CCall(func=node.func, args=[_lower_expr(a) for a in node.args])
    if isinstance(node, mir.MirSubscript):
        return lir.CIndex(value=_lower_expr(node.value), index=_lower_expr(node.index))
    raise NotImplementedError(f"MIR expr {type(node).__name__}")


def _is_string_concat(node: mir.MirBinOp) -> bool:
    return (
        node.op == "+"
        and isinstance(getattr(node.left, "ty", None), StrT)
        and isinstance(getattr(node.right, "ty", None), StrT)
    )


def _c_type(ty: Type) -> str:
    if isinstance(ty, IntT):
        prefix = "int" if ty.signed else "uint"
        return f"{prefix}{ty.bits}_t"
    if isinstance(ty, FloatT):
        return "double" if ty.bits == 64 else "float"
    if isinstance(ty, BoolT):
        return "bool"
    if isinstance(ty, StrT):
        return "const char*"
    if isinstance(ty, NoneT):
        return "void"
    if isinstance(ty, ListT):
        # Bare C has no slice type; a real implementation would carry a
        # (ptr, len) pair. Out of scope for the initial backend.
        raise NotImplementedError("list / slice types in C require a length-carrying struct")
    if isinstance(ty, UnknownT):
        raise ValueError(f"unresolved type hole: {ty.hint}")
    raise NotImplementedError(f"type {type(ty).__name__}")
