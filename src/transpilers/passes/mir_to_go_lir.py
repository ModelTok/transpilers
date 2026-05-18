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


def _collect_used_names(nodes: list[mir.MirNode]) -> set[str]:
    """Collect all MirName references (not assignment targets) in the body."""
    used: set[str] = set()
    for n in nodes:
        _collect_used_in(n, used)
    return used


def _collect_used_in(node: mir.MirNode, used: set[str]) -> None:
    if isinstance(node, mir.MirName):
        used.add(node.name)
    elif isinstance(node, mir.MirAssign):
        # The target is an assignment destination, not a use.
        # But augmented ops (+=, etc.) do read the target.
        if node.augmented_op is not None:
            used.add(node.target)
        _collect_used_in(node.value, used)
    elif isinstance(node, mir.MirReturn):
        if node.value is not None:
            _collect_used_in(node.value, used)
    elif isinstance(node, mir.MirIf):
        _collect_used_in(node.test, used)
        for c in node.body:
            _collect_used_in(c, used)
        for c in node.orelse:
            _collect_used_in(c, used)
    elif isinstance(node, mir.MirWhile):
        _collect_used_in(node.test, used)
        for c in node.body:
            _collect_used_in(c, used)
    elif isinstance(node, mir.MirForRange):
        _collect_used_in(node.start, used)
        _collect_used_in(node.stop, used)
        if node.step is not None:
            _collect_used_in(node.step, used)
        for c in node.body:
            _collect_used_in(c, used)
    elif isinstance(node, (mir.MirBinOp, mir.MirCompare, mir.MirBoolOp)):
        _collect_used_in(node.left, used)
        _collect_used_in(node.right, used)
    elif isinstance(node, mir.MirUnaryOp):
        _collect_used_in(node.operand, used)
    elif isinstance(node, mir.MirCall):
        for a in node.args:
            _collect_used_in(a, used)
    elif isinstance(node, mir.MirList):
        for e in node.elements:
            _collect_used_in(e, used)
    elif isinstance(node, mir.MirSubscript):
        _collect_used_in(node.value, used)
        _collect_used_in(node.index, used)
    elif isinstance(node, mir.MirSubscriptAssign):
        _collect_used_in(node.obj, used)
        _collect_used_in(node.index, used)
        _collect_used_in(node.value, used)
    elif isinstance(node, mir.MirFieldAssign):
        _collect_used_in(node.obj, used)
        _collect_used_in(node.value, used)
    elif isinstance(node, mir.MirFieldAccess):
        _collect_used_in(node.value, used)
    elif isinstance(node, mir.MirMethodCall):
        _collect_used_in(node.receiver, used)
        for a in node.args:
            _collect_used_in(a, used)
    elif isinstance(node, mir.MirStructInit):
        for _, v in node.field_values:
            _collect_used_in(v, used)


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
    used_names = _collect_used_names(fn.body)
    body_nodes: list[lir.LirNode] = []
    for n in fn.body:
        result = _lower_stmt(n, declared, used_names)
        if result is not None:
            body_nodes.append(result)
    return lir.GoFn(name=fn.name, params=params, return_type=ret, body=body_nodes)


def _lower_stmt(node: mir.MirNode, declared: set[str], used_names: set[str] | None = None) -> lir.LirNode | None:
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
        return _lower_assign(node, declared, used_names)
    if isinstance(node, mir.MirIf):
        return lir.GoIf(
            test=_lower_expr(node.test),
            body=[s for n in node.body if (s := _lower_stmt(n, declared, used_names)) is not None],
            orelse=[s for n in node.orelse if (s := _lower_stmt(n, declared, used_names)) is not None],
        )
    if isinstance(node, mir.MirWhile):
        return lir.GoWhile(
            test=_lower_expr(node.test),
            body=[s for n in node.body if (s := _lower_stmt(n, declared, used_names)) is not None],
        )
    if isinstance(node, mir.MirForRange):
        return lir.GoForRange(
            target=node.target,
            start=_lower_expr(node.start),
            stop=_lower_expr(node.stop),
            step=_lower_expr(node.step) if node.step else None,
            body=[s for n in node.body if (s := _lower_stmt(n, declared, used_names)) is not None],
        )
    return _lower_expr(node)


