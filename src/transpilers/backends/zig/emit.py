"""Zig LIR -> Zig source.

Deterministic emission. The `_ZigBlock` marker from the lowering pass
unwraps inline so stepped-range desugaring (`var i = a; while (i < b) ...`)
appears as a flat sequence of statements at the call site.
"""

from __future__ import annotations

from transpilers.ir import lir
from transpilers.passes.mir_to_zig_lir import _ZigBlock


INDENT = "    "


def emit_zig(module: lir.ZigModule) -> str:
    return "\n\n".join(_emit_fn(fn) for fn in module.items) + "\n"


def _emit_fn(fn: lir.ZigFn) -> str:
    params = ", ".join(f"{n}: {t}" for n, t in fn.params)
    header = f"fn {fn.name}({params}) {fn.return_type} {{"
    body = _emit_block(fn.body, 1)
    return f"{header}\n{body}\n}}"


def _augmented_form(name: str, value: lir.LirNode) -> tuple[str, lir.LirNode] | None:
    if not isinstance(value, lir.ZigBinOp):
        return None
    if not (isinstance(value.left, lir.ZigName) and value.left.name == name):
        return None
    if value.op not in ("+", "-", "*", "/", "%"):
        return None
    return value.op, value.right


def _emit_block(nodes: list[lir.LirNode], depth: int) -> str:
    lines: list[str] = []
    for n in nodes:
        if isinstance(n, _ZigBlock):
            for inner in n.items:
                lines.append(_emit_stmt(inner, depth))
        else:
            lines.append(_emit_stmt(n, depth))
    return "\n".join(lines)


def _emit_stmt(node: lir.LirNode, depth: int) -> str:
    pad = INDENT * depth
    if isinstance(node, lir.ZigReturn):
        return f"{pad}return {_emit_expr(node.value)};" if node.value else f"{pad}return;"
    if isinstance(node, lir.ZigVar):
        keyword = "var" if node.mutable else "const"
        ann = f": {node.ty}" if node.ty else ""
        return f"{pad}{keyword} {node.name}{ann} = {_emit_expr(node.value)};"
    if isinstance(node, lir.ZigReassign):
        aug = _augmented_form(node.name, node.value)
        if aug is not None:
            op, rhs = aug
            return f"{pad}{node.name} {op}= {_emit_expr(rhs)};"
        return f"{pad}{node.name} = {_emit_expr(node.value)};"
    if isinstance(node, lir.ZigIf):
        head = f"{pad}if ({_emit_expr(node.test)}) {{"
        body = _emit_block(node.body, depth + 1)
        if node.orelse:
            if len(node.orelse) == 1 and isinstance(node.orelse[0], lir.ZigIf):
                inner = _emit_stmt(node.orelse[0], depth).lstrip()
                return f"{head}\n{body}\n{pad}}} else {inner}"
            else_body = _emit_block(node.orelse, depth + 1)
            return f"{head}\n{body}\n{pad}}} else {{\n{else_body}\n{pad}}}"
        return f"{head}\n{body}\n{pad}}}"
    if isinstance(node, lir.ZigWhile):
        head = f"{pad}while ({_emit_expr(node.test)}) {{"
        body = _emit_block(node.body, depth + 1)
        return f"{head}\n{body}\n{pad}}}"
    if isinstance(node, lir.ZigForRange):
        head = f"{pad}for ({_emit_expr(node.start)}..{_emit_expr(node.stop)}) |{node.target}| {{"
        body = _emit_block(node.body, depth + 1)
        return f"{head}\n{body}\n{pad}}}"
    if isinstance(node, _ZigBlock):
        # Block at statement position — emit each item at this depth.
        return "\n".join(_emit_stmt(inner, depth) for inner in node.items)
    return f"{pad}{_emit_expr(node)};"


def _emit_expr(node: lir.LirNode | None) -> str:
    if node is None:
        return ""
    if isinstance(node, lir.ZigBinOp):
        return f"{_emit_expr(node.left)} {node.op} {_emit_expr(node.right)}"
    if isinstance(node, lir.ZigCompare):
        return f"{_emit_expr(node.left)} {node.op} {_emit_expr(node.right)}"
    if isinstance(node, lir.ZigBoolOp):
        return f"{_emit_expr(node.left)} {node.op} {_emit_expr(node.right)}"
    if isinstance(node, lir.ZigUnary):
        return f"{node.op}{_emit_expr(node.operand)}"
    if isinstance(node, lir.ZigName):
        return node.name
    if isinstance(node, lir.ZigIntLiteral):
        return str(node.value)
    if isinstance(node, lir.ZigFloatLiteral):
        text = repr(node.value)
        return text if "." in text or "e" in text else text + ".0"
    if isinstance(node, lir.ZigBoolLiteral):
        return "true" if node.value else "false"
    if isinstance(node, lir.ZigStringLiteral):
        escaped = node.value.replace("\\", "\\\\").replace('"', '\\"')
        return f'"{escaped}"'
    if isinstance(node, lir.ZigArrayLit):
        items = ", ".join(_emit_expr(e) for e in node.elements)
        return f"[_]{node.elem_ty}{{{items}}}"
    if isinstance(node, lir.ZigIndex):
        return f"{_emit_expr(node.value)}[@intCast({_emit_expr(node.index)})]"
    if isinstance(node, lir.ZigMethodCall):
        # Special-case .len which is a property in Zig.
        if node.method == "len" and not node.args:
            base = f"{_emit_expr(node.receiver)}.len"
            return f"@as({node.cast_to}, @intCast({base}))" if node.cast_to else base
        args = ", ".join(_emit_expr(a) for a in node.args)
        call = f"{_emit_expr(node.receiver)}.{node.method}({args})"
        return f"@as({node.cast_to}, @intCast({call}))" if node.cast_to else call
    if isinstance(node, lir.ZigCall):
        args = ", ".join(_emit_expr(a) for a in node.args)
        return f"{node.func}({args})"
    raise NotImplementedError(f"LIR node {type(node).__name__}")
