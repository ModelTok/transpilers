"""MIR -> Zig LIR.

Mirrors mir_to_rust_lir in structure but produces a Zig-shaped dialect.
Differences worth noting:
  - var/const split replaces let/let-mut
  - `for (a..b) |i|` for unit-step ranges; stepped ranges desugar to `while`
  - `.len` on slices is a property access (no parens), so we model it as a
    method call with no args and let the emitter drop the parens
"""

from __future__ import annotations

from transpilers.ir import lir, mir
from transpilers.ir.types import BoolT, FloatT, IntT, ListT, NoneT, StrT, Type, UnknownT


def mir_to_zig_lir(module: mir.MirModule) -> lir.ZigModule:
    return lir.ZigModule(items=[_lower_function(fn) for fn in module.functions])


def _lower_function(fn: mir.MirFunction) -> lir.ZigFn:
    params = [(p.name, _zig_type(p.ty)) for p in fn.params]
    ret = _zig_type(fn.return_type)
    mut_names = _collect_mutable(fn.body)
    declared: set[str] = {p.name for p in fn.params}
    body = [_lower_stmt(n, declared, mut_names) for n in fn.body]
    return lir.ZigFn(name=fn.name, params=params, return_type=ret, body=body)


def _collect_mutable(body: list[mir.MirNode]) -> set[str]:
    counts: dict[str, int] = {}
    aug: set[str] = set()
    _scan(body, counts, aug)
    return {n for n, c in counts.items() if c > 1} | aug


def _scan(nodes: list[mir.MirNode], counts: dict[str, int], aug: set[str]) -> None:
    for n in nodes:
        if isinstance(n, mir.MirAssign):
            counts[n.target] = counts.get(n.target, 0) + 1
            if n.augmented_op is not None:
                aug.add(n.target)
        elif isinstance(n, mir.MirIf):
            _scan(n.body, counts, aug)
            _scan(n.orelse, counts, aug)
        elif isinstance(n, mir.MirWhile):
            _scan(n.body, counts, aug)
        elif isinstance(n, mir.MirForRange):
            _scan(n.body, counts, aug)


def _lower_stmt(node: mir.MirNode, declared: set[str], mut: set[str]) -> lir.LirNode:
    if isinstance(node, mir.MirReturn):
        return lir.ZigReturn(value=_lower_expr(node.value) if node.value else None)
    if isinstance(node, mir.MirAssign):
        return _lower_assign(node, declared, mut)
    if isinstance(node, mir.MirIf):
        return lir.ZigIf(
            test=_lower_expr(node.test),
            body=[_lower_stmt(n, declared, mut) for n in node.body],
            orelse=[_lower_stmt(n, declared, mut) for n in node.orelse],
        )
    if isinstance(node, mir.MirWhile):
        return lir.ZigWhile(
            test=_lower_expr(node.test),
            body=[_lower_stmt(n, declared, mut) for n in node.body],
        )
    if isinstance(node, mir.MirForRange):
        # `for (a..b) |i|` is unit-step only. A non-None step desugars to a
        # while-loop with explicit increment — keeps the LIR honest and lets
        # the emitter pick the right form.
        if node.step is None:
            return lir.ZigForRange(
                target=node.target,
                start=_lower_expr(node.start),
                stop=_lower_expr(node.stop),
                body=[_lower_stmt(n, declared, mut) for n in node.body],
            )
        # Stepped range: emit an explicit while-loop. We synthesize a `var`
        # declaration for the loop variable.
        target = node.target
        declared.add(target)
        return _stepped_while(target, node, declared, mut)
    return _lower_expr(node)


def _stepped_while(
    target: str, node: mir.MirForRange, declared: set[str], mut: set[str]
) -> lir.LirNode:
    step = _lower_expr(node.step) if node.step is not None else lir.ZigIntLiteral(value=1)
    init = lir.ZigVar(name=target, mutable=True, ty="i64", value=_lower_expr(node.start))
    cond = lir.ZigCompare(op="<", left=lir.ZigName(name=target), right=_lower_expr(node.stop))
    incr = lir.ZigReassign(
        name=target, value=lir.ZigBinOp(op="+", left=lir.ZigName(name=target), right=step)
    )
    body = [_lower_stmt(n, declared, mut) for n in node.body]
    body.append(incr)
    # Wrap init + while in a synthetic block: emit init first, then while.
    # Since our LIR doesn't have a block node, we return a small list via a
    # marker structure — emitter handles `list[LirNode]` by emitting each.
    return _ZigBlock(items=[init, lir.ZigWhile(test=cond, body=body)])


