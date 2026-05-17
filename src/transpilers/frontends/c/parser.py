"""C source -> HIR via pycparser.

Initial subset:
  - function defs with int/long/float/double/void/char param + return types
  - return, if/else, while
  - assignments and `int x = 0;` style declarations
  - binary ops, comparisons, logical ops, unary not/neg
  - integer literals, names
  - C-style `for (init; cond; step)` desugars to `init; while (cond) { body; step; }`

Anything outside the subset raises UnsupportedConstruct. The HIR produced is
the same shape as Python's — that's the architectural payoff: the rest of
the pipeline (HIR->MIR, inference, LIR, emit, verify) sees no difference.
"""

from __future__ import annotations

from pycparser import CParser, c_ast

from transpilers.ir import hir


class UnsupportedConstruct(Exception):
    pass


# C types that map onto the shared HIR annotation strings. The HIR->MIR pass
# resolves these against the type lattice; new aliases land here.
C_TYPE_ALIASES: dict[str, str] = {
    "int": "int",
    "long": "int",
    "short": "int",
    "char": "int",
    "float": "float",
    "double": "float",
    "void": "None",
    "_Bool": "bool",
    "bool": "bool",
}


def parse_c(source: str) -> hir.HirModule:
    parser = CParser()
    tree = parser.parse(source, filename="<input>")
    body: list[hir.HirNode] = []
    for ext in tree.ext:
        if isinstance(ext, c_ast.FuncDef):
            body.append(_convert_function(ext))
            continue
        raise UnsupportedConstruct(f"top-level {type(ext).__name__}")
    return hir.HirModule(source_lang="c", body=body)


def _convert_function(fn: c_ast.FuncDef) -> hir.HirFunction:
    name = fn.decl.name
    func_decl = fn.decl.type
    params = _convert_params(func_decl.args)
    return_annotation = _type_text(func_decl.type)
    body = _convert_block(fn.body)
    return hir.HirFunction(name=name, params=params, return_annotation=return_annotation, body=body)


def _convert_params(args) -> list[hir.HirParam]:
    if args is None:
        return []
    out: list[hir.HirParam] = []
    for p in args.params:
        if isinstance(p, c_ast.Typename):
            # `int main(void)` — no params.
            continue
        out.append(hir.HirParam(name=p.name, annotation=_type_text(p.type)))
    return out


def _convert_block(node: c_ast.Node) -> list[hir.HirNode]:
    if isinstance(node, c_ast.Compound):
        items = node.block_items or []
    else:
        items = [node]
    out: list[hir.HirNode] = []
    for stmt in items:
        out.extend(_convert_stmt(stmt))
    return out


def _convert_stmt(node: c_ast.Node) -> list[hir.HirNode]:
    if isinstance(node, c_ast.Decl):
        return [_convert_decl(node)]
    if isinstance(node, c_ast.Return):
        value = _convert_expr(node.expr) if node.expr is not None else None
        return [hir.HirReturn(value=value)]
    if isinstance(node, c_ast.If):
        body = _convert_block(node.iftrue) if node.iftrue is not None else []
        orelse = _convert_block(node.iffalse) if node.iffalse is not None else []
        return [hir.HirIf(test=_convert_expr(node.cond), body=body, orelse=orelse)]
    if isinstance(node, c_ast.While):
        body = _convert_block(node.stmt)
        return [hir.HirWhile(test=_convert_expr(node.cond), body=body)]
    if isinstance(node, c_ast.For):
        return _convert_for(node)
    if isinstance(node, c_ast.Assignment):
        return [_convert_assignment(node)]
    if isinstance(node, c_ast.UnaryOp) and node.op in ("p++", "++", "p--", "--"):
        # `i++;` as a statement
        return [_convert_increment(node)]
    if isinstance(node, c_ast.FuncCall):
        # Bare call as a statement (`foo(1, 2);`) — value is discarded.
        return [_convert_expr(node)]
    if isinstance(node, c_ast.Compound):
        # Nested block — flatten. (C scoping is finer-grained than Python's,
        # but for the initial subset we don't model nested scopes.)
        return _convert_block(node)
    raise UnsupportedConstruct(f"stmt {type(node).__name__}")


def _convert_for(node: c_ast.For) -> list[hir.HirNode]:
    """`for (init; cond; step) body` desugars to `init; while (cond) { body; step; }`."""
    out: list[hir.HirNode] = []
    if node.init is not None:
        # init can be a Decl (`int i = 0`) or an Assignment or a DeclList
        if isinstance(node.init, c_ast.DeclList):
            for d in node.init.decls:
                out.append(_convert_decl(d))
        elif isinstance(node.init, c_ast.Decl):
            out.append(_convert_decl(node.init))
        elif isinstance(node.init, c_ast.Assignment):
            out.append(_convert_assignment(node.init))
        else:
            raise UnsupportedConstruct(f"for-init {type(node.init).__name__}")
    cond = _convert_expr(node.cond) if node.cond is not None else hir.HirBoolLiteral(value=True)
    body = _convert_block(node.stmt) if node.stmt is not None else []
    if node.next is not None:
        if isinstance(node.next, c_ast.UnaryOp) and node.next.op in ("p++", "++", "p--", "--"):
            body.append(_convert_increment(node.next))
        elif isinstance(node.next, c_ast.Assignment):
            body.append(_convert_assignment(node.next))
        else:
            raise UnsupportedConstruct(f"for-step {type(node.next).__name__}")
    out.append(hir.HirWhile(test=cond, body=body))
    return out


