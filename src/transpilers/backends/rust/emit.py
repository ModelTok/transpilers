"""Rust LIR -> Rust source.

Deterministic emission. No LLM here — naming/comment LLM passes operate on the
LIR before emission, never on the text. Keeping emit pure makes the output
reproducible and makes round-trip parsing (re-parsing emitted Rust back into
its CST) viable.
"""

from __future__ import annotations

from transpilers.ir import lir


INDENT = "    "


def _augmented_form(name: str, value: lir.LirNode) -> tuple[str, lir.LirNode] | None:
    """If `value` is `name <op> rhs` with op in the augmented-assign set, return
    `(op, rhs)`. Lets Reassign emit `x += v` instead of `x = x + v`."""
    if not isinstance(value, lir.RustBinOp):
        return None
    if not (isinstance(value.left, lir.RustName) and value.left.name == name):
        return None
    if value.op not in ("+", "-", "*", "/", "%"):
        return None
    return value.op, value.right


def _format_float(value: float) -> str:
    """Emit a Rust-parseable float literal. Whole numbers need an explicit
    decimal to differentiate from int (`1f64` works but `1.0` is more
    idiomatic at the source level)."""
    text = repr(value)
    if "." not in text and "e" not in text and "E" not in text:
        text += ".0"
    return text


def emit_rust(module: lir.RustModule) -> str:
    return "\n\n".join(_emit_item(item) for item in module.items) + "\n"


def _emit_item(item: lir.LirNode) -> str:
    if isinstance(item, lir.RustStruct):
        return _emit_struct(item)
    if isinstance(item, lir.RustImpl):
        return _emit_impl(item)
    if isinstance(item, lir.RustFn):
        return _emit_fn(item)
    raise NotImplementedError(f"rust top-level item {type(item).__name__}")


def _emit_struct(s: lir.RustStruct) -> str:
    field_lines = ",\n".join(f"{INDENT}{n}: {t}" for n, t in s.fields)
    return f"struct {s.name} {{\n{field_lines},\n}}"


def _emit_impl(impl: lir.RustImpl) -> str:
    body = "\n\n".join(_emit_fn(m, depth=1) for m in impl.methods)
    return f"impl {impl.struct_name} {{\n{body}\n}}"


def _emit_fn(fn: lir.RustFn, *, depth: int = 0) -> str:
    indent = INDENT * depth
    params = ", ".join(_emit_param(n, t) for n, t in fn.params)
    # Drop `-> ()` for unit-returning fns.
    ret = "" if fn.return_type == "()" else f" -> {fn.return_type}"
    header = f"{indent}fn {fn.name}({params}){ret} {{"
    body = _emit_block(fn.body, depth + 1)
    return f"{header}\n{body}\n{indent}}}"


def _emit_param(name: str, ty: str) -> str:
    # Convention: a parameter named `self` is the method receiver — emit as
    # `&self` (immutable borrow) regardless of the declared type. Method
    # mutation would need `&mut self`, which we don't yet model.
    if name == "self":
        return "&self"
    return f"{name}: {ty}"


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
        aug = _augmented_form(node.name, node.value)
        if aug is not None:
            op, rhs = aug
            return f"{pad}{node.name} {op}= {_emit_expr(rhs)};"
        return f"{pad}{node.name} = {_emit_expr(node.value)};"
    if isinstance(node, lir.RustFieldAssign):
        return f"{pad}{_emit_expr(node.obj)}.{node.field} = {_emit_expr(node.value)};"
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
        # Drop the suffix when None — Rust's type inference picks it up from
        # context (let bindings, fn signatures, surrounding binops with a
        # typed side). Keeps emitted source readable.
        return f"{node.value}{node.suffix or ''}"
    if isinstance(node, lir.RustFloatLiteral):
        return _format_float(node.value) + (node.suffix or "")
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
    if isinstance(node, lir.RustFieldAccess):
        return f"{_emit_expr(node.value)}.{node.field}"
    if isinstance(node, lir.RustStructInit):
        body = ", ".join(f"{n}: {_emit_expr(v)}" for n, v in node.field_values)
        return f"{node.name} {{ {body} }}"
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
