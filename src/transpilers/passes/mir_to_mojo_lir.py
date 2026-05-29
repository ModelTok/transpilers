"""MIR -> Mojo LIR.

Mojo's binding model is `var`-only (no `let`/`mut` split). Every locally
introduced name emits `var ...`; reassignments emit plain `<name> = ...`.
Loop variables are scoped to the loop body and don't need a declaration.

String concat: Mojo `String` supports `+`, so we can emit it directly without
the format!() detour Rust needs.
"""

from __future__ import annotations

from transpilers.ir import lir, mir
from transpilers.ir.types import (
    BoolT,
    FloatT,
    IntT,
    ListT,
    NoneT,
    SimdT,
    StrT,
    StructT,
    Type,
    UnknownT,
)


# <cmath> functions that live in Mojo's `math` module -> emit as `math.<name>`
# (with an `import math` header). Names not here that are Mojo builtins map to
# the builtin directly (no import).
_MATH_FNS = frozenset({
    "exp", "log", "log2", "log10", "sqrt", "cbrt", "pow", "fmod", "hypot",
    "sin", "cos", "tan", "asin", "acos", "atan", "atan2",
    "sinh", "cosh", "tanh", "ceil", "floor", "trunc",
})
_BUILTIN_MAP = {"fabs": "abs", "fmin": "min", "fmax": "max"}
_used_math: set[str] = set()


def mir_to_mojo_lir(module: mir.MirModule) -> lir.MojoModule:
    _used_math.clear()
    items: list[lir.LirNode] = []
    for struct in module.structs:
        items.append(_lower_struct(struct))
    for fn in module.functions:
        items.append(_lower_function(fn))
    imports = ["math"] if _used_math else []
    return lir.MojoModule(items=items, imports=imports)


def _lower_struct(s: mir.MirStruct) -> lir.MojoStruct:
    return lir.MojoStruct(
        name=s.name,
        fields=[(f.name, _mojo_type(f.ty)) for f in s.fields],
        methods=[_lower_function(m) for m in s.methods],
    )


def _lower_function(fn: mir.MirFunction) -> lir.MojoFn:
    # Mojo args are read-only by default; reassigning to `n` errors unless
    # the param is declared `var n: …`. Subscript-assigning to `xs` (e.g.
    # `xs[i] = v`) requires `mut xs: …` instead. Scan the body for both.
    param_names = {p.name for p in fn.params}
    var_params, mut_params = _params_reassigned(fn.body, param_names)
    params = []
    for p in fn.params:
        if p.name in mut_params:
            params.append((f"mut {p.name}", _mojo_type(p.ty)))
        elif p.name in var_params:
            params.append((f"var {p.name}", _mojo_type(p.ty)))
        else:
            params.append((p.name, _mojo_type(p.ty)))
    ret = _mojo_type(fn.return_type)
    declared: set[str] = {p.name for p in fn.params}
    body = [_lower_stmt(n, declared) for n in fn.body]
    return lir.MojoFn(name=fn.name, params=params, return_type=ret, body=body)


def _params_reassigned(
    body: list[mir.MirNode], param_names: set[str]
) -> tuple[set[str], set[str]]:
    """Return two sets: (var_params, mut_params).

    var_params: params that are scalar-reassigned (need `var` prefix).
    mut_params: params that are subscript-assigned (need `mut` prefix).
    """
    var_out: set[str] = set()
    mut_out: set[str] = set()

    def _scan(nodes: list[mir.MirNode]) -> None:
        for n in nodes:
            if isinstance(n, mir.MirAssign) and n.target in param_names:
                var_out.add(n.target)
            elif (
                isinstance(n, mir.MirSubscriptAssign)
                and isinstance(n.obj, mir.MirName)
                and n.obj.name in param_names
            ):
                mut_out.add(n.obj.name)
            elif isinstance(n, mir.MirIf):
                _scan(n.body)
                _scan(n.orelse)
            elif isinstance(n, mir.MirWhile):
                _scan(n.body)
            elif isinstance(n, mir.MirForRange):
                _scan(n.body)

    _scan(body)
    return var_out, mut_out


