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
from transpilers.ir.types import BoolT, FloatT, IntT, ListT, NoneT, StrT, StructT, Type, UnknownT


def mir_to_zig_lir(module: mir.MirModule) -> lir.ZigModule:
    items: list[lir.LirNode] = []
    for s in module.structs:
        items.append(_lower_struct(s))
    for fn in module.functions:
        items.append(_lower_function(fn))
    return lir.ZigModule(items=items)


def _lower_struct(s: mir.MirStruct) -> lir.ZigStruct:
    return lir.ZigStruct(
        name=s.name,
        fields=[(f.name, _zig_type(f.ty)) for f in s.fields],
        methods=[_lower_function(m) for m in s.methods],
    )


def _lower_function(fn: mir.MirFunction) -> lir.ZigFn:
    # Determine which list params are mutated via subscript assignment.
    param_names = {p.name for p in fn.params}
    mutated_list_params = _collect_subscript_mutated_params(fn.body, param_names)
    # Zig function parameters are const. If a parameter is reassigned in the
    # body, we rename it in the signature (e.g., `n` → `n_`) and declare
    # a mutable shadow `var n: T = n_;` at the top of the body.
    reassigned_params = _collect_reassigned_params(fn.body, param_names)
    params = []
    for p in fn.params:
        param_name = f"{p.name}_" if p.name in reassigned_params else p.name
        params.append((param_name, _zig_list_param_type(p.ty, p.name, mutated_list_params)))
    ret = _zig_type(fn.return_type)
    mut_names = _collect_mutable(fn.body)
    # Parameters start in `declared`. Reassigned params get a mutable preamble.
    declared: set[str] = param_names.copy()
    preamble: list[lir.LirNode] = []
    for p in fn.params:
        if p.name in reassigned_params:
            # `var n: i64 = n_;` — binds the renamed param into a mutable local.
            preamble.append(lir.ZigVar(
                name=p.name,
                mutable=True,
                ty=_zig_type(p.ty) if not isinstance(p.ty, UnknownT) else None,
                value=lir.ZigName(name=f"{p.name}_"),
            ))
    body = preamble + [_lower_stmt(n, declared, mut_names) for n in fn.body]
    return lir.ZigFn(name=fn.name, params=params, return_type=ret, body=body)


def _collect_reassigned_params(body: list[mir.MirNode], param_names: set[str]) -> set[str]:
    """Return names of parameters that are reassigned (non-augmented) in the body."""
    reassigned: set[str] = set()
    _scan_reassigned(body, param_names, reassigned)
    return reassigned


def _scan_reassigned(nodes: list[mir.MirNode], param_names: set[str], out: set[str]) -> None:
    for n in nodes:
        if isinstance(n, mir.MirAssign) and n.target in param_names:
            out.add(n.target)
        elif isinstance(n, mir.MirIf):
            _scan_reassigned(n.body, param_names, out)
            _scan_reassigned(n.orelse, param_names, out)
        elif isinstance(n, mir.MirWhile):
            _scan_reassigned(n.body, param_names, out)
        elif isinstance(n, mir.MirForRange):
            _scan_reassigned(n.body, param_names, out)


def _collect_subscript_mutated_params(body: list[mir.MirNode], param_names: set[str]) -> set[str]:
    """Return names of params that appear as the target of a subscript assignment."""
    mutated: set[str] = set()
    _scan_subscript_assigns(body, param_names, mutated)
    return mutated


def _scan_subscript_assigns(nodes: list[mir.MirNode], param_names: set[str], mutated: set[str]) -> None:
    for n in nodes:
        if isinstance(n, mir.MirSubscriptAssign):
            if isinstance(n.obj, mir.MirName) and n.obj.name in param_names:
                mutated.add(n.obj.name)
        elif isinstance(n, mir.MirIf):
            _scan_subscript_assigns(n.body, param_names, mutated)
            _scan_subscript_assigns(n.orelse, param_names, mutated)
        elif isinstance(n, mir.MirWhile):
            _scan_subscript_assigns(n.body, param_names, mutated)
        elif isinstance(n, mir.MirForRange):
            _scan_subscript_assigns(n.body, param_names, mutated)