def _convert_decl(node: c_ast.Decl) -> hir.HirNode:
    annotation = _type_text(node.type)
    value = _convert_expr(node.init) if node.init is not None else hir.HirIntLiteral(value=0)
    return hir.HirAssign(target=node.name, value=value, annotation=annotation)


def _convert_assignment(node: c_ast.Assignment) -> hir.HirNode:
    if not isinstance(node.lvalue, c_ast.ID):
        raise UnsupportedConstruct(f"assignment lhs {type(node.lvalue).__name__}")
    target = node.lvalue.name
    value = _convert_expr(node.rvalue)
    aug = node.op[:-1] if node.op != "=" and node.op.endswith("=") else None
    return hir.HirAssign(target=target, value=value, annotation=None, augmented_op=aug)


def _convert_increment(node: c_ast.UnaryOp) -> hir.HirNode:
    """`i++` / `i--` → `i += 1` / `i -= 1`. We model as augmented-assignment so
    the existing MIR mutability inference picks up the rebind."""
    if not isinstance(node.expr, c_ast.ID):
        raise UnsupportedConstruct(f"increment lhs {type(node.expr).__name__}")
    op = "+" if node.op in ("p++", "++") else "-"
    return hir.HirAssign(
        target=node.expr.name,
        value=hir.HirIntLiteral(value=1),
        annotation=None,
        augmented_op=op,
    )


def _convert_expr(node: c_ast.Node) -> hir.HirNode:
    if isinstance(node, c_ast.Constant):
        if node.type == "int":
            return hir.HirIntLiteral(value=int(node.value, 0))  # base=0 handles 0x..., 0..., 0b...
        if node.type in ("float", "double"):
            # Strip the f/F/l/L suffix C floats may carry (`1.5f`, `2.0L`).
            text = node.value.rstrip("fFlL")
            return hir.HirFloatLiteral(value=float(text))
        if node.type == "string":
            return hir.HirStringLiteral(value=node.value[1:-1])
        raise UnsupportedConstruct(f"constant type {node.type}")
    if isinstance(node, c_ast.ID):
        return hir.HirName(name=node.name)
    if isinstance(node, c_ast.BinaryOp):
        return _convert_binop(node)
    if isinstance(node, c_ast.UnaryOp):
        return _convert_unaryop(node)
    if isinstance(node, c_ast.FuncCall):
        return _convert_call(node)
    if isinstance(node, c_ast.Assignment):
        # Expression-level assignment (`x = 5` as an expression). C allows this;
        # we don't, in the initial subset.
        raise UnsupportedConstruct("assignment as expression")
    raise UnsupportedConstruct(f"expr {type(node).__name__}")


COMPARE_OPS = {"==", "!=", "<", "<=", ">", ">="}
ARITH_OPS = {"+", "-", "*", "/", "%"}
LOGICAL_OPS = {"&&", "||"}


def _convert_binop(node: c_ast.BinaryOp) -> hir.HirNode:
    left = _convert_expr(node.left)
    right = _convert_expr(node.right)
    if node.op in COMPARE_OPS:
        return hir.HirCompare(op=node.op, left=left, right=right)
    if node.op in LOGICAL_OPS:
        return hir.HirBoolOp(op="and" if node.op == "&&" else "or", left=left, right=right)
    if node.op in ARITH_OPS:
        return hir.HirBinOp(op=node.op, left=left, right=right)
    raise UnsupportedConstruct(f"binary op {node.op}")


def _convert_unaryop(node: c_ast.UnaryOp) -> hir.HirNode:
    if node.op == "!":
        return hir.HirUnaryOp(op="not", operand=_convert_expr(node.expr))
    if node.op == "-":
        return hir.HirUnaryOp(op="-", operand=_convert_expr(node.expr))
    if node.op in ("p++", "++", "p--", "--"):
        # ++/-- as an expression is asymmetric (pre vs post). We only support
        # them as statements via `_convert_increment`.
        raise UnsupportedConstruct("++/-- as expression")
    raise UnsupportedConstruct(f"unary op {node.op}")


def _convert_call(node: c_ast.FuncCall) -> hir.HirNode:
    if not isinstance(node.name, c_ast.ID):
        raise UnsupportedConstruct(f"call target {type(node.name).__name__}")
    args = []
    if node.args is not None:
        args = [_convert_expr(a) for a in node.args.exprs]
    return hir.HirCall(func=node.name.value if hasattr(node.name, "value") else node.name.name, args=args)


# ---------- type text rendering ----------

def _type_text(node: c_ast.Node) -> str:
    """Render a C type expression as a HIR annotation string. We collapse
    aliases (long, short, char) into the lattice via C_TYPE_ALIASES so the
    HIR->MIR pass doesn't need C knowledge."""
    if isinstance(node, c_ast.TypeDecl):
        return _type_text(node.type)
    if isinstance(node, c_ast.IdentifierType):
        # `long long` collapses to `int` via our alias map; any single token
        # also passes through.
        names = list(node.names)
        # Use the most specific token (last one wins for `long long int` etc.)
        for token in names:
            if token in C_TYPE_ALIASES:
                return C_TYPE_ALIASES[token]
        return " ".join(names)
    raise UnsupportedConstruct(f"C type {type(node).__name__}")
