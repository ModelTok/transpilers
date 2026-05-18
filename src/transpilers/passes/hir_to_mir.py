"""HIR -> MIR.

Algorithmic for the annotated subset. Where annotations are missing, we leave
UnknownT holes for a later inference pass (algorithmic dataflow first, LLM as
fallback). The boundary is non-negotiable: algorithmic passes must not invent
types they don't know.
"""

from __future__ import annotations

from transpilers.ir import hir, mir
from transpilers.ir.types import (
    BoolT,
    FloatT,
    IntT,
    ListT,
    NoneT,
    RangeT,
    SimdT,
    StrT,
    StructT,
    Type,
    UnknownT,
)


PYTHON_TYPE_MAP: dict[str, Type] = {
    "int": IntT(),
    "float": FloatT(),
    "bool": BoolT(),
    "str": StrT(),
    "None": NoneT(),
}


# Module-level registry of user-defined struct names. Populated during
# hir_to_mir so type-annotation resolution can recognize `Point` as
# StructT("Point") rather than UnknownT.
_KNOWN_STRUCTS: set[str] = set()
_STRUCT_FIELD_NAMES: dict[str, list[str]] = {}
_STRUCT_FIELD_TYPES: dict[str, dict[str, Type]] = {}


def _default_init_for(ty: Type) -> mir.MirNode:
    if isinstance(ty, IntT):
        return mir.MirIntLiteral(value=0, ty=IntT())
    if isinstance(ty, FloatT):
        return mir.MirFloatLiteral(value=0.0, ty=FloatT())
    if isinstance(ty, BoolT):
        return mir.MirBoolLiteral(value=False, ty=BoolT())
    if isinstance(ty, StrT):
        return mir.MirStringLiteral(value="", ty=StrT())
    # Unknown / struct / list defaults aren't expressible as one literal;
    # fall back to int 0 (common case).
    return mir.MirIntLiteral(value=0, ty=IntT())


def hir_to_mir(module: hir.HirModule) -> mir.MirModule:
    functions: list[mir.MirFunction] = []
    structs: list[mir.MirStruct] = []
    _KNOWN_STRUCTS.clear()
    _STRUCT_FIELD_NAMES.clear()
    _STRUCT_FIELD_TYPES.clear()
    # First pass: register struct names so methods and fields can reference
    # them in their annotations.
    for node in module.body:
        if isinstance(node, hir.HirStruct):
            _KNOWN_STRUCTS.add(node.name)
    for node in module.body:
        if isinstance(node, hir.HirFunction):
            functions.append(_lower_function(node))
        elif isinstance(node, hir.HirStruct):
            structs.append(_lower_struct(node))
    return mir.MirModule(functions=functions, structs=structs)


def _lower_struct(s: hir.HirStruct) -> mir.MirStruct:
    fields = [mir.MirParam(name=f.name, ty=_resolve_annotation(f.annotation)) for f in s.fields]
    methods = [_lower_function(m) for m in s.methods]
    _STRUCT_FIELD_NAMES[s.name] = [f.name for f in fields]
    _STRUCT_FIELD_TYPES[s.name] = {f.name: f.ty for f in fields}
    return mir.MirStruct(name=s.name, fields=fields, methods=methods)


def _lower_function(fn: hir.HirFunction) -> mir.MirFunction:
    params = [mir.MirParam(name=p.name, ty=_resolve_annotation(p.annotation)) for p in fn.params]
    ret_ty = _resolve_annotation(fn.return_annotation)
    env: dict[str, Type] = {p.name: p.ty for p in params}
    body = [_lower_stmt(n, env) for n in fn.body]
    return mir.MirFunction(name=fn.name, params=params, return_type=ret_ty, body=body)


