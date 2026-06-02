"""MIR -> Mojo LIR.

Mojo's binding model is `var`-only (no `let`/`mut` split). Every locally
introduced name emits `var ...`; reassignments emit plain `<name> = ...`.
Loop variables are scoped to the loop body and don't need a declaration.

String concat: Mojo `String` supports `+`, so we can emit it directly without
the format!() detour Rust needs.

Structure is shared with the other backends via ``_mir_lower_base``; this
module supplies the Mojo spec plus the cmath/SIMD/pow_N call rewrites and the
`import math` bookkeeping.
"""

from __future__ import annotations

import re

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

from ._mir_lower_base import MirLoweringBase


# <cmath> functions that live in Mojo's `math` module -> emit as `math.<name>`
# (with an `import math` header). Names not here that are Mojo builtins map to
# the builtin directly (no import).
_MATH_FNS = frozenset({
    "exp", "log", "log2", "log10", "sqrt", "cbrt", "pow", "fmod", "hypot",
    "sin", "cos", "tan", "asin", "acos", "atan", "atan2",
    "sinh", "cosh", "tanh", "ceil", "floor", "trunc",
})
_BUILTIN_MAP = {"fabs": "abs", "fmin": "min", "fmax": "max"}


class _MojoLowering(MirLoweringBase):
    prefix = "Mojo"
    module_cls = lir.MojoModule

    def __init__(self) -> None:
        super().__init__()
        self._used_math: set[str] = set()

    def type_str(self, ty: Type) -> str:
        return _mojo_type(ty)

    def lower_module(self, module: mir.MirModule) -> lir.MojoModule:
        self._used_math.clear()
        items: list[lir.LirNode] = []
        for struct in module.structs:
            items.extend(self.lower_struct_items(struct))
        for fn in module.functions:
            items.append(self.lower_function(fn))
        # Idiomatic Mojo uses `from math import sqrt, exp` (explicit names), not
        # `import math` + qualified `math.sqrt` (module-qualified access is not
        # the standard form). Only the actually-used names are imported.
        imports = ([f"from math import {', '.join(sorted(self._used_math))}"]
                   if self._used_math else [])
        return lir.MojoModule(items=items, imports=imports)

    # -- function signature: var/mut param decoration --------------------- #

    def lower_params(self, fn: mir.MirFunction):
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
        return params

    # -- assign: var vs bare reassign ------------------------------------- #

    def lower_assign(self, node: mir.MirAssign, declared: set[str], mut: set[str]):
        if node.augmented_op is not None:
            rhs = lir.MojoBinOp(
                op=node.augmented_op,
                left=lir.MojoName(name=node.target),
                right=self.lower_expr(node.value),
            )
            return lir.MojoReassign(name=node.target, value=rhs)
        if node.target in declared:
            return lir.MojoReassign(name=node.target, value=self.lower_expr(node.value))
        declared.add(node.target)
        return lir.MojoVar(
            name=node.target,
            ty=_mojo_type(node.ty) if not isinstance(node.ty, UnknownT) else None,
            value=self.lower_expr(node.value),
        )

    # -- expressions ------------------------------------------------------- #

    def lower_expr_special(self, node: mir.MirNode):
        if isinstance(node, mir.MirBinOp) and node.op == "//":
            return lir.MojoBinOp(op="//", left=self.lower_expr(node.left), right=self.lower_expr(node.right))
        return None

    def lower_binop(self, node: mir.MirBinOp):
        return lir.MojoBinOp(op=node.op, left=self.lower_expr(node.left), right=self.lower_expr(node.right))

    def lower_boolop(self, node: mir.MirBoolOp):
        return lir.MojoBoolOp(op=node.op, left=self.lower_expr(node.left), right=self.lower_expr(node.right))

    def lower_unary(self, node: mir.MirUnaryOp):
        op = "not" if node.op == "not" else "-"
        return lir.MojoUnary(op=op, operand=self.lower_expr(node.operand))

    def lower_null(self, node: mir.MirNullLiteral):
        return lir.MojoName(name="None")

    def lower_list(self, node: mir.MirList):
        return lir.MojoList(elements=[self.lower_expr(e) for e in node.elements])

    def lower_call(self, node: mir.MirCall):
        args = [self.lower_expr(a) for a in node.args]
        if node.func == "__ternary__" and len(args) == 3:
            return _MojoIfExpr(test=args[0], then_=args[1], else_=args[2])
        # ObjexxFCL integer-power helpers (pervasive in EnergyPlus): pow_2(x) -> x**2.
        _pn = re.fullmatch(r"pow_(\d+)", node.func)
        if _pn and len(args) == 1:
            return lir.MojoBinOp(op="**", left=args[0],
                                 right=lir.MojoIntLiteral(value=int(_pn.group(1))))
        # ObjexxFCL/Fortran scalar intrinsics.
        if node.func == "mod" and len(args) == 2:          # mod(a, b) -> a % b
            return lir.MojoBinOp(op="%", left=args[0], right=args[1])
        if node.func == "sign" and len(args) == 2:         # Fortran SIGN(a,b) == copysign
            self._used_math.add("copysign")
            return lir.MojoCall(func="copysign", args=args)
        if node.func == "len":
            if len(args) != 1:
                raise ValueError("len() takes exactly one argument")
            return lir.MojoCall(func="len", args=args)
        # SIMD lifting — the C++ frontend translates Intel intrinsics into
        # synthetic `simd_pack` / `simd_splat` / `simd_zero` / `simd_sqrt`
        # calls. Map them to Mojo's portable `SIMD[DType.X, N](...)` form.
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
        # <cmath> intrinsics -> Mojo math fns via `from math import <name>`.
        if node.func in _MATH_FNS:
            self._used_math.add(node.func)
            return lir.MojoCall(func=node.func, args=args)
        if node.func in _BUILTIN_MAP:
            return lir.MojoCall(func=_BUILTIN_MAP[node.func], args=args)
        # Print/abs/min/max identity (already Mojo builtins).
        return lir.MojoCall(func=node.func, args=args)


_LOWERING = _MojoLowering()


def mir_to_mojo_lir(module: mir.MirModule) -> lir.MojoModule:
    return _LOWERING.lower_module(module)


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
