"""Rust LIR -> Rust source.

Deterministic emission. No LLM here — naming/comment LLM passes operate on the
LIR before emission, never on the text. Keeping emit pure makes the output
reproducible and makes round-trip parsing (re-parsing emitted Rust back into
its CST) viable.
"""

from __future__ import annotations

from transpilers.ir import lir


INDENT = "    "


def emit_rust(module: lir.RustModule) -> str:
    return "\n\n".join(_emit_fn(fn) for fn in module.items) + "\n"


def _emit_fn(fn: lir.RustFn) -> str:
    params = ", ".join(f"{n}: {t}" for n, t in fn.params)
    header = f"fn {fn.name}({params}) -> {fn.return_type} {{"
    body = _emit_block(fn.body, 1)
    return f"{header}\n{body}\n}}"


def _emit_block(nodes: list[lir.LirNode], depth: int) -> str:
    lines: list[str] = []
    for n in nodes:
        lines.append(_emit_stmt(n, depth))
    return "\n".join(lines)


def _emit_stmt(node: lir.LirNode, depth: int) -> str:
    pad = INDENT * depth
    if isinstance(node, lir.RustReturn):
        return f"{pad}return {_emit_expr(node.value)};" if node.value else f"{pad}return;"
    if isinstance(node, lir.RustLet):
        mut = "mut " if node.mutable else ""
        ann = f": {node.ty}" if node.ty else ""
        return f"{pad}let {mut}{node.name}{ann} = {_emit_expr(node.value)};"
    if isinstance(node, lir.RustReassign):
        return f"{pad}{node.name} = {_emit_expr(node.value)};"
    if isinstance(node, lir.RustIf):
        head = f"{pad}if {_emit_expr(node.test)} {{"
        body = _emit_block(node.body, depth + 1)
        if node.orelse:
            # Collapse `else { if ... }` into `else if ...` for readability.
            if len(node.orelse) == 1 and isinstance(node.orelse[0], lir.RustIf):
                inner = _emit_stmt(node.orelse[0], depth).lstrip()
                tail = f"{pad}}} else {inner}"
                return f"{head}\n{body}\n{tail}"
            else_body = _emit_block(node.orelse, depth + 1)
            return f"{head}\n{body}\n{pad}}} else {{\n{else_body}\n{pad}}}"
        return f"{head}\n{body}\n{pad}}}"
    if isinstance(node, lir.RustWhile):
        head = f"{pad}while {_emit_expr(node.test)} {{"
        body = _emit_block(node.body, depth + 1)
        return f"{head}\n{body}\n{pad}}}"
    if isinstance(node, lir.RustForRange):
        rng = f"{_emit_expr(node.start)}..{_emit_expr(node.stop)}"
        if node.step is not None:
            rng = f"({rng}).step_by({_emit_expr(node.step)} as usize)"
        head = f"{pad}for {node.target} in {rng} {{"
        body = _emit_block(node.body, depth + 1)
        return f"{head}\n{body}\n{pad}}}"
    # Expression-statement fallthrough.
    return f"{pad}{_emit_expr(node)};"


def _emit_expr(node: lir.LirNode | None) -> str:
    if node is None:
        return ""
    if isinstance(node, lir.RustBinOp):
        return f"{_emit_expr(node.left)} {node.op} {_emit_expr(node.right)}"
    if isinstance(node, lir.RustCompare):
        return f"{_emit_expr(node.left)} {node.op} {_emit_expr(node.right)}"
    if isinstance(node, lir.RustBoolOp):
        return f"{_emit_expr(node.left)} {node.op} {_emit_expr(node.right)}"
    if isinstance(node, lir.RustUnary):
        return f"{node.op}{_emit_expr(node.operand)}"
    if isinstance(node, lir.RustName):
        return node.name
    if isinstance(node, lir.RustIntLiteral):
        return f"{node.value}{node.suffix}"
    if isinstance(node, lir.RustBoolLiteral):
        return "true" if node.value else "false"
    if isinstance(node, lir.RustStringLiteral):
        # StrT lowers to `String` (owned) for parameters and returns, so
        # literals must materialize as owned strings too. `String::from(...)`
        # is unambiguous; for format! arguments it's slightly verbose but
        # still correct since `format!` accepts Display on either form.
        escaped = node.value.replace("\\", "\\\\").replace('"', '\\"')
        return f'String::from("{escaped}")'
    if isinstance(node, lir.RustFormat):
        template = "{}" * len(node.args)
        rendered = ", ".join(_emit_expr(a) for a in node.args)
        return f'format!("{template}", {rendered})'
    if isinstance(node, lir.RustVec):
        items = ", ".join(_emit_expr(e) for e in node.elements)
        return f"vec![{items}]"
    if isinstance(node, lir.RustIndex):
        return f"{_emit_expr(node.value)}[{_emit_expr(node.index)} as usize]"
    if isinstance(node, lir.RustMethodCall):
        args = ", ".join(_emit_expr(a) for a in node.args)
        call = f"{_emit_expr(node.receiver)}.{node.method}({args})"
        return f"{call} as {node.cast_to}" if node.cast_to else call
    if isinstance(node, lir.RustCall):
        args = ", ".join(_emit_expr(a) for a in node.args)
        return f"{node.func}({args})"
    raise NotImplementedError(f"LIR node {type(node).__name__}")
