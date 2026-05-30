"""MIR -> Rust LIR.

Target-shaping. Decides:
  - which assignments are declarations (`let`) vs reassignments
  - which bindings need `mut`
  - how `len(...)`, `range(...)` and similar builtins shape into Rust
  - which Python types map to which Rust types

Idiom rewrites (Python comprehensions -> .iter().map().collect()) belong in
dedicated idiom passes that may consult LLM hooks. This pass stays
algorithmic.

Structure is shared with the other backends via ``_mir_lower_base``; this
module supplies only the Rust-specific spec (type map, mutability decoration,
let/reassign split, builtin call table) and the private marker nodes the Rust
emitter consumes.
"""

from __future__ import annotations

from transpilers.ir import lir, mir
from transpilers.ir.types import BoolT, FloatT, IntT, ListT, NoneT, StrT, StructT, Type, UnknownT

from ._mir_lower_base import (
    MirLoweringBase,
    collect_mutable,
    is_list_concat,
    is_string_concat,
    scan_reassigned_params,
    scan_subscript_assigned_params,
)


class _RustLowering(MirLoweringBase):
    prefix = "Rust"
    module_cls = lir.RustModule

    def type_str(self, ty: Type) -> str:
        return _rust_type(ty)

    # -- struct: Rust splits into a def + an impl block -------------------- #

    def lower_struct_items(self, s: mir.MirStruct) -> list[lir.LirNode]:
        return [
            lir.RustStruct(name=s.name, fields=[(f.name, _rust_type(f.ty)) for f in s.fields]),
            lir.RustImpl(struct_name=s.name, methods=[self.lower_function(m) for m in s.methods]),
        ]

    # -- function signature: mut params + &mut for subscript-assigned ------ #

    def lower_params(self, fn: mir.MirFunction):
        mut_names = collect_mutable(fn.body)
        param_names = {p.name for p in fn.params}
        reassigned = scan_reassigned_params(fn.body, param_names)
        subscript_assigned = scan_subscript_assigned_params(fn.body, param_names)
        return [
            (
                f"mut {p.name}" if (p.name in mut_names or p.name in reassigned) else p.name,
                _rust_param_type(p.ty, mutable=p.name in subscript_assigned),
            )
            for p in fn.params
        ]

    def function_preamble(self, fn, param_names):
        return set(param_names), collect_mutable(fn.body), []

    # -- assign: let vs reassign, augmented unfold ------------------------- #

    def lower_assign(self, node: mir.MirAssign, declared: set[str], mut: set[str]):
        if node.augmented_op is not None:
            # x += value  →  x = x + value  (explicit form composes more
            # cleanly with type promotion later).
            rhs = lir.RustBinOp(
                op=node.augmented_op,
                left=lir.RustName(name=node.target),
                right=self.lower_expr(node.value),
            )
            return lir.RustReassign(name=node.target, value=rhs)
        if node.target in declared:
            return lir.RustReassign(name=node.target, value=self.lower_expr(node.value))
        declared.add(node.target)
        # Unknown inferred type → omit annotation; Rust's local inference
        # picks it up from the initializer.
        try:
            ty_str = _rust_type(node.ty) if not isinstance(node.ty, UnknownT) else None
        except ValueError:
            ty_str = None
        is_list = isinstance(node.ty, ListT)
        return lir.RustLet(
            name=node.target,
            mutable=(node.target in mut) or is_list,
            ty=ty_str,
            value=self.lower_expr(node.value),
        )

    # -- expressions ------------------------------------------------------- #

    def lower_binop(self, node: mir.MirBinOp):
        if is_string_concat(node):
            return lir.RustFormat(args=_flatten_concat(self, node))
        if is_list_concat(node):
            return _RustListConcat(left=self.lower_expr(node.left), right=self.lower_expr(node.right))
        # Python `//` (FloorDivide) → Rust `/` on integer types.
        op = "/" if node.op == "//" else node.op
        return lir.RustBinOp(op=op, left=self.lower_expr(node.left), right=self.lower_expr(node.right))

    def lower_boolop(self, node: mir.MirBoolOp):
        op = "&&" if node.op == "and" else "||"
        return lir.RustBoolOp(op=op, left=self.lower_expr(node.left), right=self.lower_expr(node.right))

    def lower_null(self, node: mir.MirNullLiteral):
        # No OptionT in the type lattice yet; emit a bare `None` so the
        # downstream rustc surfaces the missing context.
        return lir.RustName(name="None")

    def lower_list(self, node: mir.MirList):
        return lir.RustVec(elements=[self.lower_expr(e) for e in node.elements])

    def lower_subscript(self, node: mir.MirSubscript):
        return lir.RustIndex(value=self.lower_expr(node.value), index=self.lower_expr(node.index))

    def lower_call(self, node: mir.MirCall):
        # Stdlib mapping table — turn well-known Python-style builtins into
        # idiomatic Rust so the output is runnable, not just syntactically OK.
        args = [self.lower_expr(a) for a in node.args]
        if node.func == "__ternary__" and len(args) == 3:
            return _RustIfExpr(test=args[0], then_=args[1], else_=args[2])
        if node.func == "len":
            if len(args) != 1:
                raise ValueError("len() takes exactly one argument")
            return lir.RustMethodCall(receiver=args[0], method="len", args=[], cast_to="i64")
        if node.func in ("print", "println"):
            # Rewrap each arg so the rendering matches Python's str(): bools
            # become "True"/"False", floats use `{:?}` (Rust Debug for f64
            # preserves the trailing `.0` that Display drops). Build the
            # template dynamically per-arg.
            tokens: list[str] = []
            rendered_args: list[lir.LirNode] = []
            for orig, lowered in zip(node.args, args):
                refined = _pyprint_arg(orig, lowered)
                tokens.append("{:?}" if isinstance(refined, _RustPyFloat) else "{}")
                rendered_args.append(refined)
            template = " ".join(tokens)
            return lir.RustMacro(name="println", template=template, args=rendered_args)
        if node.func == "abs" and len(args) == 1:
            return lir.RustMethodChain(receiver=args[0], method="abs", args=[])
        if node.func == "min" and len(args) == 2:
            return lir.RustMethodChain(receiver=args[0], method="min", args=[args[1]])
        if node.func == "max" and len(args) == 2:
            return lir.RustMethodChain(receiver=args[0], method="max", args=[args[1]])
        if node.func == "int" and len(args) == 1:
            return lir.RustBinOp(op="as", left=args[0], right=lir.RustName(name="i64"))
        if node.func == "float" and len(args) == 1:
            return lir.RustBinOp(op="as", left=args[0], right=lir.RustName(name="f64"))
        if node.func == "bool" and len(args) == 1:
            return lir.RustCompare(op="!=", left=args[0], right=lir.RustIntLiteral(value=0))
        if node.func == "str" and len(args) == 1:
            return lir.RustMethodChain(receiver=args[0], method="to_string", args=[])
        # Default: direct function call. Pass list arguments by reference so
        # the caller's binding isn't moved.
        refined: list[lir.LirNode] = []
        for orig, lowered in zip(node.args, args):
            if isinstance(getattr(orig, "ty", None), ListT):
                refined.append(_RustRef(value=lowered))
            else:
                refined.append(lowered)
        return lir.RustCall(func=node.func, args=refined)


