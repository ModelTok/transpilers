"""C LIR -> C source.

Emits an `#include <stdint.h>` / `<stdbool.h>` preamble so int64_t / bool
resolve cleanly. Deterministic — no LLM at this layer.
"""

from __future__ import annotations

from transpilers.ir import lir


INDENT = "    "
PREAMBLE = "#include <stdint.h>\n#include <stdbool.h>\n\n"


def emit_c(module: lir.CModule) -> str:
    return PREAMBLE + "\n\n".join(_emit_fn(fn) for fn in module.items) + "\n"


def _emit_fn(fn: lir.CFn) -> str:
    params = ", ".join(f"{t} {n}" for n, t in fn.params) or "void"
    header = f"{fn.return_type} {fn.name}({params}) {{"
    body = _emit_block(fn.body, 1)
    return f"{header}\n{body}\n}}"


def _emit_block(nodes: list[lir.LirNode], depth: int) -> str:
    return "\n".join(_emit_stmt(n, depth) for n in nodes)


def _emit_stmt(node: lir.LirNode, depth: int) -> str:
    pad = INDENT * depth
    if isinstance(node, lir.CReturn):
        return f"{pad}return {_emit_expr(node.value)};" if node.value else f"{pad}return;"
    if isinstance(node, lir.CDecl):
        return f"{pad}{node.ty} {node.name} = {_emit_expr(node.value)};"
    if isinstance(node, lir.CReassign):
        return f"{pad}{node.name} = {_emit_expr(node.value)};"
    if isinstance(node, lir.CIf):
        head = f"{pad}if ({_emit_expr(node.test)}) {{"
        body = _emit_block(node.body, depth + 1)
        if node.orelse:
            if len(node.orelse) == 1 and isinstance(node.orelse[0], lir.CIf):
                inner = _emit_stmt(node.orelse[0], depth).lstrip()
                return f"{head}\n{body}\n{pad}}} else {inner}"
            else_body = _emit_block(node.orelse, depth + 1)
            return f"{head}\n{body}\n{pad}}} else {{\n{else_body}\n{pad}}}"
        return f"{head}\n{body}\n{pad}}}"
    if isinstance(node, lir.CWhile):
        head = f"{pad}while ({_emit_expr(node.test)}) {{"
        body = _emit_block(node.body, depth + 1)
        return f"{head}\n{body}\n{pad}}}"
    if isinstance(node, lir.CForRange):
        # Native C for-loop. Step expressed as either `i++` (None or +1) or
        # explicit `i += <step>`.
        step_expr = "i++" if node.step is None else f"{node.target} += {_emit_expr(node.step)}"
        # Rebuild with the real target name when step is None:
        if node.step is None:
            step_expr = f"{node.target}++"
        head = (
            f"{pad}for (int64_t {node.target} = {_emit_expr(node.start)}; "
            f"{node.target} < {_emit_expr(node.stop)}; {step_expr}) {{"
        )
        body = _emit_block(node.body, depth + 1)
        return f"{head}\n{body}\n{pad}}}"
    return f"{pad}{_emit_expr(node)};"


def _emit_expr(node: lir.LirNode | None) -> str:
    if node is None:
        return ""
    if isinstance(node, lir.CBinOp):
        return f"{_emit_expr(node.left)} {node.op} {_emit_expr(node.right)}"
    if isinstance(node, lir.CCompare):
        return f"{_emit_expr(node.left)} {node.op} {_emit_expr(node.right)}"
    if isinstance(node, lir.CBoolOp):
        return f"{_emit_expr(node.left)} {node.op} {_emit_expr(node.right)}"
    if isinstance(node, lir.CUnary):
        return f"{node.op}{_emit_expr(node.operand)}"
    if isinstance(node, lir.CName):
        return node.name
    if isinstance(node, lir.CIntLiteral):
        return str(node.value)
    if isinstance(node, lir.CBoolLiteral):
        return "true" if node.value else "false"
    if isinstance(node, lir.CStringLiteral):
        escaped = node.value.replace("\\", "\\\\").replace('"', '\\"')
        return f'"{escaped}"'
    if isinstance(node, lir.CIndex):
        return f"{_emit_expr(node.value)}[{_emit_expr(node.index)}]"
    if isinstance(node, lir.CCall):
        args = ", ".join(_emit_expr(a) for a in node.args)
        return f"{node.func}({args})"
    raise NotImplementedError(f"LIR node {type(node).__name__}")
