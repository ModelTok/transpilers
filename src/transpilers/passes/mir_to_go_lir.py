"""MIR -> Go LIR."""

from __future__ import annotations

from transpilers.ir import lir, mir
from transpilers.ir.types import BoolT, FloatT, IntT, ListT, NoneT, StrT, StructT, Type, UnknownT


def mir_to_go_lir(module: mir.MirModule) -> lir.GoModule:
    items: list[lir.LirNode] = []
    for s in module.structs:
        items.append(_lower_struct(s))
    for fn in module.functions:
        items.append(_lower_function(fn))
    return lir.GoModule(items=items)


def _lower_struct(s: mir.MirStruct) -> lir.GoStruct:
    return lir.GoStruct(
        name=s.name,
        fields=[(f.name, _go_type(f.ty)) for f in s.fields],
        methods=[_lower_function(m) for m in s.methods],
    )


def _lower_function(fn: mir.MirFunction) -> lir.GoFn:
    params = [(p.name, _go_type(p.ty)) for p in fn.params]
    ret = _go_type(fn.return_type)
    declared: set[str] = {p.name for p in fn.params}
    body = [_lower_stmt(n, declared) for n in fn.body]
    return lir.GoFn(name=fn.name, params=params, return_type=ret, body=body)


def _lower_stmt(node: mir.MirNode, declared: set[str]) -> lir.LirNode:
    if isinstance(node, mir.MirReturn):
        return lir.GoReturn(value=_lower_expr(node.value) if node.value else None)
    if isinstance(node, mir.MirFieldAssign):
        return lir.GoFieldAssign(
            obj=_lower_expr(node.obj), field=node.field, value=_lower_expr(node.value)
        )
    if isinstance(node, mir.MirSubscriptAssign):
        return lir.GoSubscriptAssign(
            obj=_lower_expr(node.obj),
            index=_lower_expr(node.index),
            value=_lower_expr(node.value),
        )
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
    if isinstance(node, mir.MirBinOp) and node.op == "//":
        return lir.GoBinOp(op="/", left=_lower_expr(node.left), right=_lower_expr(node.right))
    if isinstance(node, mir.MirSubscript):
        return _GoIndex(value=_lower_expr(node.value), index=_lower_expr(node.index))
    if isinstance(node, mir.MirList):
        # `[]int64{1, 2, 3}` — Go slice literal. Element type assumed int64
        # (the most common case in our integer-heavy corpus); a typed-context
        # propagation pass could pick precisely from the LHS annotation.
        elem_ty = "int64"
        if isinstance(node.ty, ListT):
            elem_ty = _go_type(node.ty.elem)
        return _GoSliceLit(elem_ty=elem_ty, elements=[_lower_expr(e) for e in node.elements])
    if isinstance(node, mir.MirFieldAccess):
        return lir.GoFieldAccess(value=_lower_expr(node.value), field=node.field)
    if isinstance(node, mir.MirStructInit):
        return lir.GoStructInit(
            name=node.name,
            field_values=[(n, _lower_expr(v)) for n, v in node.field_values],
        )
    if isinstance(node, mir.MirMethodCall):
        return _GoMethodCall(
            receiver=_lower_expr(node.receiver),
            method=node.method,
            args=[_lower_expr(a) for a in node.args],
        )
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
    if isinstance(node, mir.MirFloatLiteral):
        return lir.GoFloatLiteral(value=node.value)
    if isinstance(node, mir.MirBoolLiteral):
        return lir.GoBoolLiteral(value=node.value)
    if isinstance(node, mir.MirStringLiteral):
        return lir.GoStringLiteral(value=node.value)
    if isinstance(node, mir.MirCall):
        args = [_lower_expr(a) for a in node.args]
        if node.func == "len":
            return lir.GoCall(func="len", args=args)
        if node.func in ("print", "println"):
            # Go's `println` builtin writes to stderr — not what Python's
            # print does. Use `fmt.Println` for stdout. The Go emitter
            # adds the `import "fmt"` when it sees the qualified call.
            return lir.GoCall(func="fmt.Println", args=args)
        if node.func == "abs" and len(args) == 1:
            x = args[0]
            return _GoIfExpr(
                test=lir.GoCompare(op="<", left=x, right=lir.GoIntLiteral(value=0)),
                then_=lir.GoUnary(op="-", operand=x),
                else_=x,
            )
        if node.func == "min" and len(args) == 2:
            return lir.GoCall(func="min", args=args)
        if node.func == "max" and len(args) == 2:
            return lir.GoCall(func="max", args=args)
        if node.func == "int" and len(args) == 1:
            return lir.GoCall(func="int64", args=args)
        if node.func == "float" and len(args) == 1:
            return lir.GoCall(func="float64", args=args)
        return lir.GoCall(func=node.func, args=args)
    raise NotImplementedError(f"MIR expr {type(node).__name__}")


class _GoMethodCall(lir.LirNode):
    def __init__(self, receiver: lir.LirNode, method: str, args: list[lir.LirNode]) -> None:
        self.receiver = receiver
        self.method = method
        self.args = args


class _GoIfExpr(lir.LirNode):
    """Branchless expression form via an inline IIFE. Used for builtin
    lowering when Go has no equivalent (`abs` on int)."""

    def __init__(self, test: lir.LirNode, then_: lir.LirNode, else_: lir.LirNode) -> None:
        self.test = test
        self.then_ = then_
        self.else_ = else_


class _GoIndex(lir.LirNode):
    """Array/slice subscript: `arr[index]`."""

    def __init__(self, value: lir.LirNode, index: lir.LirNode) -> None:
        self.value = value
        self.index = index


class _GoSliceLit(lir.LirNode):
    """`[]<elem_ty>{a, b, c}` — Go slice literal."""

    def __init__(self, elem_ty: str, elements: list[lir.LirNode]) -> None:
        self.elem_ty = elem_ty
        self.elements = elements


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
    if isinstance(ty, StructT):
        return ty.name
    if isinstance(ty, UnknownT):
        raise ValueError(f"unresolved type hole: {ty.hint}")
    raise NotImplementedError(f"type {type(ty).__name__}")