_LOWERING = _RustLowering()


def mir_to_rust_lir(module: mir.MirModule) -> lir.RustModule:
    return _LOWERING.lower_module(module)


def _rust_param_type(ty: Type, *, mutable: bool = False) -> str:
    if isinstance(ty, ListT):
        ref = "&mut" if mutable else "&"
        try:
            return f"{ref} Vec<{_rust_type(ty.elem)}>"
        except ValueError:
            return f"{ref} Vec<_>"
    return _rust_type(ty)


def _pyprint_arg(orig: mir.MirNode, lowered: lir.LirNode) -> lir.LirNode:
    """Wrap `lowered` so it renders the way Python's `print` would.
    Bools become `"True"` / `"False"` strings via an inline ternary.
    Floats are marked with `_RustPyFloat` so the caller can emit `{:?}`
    in the format string (Rust Debug for f64 preserves the trailing `.0`
    that Display drops)."""
    ty = getattr(orig, "ty", None)
    if isinstance(ty, BoolT):
        return _RustIfExpr(
            test=lowered,
            then_=lir.RustStringLiteral(value="True"),
            else_=lir.RustStringLiteral(value="False"),
        )
    if isinstance(ty, FloatT):
        return _RustPyFloat(value=lowered)
    return lowered


class _RustIfExpr(lir.LirNode):
    """`if <test> { <then> } else { <else> }` — Rust if-as-expression.
    Used by `_pyprint_arg` for bool→Python-cap rendering."""

    def __init__(self, test: lir.LirNode, then_: lir.LirNode, else_: lir.LirNode) -> None:
        self.test = test
        self.then_ = then_
        self.else_ = else_


class _RustPyFloat(lir.LirNode):
    """`{:?}` format marker. The enclosing print lowering emits `{:?}` in the
    template string for this arg position; the emitter renders `.value`
    directly (the Debug specifier handles the `.0` suffix)."""

    def __init__(self, value: lir.LirNode) -> None:
        self.value = value


class _RustRef(lir.LirNode):
    """`&mut value` — mutable reference. Vec params always use `&mut`
    so callee can do subscript-assigns without a separate borrow path."""

    def __init__(self, value: lir.LirNode) -> None:
        self.value = value


class _RustListConcat(lir.LirNode):
    """Python `left + right` where both sides are lists. Emits an inline
    block that clones `left`, extends it with `right`'s elements, and
    yields the combined Vec:
        `{ let mut _t = <left>.clone(); _t.extend(<right>); _t }`"""

    def __init__(self, left: lir.LirNode, right: lir.LirNode) -> None:
        self.left = left
        self.right = right


def _flatten_concat(lowering: _RustLowering, node: mir.MirBinOp) -> list[lir.LirNode]:
    out: list[lir.LirNode] = []
    for side in (node.left, node.right):
        if isinstance(side, mir.MirBinOp) and is_string_concat(side):
            out.extend(_flatten_concat(lowering, side))
        else:
            out.append(lowering.lower_expr(side))
    return out


def _rust_type(ty: Type) -> str:
    if isinstance(ty, IntT):
        return f"{'i' if ty.signed else 'u'}{ty.bits}"
    if isinstance(ty, FloatT):
        return f"f{ty.bits}"
    if isinstance(ty, BoolT):
        return "bool"
    if isinstance(ty, StrT):
        return "String"
    if isinstance(ty, NoneT):
        return "()"
    if isinstance(ty, ListT):
        # Recursive unknown element types fall back to the `_` placeholder
        # so the surrounding `Vec<_>` can be inferred from initializer.
        try:
            return f"Vec<{_rust_type(ty.elem)}>"
        except ValueError:
            return "Vec<_>"
    if isinstance(ty, StructT):
        return ty.name
    if isinstance(ty, UnknownT):
        raise ValueError(f"unresolved type hole: {ty.hint}")
    raise NotImplementedError(f"type {type(ty).__name__}")
