"""MIR -> Rust LIR.

Target-shaping. Decides:
  - which assignments are declarations (`let`) vs reassignments
  - which bindings need `mut`
  - how `len(...)`, `range(...)` and similar builtins shape into Rust
  - which Python types map to which Rust types

Idiom rewrites (Python comprehensions -> .iter().map().collect()) belong in
dedicated idiom passes that may consult LLM hooks. This pass stays
algorithmic.
"""

from __future__ import annotations

from transpilers.ir import lir, mir
from transpilers.ir.types import BoolT, FloatT, IntT, ListT, NoneT, StrT, StructT, Type, UnknownT


def mir_to_rust_lir(module: mir.MirModule) -> lir.RustModule:
    items: list[lir.LirNode] = []
    for struct in module.structs:
        items.append(_lower_struct_def(struct))
        items.append(_lower_struct_impl(struct))
    for fn in module.functions:
        items.append(_lower_function(fn))
    return lir.RustModule(items=items)


def _lower_struct_def(s: mir.MirStruct) -> lir.RustStruct:
    return lir.RustStruct(
        name=s.name,
        fields=[(f.name, _rust_type(f.ty)) for f in s.fields],
    )


def _lower_struct_impl(s: mir.MirStruct) -> lir.RustImpl:
    return lir.RustImpl(struct_name=s.name, methods=[_lower_function(m) for m in s.methods])


def _lower_function(fn: mir.MirFunction) -> lir.RustFn:
    params = [(p.name, _rust_type(p.ty)) for p in fn.params]
    ret = _rust_type(fn.return_type)
    mut_names = _collect_mutable(fn.body)
    declared: set[str] = {p.name for p in fn.params}
    body = [_lower_stmt(n, declared, mut_names) for n in fn.body]
    return lir.RustFn(name=fn.name, params=params, return_type=ret, body=body)


# ---------- mutability inference ----------

def _collect_mutable(body: list[mir.MirNode]) -> set[str]:
    """A binding is `mut` if it is assigned more than once or with an augmented op."""
    counts: dict[str, int] = {}
    aug: set[str] = set()
    _scan_assigns(body, counts, aug)
    return {name for name, n in counts.items() if n > 1} | aug


def _scan_assigns(nodes: list[mir.MirNode], counts: dict[str, int], aug: set[str]) -> None:
    for n in nodes:
        if isinstance(n, mir.MirAssign):
            counts[n.target] = counts.get(n.target, 0) + 1
            if n.augmented_op is not None:
                aug.add(n.target)
        elif isinstance(n, mir.MirFieldAssign):
            # A field assignment mutates the receiver — force `mut` on the
            # backing local. Heuristic: receiver is a MirName.
            if isinstance(n.obj, mir.MirName):
                aug.add(n.obj.name)
        elif isinstance(n, mir.MirIf):
            _scan_assigns(n.body, counts, aug)
            _scan_assigns(n.orelse, counts, aug)
        elif isinstance(n, mir.MirWhile):
            _scan_assigns(n.body, counts, aug)
        elif isinstance(n, mir.MirForRange):
            _scan_assigns(n.body, counts, aug)


# ---------- lowering ----------

def _lower_stmt(node: mir.MirNode, declared: set[str], mut: set[str]) -> lir.LirNode:
    if isinstance(node, mir.MirReturn):
        return lir.RustReturn(value=_lower_expr(node.value) if node.value else None)
    if isinstance(node, mir.MirFieldAssign):
        return lir.RustFieldAssign(
            obj=_lower_expr(node.obj), field=node.field, value=_lower_expr(node.value)
        )
    if isinstance(node, mir.MirSubscriptAssign):
        return lir.RustSubscriptAssign(
            obj=_lower_expr(node.obj),
            index=_lower_expr(node.index),
            value=_lower_expr(node.value),
        )
    if isinstance(node, mir.MirAssign):
        return _lower_assign(node, declared, mut)
    if isinstance(node, mir.MirIf):
        return lir.RustIf(
            test=_lower_expr(node.test),
            body=[_lower_stmt(n, declared, mut) for n in node.body],
            orelse=[_lower_stmt(n, declared, mut) for n in node.orelse],
        )
    if isinstance(node, mir.MirWhile):
        return lir.RustWhile(
            test=_lower_expr(node.test),
            body=[_lower_stmt(n, declared, mut) for n in node.body],
        )
    if isinstance(node, mir.MirForRange):
        # Loop var is scoped to the loop in Rust — don't add to outer declared.
        return lir.RustForRange(
            target=node.target,
            start=_lower_expr(node.start),
            stop=_lower_expr(node.stop),
            step=_lower_expr(node.step) if node.step else None,
            body=[_lower_stmt(n, declared, mut) for n in node.body],
        )
    return _lower_expr(node)


