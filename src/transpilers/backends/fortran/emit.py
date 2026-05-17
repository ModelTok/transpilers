"""Fortran LIR -> Fortran source.

Modern free-form Fortran (90+). Functions emit:

    function NAME(params) result(result_)
      implicit none
      <param decls with intent(in)>
      <result decl>
      <local decls>

      <body>
    end function

Subroutines (NoneT return) emit `subroutine NAME(...) ... end subroutine`
instead.
"""

from __future__ import annotations

from transpilers.ir import lir
from transpilers.passes.mir_to_fortran_lir import _ReturnAssign


INDENT = "  "


def emit_fortran(module: lir.FortranModule) -> str:
    return "\n\n".join(_emit_fn(fn) for fn in module.items) + "\n"


def _emit_fn(fn: lir.FortranFn) -> str:
    is_subroutine = fn.return_type is None
    keyword = "subroutine" if is_subroutine else "function"
    params = ", ".join(n for n, _ in fn.params)
    head = f"{keyword} {fn.name}({params})"
    if not is_subroutine:
        head += f" result({fn.result_name})"

    decl_lines = [f"{INDENT}implicit none"]
    for name, ty in fn.params:
        decl_lines.append(f"{INDENT}{ty}, intent(in) :: {name}")
    if not is_subroutine:
        decl_lines.append(f"{INDENT}{fn.return_type} :: {fn.result_name}")
    for name, ty in fn.locals:
        decl_lines.append(f"{INDENT}{ty} :: {name}")

    body_lines = []
    for stmt in fn.body:
        body_lines.extend(_emit_stmt(stmt, 1))

    end = f"end {keyword}"
    return "\n".join([head, *decl_lines, "", *body_lines, end])


def _emit_stmt(node: lir.LirNode, depth: int) -> list[str]:
    pad = INDENT * depth
    if isinstance(node, _ReturnAssign):
        return [f"{pad}{node.result_name} = {_emit_expr(node.value)}", f"{pad}return"]
    if isinstance(node, lir.FortranReturn):
        return [f"{pad}return"]
    if isinstance(node, lir.FortranAssign):
        return [f"{pad}{node.name} = {_emit_expr(node.value)}"]
    if isinstance(node, lir.FortranIf):
        out = [f"{pad}if ({_emit_expr(node.test)}) then"]
        for inner in node.body:
            out.extend(_emit_stmt(inner, depth + 1))
        if node.orelse:
            # Collapse `else if` chain when else is a single FortranIf.
            if len(node.orelse) == 1 and isinstance(node.orelse[0], lir.FortranIf):
                nested = node.orelse[0]
                out.append(f"{pad}else if ({_emit_expr(nested.test)}) then")
                for inner in nested.body:
                    out.extend(_emit_stmt(inner, depth + 1))
                if nested.orelse:
                    out.append(f"{pad}else")
                    for inner in nested.orelse:
                        out.extend(_emit_stmt(inner, depth + 1))
            else:
                out.append(f"{pad}else")
                for inner in node.orelse:
                    out.extend(_emit_stmt(inner, depth + 1))
        out.append(f"{pad}end if")
        return out
    if isinstance(node, lir.FortranWhile):
        out = [f"{pad}do while ({_emit_expr(node.test)})"]
        for inner in node.body:
            out.extend(_emit_stmt(inner, depth + 1))
        out.append(f"{pad}end do")
        return out
    if isinstance(node, lir.FortranForRange):
        stop_expr = _emit_inclusive_stop(node.stop)
        step = "" if node.step is None else f", {_emit_expr(node.step)}"
        out = [f"{pad}do {node.target} = {_emit_expr(node.start)}, {stop_expr}{step}"]
        for inner in node.body:
            out.extend(_emit_stmt(inner, depth + 1))
        out.append(f"{pad}end do")
        return out
    return [f"{pad}{_emit_expr(node)}"]


def _emit_inclusive_stop(stop: lir.LirNode) -> str:
    """MIR range stop is exclusive; Fortran's `do` is inclusive. Subtract 1.
    Constant-fold when both are literal ints to keep output readable."""
    if isinstance(stop, lir.FortranIntLiteral):
        return str(stop.value - 1)
    if isinstance(stop, lir.FortranBinOp) and stop.op == "+" and isinstance(stop.right, lir.FortranIntLiteral):
        # `n + 1` (a common pattern coming from inclusive→exclusive adjustments
        # in the frontend) → just `n`.
        new_value = stop.right.value - 1
        if new_value == 0:
            return _emit_expr(stop.left)
        return f"{_emit_expr(stop.left)} + {new_value}"
    return f"{_emit_expr(stop)} - 1"


def _emit_expr(node: lir.LirNode | None) -> str:
    if node is None:
        return ""
    if isinstance(node, lir.FortranBinOp):
        return f"{_emit_expr(node.left)} {node.op} {_emit_expr(node.right)}"
    if isinstance(node, lir.FortranCompare):
        return f"{_emit_expr(node.left)} {node.op} {_emit_expr(node.right)}"
    if isinstance(node, lir.FortranBoolOp):
        return f"{_emit_expr(node.left)} {node.op} {_emit_expr(node.right)}"
    if isinstance(node, lir.FortranUnary):
        if node.op == ".not.":
            return f".not. {_emit_expr(node.operand)}"
        return f"-{_emit_expr(node.operand)}"
    if isinstance(node, lir.FortranName):
        return node.name
    if isinstance(node, lir.FortranIntLiteral):
        return str(node.value)
    if isinstance(node, lir.FortranFloatLiteral):
        text = repr(node.value)
        if "." not in text and "e" not in text:
            text += ".0"
        return text + "_8"  # double-precision kind suffix
    if isinstance(node, lir.FortranBoolLiteral):
        return ".true." if node.value else ".false."
    if isinstance(node, lir.FortranStringLiteral):
        escaped = node.value.replace('"', '""')
        return f'"{escaped}"'
    if isinstance(node, lir.FortranCall):
        args = ", ".join(_emit_expr(a) for a in node.args)
        return f"{node.func}({args})"
    raise NotImplementedError(f"LIR node {type(node).__name__}")
