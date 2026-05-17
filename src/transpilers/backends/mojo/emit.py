"""Mojo LIR -> Mojo source.

Indentation-sensitive, brace-free. Empty function bodies need `pass`.
"""

from __future__ import annotations

from transpilers.ir import lir


INDENT = "    "


def _augmented_form(name: str, value: lir.LirNode) -> tuple[str, lir.LirNode] | None:
    if not isinstance(value, lir.MojoBinOp):
        return None
    if not (isinstance(value.left, lir.MojoName) and value.left.name == name):
        return None
    if value.op not in ("+", "-", "*", "/", "%"):
        return None
    return value.op, value.right


def emit_mojo(module: lir.MojoModule) -> str:
    return "\n\n".join(_emit_item(item) for item in module.items) + "\n"


def _emit_item(item: lir.LirNode) -> str:
    if isinstance(item, lir.MojoStruct):
        return _emit_struct(item)
    if isinstance(item, lir.MojoFn):
        return _emit_fn(item)
    raise NotImplementedError(f"mojo top-level item {type(item).__name__}")


def _emit_struct(s: lir.MojoStruct) -> str:
    """`@fieldwise_init` + `Copyable, Movable` conformance gives the struct
    a usable constructor and value semantics in current Mojo."""
    lines = ["@fieldwise_init", f"struct {s.name}(Copyable, Movable):"]
    if not s.fields and not s.methods:
        lines.append(INDENT + "pass")
        return "\n".join(lines)
    for name, ty in s.fields:
        lines.append(f"{INDENT}var {name}: {ty}")
    for m in s.methods:
        lines.append("")
        lines.append(_emit_fn(m, depth=1))
    return "\n".join(lines)


def _emit_fn(fn: lir.MojoFn, *, depth: int = 0) -> str:
    indent = INDENT * depth
    params = ", ".join(_emit_param(n, t) for n, t in fn.params)
    ret = f" -> {fn.return_type}" if fn.return_type != "None" else ""
    header = f"{indent}def {fn.name}({params}){ret}:"
    body = _emit_block(fn.body, depth + 1) or (indent + INDENT + "pass")
    return f"{header}\n{body}"


def _emit_param(name: str, ty: str) -> str:
    if name == "self":
        return "self"
    return f"{name}: {ty}"


def _emit_block(nodes: list[lir.LirNode], depth: int) -> str:
    lines = [_emit_stmt(n, depth) for n in nodes]
    return "\n".join(lines)


def _emit_stmt(node: lir.LirNode, depth: int) -> str:
    pad = INDENT * depth
    if isinstance(node, lir.MojoReturn):
        return f"{pad}return {_emit_expr(node.value)}" if node.value else f"{pad}return"
    if isinstance(node, lir.MojoVar):
        ann = f": {node.ty}" if node.ty else ""
        return f"{pad}var {node.name}{ann} = {_emit_expr(node.value)}"
    if isinstance(node, lir.MojoReassign):
        aug = _augmented_form(node.name, node.value)
        if aug is not None:
            op, rhs = aug
            return f"{pad}{node.name} {op}= {_emit_expr(rhs)}"
        return f"{pad}{node.name} = {_emit_expr(node.value)}"
    if isinstance(node, lir.MojoFieldAssign):
        return f"{pad}{_emit_expr(node.obj)}.{node.field} = {_emit_expr(node.value)}"
    if isinstance(node, lir.MojoIf):
        head = f"{pad}if {_emit_expr(node.test)}:"
        body = _emit_block(node.body, depth + 1) or (pad + INDENT + "pass")
        if node.orelse:
            # Collapse `else: if ...` chain into `elif`.
            if len(node.orelse) == 1 and isinstance(node.orelse[0], lir.MojoIf):
                inner = _emit_stmt(node.orelse[0], depth)
                # Replace `if` with `elif` at this indent level.
                elif_inner = inner.replace(f"{pad}if ", f"{pad}elif ", 1)
                return f"{head}\n{body}\n{elif_inner}"
            else_body = _emit_block(node.orelse, depth + 1) or (pad + INDENT + "pass")
            return f"{head}\n{body}\n{pad}else:\n{else_body}"
        return f"{head}\n{body}"
    if isinstance(node, lir.MojoWhile):
        head = f"{pad}while {_emit_expr(node.test)}:"
        body = _emit_block(node.body, depth + 1) or (pad + INDENT + "pass")
        return f"{head}\n{body}"
    if isinstance(node, lir.MojoForRange):
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
    if isinstance(node, lir.MojoBinOp):
        return f"{_emit_expr(node.left)} {node.op} {_emit_expr(node.right)}"
    if isinstance(node, lir.MojoCompare):
        return f"{_emit_expr(node.left)} {node.op} {_emit_expr(node.right)}"
    if isinstance(node, lir.MojoBoolOp):
        return f"{_emit_expr(node.left)} {node.op} {_emit_expr(node.right)}"
    if isinstance(node, lir.MojoUnary):
        return f"{node.op} {_emit_expr(node.operand)}" if node.op == "not" else f"{node.op}{_emit_expr(node.operand)}"
    if isinstance(node, lir.MojoName):
        return node.name
    if isinstance(node, lir.MojoIntLiteral):
        return str(node.value)
    if isinstance(node, lir.MojoFloatLiteral):
        text = repr(node.value)
        return text if "." in text or "e" in text else text + ".0"
    if isinstance(node, lir.MojoBoolLiteral):
        return "True" if node.value else "False"
    if isinstance(node, lir.MojoStringLiteral):
        escaped = node.value.replace("\\", "\\\\").replace('"', '\\"')
        return f'"{escaped}"'
    if isinstance(node, lir.MojoList):
        items = ", ".join(_emit_expr(e) for e in node.elements)
        return f"[{items}]"
    if isinstance(node, lir.MojoFieldAccess):
        return f"{_emit_expr(node.value)}.{node.field}"
    if isinstance(node, lir.MojoStructInit):
        # @fieldwise_init synthesizes a positional constructor in declaration
        # order; emit as `Point(0, 0)`.
        args = ", ".join(_emit_expr(v) for _, v in node.field_values)
        return f"{node.name}({args})"
    if isinstance(node, lir.MojoIndex):
        return f"{_emit_expr(node.value)}[{_emit_expr(node.index)}]"
    if isinstance(node, lir.MojoCall):
        args = ", ".join(_emit_expr(a) for a in node.args)
        return f"{node.func}({args})"
    if isinstance(node, lir.MojoMethodCall):
        if not node.paren:
            return f"{_emit_expr(node.receiver)}.{node.method}"
        args = ", ".join(_emit_expr(a) for a in node.args)
        return f"{_emit_expr(node.receiver)}.{node.method}({args})"
    raise NotImplementedError(f"LIR node {type(node).__name__}")