def _lower_stmt(node: mir.MirNode, declared: set[str]) -> lir.LirNode:
    if isinstance(node, mir.MirReturn):
        return lir.MojoReturn(value=_lower_expr(node.value) if node.value else None)
    if isinstance(node, mir.MirBreak):
        return lir.MojoBreak()
    if isinstance(node, mir.MirContinue):
        return lir.MojoContinue()
    if isinstance(node, mir.MirFieldAssign):
        return lir.MojoFieldAssign(
            obj=_lower_expr(node.obj), field=node.field, value=_lower_expr(node.value)
        )
    if isinstance(node, mir.MirSubscriptAssign):
        return lir.MojoSubscriptAssign(
            obj=_lower_expr(node.obj),
            index=_lower_expr(node.index),
            value=_lower_expr(node.value),
        )
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
    if isinstance(node, mir.MirBinOp) and node.op == "//":
        return lir.MojoBinOp(op="//", left=_lower_expr(node.left), right=_lower_expr(node.right))
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
    if isinstance(node, mir.MirNullLiteral):
        return lir.MojoName(name="None")
    if isinstance(node, mir.MirCall):
        return _lower_call(node)
    if isinstance(node, mir.MirList):
        return lir.MojoList(elements=[_lower_expr(e) for e in node.elements])
    if isinstance(node, mir.MirSubscript):
        return lir.MojoIndex(value=_lower_expr(node.value), index=_lower_expr(node.index))
    if isinstance(node, mir.MirFieldAccess):
        return lir.MojoFieldAccess(value=_lower_expr(node.value), field=node.field)
    if isinstance(node, mir.MirStructInit):
        return lir.MojoStructInit(
            name=node.name,
            field_values=[(n, _lower_expr(v)) for n, v in node.field_values],
        )
    raise NotImplementedError(f"MIR expr {type(node).__name__}")


def _lower_call(node: mir.MirCall) -> lir.LirNode:
    args = [_lower_expr(a) for a in node.args]
    if node.func == "__ternary__" and len(args) == 3:
        return _MojoIfExpr(test=args[0], then_=args[1], else_=args[2])
    if node.func == "len":
        if len(args) != 1:
            raise ValueError("len() takes exactly one argument")
        return lir.MojoCall(func="len", args=args)
    # SIMD lifting — the C++ frontend translates Intel intrinsics into
    # synthetic `simd_pack` / `simd_splat` / `simd_zero` / `simd_sqrt`
    # calls. Map them to Mojo's portable `SIMD[DType.X, N](...)` form.
    # We assume float64 + lanes-from-arg-count for the heuristic; a real
    # type-context-propagation pass could pick precisely.
    if node.func == "simd_pack" and args:
        return lir.MojoCall(func=f"SIMD[DType.float64, {len(args)}]", args=args)
    if node.func == "simd_splat" and len(args) == 1:
        return lir.MojoCall(func="SIMD[DType.float64, 4]", args=args)
    if node.func == "simd_zero" and not args:
        return lir.MojoCall(
            func="SIMD[DType.float64, 4]",
            args=[lir.MojoFloatLiteral(value=0.0)],
        )
    if node.func == "simd_sqrt" and len(args) == 1:
        return lir.MojoMethodCall(receiver=args[0], method="sqrt", args=[])
    if node.func == "simd_abs" and len(args) == 1:
        return lir.MojoCall(func="abs", args=args)
    # <cmath> intrinsics -> Mojo `math.<name>` (+ `import math`).
    if node.func in _MATH_FNS:
        _used_math.add(node.func)
        return lir.MojoCall(func=f"math.{node.func}", args=args)
    if node.func in _BUILTIN_MAP:
        return lir.MojoCall(func=_BUILTIN_MAP[node.func], args=args)
    # Print/abs/min/max identity (already Mojo builtins).
    return lir.MojoCall(func=node.func, args=args)


class _MojoIfExpr(lir.LirNode):
    """`<then> if <test> else <else>` — Python/Mojo ternary syntax."""

    def __init__(self, test: lir.LirNode, then_: lir.LirNode, else_: lir.LirNode) -> None:
        self.test = test
        self.then_ = then_
        self.else_ = else_


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
    if isinstance(ty, SimdT):
        # `SIMD[DType.<elem>, <lanes>]` — Mojo's portable SIMD type. The
        # compiler picks AVX2/AVX-512/NEON/SVE per target ISA.
        return f"SIMD[DType.{_dtype_for(ty.elem)}, {ty.lanes}]"
    if isinstance(ty, UnknownT):
        raise ValueError(f"unresolved type hole: {ty.hint}")
    raise NotImplementedError(f"type {type(ty).__name__}")


def _dtype_for(elem: Type) -> str:
    if isinstance(elem, FloatT):
        return f"float{elem.bits}"
    if isinstance(elem, IntT):
        prefix = "int" if elem.signed else "uint"
        return f"{prefix}{elem.bits}"
    if isinstance(elem, BoolT):
        return "bool"
    raise NotImplementedError(f"no DType for {type(elem).__name__}")
