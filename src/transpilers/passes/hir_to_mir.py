"""HIR -> MIR.

Algorithmic for explicitly annotated Python. Where annotations are missing,
we leave UnknownT holes for a later inference pass (algorithmic dataflow first,
LLM as fallback). This boundary is the single most important design decision
in the system: algorithmic passes must not invent types they don't know.
"""

from __future__ import annotations

from transpilers.ir import hir, mir
from transpilers.ir.types import BoolT, FloatT, IntT, NoneT, StrT, Type, UnknownT


PYTHON_TYPE_MAP: dict[str, Type] = {
    "int": IntT(),
    "float": FloatT(),
    "bool": BoolT(),
    "str": StrT(),
    "None": NoneT(),
}


def hir_to_mir(module: hir.HirModule) -> mir.MirModule:
    functions: list[mir.MirFunction] = []
    for node in module.body:
        if isinstance(node, hir.HirFunction):
            functions.append(_lower_function(node))
    return mir.MirModule(functions=functions)


def _lower_function(fn: hir.HirFunction) -> mir.MirFunction:
    params = [mir.MirParam(name=p.name, ty=_resolve_annotation(p.annotation)) for p in fn.params]
    ret_ty = _resolve_annotation(fn.return_annotation)
    env = {p.name: p.ty for p in params}
    body = [_lower_node(n, env) for n in fn.body]
    return mir.MirFunction(name=fn.name, params=params, return_type=ret_ty, body=body)


def _lower_node(node: hir.HirNode, env: dict[str, Type]) -> mir.MirNode:
    if isinstance(node, hir.HirReturn):
        return mir.MirReturn(value=_lower_node(node.value, env) if node.value else None)
    if isinstance(node, hir.HirBinOp):
        left = _lower_node(node.left, env)
        right = _lower_node(node.right, env)
        ty = _binop_type(node.op, _type_of(left), _type_of(right))
        return mir.MirBinOp(op=node.op, left=left, right=right, ty=ty)
    if isinstance(node, hir.HirName):
        return mir.MirName(name=node.name, ty=env.get(node.name, UnknownT(hint=f"name {node.name}")))
    if isinstance(node, hir.HirIntLiteral):
        return mir.MirIntLiteral(value=node.value, ty=IntT())
    raise NotImplementedError(f"HIR node {type(node).__name__}")


def _resolve_annotation(ann: str | None) -> Type:
    if ann is None:
        # Type-inference hole. Later pass fills this — algorithmic dataflow,
        # then LLM fallback. Never invented here.
        return UnknownT(hint="missing Python annotation")
    if ann in PYTHON_TYPE_MAP:
        return PYTHON_TYPE_MAP[ann]
    return UnknownT(hint=f"unknown annotation {ann!r}")


def _type_of(node: mir.MirNode) -> Type:
    return getattr(node, "ty", UnknownT())


def _binop_type(op: str, lt: Type, rt: Type) -> Type:
    if isinstance(lt, IntT) and isinstance(rt, IntT):
        return IntT()
    if isinstance(lt, (IntT, FloatT)) and isinstance(rt, (IntT, FloatT)):
        return FloatT()
    return UnknownT(hint=f"binop {op}")