def _lower_stmt(node: hir.HirNode, env: dict[str, Type]) -> mir.MirNode:
    if isinstance(node, hir.HirReturn):
        return mir.MirReturn(value=_lower_expr(node.value, env) if node.value else None)
    if isinstance(node, hir.HirFieldAssign):
        return mir.MirFieldAssign(
            obj=_lower_expr(node.obj, env),
            field=node.field,
            value=_lower_expr(node.value, env),
        )
    if isinstance(node, hir.HirAssign):
        value = _lower_expr(node.value, env)
        ann_ty = _resolve_annotation(node.annotation) if node.annotation else None
        # Augmented ops desugar to `target = target <op> value`; we keep the
        # original op symbol on MIR so emission can pick `+=` form for readability.
        ty = ann_ty if ann_ty is not None and not isinstance(ann_ty, UnknownT) else _type_of(value)
        if node.target not in env:
            env[node.target] = ty
        return mir.MirAssign(target=node.target, value=value, ty=ty, augmented_op=node.augmented_op)
    if isinstance(node, hir.HirIf):
        return mir.MirIf(
            test=_lower_expr(node.test, env),
            body=[_lower_stmt(n, env) for n in node.body],
            orelse=[_lower_stmt(n, env) for n in node.orelse],
        )
    if isinstance(node, hir.HirWhile):
        return mir.MirWhile(
            test=_lower_expr(node.test, env),
            body=[_lower_stmt(n, env) for n in node.body],
        )
    if isinstance(node, hir.HirFor):
        return _lower_for(node, env)
    # Bare expression statement (rare in our subset, but legal): wrap as no-op-ish.
    return _lower_expr(node, env)


def _lower_for(node: hir.HirFor, env: dict[str, Type]) -> mir.MirForRange:
    if not (isinstance(node.iter, hir.HirCall) and node.iter.func == "range"):
        raise NotImplementedError("for-loop iter must be range(...) in the initial subset")
    args = [_lower_expr(a, env) for a in node.iter.args]
    if len(args) == 1:
        start = mir.MirIntLiteral(value=0, ty=IntT())
        stop, step = args[0], None
    elif len(args) == 2:
        start, stop, step = args[0], args[1], None
    elif len(args) == 3:
        start, stop, step = args[0], args[1], args[2]
    else:
        raise NotImplementedError(f"range arity {len(args)}")
    env[node.target] = IntT()
    body = [_lower_stmt(n, env) for n in node.body]
    return mir.MirForRange(target=node.target, start=start, stop=stop, step=step, body=body)


def _lower_expr(node: hir.HirNode, env: dict[str, Type]) -> mir.MirNode:
    if isinstance(node, hir.HirBinOp):
        left = _lower_expr(node.left, env)
        right = _lower_expr(node.right, env)
        return mir.MirBinOp(op=node.op, left=left, right=right, ty=_binop_type(node.op, _type_of(left), _type_of(right)))
    if isinstance(node, hir.HirCompare):
        return mir.MirCompare(
            op=node.op, left=_lower_expr(node.left, env), right=_lower_expr(node.right, env), ty=BoolT()
        )
    if isinstance(node, hir.HirBoolOp):
        return mir.MirBoolOp(
            op=node.op, left=_lower_expr(node.left, env), right=_lower_expr(node.right, env), ty=BoolT()
        )
    if isinstance(node, hir.HirUnaryOp):
        operand = _lower_expr(node.operand, env)
        ty = BoolT() if node.op == "not" else _type_of(operand)
        return mir.MirUnaryOp(op=node.op, operand=operand, ty=ty)
    if isinstance(node, hir.HirName):
        return mir.MirName(name=node.name, ty=env.get(node.name, UnknownT(hint=f"name {node.name}")))
    if isinstance(node, hir.HirIntLiteral):
        return mir.MirIntLiteral(value=node.value, ty=IntT())
    if isinstance(node, hir.HirFloatLiteral):
        return mir.MirFloatLiteral(value=node.value, ty=FloatT())
    if isinstance(node, hir.HirBoolLiteral):
        return mir.MirBoolLiteral(value=node.value, ty=BoolT())
    if isinstance(node, hir.HirStringLiteral):
        return mir.MirStringLiteral(value=node.value, ty=StrT())
    if isinstance(node, hir.HirCall):
        return _lower_call(node, env)
    if isinstance(node, hir.HirList):
        elements = [_lower_expr(e, env) for e in node.elements]
        elem_ty = _type_of(elements[0]) if elements else UnknownT(hint="empty list literal")
        return mir.MirList(elements=elements, ty=ListT(elem=elem_ty))
    if isinstance(node, hir.HirSubscript):
        value = _lower_expr(node.value, env)
        index = _lower_expr(node.index, env)
        value_ty = _type_of(value)
        ty: Type = value_ty.elem if isinstance(value_ty, ListT) else UnknownT(hint="subscript on non-list")
        return mir.MirSubscript(value=value, index=index, ty=ty)
    if isinstance(node, hir.HirFieldAccess):
        # Type of a field access stays Unknown for now — a field-resolution
        # pass would look up the struct's field types. Out of scope for the
        # minimal struct slice; the LIR emitters handle Unknown by leaving
        # the field bare and letting target inference work.
        return mir.MirFieldAccess(value=_lower_expr(node.value, env), field=node.field)
    if isinstance(node, hir.HirMethodCall):
        return mir.MirMethodCall(
            receiver=_lower_expr(node.receiver, env),
            method=node.method,
            args=[_lower_expr(a, env) for a in node.args],
        )
    if isinstance(node, hir.HirStructInit):
        # Pair positional ctor args with the struct's declared field names so
        # every target's emitter can render named-field form when it wants.
        field_names = _STRUCT_FIELD_NAMES.get(node.name, [])
        field_types = _STRUCT_FIELD_TYPES.get(node.name, {})
        lowered_args = [_lower_expr(a, env) for a in node.args]
        pairs: list[tuple[str, mir.MirNode]] = []
        for i, fname in enumerate(field_names):
            if i < len(lowered_args):
                pairs.append((fname, lowered_args[i]))
            else:
                pairs.append((fname, _default_init_for(field_types.get(fname, UnknownT()))))
        return mir.MirStructInit(
            name=node.name, field_values=pairs, ty=StructT(name=node.name)
        )
    raise NotImplementedError(f"HIR expr {type(node).__name__}")


