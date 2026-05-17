"""MIR -> Mojo LIR.

Mojo's binding model is `var`-only (no `let`/`mut` split). Every locally
introduced name emits `var ...`; reassignments emit plain `<name> = ...`.
Loop variables are scoped to the loop body and don't need a declaration.

String concat: Mojo `String` supports `+`, so we can emit it directly without
the format!() detour Rust needs.
"""

from __future__ import annotations

from transpilers.ir import lir, mir
from transpilers.ir.types import BoolT, FloatT, IntT, ListT, NoneT, StrT, StructT, Type, UnknownT


def mir_to_mojo_lir(module: mir.MirModule) -> lir.MojoModule:
    items: list[lir.LirNode] = []
    for struct in module.structs:
        items.append(_lower_struct(struct))
    for fn in module.functions:
        items.append(_lower_function(fn))
    return lir.MojoModule(items=items)


def _lower_struct(s: mir.MirStruct) -> lir.MojoStruct:
    return lir.MojoStruct(
        name=s.name,
        fields=[(f.name, _mojo_type(f.ty)) for f in s.fields],
        methods=[_lower_function(m) for m in s.methods],
    )


def _lower_function(fn: mir.MirFunction) -> lir.MojoFn:
    params = [(p.name, _mojo_type(p.ty)) for p in fn.params]
    ret = _mojo_type(fn.return_type)
    declared: set[str] = {p.name for p in fn.params}
    body = [_lower_stmt(n, declared) for n in fn.body]
    return lir.MojoFn(name=fn.name, params=params, return_type=ret, body=body)


def _lower_stmt(node: mir.MirNode, declared: set[str]) -> lir.LirNode:
    if isinstance(node, mir.MirReturn):
        return lir.MojoReturn(value=_lower_expr(node.value) if node.value else None)
    if isinstance(node, mir.MirAssign):
        return _lower_assign(node, declared)
    if isinstance(node, mir.MirIf):
        return lir.MojoIf(
            test=_lower_expr(node.test),
            body=[_lower_stmt(n, declared) for n in node.body],
            orelse=[_lower_stmt(n, declared) for n in node.orelse],
        )
    if isinstance(node, mir.MirWhile):
        return lir.MojoWhile(
            test=_lower_expr(node.test),
            body=[_lower_stmt(n, declared) for n in node.body],
        )
    if isinstance(node, mir.MirForRange):
        return lir.MojoForRange(
            target=node.target,
            start=_lower_expr(node.start),
            stop=_lower_expr(node.stop),
            step=_lower_expr(node.step) if node.step else None,
            body=[_lower_stmt(n, declared) for n in node.body],
        )
    return _lower_expr(node)


def _lower_assign(node: mir.MirAssign, declared: set[str]) -> lir.LirNode:
    if node.augmented_op is not None:
        rhs = lir.MojoBinOp(op=node.augmented_op, left=lir.MojoName(name=node.target), right=_lower_expr(node.value))
        return lir.MojoReassign(name=node.target, value=rhs)
    if node.target in declared:
        return lir.MojoReassign(name=node.target, value=_lower_expr(node.value))
    declared.add(node.target)
    return lir.MojoVar(
        name=node.target,
        ty=_mojo_type(node.ty) if not isinstance(node.ty, UnknownT) else None,
        value=_lower_expr(node.value),
    )


def _lower_expr(node: mir.MirNode) -> lir.LirNode:
    if isinstance(node, mir.MirFieldAccess):
        return lir.MojoFieldAccess(value=_lower_expr(node.value), field=node.field)
    if isinstance(node, mir.MirMethodCall):
        return lir.MojoMethodCall(
            receiver=_lower_expr(node.receiver),
            method=node.method,
            args=[_lower_expr(a) for a in node.args],
        )
    if isinstance(node, mir.MirBinOp):
        return lir.MojoBinOp(op=node.op, left=_lower_expr(node.left), right=_lower_expr(node.right))
    if isinstance(node, mir.MirCompare):
        return lir.MojoCompare(op=node.op, left=_lower_expr(node.left), right=_lower_expr(node.right))
    if isinstance(node, mir.MirBoolOp):
        return lir.MojoBoolOp(op=node.op, left=_lower_expr(node.left), right=_lower_expr(node.right))
    if isinstance(node, mir.MirUnaryOp):
        op = "not" if node.op == "not" else "-"
        return lir.MojoUnary(op=op, operand=_lower_expr(node.operand))
    if isinstance(node, mir.MirName):
        return lir.MojoName(name=node.name)
    if isinstance(node, mir.MirIntLiteral):
        return lir.MojoIntLiteral(value=node.value)
    if isinstance(node, mir.MirFloatLiteral):
        return lir.MojoFloatLiteral(value=node.value)
    if isinstance(node, mir.MirBoolLiteral):
        return lir.MojoBoolLiteral(value=node.value)
    if isinstance(node, mir.MirStringLiteral):
        return lir.MojoStringLiteral(value=node.value)
    if isinstance(node, mir.MirCall):
        return _lower_call(node)
    if isinstance(node, mir.MirList):
        return lir.MojoList(elements=[_lower_expr(e) for e in node.elements])
    if isinstance(node, mir.MirSubscript):
        return lir.MojoIndex(value=_lower_expr(node.value), index=_lower_expr(node.index))
    raise NotImplementedError(f"MIR expr {type(node).__name__}")


def _lower_call(node: mir.MirCall) -> lir.LirNode:
    if node.func == "len":
        if len(node.args) != 1:
            raise ValueError("len() takes exactly one argument")
        # Mojo provides len() as a builtin. No casting needed since our
        # IntT(64) maps to Mojo's `Int` which is the right shape.
        return lir.MojoCall(func="len", args=[_lower_expr(node.args[0])])
    return lir.MojoCall(func=node.func, args=[_lower_expr(a) for a in node.args])


def _mojo_type(ty: Type) -> str:
    if isinstance(ty, IntT):
        # Mojo's `Int` is the idiomatic default — platform-sized but our
        # IR uses 64-bit, which matches on 64-bit targets. Use `Int` for
        # readability; `Int64` is also accepted.
        if ty.bits == 64 and ty.signed:
            return "Int"
        return f"{'Int' if ty.signed else 'UInt'}{ty.bits}"
    if isinstance(ty, FloatT):
        return f"Float{ty.bits}"
    if isinstance(ty, BoolT):
        return "Bool"
    if isinstance(ty, StrT):
        return "String"
    if isinstance(ty, NoneT):
        return "None"
    if isinstance(ty, ListT):
        return f"List[{_mojo_type(ty.elem)}]"
    if isinstance(ty, StructT):
        return ty.name
    if isinstance(ty, UnknownT):
        raise ValueError(f"unresolved type hole: {ty.hint}")
    raise NotImplementedError(f"type {type(ty).__name__}")
