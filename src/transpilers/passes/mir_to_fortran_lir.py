"""MIR -> Fortran LIR.

Two responsibilities not seen in the other backends:
  1. Collect every declared name (params + assigns + for-range targets) and
     its type for the function-entry declaration block. Fortran refuses
     inline declarations the way C-family languages welcome them.
  2. Turn every `return <expr>` into an assignment to the result variable
     plus a bare `return` statement. Fortran functions return whatever the
     result variable holds at function exit.
"""

from __future__ import annotations

from transpilers.ir import lir, mir
from transpilers.ir.types import BoolT, FloatT, IntT, ListT, NoneT, StrT, StructT, Type, UnknownT


RESULT_VAR = "result_"  # synthesized to avoid clashing with user identifiers


def mir_to_fortran_lir(module: mir.MirModule) -> lir.FortranModule:
    items: list[lir.LirNode] = []
    for s in module.structs:
        items.append(_lower_struct(s))
    for fn in module.functions:
        items.append(_lower_function(fn))
    return lir.FortranModule(items=items)


def _lower_struct(s: mir.MirStruct) -> lir.FortranType:
    """Methods are emitted as free functions in the module — Fortran needs
    `type :: Name ... end type Name` + free `function name_method(self, ...)`."""
    methods: list[lir.FortranFn] = []
    for m in s.methods:
        lowered = _lower_function(m)
        lowered.name = f"{s.name}_{lowered.name}"
        methods.append(lowered)
    return lir.FortranType(
        name=s.name,
        fields=[(f.name, _fortran_type(f.ty)) for f in s.fields],
        methods=methods,
    )


def _lower_function(fn: mir.MirFunction) -> lir.FortranFn:
    params = [(p.name, _fortran_type(p.ty)) for p in fn.params]
    ret = _fortran_type(fn.return_type) if not isinstance(fn.return_type, NoneT) else None

    # Collect every local name and its type. We do this with a single MIR
    # walk so we don't visit nodes twice.
    locals_map: dict[str, Type] = {}
    _collect_locals(fn.body, locals_map, exclude={p.name for p in fn.params} | {RESULT_VAR})

    result_name = RESULT_VAR if ret is not None else ""
    body = [_lower_stmt(n, result_name) for n in fn.body]

    return lir.FortranFn(
        name=fn.name,
        params=params,
        return_type=ret,
        result_name=result_name,
        locals=[(name, _fortran_type(ty)) for name, ty in locals_map.items()],
        body=body,
    )


# ---------- local collection ----------

def _collect_locals(nodes: list[mir.MirNode], out: dict[str, Type], exclude: set[str]) -> None:
    for n in nodes:
        if isinstance(n, mir.MirAssign):
            if n.target not in exclude and n.target not in out:
                out[n.target] = n.ty
        elif isinstance(n, mir.MirIf):
            _collect_locals(n.body, out, exclude)
            _collect_locals(n.orelse, out, exclude)
        elif isinstance(n, mir.MirWhile):
            _collect_locals(n.body, out, exclude)
        elif isinstance(n, mir.MirForRange):
            if n.target not in exclude and n.target not in out:
                out[n.target] = IntT()
            _collect_locals(n.body, out, exclude)


# ---------- statements ----------

def _lower_stmt(node: mir.MirNode, result_name: str) -> lir.LirNode:
    if isinstance(node, mir.MirFieldAssign):
        # Fortran field assignment: `obj%field = value` — emit as a plain
        # FortranAssign with the path baked into `name`.
        return lir.FortranAssign(
            name=_emit_field_path(node.obj, node.field),
            value=_lower_expr(node.value),
        )
    if isinstance(node, mir.MirReturn):
        if node.value is None or not result_name:
            return lir.FortranReturn()
        return _ReturnAssign(result_name=result_name, value=_lower_expr(node.value))
    if isinstance(node, mir.MirAssign):
        if node.augmented_op is not None:
            rhs = lir.FortranBinOp(
                op=node.augmented_op,
                left=lir.FortranName(name=node.target),
                right=_lower_expr(node.value),
            )
            return lir.FortranAssign(name=node.target, value=rhs)
        return lir.FortranAssign(name=node.target, value=_lower_expr(node.value))
    if isinstance(node, mir.MirIf):
        return lir.FortranIf(
            test=_lower_expr(node.test),
            body=[_lower_stmt(n, result_name) for n in node.body],
            orelse=[_lower_stmt(n, result_name) for n in node.orelse],
        )
    if isinstance(node, mir.MirWhile):
        return lir.FortranWhile(
            test=_lower_expr(node.test),
            body=[_lower_stmt(n, result_name) for n in node.body],
        )
    if isinstance(node, mir.MirForRange):
        return lir.FortranForRange(
            target=node.target,
            start=_lower_expr(node.start),
            stop=_lower_expr(node.stop),
            step=_lower_expr(node.step) if node.step else None,
            body=[_lower_stmt(n, result_name) for n in node.body],
        )
    return _lower_expr(node)