def _lower_assign(node: mir.MirAssign, declared: set[str], mut: set[str]) -> lir.LirNode:
    if node.augmented_op is not None:
        # x += value  →  x = x + value  (in Rust we could emit `x += v` but
        # explicit form composes more cleanly with type promotion later).
        rhs = lir.RustBinOp(op=node.augmented_op, left=lir.RustName(name=node.target), right=_lower_expr(node.value))
        return lir.RustReassign(name=node.target, value=rhs)
    if node.target in declared:
        return lir.RustReassign(name=node.target, value=_lower_expr(node.value))
    declared.add(node.target)
    # When the inferred type is unknown, omit the annotation entirely —
    # Rust's local type inference picks it up from the initializer's type.
    try:
        ty_str = _rust_type(node.ty) if not isinstance(node.ty, UnknownT) else None
    except ValueError:
        # Nested unknown (e.g., ListT(elem=UnknownT)) — fall through to
        # untyped binding rather than failing the whole emission.
        ty_str = None
    return lir.RustLet(
        name=node.target,
        mutable=node.target in mut,
        ty=ty_str,
        value=_lower_expr(node.value),
    )


def _lower_expr(node: mir.MirNode) -> lir.LirNode:
    if isinstance(node, mir.MirFieldAccess):
        return lir.RustFieldAccess(value=_lower_expr(node.value), field=node.field)
    if isinstance(node, mir.MirStructInit):
        return lir.RustStructInit(
            name=node.name,
            field_values=[(n, _lower_expr(v)) for n, v in node.field_values],
        )
    if isinstance(node, mir.MirMethodCall):
        return lir.RustMethodCall(
            receiver=_lower_expr(node.receiver),
            method=node.method,
            args=[_lower_expr(a) for a in node.args],
        )
    if isinstance(node, mir.MirBinOp):
        if _is_string_concat(node):
            return lir.RustFormat(args=_flatten_concat(node))
        # Python's `//` (FloorDivide) → Rust `/` on integer types
        # (integer division is the default for `/` on ints in Rust).
        op = "/" if node.op == "//" else node.op
        return lir.RustBinOp(op=op, left=_lower_expr(node.left), right=_lower_expr(node.right))
    if isinstance(node, mir.MirCompare):
        return lir.RustCompare(op=node.op, left=_lower_expr(node.left), right=_lower_expr(node.right))
    if isinstance(node, mir.MirBoolOp):
        op = "&&" if node.op == "and" else "||"
        return lir.RustBoolOp(op=op, left=_lower_expr(node.left), right=_lower_expr(node.right))
    if isinstance(node, mir.MirUnaryOp):
        op = "!" if node.op == "not" else "-"
        return lir.RustUnary(op=op, operand=_lower_expr(node.operand))
    if isinstance(node, mir.MirName):
        return lir.RustName(name=node.name)
    if isinstance(node, mir.MirIntLiteral):
        return lir.RustIntLiteral(value=node.value)
    if isinstance(node, mir.MirFloatLiteral):
        return lir.RustFloatLiteral(value=node.value)
    if isinstance(node, mir.MirBoolLiteral):
        return lir.RustBoolLiteral(value=node.value)
    if isinstance(node, mir.MirStringLiteral):
        return lir.RustStringLiteral(value=node.value)
    if isinstance(node, mir.MirCall):
        return _lower_call(node)
    if isinstance(node, mir.MirList):
        return lir.RustVec(elements=[_lower_expr(e) for e in node.elements])
    if isinstance(node, mir.MirSubscript):
        return lir.RustIndex(value=_lower_expr(node.value), index=_lower_expr(node.index))
    raise NotImplementedError(f"MIR expr {type(node).__name__}")


def _lower_call(node: mir.MirCall) -> lir.LirNode:
    # Stdlib mapping table — turn well-known Python-style builtins into
    # idiomatic Rust so the output is runnable, not just syntactically OK.
    args = [_lower_expr(a) for a in node.args]
    if node.func == "len":
        if len(args) != 1:
            raise ValueError("len() takes exactly one argument")
        return lir.RustMethodCall(receiver=args[0], method="len", args=[], cast_to="i64")
    if node.func in ("print", "println"):
        template = " ".join("{}" for _ in args)
        return lir.RustMacro(name="println", template=template, args=args)
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
    # Default: emit as a direct function call. User-defined functions land
    # here; unknown builtins too (rustc surfaces the error).
    return lir.RustCall(func=node.func, args=args)


def _is_string_concat(node: mir.MirBinOp) -> bool:
    return (
        node.op == "+"
        and isinstance(getattr(node.left, "ty", None), StrT)
        and isinstance(getattr(node.right, "ty", None), StrT)
    )


def _flatten_concat(node: mir.MirBinOp) -> list[lir.LirNode]:
    out: list[lir.LirNode] = []
    for side in (node.left, node.right):
        if isinstance(side, mir.MirBinOp) and _is_string_concat(side):
            out.extend(_flatten_concat(side))
        else:
            out.append(_lower_expr(side))
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
