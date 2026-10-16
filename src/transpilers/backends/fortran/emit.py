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


MODULE_NAME = "m"


_PY_FLOAT_FORTRAN = """\
  function pyfloat(x) result(s)
    real(8), intent(in) :: x
    character(len=40) :: s
    integer :: i, j
    write(s, '(g0.16)') x
    s = adjustl(s)
    i = index(s, '.')
    if (i > 0) then
      j = len_trim(s)
      do while (j > i + 1 .and. s(j:j) == '0')
        j = j - 1
      end do
      s = s(1:j)
    end if
  end function pyfloat"""


def emit_fortran(module: lir.FortranModule) -> str:
    types = [item for item in module.items if isinstance(item, lir.FortranType)]
    fns = [item for item in module.items if isinstance(item, lir.FortranFn)]

    main_fn = next((f for f in fns if f.name == "main"), None)
    lib_fns = [f for f in fns if f.name != "main"]

    method_fns: list[lir.FortranFn] = []
    for t in types:
        method_fns.extend(t.methods)

    all_lib = method_fns + lib_fns

    type_blocks = "\n\n".join(_emit_type_decl_only(t) for t in types)
    fn_blocks = "\n\n".join(_emit_fn(f) for f in all_lib)
    program_body = _emit_program(main_fn) if main_fn else ""
    if "pyfloat(" in fn_blocks or "pyfloat(" in program_body:
        fn_blocks = _PY_FLOAT_FORTRAN + ("\n\n" + fn_blocks if fn_blocks else "")

    module_lines = [f"module {MODULE_NAME}", f"{INDENT}implicit none"]
    if type_blocks:
        module_lines.append("")
        module_lines.append(type_blocks)
    if fn_blocks:
        module_lines.append("")
        module_lines.append("contains")
        module_lines.append("")
        module_lines.append(fn_blocks)
        module_lines.append("")
    module_lines.append(f"end module {MODULE_NAME}")
    module_block = "\n".join(module_lines)

    if main_fn is None:
        return module_block + "\n"

    return module_block + "\n\n" + program_body + "\n"


def _emit_program(main_fn: lir.FortranFn) -> str:
    """Emit a `program prog ... end program prog` block from the main function."""
    decl_lines = [f"{INDENT}use {MODULE_NAME}", f"{INDENT}implicit none"]
    for name, ty in main_fn.locals:
        if "dimension(:)" in ty:
            decl_lines.append(f"{INDENT}{ty}, allocatable :: {name}")
        else:
            decl_lines.append(f"{INDENT}{ty} :: {name}")
    body_lines: list[str] = []
    for stmt in main_fn.body:
        body_lines.extend(_emit_stmt(stmt, 1))
    lines = ["program prog", *decl_lines, ""]
    if body_lines:
        lines.extend(body_lines)
    lines.append("end program prog")
    return "\n".join(lines)


def _emit_type_decl_only(t: lir.FortranType) -> str:
    """Type declaration only (no methods) — used inside a module's
    pre-`contains` declaration area."""
    lines = [f"{INDENT}type :: {t.name}"]
    for n, ty in t.fields:
        lines.append(f"{INDENT}{INDENT}{ty} :: {n}")
    lines.append(f"{INDENT}end type {t.name}")
    return "\n".join(lines)


def _emit_item(item: lir.LirNode) -> str:
    if isinstance(item, lir.FortranType):
        return _emit_type(item)
    if isinstance(item, lir.FortranFn):
        return _emit_fn(item)
    raise NotImplementedError(f"fortran top-level item {type(item).__name__}")


def _emit_type(t: lir.FortranType) -> str:
    """`type :: Name ... end type Name` followed by free-function methods.
    Methods land outside the type block since Fortran type-bound procedures
    need a `contains` block inside the type — that's a follow-on; here we
    use the simpler free-function form named `Name_method`."""
    lines = [f"type :: {t.name}"]
    for n, ty in t.fields:
        lines.append(f"{INDENT}{ty} :: {n}")
    lines.append(f"end type {t.name}")
    if not t.methods:
        return "\n".join(lines)
    method_defs = "\n\n".join(_emit_fn(m) for m in t.methods)
    return "\n".join(lines) + "\n\n" + method_defs