class _ReturnAssign(lir.LirNode):
    """Marker carrying `result_ = <value>; return` so the emitter renders
    both lines. Not part of the public LIR shape."""

    def __init__(self, result_name: str, value: lir.LirNode) -> None:
        self.result_name = result_name
        self.value = value


# ---------- expressions ----------

def _lower_expr(node: mir.MirNode) -> lir.LirNode:
    if isinstance(node, mir.MirFieldAccess):
        return lir.FortranFieldAccess(value=_lower_expr(node.value), field=node.field)
    if isinstance(node, mir.MirMethodCall):
        recv_ty = getattr(node.receiver, "ty", UnknownT())
        if not isinstance(recv_ty, StructT):
            raise NotImplementedError(
                f"fortran method call on receiver with type {recv_ty}"
            )
        return lir.FortranCall(
            func=f"{recv_ty.name}_{node.method}",
            args=[_lower_expr(node.receiver)] + [_lower_expr(a) for a in node.args],
        )
    if isinstance(node, mir.MirBinOp):
        if _is_string_concat(node):
            raise NotImplementedError(
                "Fortran string concat requires fixed-length char buffers; not yet supported"
            )
        return lir.FortranBinOp(op=node.op, left=_lower_expr(node.left), right=_lower_expr(node.right))
    if isinstance(node, mir.MirCompare):
        return lir.FortranCompare(op=node.op, left=_lower_expr(node.left), right=_lower_expr(node.right))
    if isinstance(node, mir.MirBoolOp):
        op = ".and." if node.op == "and" else ".or."
        return lir.FortranBoolOp(op=op, left=_lower_expr(node.left), right=_lower_expr(node.right))
    if isinstance(node, mir.MirUnaryOp):
        op = ".not." if node.op == "not" else "-"
        return lir.FortranUnary(op=op, operand=_lower_expr(node.operand))
    if isinstance(node, mir.MirName):
        return lir.FortranName(name=node.name)
    if isinstance(node, mir.MirIntLiteral):
        return lir.FortranIntLiteral(value=node.value)
    if isinstance(node, mir.MirFloatLiteral):
        return lir.FortranFloatLiteral(value=node.value)
    if isinstance(node, mir.MirBoolLiteral):
        return lir.FortranBoolLiteral(value=node.value)
    if isinstance(node, mir.MirStringLiteral):
        return lir.FortranStringLiteral(value=node.value)
    if isinstance(node, mir.MirCall):
        return lir.FortranCall(func=node.func, args=[_lower_expr(a) for a in node.args])
    if isinstance(node, mir.MirFieldAccess):
        return lir.FortranFieldAccess(value=_lower_expr(node.value), field=node.field)
    if isinstance(node, mir.MirStructInit):
        return lir.FortranStructInit(
            name=node.name,
            field_values=[(n, _lower_expr(v)) for n, v in node.field_values],
        )
    raise NotImplementedError(f"fortran MIR expr {type(node).__name__}")


def _emit_field_path(obj: mir.MirNode, field: str) -> str:
    """Build a `obj%field` path string for assignment-LHS use."""
    if isinstance(obj, mir.MirName):
        return f"{obj.name}%{field}"
    if isinstance(obj, mir.MirFieldAccess):
        return f"{_emit_field_path(obj.value, obj.field)}%{field}"
    raise NotImplementedError(f"fortran field-assign on {type(obj).__name__}")


def _is_string_concat(node: mir.MirBinOp) -> bool:
    return (
        node.op == "+"
        and isinstance(getattr(node.left, "ty", None), StrT)
        and isinstance(getattr(node.right, "ty", None), StrT)
    )


def _fortran_type(ty: Type) -> str:
    if isinstance(ty, IntT):
        return "integer"
    if isinstance(ty, FloatT):
        # `real(8)` is fortran-portable for f64; `real` alone is single
        # precision on most compilers. Use the kind suffix.
        return "real(8)" if ty.bits == 64 else "real"
    if isinstance(ty, BoolT):
        return "logical"
    if isinstance(ty, StrT):
        # Fortran character lengths must be declared; use a generous default
        # for the type signature. Real use needs per-variable lengths.
        return "character(len=*)"
    if isinstance(ty, NoneT):
        return ""
    if isinstance(ty, ListT):
        raise NotImplementedError("fortran array emission not yet supported")
    if isinstance(ty, StructT):
        return f"type({ty.name})"
    if isinstance(ty, UnknownT):
        raise ValueError(f"unresolved type hole: {ty.hint}")
    raise NotImplementedError(f"type {type(ty).__name__}")
