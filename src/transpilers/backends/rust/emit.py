"""Rust LIR -> Rust source.

Deterministic emission. No LLM here — naming/comment LLM passes operate on the
LIR before emission, never on the text. Keeping emit pure makes the output
reproducible and makes round-trip parsing (re-parsing emitted Rust back into
its CST) viable.
"""

from __future__ import annotations

from transpilers.ir import lir


def emit_rust(module: lir.RustModule) -> str:
    return "\n\n".join(_emit_fn(fn) for fn in module.items) + "\n"


def _emit_fn(fn: lir.RustFn) -> str:
    params = ", ".join(f"{n}: {t}" for n, t in fn.params)
    header = f"fn {fn.name}({params}) -> {fn.return_type} {{"
    body = "\n".join("    " + _emit_node(n) for n in fn.body)
    return f"{header}\n{body}\n}}"


def _emit_node(node: lir.LirNode) -> str:
    if isinstance(node, lir.RustReturn):
        return f"return {_emit_expr(node.value)};" if node.value else "return;"
    return _emit_expr(node) + ";"


def _emit_expr(node: lir.LirNode | None) -> str:
    if node is None:
        return ""
    if isinstance(node, lir.RustBinOp):
        return f"{_emit_expr(node.left)} {node.op} {_emit_expr(node.right)}"
    if isinstance(node, lir.RustName):
        return node.name
    if isinstance(node, lir.RustIntLiteral):
        return f"{node.value}{node.suffix}"
    raise NotImplementedError(f"LIR node {type(node).__name__}")
