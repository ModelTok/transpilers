"""MIR -> Rust LIR.

Target-shaping pass. Maps the MIR type lattice into concrete Rust types and
rewrites operations into Rust-flavored shapes. Stays algorithmic; idiom
rewrites (e.g., Python list-comp -> .iter().map().collect()) belong in
dedicated idiom passes that may consult LLM hooks.
"""

from __future__ import annotations

from transpilers.ir import lir, mir
from transpilers.ir.types import BoolT, FloatT, IntT, NoneT, StrT, Type, UnknownT


def mir_to_rust_lir(module: mir.MirModule) -> lir.RustModule:
    items = [_lower_function(fn) for fn in module.functions]
    return lir.RustModule(items=items)


def _lower_function(fn: mir.MirFunction) -> lir.RustFn:
    params = [(p.name, _rust_type(p.ty)) for p in fn.params]
    ret = _rust_type(fn.return_type)
    body = [_lower_node(n) for n in fn.body]
    return lir.RustFn(name=fn.name, params=params, return_type=ret, body=body)


def _lower_node(node: mir.MirNode) -> lir.LirNode:
    if isinstance(node, mir.MirReturn):
        return lir.RustReturn(value=_lower_node(node.value) if node.value else None)
    if isinstance(node, mir.MirBinOp):
        return lir.RustBinOp(op=node.op, left=_lower_node(node.left), right=_lower_node(node.right))
    if isinstance(node, mir.MirName):
        return lir.RustName(name=node.name)
    if isinstance(node, mir.MirIntLiteral):
        return lir.RustIntLiteral(value=node.value)
    raise NotImplementedError(f"MIR node {type(node).__name__}")


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
    if isinstance(ty, UnknownT):
        # A surfaced hole is a bug at this layer: a previous pass should have
        # resolved it (algorithmically or via LLM). Refuse to emit guesses.
        raise ValueError(f"unresolved type hole: {ty.hint}")
    raise NotImplementedError(f"type {type(ty).__name__}")