def _zig_list_param_type(ty: Type, name: str, mutated: set[str]) -> str:
    """Return the Zig type for a function parameter.
    List params use slices; mutable ones drop the `const`."""
    if isinstance(ty, ListT):
        elem = _zig_type(ty.elem)
        if name in mutated:
            return f"[]{elem}"
        return f"[]const {elem}"
    return _zig_type(ty)


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
        elif isinstance(n, mir.MirFieldAssign):
            if isinstance(n.obj, mir.MirName):
                aug.add(n.obj.name)
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
    if isinstance(node, mir.MirFieldAssign):
        return lir.ZigFieldAssign(
            obj=_lower_expr(node.obj), field=node.field, value=_lower_expr(node.value)
        )
    if isinstance(node, mir.MirSubscriptAssign):
        return lir.ZigSubscriptAssign(
            obj=_lower_expr(node.obj),
            index=_lower_expr(node.index),
            value=_lower_expr(node.value),
        )
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
            # When the stop is a `len(xs)` call, use a while loop with an
            # i64 counter instead of `for (0..xs.len) |i|`. The Zig for-range
            # yields `usize`, but the loop body may use `i` as `i64` (e.g.,
            # `return i`). A while loop keeps the counter as i64 consistently.
            if _is_len_call(node.stop):
                target = node.target
                declared.add(target)
                return _stepped_while_explicit(
                    target, node, declared, mut,
                    start=_lower_expr(node.start),
                    stop=_lower_expr(node.stop),
                )
            stop_expr = _lower_expr(node.stop)
            return lir.ZigForRange(
                target=node.target,
                start=_lower_expr(node.start),
                stop=stop_expr,
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


class _ZigMutableArrayDecl(lir.LirNode):
    """A two-statement list-variable declaration for mutable slices:
        var <arr_name> = <array_lit>;
        const <name>: []<elem_ty> = <arr_name>[0..];
    Emitted when a list literal needs to coerce to a mutable slice."""

    def __init__(self, name: str, arr_name: str, array_lit: lir.ZigArrayLit) -> None:
        self.name = name
        self.arr_name = arr_name
        self.array_lit = array_lit


def _lower_assign(node: mir.MirAssign, declared: set[str], mut: set[str]) -> lir.LirNode:
    if node.augmented_op is not None:
        op = node.augmented_op
        rhs_expr = _lower_expr(node.value)
        lhs = lir.ZigName(name=node.target)
        # Zig requires @divTrunc / @rem for integer division and modulo —
        # the augmented `/=` and `%=` forms can't use builtin calls directly,
        # so we lower to a plain reassign with the builtin call as the RHS.
        target_ty = getattr(node, "ty", None)
        if op in ("/", "//") and _is_int_type(target_ty):
            value = lir.ZigCall(func="@divTrunc", args=[lhs, rhs_expr])
        elif op == "%" and _is_int_type(target_ty):
            value = lir.ZigCall(func="@rem", args=[lhs, rhs_expr])
        else:
            value = lir.ZigBinOp(op=op, left=lhs, right=rhs_expr)
        return lir.ZigReassign(name=node.target, value=value)
    lowered_value = _lower_expr(node.value)
    # When the value is a list literal, emit a two-statement mutable array decl.
    # This produces `var _xs_arr = [_]i64{...}; var xs: []i64 = _xs_arr[0..];`
    # so the slice can be passed to both mutable and immutable slice parameters.
    if isinstance(lowered_value, lir.ZigArrayLit) and isinstance(node.ty, ListT):
        arr_name = f"_{node.target}_arr"
        return _ZigMutableArrayDecl(name=node.target, arr_name=arr_name, array_lit=lowered_value)
    if node.target in declared:
        return lir.ZigReassign(name=node.target, value=lowered_value)
    declared.add(node.target)
    return lir.ZigVar(
        name=node.target,
        mutable=node.target in mut,
        ty=_zig_type(node.ty) if not isinstance(node.ty, UnknownT) else None,
        value=lowered_value,
    )


def _lower_expr(node: mir.MirNode) -> lir.LirNode:
    if isinstance(node, mir.MirFieldAccess):
        return lir.ZigFieldAccess(value=_lower_expr(node.value), field=node.field)
    if isinstance(node, mir.MirStructInit):
        return lir.ZigStructInit(
            name=node.name,
            field_values=[(n, _lower_expr(v)) for n, v in node.field_values],
        )
    if isinstance(node, mir.MirMethodCall):
        # Zig method calls land as `receiver.method(args)` — same emission
        # as a regular method call since the receiver is implicit in Zig's
        # `pub fn method(self: T, ...)` declarations.
        return _ZigMethodCall(
            receiver=_lower_expr(node.receiver),
            method=node.method,
            args=[_lower_expr(a) for a in node.args],
        )
    if isinstance(node, mir.MirBinOp):
        left = _lower_expr(node.left)
        right = _lower_expr(node.right)
        left_ty = getattr(node.left, "ty", None)
        right_ty = getattr(node.right, "ty", None)
        both_int = _is_int_type(left_ty) or _is_int_type(right_ty)
        # Zig requires explicit builtins for integer division and modulo.
        # `/` and `//` → @divTrunc; `%` → @rem.
        if node.op in ("/", "//"):
            if both_int:
                return lir.ZigCall(func="@divTrunc", args=[left, right])
            # Float division keeps plain `/`.
            return lir.ZigBinOp(op="/", left=left, right=right)
        if node.op == "%":
            if both_int:
                return lir.ZigCall(func="@rem", args=[left, right])
            return lir.ZigBinOp(op="%", left=left, right=right)
        if _is_string_concat(node):
            raise NotImplementedError(
                "string concatenation in Zig requires allocator-aware emission "
                "(std.fmt.allocPrint), not yet supported"
            )
        return lir.ZigBinOp(op=node.op, left=left, right=right)
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
    if isinstance(node, mir.MirFloatLiteral):
        return lir.ZigFloatLiteral(value=node.value)
    if isinstance(node, mir.MirBoolLiteral):
        return lir.ZigBoolLiteral(value=node.value)
    if isinstance(node, mir.MirStringLiteral):
        return lir.ZigStringLiteral(value=node.value)
    if isinstance(node, mir.MirNullLiteral):
        return lir.ZigName(name="null")
    if isinstance(node, mir.MirCall):
        return _lower_call(node)
    if isinstance(node, mir.MirList):
        elem_ty = _zig_type(node.ty.elem) if isinstance(node.ty, ListT) else "i64"
        return lir.ZigArrayLit(elem_ty=elem_ty, elements=[_lower_expr(e) for e in node.elements])
    if isinstance(node, mir.MirSubscript):
        return lir.ZigIndex(value=_lower_expr(node.value), index=_lower_expr(node.index))
    raise NotImplementedError(f"MIR expr {type(node).__name__}")


def _lower_call(node: mir.MirCall) -> lir.LirNode:
    args = [_lower_expr(a) for a in node.args]
    if node.func == "__ternary__" and len(args) == 3:
        return _ZigIfExpr(test=args[0], then_=args[1], else_=args[2])
    if node.func == "len":
        if len(args) != 1:
            raise ValueError("len() takes exactly one argument")
        return lir.ZigMethodCall(receiver=args[0], method="len", args=[], cast_to="i64")
    # Stdlib mapping. Zig has @abs/@min/@max as builtins (prefixed with `@`).
    # Print goes through std.debug.print with a format string and tuple.
    if node.func in ("print", "println"):
        # `std.debug.print("{}\n", .{<args>})`. The trailing newline matches
        # Python's print default and Rust's println!.
        # Rewrap each arg so bools render as "True"/"False" like Python.
        rendered_args = [_pyprint_arg(orig, lowered) for orig, lowered in zip(node.args, args)]
        # Build the template after wrapping: bool args become []const u8 (string),
        # which needs `{s}`; everything else uses `{}`.
        specs = []
        for orig, rendered in zip(node.args, rendered_args):
            orig_ty = getattr(orig, "ty", None)
            if isinstance(orig_ty, BoolT) or isinstance(rendered, _ZigIfExpr):
                specs.append("{s}")
            elif isinstance(orig_ty, FloatT) or isinstance(rendered, _ZigPyFloat):
                specs.append("{s}")
            else:
                specs.append("{}")
        template = " ".join(specs) + "\n"
        # Encode the call as a regular ZigCall whose first arg is a string
        # literal and second arg is a synthetic ".{a, b, c}" tuple expression.
        # Emitter sees the special name and renders the tuple form.
        return lir.ZigCall(
            func="std.debug.print",
            args=[lir.ZigStringLiteral(value=template), _ZigTuple(rendered_args)],
        )
    if node.func == "abs" and len(args) == 1:
        return lir.ZigCall(func="@abs", args=args)
    if node.func == "min" and len(args) == 2:
        return lir.ZigCall(func="@min", args=args)
    if node.func == "max" and len(args) == 2:
        return lir.ZigCall(func="@max", args=args)
    if node.func == "int" and len(args) == 1:
        # Cast-to-int — Zig requires explicit @as for type assertions.
        return lir.ZigCall(func="@as", args=[lir.ZigName(name="i64"), args[0]])
    if node.func == "float" and len(args) == 1:
        return lir.ZigCall(func="@floatFromInt", args=args)
    if node.func == "bool" and len(args) == 1:
        return lir.ZigCompare(op="!=", left=args[0], right=lir.ZigIntLiteral(value=0))
    return lir.ZigCall(func=node.func, args=args)


class _ZigTuple(lir.LirNode):
    """`.{a, b, c}` — Zig anonymous struct literal used as the args
    parameter of std.debug.print. Not a public LIR shape; emitter
    renders specially."""

    def __init__(self, elements: list[lir.LirNode]) -> None:
        self.elements = elements


class _ZigIfExpr(lir.LirNode):
    """`if (<test>) <then_> else <else_>` — Zig if-expression used for
    bool-to-Python-string rendering in print args."""

    def __init__(self, test: lir.LirNode, then_: lir.LirNode, else_: lir.LirNode) -> None:
        self.test = test
        self.then_ = then_
        self.else_ = else_


class _ZigMethodCall(lir.LirNode):
    """Local carrier for receiver.method(args) emission. Same shape as
    ZigMethodCall but distinguishable from the `.len`-style property
    access that the existing ZigMethodCall handles."""

    def __init__(self, receiver: lir.LirNode, method: str, args: list[lir.LirNode]) -> None:
        self.receiver = receiver
        self.method = method
        self.args = args


def _is_len_call(node: mir.MirNode) -> bool:
    """Return True if `node` is a `len(xs)` call."""
    return isinstance(node, mir.MirCall) and node.func == "len" and len(node.args) == 1


def _stepped_while_explicit(
    target: str,
    node: mir.MirForRange,
    declared: set[str],
    mut: set[str],
    start: lir.LirNode,
    stop: lir.LirNode,
) -> lir.LirNode:
    """Emit `for i in range(0, N)` as a while loop with an i64 counter.

    var i: i64 = start;
    while (i < stop) {
        ...body...
        i += 1;
    }
    """
    init = lir.ZigVar(name=target, mutable=True, ty="i64", value=start)
    cond = lir.ZigCompare(op="<", left=lir.ZigName(name=target), right=stop)
    incr = lir.ZigReassign(
        name=target,
        value=lir.ZigBinOp(op="+", left=lir.ZigName(name=target), right=lir.ZigIntLiteral(value=1)),
    )
    body = [_lower_stmt(n, declared, mut) for n in node.body]
    body.append(incr)
    return _ZigBlock(items=[init, lir.ZigWhile(test=cond, body=body)])


def _is_string_concat(node: mir.MirBinOp) -> bool:
    return (
        node.op == "+"
        and isinstance(getattr(node.left, "ty", None), StrT)
        and isinstance(getattr(node.right, "ty", None), StrT)
    )


def _is_int_type(ty: object) -> bool:
    """Return True if `ty` is a concrete integer type. An UnknownT or None
    does not count — we only apply @divTrunc / @rem when we can prove the
    operand is integer, since emitting the wrong builtin on floats breaks
    things worse than the original `/`."""
    return isinstance(ty, IntT)


def _pyprint_arg(orig: mir.MirNode, lowered: lir.LirNode) -> lir.LirNode:
    """Wrap `lowered` so it renders the way Python's `print` would."""
    ty = getattr(orig, "ty", None)
    if isinstance(ty, BoolT):
        return _ZigIfExpr(
            test=lowered,
            then_=lir.ZigStringLiteral(value="True"),
            else_=lir.ZigStringLiteral(value="False"),
        )
    if isinstance(ty, FloatT):
        return _ZigPyFloat(value=lowered)
    return lowered


class _ZigPyFloat(lir.LirNode):
    """`_py_float(x)` — calls the injected helper that preserves `.0`
    for whole-number floats, matching Python's print behavior."""

    def __init__(self, value: lir.LirNode) -> None:
        self.value = value


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
    if isinstance(ty, StructT):
        return ty.name
    if isinstance(ty, UnknownT):
        raise ValueError(f"unresolved type hole: {ty.hint}")
    raise NotImplementedError(f"type {type(ty).__name__}")
