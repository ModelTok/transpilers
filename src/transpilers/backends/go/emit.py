"""Go LIR -> Go source.

Emits a `package main` preamble so the file is a valid translation unit. Go
gofmt-style formatting (tabs, brace placement) is approximated; output is
deterministic and parses cleanly with `go build`.
"""

from __future__ import annotations

from transpilers.ir import lir


INDENT = "\t"
PREAMBLE = "package main\n\n"


def _augmented_form(name: str, value: lir.LirNode) -> tuple[str, lir.LirNode] | None:
    if not isinstance(value, lir.GoBinOp):
        return None
    if not (isinstance(value.left, lir.GoName) and value.left.name == name):
        return None
    if value.op not in ("+", "-", "*", "/", "%"):
        return None
    return value.op, value.right


def emit_go(module: lir.GoModule) -> str:
    return PREAMBLE + "\n\n".join(_emit_fn(fn) for fn in module.items) + "\n"


def _emit_fn(fn: lir.GoFn) -> str:
    params = ", ".join(f"{n} {t}" for n, t in fn.params)
    ret = f" {fn.return_type}" if fn.return_type else ""
    header = f"func {fn.name}({params}){ret} {{"
    body = _emit_block(fn.body, 1)
    return f"{header}\n{body}\n}}"


def _emit_block(nodes: list[lir.LirNode], depth: int) -> str:
    return "\n".join(_emit_stmt(n, depth) for n in nodes)


def _emit_stmt(node: lir.LirNode, depth: int) -> str:
    pad = INDENT * depth
    if isinstance(node, lir.GoReturn):
        return f"{pad}return {_emit_expr(node.value)}" if node.value else f"{pad}return"
    if isinstance(node, lir.GoDecl):
        return f"{pad}var {node.name} {node.ty} = {_emit_expr(node.value)}"
        # Note: Go statements have no trailing semicolons; emit doesn't add them.
    if isinstance(node, lir.GoReassign):
        return f"{pad}{node.name} = {_emit_expr(node.value)}"
    if isinstance(node, lir.GoIf):
        head = f"{pad}if {_emit_expr(node.test)} {{"
        body = _emit_block(node.body, depth + 1)
        if node.orelse:
            if len(node.orelse) == 1 and isinstance(node.orelse[0], lir.GoIf):
                inner = _emit_stmt(node.orelse[0], depth).lstrip()
                return f"{head}\n{body}\n{pad}}} else {inner}"
            else_body = _emit_block(node.orelse, depth + 1)
            return f"{head}\n{body}\n{pad}}} else {{\n{else_body}\n{pad}}}"
        return f"{head}\n{body}\n{pad}}}"
    if isinstance(node, lir.GoWhile):
        head = f"{pad}for {_emit_expr(node.test)} {{"
        body = _emit_block(node.body, depth + 1)
        return f"{head}\n{body}\n{pad}}}"
    if isinstance(node, lir.GoForRange):
        if node.step is None:
            step = f"{node.target}++"
        else:
            step = f"{node.target} += {_emit_expr(node.step)}"
        # Force int64 on the loop variable to avoid mismatched int / int64
        # errors when stop is int64. Go is strict about implicit conversions.
        head = (
            f"{pad}for {node.target} := int64({_emit_expr(node.start)}); "
            f"{node.target} < {_emit_expr(node.stop)}; {step} {{"
        )
        body = _emit_block(node.body, depth + 1)
        return f"{head}\n{body}\n{pad}}}"
    return f"{pad}{_emit_expr(node)}"


def _emit_expr(node: lir.LirNode | None) -> str:
    if node is None:
        return ""
    if isinstance(node, lir.GoBinOp):
        return f"{_emit_expr(node.left)} {node.op} {_emit_expr(node.right)}"
    if isinstance(node, lir.GoCompare):
        return f"{_emit_expr(node.left)} {node.op} {_emit_expr(node.right)}"
    if isinstance(node, lir.GoBoolOp):
        return f"{_emit_expr(node.left)} {node.op} {_emit_expr(node.right)}"
    if isinstance(node, lir.GoUnary):
        return f"{node.op}{_emit_expr(node.operand)}"
    if isinstance(node, lir.GoName):
        return node.name
    if isinstance(node, lir.GoIntLiteral):
        return str(node.value)
    if isinstance(node, lir.GoFloatLiteral):
        text = repr(node.value)
        return text if "." in text or "e" in text else text + ".0"
    if isinstance(node, lir.GoBoolLiteral):
        return "true" if node.value else "false"
    if isinstance(node, lir.GoStringLiteral):
        escaped = node.value.replace("\\", "\\\\").replace('"', '\\"')
        return f'"{escaped}"'
    if isinstance(node, lir.GoCall):
        args = ", ".join(_emit_expr(a) for a in node.args)
        return f"{node.func}({args})"
    raise NotImplementedError(f"LIR node {type(node).__name__}")