def _collect_assigned_names(nodes: list[lir.LirNode]) -> set[str]:
    """Return the set of names that appear on the LHS of any assignment in
    the body (including nested blocks). Used to suppress `intent(in)` for
    parameters that the function body mutates."""
    assigned: set[str] = set()
    for node in nodes:
        if isinstance(node, lir.FortranAssign):
            assigned.add(node.name.split("%")[0])
        elif isinstance(node, lir.FortranSubscriptAssign):
            if isinstance(node.obj, lir.FortranName):
                assigned.add(node.obj.name)
        elif isinstance(node, lir.FortranIf):
            assigned |= _collect_assigned_names(node.body)
            assigned |= _collect_assigned_names(node.orelse)
        elif isinstance(node, lir.FortranWhile):
            assigned |= _collect_assigned_names(node.body)
        elif isinstance(node, lir.FortranForRange):
            assigned.add(node.target)
            assigned |= _collect_assigned_names(node.body)
    return assigned


def _calls_name(nodes: list[lir.LirNode], name: str) -> bool:
    """Return True if any FortranCall in the body (recursively) calls `name`."""
    for node in nodes:
        if isinstance(node, lir.FortranCall) and node.func == name:
            return True
        if isinstance(node, lir.FortranAssign) and _calls_name_expr(node.value, name):
            return True
        if isinstance(node, _ReturnAssign) and _calls_name_expr(node.value, name):
            return True
        if isinstance(node, lir.FortranIf):
            if _calls_name(node.body, name) or _calls_name(node.orelse, name):
                return True
        if isinstance(node, lir.FortranWhile) and _calls_name(node.body, name):
            return True
        if isinstance(node, lir.FortranForRange) and _calls_name(node.body, name):
            return True
    return False


def _calls_name_expr(node: lir.LirNode | None, name: str) -> bool:
    if node is None:
        return False
    if isinstance(node, lir.FortranCall):
        if node.func == name:
            return True
        return any(_calls_name_expr(a, name) for a in node.args)
    if isinstance(node, lir.FortranBinOp):
        return _calls_name_expr(node.left, name) or _calls_name_expr(node.right, name)
    if isinstance(node, lir.FortranCompare):
        return _calls_name_expr(node.left, name) or _calls_name_expr(node.right, name)
    if isinstance(node, lir.FortranBoolOp):
        return _calls_name_expr(node.left, name) or _calls_name_expr(node.right, name)
    if isinstance(node, lir.FortranUnary):
        return _calls_name_expr(node.operand, name)
    return False


def _emit_fn(fn: lir.FortranFn) -> str:
    is_subroutine = fn.return_type is None
    keyword = "subroutine" if is_subroutine else "function"
    is_recursive = _calls_name(fn.body, fn.name)
    recursive_prefix = "recursive " if is_recursive else ""
    params = ", ".join(n for n, _ in fn.params)
    head = f"{recursive_prefix}{keyword} {fn.name}({params})"
    if not is_subroutine:
        head += f" result({fn.result_name})"

    assigned_in_body = _collect_assigned_names(fn.body)

    decl_lines = [f"{INDENT}implicit none"]
    for name, ty in fn.params:
        is_array = "dimension(:)" in ty
        if name in assigned_in_body and not is_array:
            decl_lines.append(f"{INDENT}{ty}, value :: {name}")
        elif name in assigned_in_body and is_array:
            decl_lines.append(f"{INDENT}{ty}, intent(inout) :: {name}")
        else:
            decl_lines.append(f"{INDENT}{ty}, intent(in) :: {name}")
    if not is_subroutine:
        decl_lines.append(f"{INDENT}{fn.return_type} :: {fn.result_name}")
    for name, ty in fn.locals:
        if "dimension(:)" in ty:
            decl_lines.append(f"{INDENT}{ty}, allocatable :: {name}")
        else:
            decl_lines.append(f"{INDENT}{ty} :: {name}")

    body_lines = []
    for stmt in fn.body:
        body_lines.extend(_emit_stmt(stmt, 1))

    end = f"end {keyword}"
    return "\n".join([head, *decl_lines, "", *body_lines, end])


def _flatten_snippet(snippet: str) -> str:
    """Collapse a multi-line source snippet to a single comment-safe line."""
    return " ".join(snippet.split())


