"""Python LIR -> Python source.

Indentation-sensitive, no braces. Empty function bodies need `pass`.
"""

from __future__ import annotations

from transpilers.ir import lir


INDENT = "    "


def emit_python(module: lir.PyModule) -> str:
    return "\n\n".join(_emit_fn(fn) for fn in module.items) + "\n"


def _emit_fn(fn: lir.PyFn) -> str:
    params = ", ".join(f"{n}: {t}" if t else n for n, t in fn.params)
    ret = f" -> {fn.return_type}" if fn.return_type and fn.return_type != "None" else ""
    header = f"def {fn.name}({params}){ret}:"
    body = _emit_block(fn.body, 1) or (INDENT + "pass")
    return f"{header}\n{body}"


def _emit_block(nodes: list[lir.LirNode], depth: int) -> str:
    return "\n".join(_emit_stmt(n, depth) for n in nodes)


def _emit_stmt(node: lir.LirNode, depth: int) -> str:
    pad = INDENT * depth
    if isinstance(node, lir.PyReturn):
        return f"{pad}return {_emit_expr(node.value)}" if node.value else f"{pad}return"
    if isinstance(node, lir.PyAssign):
        ann = f": {node.ty}" if node.ty else ""
        return f"{pad}{node.name}{ann} = {_emit_expr(node.value)}"
    if isinstance(node, lir.PyIf):
        head = f"{pad}if {_emit_expr(node.test)}:"
        body = _emit_block(node.body, depth + 1) or (pad + INDENT + "pass")
        if node.orelse:
            if len(node.orelse) == 1 and isinstance(node.orelse[0], lir.PyIf):
                inner = _emit_stmt(node.orelse[0], depth)
                elif_inner = inner.replace(f"{pad}if ", f"{pad}elif ", 1)
                return f"{head}\n{body}\n{elif_inner}"
            else_body = _emit_block(node.orelse, depth + 1) or (pad + INDENT + "pass")
            return f"{head}\n{body}\n{pad}else:\n{else_body}"
        return f"{head}\n{body}"
    if isinstance(node, lir.PyWhile):
        head = f"{pad}while {_emit_expr(node.test)}:"
        body = _emit_block(node.body, depth + 1) or (pad + INDENT + "pass")
        return f"{head}\n{body}"
    if isinstance(node, lir.PyForRange):
        if node.step is None:
            args = f"{_emit_expr(node.start)}, {_emit_expr(node.stop)}"
        else:
            args = f"{_emit_expr(node.start)}, {_emit_expr(node.stop)}, {_emit_expr(node.step)}"
        head = f"{pad}for {node.target} in range({args}):"
        body = _emit_block(node.body, depth + 1) or (pad + INDENT + "pass")
        return f"{head}\n{body}"
    return f"{pad}{_emit_expr(node)}"


def _emit_expr(node: lir.LirNode | None) -> str:
    if node is None:
        return ""
    if isinstance(node, lir.PyBinOp):
        return f"{_emit_expr(node.left)} {node.op} {_emit_expr(node.right)}"
    if isinstance(node, lir.PyCompare):
        return f"{_emit_expr(node.left)} {node.op} {_emit_expr(node.right)}"
    if isinstance(node, lir.PyBoolOp):
        return f"{_emit_expr(node.left)} {node.op} {_emit_expr(node.right)}"
    if isinstance(node, lir.PyUnary):
        return f"{node.op} {_emit_expr(node.operand)}" if node.op == "not" else f"{node.op}{_emit_expr(node.operand)}"
    if isinstance(node, lir.PyName):
        return node.name
    if isinstance(node, lir.PyIntLiteral):
        return str(node.value)
    if isinstance(node, lir.PyBoolLiteral):
        return "True" if node.value else "False"
    if isinstance(node, lir.PyStringLiteral):
        escaped = node.value.replace("\\", "\\\\").replace('"', '\\"')
        return f'"{escaped}"'
    if isinstance(node, lir.PyCall):
        args = ", ".join(_emit_expr(a) for a in node.args)
        return f"{node.func}({args})"
    raise NotImplementedError(f"LIR node {type(node).__name__}")