def _lower_assign(node: mir.MirAssign, declared: set[str], used_names: set[str] | None = None) -> lir.LirNode | None:
    if node.augmented_op is not None:
        rhs = lir.GoBinOp(op=node.augmented_op, left=lir.GoName(name=node.target), right=_lower_expr(node.value))
        return lir.GoReassign(name=node.target, value=rhs)
    if node.target in declared:
        return lir.GoReassign(name=node.target, value=_lower_expr(node.value))
    # Skip declarations of variables that are never read — Go forbids unused vars.
    if used_names is not None and node.target not in used_names:
        return None
    declared.add(node.target)
    return lir.GoDecl(
        name=node.target,
        ty=_go_type(node.ty) if not isinstance(node.ty, UnknownT) else "int64",
        value=_lower_expr(node.value),
    )


def _lower_expr(node: mir.MirNode) -> lir.LirNode:
    if isinstance(node, mir.MirBinOp) and node.op == "//":
        return lir.GoBinOp(op="/", left=_lower_expr(node.left), right=_lower_expr(node.right))
    if isinstance(node, mir.MirBinOp) and node.op == "+" and _is_list_concat(node):
        # Python `a + [x]` on lists → Go `append(a, x...)` or `append(a, elems...)`
        left = _lower_expr(node.left)
        right_mir = node.right
        if isinstance(right_mir, mir.MirList):
            # append(left, elem, elem, ...)
            elem_args = [_lower_expr(e) for e in right_mir.elements]
            return lir.GoCall(func="append", args=[left] + elem_args)
        # General case: append(left, right...)
        return _GoSliceAppend(left=left, right=_lower_expr(right_mir))
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
        arg_nodes = node.args  # keep MIR args for type inspection
        args = [_lower_expr(a) for a in arg_nodes]
        if node.func == "len":
            # Go's len() returns int, not int64; cast to avoid type mismatches.
            return lir.GoCall(func="int64", args=[lir.GoCall(func="len", args=args)])
        if node.func in ("print", "println"):
            # Go's `println` builtin writes to stderr — not what Python's
            # print does. Use `fmt.Println` for stdout. The Go emitter
            # adds the `import "fmt"` when it sees the qualified call.
            # Wrap float args with strconv.FormatFloat to match Python's repr(),
            # and bool args with a map expression to capitalise True/False.
            wrapped = [_wrap_print_arg(a, m) for a, m in zip(args, arg_nodes)]
            return lir.GoCall(func="fmt.Println", args=wrapped)
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


class _GoSliceAppend(lir.LirNode):
    """`append(left, right...)` — general slice concatenation."""

    def __init__(self, left: lir.LirNode, right: lir.LirNode) -> None:
        self.left = left
        self.right = right


class _GoBoolStr(lir.LirNode):
    """Emits `map[bool]string{true: "True", false: "False"}[x]` to match
    Python's capitalised bool output."""

    def __init__(self, value: lir.LirNode) -> None:
        self.value = value


class _GoFloatStr(lir.LirNode):
    """Emits `strconv.FormatFloat(x, 'g', -1, 64)` to match Python's float repr."""

    def __init__(self, value: lir.LirNode) -> None:
        self.value = value


def _wrap_print_arg(lowered: lir.LirNode, mir_arg: mir.MirNode) -> lir.LirNode:
    """Wrap a print argument so its string representation matches Python."""
    ty = getattr(mir_arg, "ty", None)
    if isinstance(ty, BoolT):
        return _GoBoolStr(value=lowered)
    if isinstance(ty, FloatT):
        return _GoFloatStr(value=lowered)
    return lowered


def _is_list_concat(node: mir.MirBinOp) -> bool:
    return isinstance(getattr(node.left, "ty", None), ListT) or isinstance(
        getattr(node.right, "ty", None), ListT
    )


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
