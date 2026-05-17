"""Go LIR -> Go source.

Emits a `package main` preamble so the file is a valid translation unit. Go
gofmt-style formatting (tabs, brace placement) is approximated; output is
deterministic and parses cleanly with `go build`.
"""

from __future__ import annotations

from transpilers.ir import lir


INDENT = "\t"
PREAMBLE = "package main\n\n"


def _is_go_method_call(node: lir.LirNode) -> bool:
    from transpilers.passes.mir_to_go_lir import _GoMethodCall as _MC
    return isinstance(node, _MC)


def _augmented_form(name: str, value: lir.LirNode) -> tuple[str, lir.LirNode] | None:
    if not isinstance(value, lir.GoBinOp):
        return None
    if not (isinstance(value.left, lir.GoName) and value.left.name == name):
        return None
    if value.op not in ("+", "-", "*", "/", "%"):
        return None
    return value.op, value.right


def emit_go(module: lir.GoModule) -> str:
    return PREAMBLE + "\n\n".join(_emit_item(item) for item in module.items) + "\n"


def _emit_item(item: lir.LirNode) -> str:
    if isinstance(item, lir.GoStruct):
        return _emit_struct(item)
    if isinstance(item, lir.GoFn):
        return _emit_fn(item)
    raise NotImplementedError(f"go top-level item {type(item).__name__}")


def _emit_struct(s: lir.GoStruct) -> str:
    field_lines = "\n".join(f"{INDENT}{n} {t}" for n, t in s.fields)
    type_def = f"type {s.name} struct {{\n{field_lines}\n}}"
    methods = "\n\n".join(_emit_fn(m, receiver_struct=s.name) for m in s.methods)
    return f"{type_def}\n\n{methods}" if methods else type_def


def _emit_fn(fn: lir.GoFn, *, receiver_struct: str | None = None) -> str:
    if receiver_struct is not None and fn.params and fn.params[0][0] == "self":
        receiver = f"(self *{receiver_struct}) "
        rest = fn.params[1:]
    else:
        receiver = ""
        rest = fn.params
    params = ", ".join(f"{n} {t}" for n, t in rest)
    ret = f" {fn.return_type}" if fn.return_type else ""
    header = f"func {receiver}{fn.name}({params}){ret} {{"
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
    if isinstance(node, lir.GoFieldAssign):
        return f"{pad}{_emit_expr(node.obj)}.{node.field} = {_emit_expr(node.value)}"
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
    if isinstance(node, lir.GoFieldAccess):
        return f"{_emit_expr(node.value)}.{node.field}"
    if isinstance(node, lir.GoStructInit):
        body = ", ".join(f"{n}: {_emit_expr(v)}" for n, v in node.field_values)
        return f"{node.name}{{{body}}}"
    from transpilers.passes.mir_to_go_lir import _GoMethodCall as _MC, _GoIfExpr
    if isinstance(node, _MC):
        args = ", ".join(_emit_expr(a) for a in node.args)
        return f"{_emit_expr(node.receiver)}.{node.method}({args})"
    if isinstance(node, _GoIfExpr):
        return (
            f"func() int64 {{ if {_emit_expr(node.test)} {{ return {_emit_expr(node.then_)} }}; "
            f"return {_emit_expr(node.else_)} }}()"
        )
    raise NotImplementedError(f"LIR node {type(node).__name__}")