def _emit_stmt(node: lir.LirNode, depth: int) -> list[str]:
    pad = INDENT * depth
    if isinstance(node, lir.FortranRaw):
        return [f"{pad}! TODO[port]: {_flatten_snippet(node.snippet)}"]
    if isinstance(node, _ReturnAssign):
        return [f"{pad}{node.result_name} = {_emit_expr(node.value)}", f"{pad}return"]
    if isinstance(node, lir.FortranExit):
        return [f"{pad}exit"]
    if isinstance(node, lir.FortranCycle):
        return [f"{pad}cycle"]
    if isinstance(node, lir.FortranReturn):
        return [f"{pad}return"]
    if isinstance(node, lir.FortranAssign):
        return [f"{pad}{node.name} = {_emit_expr(node.value)}"]
    if isinstance(node, lir.FortranSubscriptAssign):
        return [
            f"{pad}{_emit_expr(node.obj)}({_emit_expr(node.index)} + 1) = {_emit_expr(node.value)}"
        ]
    if isinstance(node, lir.FortranCall) and node.func in ("print", "println"):
        rendered = ", ".join(_emit_expr(a) for a in node.args)
        return [f"{pad}print '(*(g0, 1x))', {rendered}"]
    if isinstance(node, lir.FortranIf):
        out = [f"{pad}if ({_emit_expr(node.test)}) then"]
        for inner in node.body:
            out.extend(_emit_stmt(inner, depth + 1))
        if node.orelse:
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
    if (
        isinstance(stop, lir.FortranBinOp)
        and stop.op == "+"
        and isinstance(stop.right, lir.FortranIntLiteral)
    ):
        new_value = stop.right.value - 1
        if new_value == 0:
            return _emit_expr(stop.left)
        return f"{_emit_expr(stop.left)} + {new_value}"
    return f"{_emit_expr(stop)} - 1"


def _op_of(node: lir.LirNode) -> str | None:
    if isinstance(node, (lir.FortranBinOp, lir.FortranCompare, lir.FortranBoolOp)):
        return node.op
    return None


def _paren(child: lir.LirNode, parent_op: str, *, on_right: bool) -> str:
    from transpilers.backends._precedence import paren_emit

    return paren_emit(
        child, parent_op, on_right=on_right, emit_expr=_emit_expr, op_of=_op_of
    )


def _emit_expr(node: lir.LirNode | None) -> str:
    if node is None:
        return ""
    if isinstance(node, lir.FortranRaw):
        text = _flatten_snippet(node.snippet).replace("'", "''")
        return f"todo_port('{text}')"
    if isinstance(node, lir.FortranBinOp):
        return f"{_paren(node.left, node.op, on_right=False)} {node.op} {_paren(node.right, node.op, on_right=True)}"
    if isinstance(node, lir.FortranCompare):
        return f"{_paren(node.left, node.op, on_right=False)} {node.op} {_paren(node.right, node.op, on_right=True)}"
    if isinstance(node, lir.FortranBoolOp):
        return f"{_paren(node.left, node.op, on_right=False)} {node.op} {_paren(node.right, node.op, on_right=True)}"
    if isinstance(node, lir.FortranUnary):
        operand = _paren(node.operand, "__unary__", on_right=False)
        if node.op == ".not.":
            return f".not. {operand}"
        return f"-{operand}"
    if isinstance(node, lir.FortranName):
        return node.name
    if isinstance(node, lir.FortranIntLiteral):
        return str(node.value)
    if isinstance(node, lir.FortranFloatLiteral):
        text = repr(node.value)
        if "." not in text and "e" not in text:
            text += ".0"
        return text + "_8"
    if isinstance(node, lir.FortranBoolLiteral):
        return ".true." if node.value else ".false."
    if isinstance(node, lir.FortranStringLiteral):
        escaped = node.value.replace('"', '""')
        return f'"{escaped}"'
    if isinstance(node, lir.FortranCall):
        args = ", ".join(_emit_expr(a) for a in node.args)
        return f"{node.func}({args})"
    if isinstance(node, lir.FortranFieldAccess):
        return f"{_emit_expr(node.value)}%{node.field}"
    if isinstance(node, lir.FortranStructInit):
        args = ", ".join(_emit_expr(v) for _, v in node.field_values)
        return f"{node.name}({args})"
    if isinstance(node, lir.FortranArrayLit):
        if not node.elements:
            assert node.elem_type, "empty FortranArrayLit requires elem_type"
            return f"[{node.elem_type} ::]"
        elems = ", ".join(_emit_expr(e) for e in node.elements)
        return f"[{elems}]"
    if isinstance(node, lir.FortranSubscript):
        if isinstance(node.index, lir.FortranIntLiteral):
            return f"{_emit_expr(node.value)}({node.index.value + 1})"
        if (
            isinstance(node.index, lir.FortranBinOp)
            and node.index.op == "+"
            and isinstance(node.index.right, lir.FortranIntLiteral)
        ):
            return f"{_emit_expr(node.value)}({_emit_expr(node.index.left)} + {node.index.right.value + 1})"
        return f"{_emit_expr(node.value)}({_emit_expr(node.index)} + 1)"
    raise NotImplementedError(f"LIR node {type(node).__name__}")