# Internal block carrier — emitter unwraps. Kept private; not part of the
# public LIR shape.
class _ZigBlock(lir.LirNode):
    def __init__(self, items: list[lir.LirNode]) -> None:
        self.items = items


def _lower_assign(node: mir.MirAssign, declared: set[str], mut: set[str]) -> lir.LirNode:
    if node.augmented_op is not None:
        rhs = lir.ZigBinOp(op=node.augmented_op, left=lir.ZigName(name=node.target), right=_lower_expr(node.value))
        return lir.ZigReassign(name=node.target, value=rhs)
    if node.target in declared:
        return lir.ZigReassign(name=node.target, value=_lower_expr(node.value))
    declared.add(node.target)
    return lir.ZigVar(
        name=node.target,
        mutable=node.target in mut,
        ty=_zig_type(node.ty) if not isinstance(node.ty, UnknownT) else None,
        value=_lower_expr(node.value),
    )


def _lower_expr(node: mir.MirNode) -> lir.LirNode:
    if isinstance(node, mir.MirBinOp):
        return lir.ZigBinOp(op=node.op, left=_lower_expr(node.left), right=_lower_expr(node.right))
    if isinstance(node, mir.MirCompare):
        return lir.ZigCompare(op=node.op, left=_lower_expr(node.left), right=_lower_expr(node.right))
    if isinstance(node, mir.MirBoolOp):
        return lir.ZigBoolOp(op=node.op, left=_lower_expr(node.left), right=_lower_expr(node.right))
    if isinstance(node, mir.MirUnaryOp):
        op = "!" if node.op == "not" else "-"
        return lir.ZigUnary(op=op, operand=_lower_expr(node.operand))
    if isinstance(node, mir.MirName):
        return lir.ZigName(name=node.name)
    if isinstance(node, mir.MirIntLiteral):
        return lir.ZigIntLiteral(value=node.value)
    if isinstance(node, mir.MirBoolLiteral):
        return lir.ZigBoolLiteral(value=node.value)
    if isinstance(node, mir.MirStringLiteral):
        return lir.ZigStringLiteral(value=node.value)
    if isinstance(node, mir.MirCall):
        return _lower_call(node)
    if isinstance(node, mir.MirList):
        elem_ty = _zig_type(node.ty.elem) if isinstance(node.ty, ListT) else "i64"
        return lir.ZigArrayLit(elem_ty=elem_ty, elements=[_lower_expr(e) for e in node.elements])
    if isinstance(node, mir.MirSubscript):
        return lir.ZigIndex(value=_lower_expr(node.value), index=_lower_expr(node.index))
    raise NotImplementedError(f"MIR expr {type(node).__name__}")


def _lower_call(node: mir.MirCall) -> lir.LirNode:
    if node.func == "len":
        if len(node.args) != 1:
            raise ValueError("len() takes exactly one argument")
        # Zig slices expose `.len` as a property (no parens). We model it as a
        # zero-arg method call and let the emitter drop the parens.
        return lir.ZigMethodCall(
            receiver=_lower_expr(node.args[0]), method="len", args=[], cast_to="i64"
        )
    return lir.ZigCall(func=node.func, args=[_lower_expr(a) for a in node.args])


def _zig_type(ty: Type) -> str:
    if isinstance(ty, IntT):
        return f"{'i' if ty.signed else 'u'}{ty.bits}"
    if isinstance(ty, FloatT):
        return f"f{ty.bits}"
    if isinstance(ty, BoolT):
        return "bool"
    if isinstance(ty, StrT):
        return "[]const u8"
    if isinstance(ty, NoneT):
        return "void"
    if isinstance(ty, ListT):
        return f"[]const {_zig_type(ty.elem)}"
    if isinstance(ty, UnknownT):
        raise ValueError(f"unresolved type hole: {ty.hint}")
    raise NotImplementedError(f"type {type(ty).__name__}")