def _lower_call(node: hir.HirCall, env: dict[str, Type]) -> mir.MirNode:
    args = [_lower_expr(a, env) for a in node.args]
    if node.func == "len":
        return mir.MirCall(func="len", args=args, ty=IntT())
    if node.func == "range":
        return mir.MirCall(func="range", args=args, ty=RangeT())
    # Common builtins across source languages — assign a plausible return
    # type so call results flow through inference rather than blocking on
    # UnknownT. Heuristic, not exhaustive; the stdlib_maps/ tables are the
    # long-term home for richer mappings.
    if node.func in ("int", "abs", "min", "max", "sum", "ord", "id", "hash"):
        return mir.MirCall(func=node.func, args=args, ty=IntT())
    if node.func in ("float", "round"):
        return mir.MirCall(func=node.func, args=args, ty=FloatT())
    if node.func == "bool":
        return mir.MirCall(func=node.func, args=args, ty=BoolT())
    if node.func in ("str", "repr", "format"):
        return mir.MirCall(func=node.func, args=args, ty=StrT())
    if node.func in ("print", "println"):
        return mir.MirCall(func=node.func, args=args, ty=NoneT())
    return mir.MirCall(func=node.func, args=args, ty=UnknownT(hint=f"call {node.func}"))


def _resolve_annotation(ann: str | None) -> Type:
    if ann is None:
        return UnknownT(hint="missing Python annotation")
    if ann in PYTHON_TYPE_MAP:
        return PYTHON_TYPE_MAP[ann]
    if ann.startswith("list[") and ann.endswith("]"):
        inner = ann[len("list[") : -1]
        return ListT(elem=_resolve_annotation(inner))
    if ann.startswith("simd[") and ann.endswith("]"):
        # `simd[<elem>, <lanes>]` — a SIMD vector type. The C++ frontend
        # produces these strings when it sees Intel/ARM vector typedefs.
        inner = ann[len("simd[") : -1]
        elem_text, _, lanes_text = inner.rpartition(",")
        elem = _resolve_annotation(elem_text.strip())
        lanes = int(lanes_text.strip())
        return SimdT(elem=elem, lanes=lanes)
    if ann in _KNOWN_STRUCTS:
        return StructT(name=ann)
    # Unknown identifier-shaped annotation looking like a class name
    # (e.g., third-party `Charset`, `Scanner`) — treat as opaque struct.
    # Lossy: we don't know the actual layout, but downstream emission can
    # render the name and let the target's typechecker decide.
    if ann.isidentifier() and ann[0].isupper():
        return StructT(name=ann)
    return UnknownT(hint=f"unknown annotation {ann!r}")


def _type_of(node: mir.MirNode) -> Type:
    return getattr(node, "ty", UnknownT())


def _binop_type(op: str, lt: Type, rt: Type) -> Type:
    if isinstance(lt, IntT) and isinstance(rt, IntT):
        return IntT()
    if isinstance(lt, (IntT, FloatT)) and isinstance(rt, (IntT, FloatT)):
        return FloatT()
    if op == "+" and isinstance(lt, StrT) and isinstance(rt, StrT):
        return StrT()
    return UnknownT(hint=f"binop {op}")
