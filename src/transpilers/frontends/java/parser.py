"""Java source -> HIR via tree-sitter-java.

Initial subset:
  - one or more `class Foo { ... }` containers; `static` methods inside are
    extracted as top-level functions on the HIR. Non-static, generics,
    inheritance, interfaces are out of scope.
  - primitive types (int, long, short, byte, float, double, boolean, void)
  - return, if/else, while, C-style for, local variable declarations
  - binary / comparison / logical ops, integer / boolean literals, identifiers
  - method invocations
"""

from __future__ import annotations

from tree_sitter import Language, Node
import tree_sitter_java

from transpilers.ir import hir
from transpilers.frontends._treesitter import make_parser, named_children, required_field, text


class UnsupportedConstruct(Exception):
    pass


JAVA_TYPE_ALIASES: dict[str, str] = {
    "int": "int",
    "long": "int",
    "short": "int",
    "byte": "int",
    "float": "float",
    "double": "float",
    "boolean": "bool",
    "void": "None",
    "String": "str",
}


_LANGUAGE = Language(tree_sitter_java.language())


def parse_java(source: str) -> hir.HirModule:
    parser = make_parser(_LANGUAGE)
    tree = parser.parse(bytes(source, "utf-8"))
    body: list[hir.HirNode] = []
    for c in named_children(tree.root_node):
        if c.type == "class_declaration":
            body.extend(_extract_methods(c))
            continue
        if c.type in ("import_declaration", "package_declaration", "line_comment", "block_comment"):
            continue
        raise UnsupportedConstruct(f"top-level {c.type}")
    return hir.HirModule(source_lang="java", body=body)


def _extract_methods(class_decl: Node) -> list[hir.HirFunction]:
    body_node = required_field(class_decl, "body")
    out: list[hir.HirFunction] = []
    for c in named_children(body_node):
        if c.type == "method_declaration":
            out.append(_convert_method(c))
        elif c.type in ("field_declaration", "constructor_declaration"):
            # Fields and constructors are out of scope — refuse so the user
            # knows.
            raise UnsupportedConstruct(f"class body {c.type}")
    return out


def _convert_method(node: Node) -> hir.HirFunction:
    name_node = required_field(node, "name")
    type_node = required_field(node, "type")
    params_node = required_field(node, "parameters")
    body_node = required_field(node, "body")
    params = [_convert_param(p) for p in named_children(params_node) if p.type == "formal_parameter"]
    return hir.HirFunction(
        name=text(name_node),
        params=params,
        return_annotation=_type_text(type_node),
        body=_convert_block(body_node),
    )


def _convert_param(node: Node) -> hir.HirParam:
    type_node = required_field(node, "type")
    name_node = required_field(node, "name")
    return hir.HirParam(name=text(name_node), annotation=_type_text(type_node))


def _convert_block(node: Node) -> list[hir.HirNode]:
    out: list[hir.HirNode] = []
    for c in named_children(node):
        out.extend(_convert_stmt(c))
    return out


def _convert_stmt(node: Node) -> list[hir.HirNode]:
    kind = node.type
    if kind == "return_statement":
        kids = named_children(node)
        return [hir.HirReturn(value=_convert_expr(kids[0]) if kids else None)]
    if kind == "if_statement":
        return [_convert_if(node)]
    if kind == "while_statement":
        return [_convert_while(node)]
    if kind == "for_statement":
        return _convert_for(node)
    if kind == "local_variable_declaration":
        return _convert_local_var_decl(node)
    if kind == "expression_statement":
        kids = named_children(node)
        if not kids:
            return []
        return [_convert_expression_stmt(kids[0])]
    if kind == "block":
        return _convert_block(node)
    if kind in ("line_comment", "block_comment"):
        return []
    raise UnsupportedConstruct(f"java stmt {kind}")


def _convert_if(node: Node) -> hir.HirNode:
    cond = _convert_expr(required_field(node, "condition"))
    body = _convert_stmt(required_field(node, "consequence"))
    orelse_node = node.child_by_field_name("alternative")
    orelse = _convert_stmt(orelse_node) if orelse_node is not None else []
    return hir.HirIf(test=cond, body=body, orelse=orelse)


def _convert_while(node: Node) -> hir.HirNode:
    cond = _convert_expr(required_field(node, "condition"))
    body = _convert_stmt(required_field(node, "body"))
    return hir.HirWhile(test=cond, body=body)


def _convert_for(node: Node) -> list[hir.HirNode]:
    """Java C-style for: `for (init; cond; update) body`. Desugar to
    init; while(cond) { body; update; }."""
    out: list[hir.HirNode] = []
    init_node = node.child_by_field_name("init")
    cond_node = node.child_by_field_name("condition")
    update_node = node.child_by_field_name("update")
    body_node = required_field(node, "body")
    if init_node is not None:
        out.extend(_convert_stmt(init_node))
    cond = _convert_expr(cond_node) if cond_node is not None else hir.HirBoolLiteral(value=True)
    inner = _convert_stmt(body_node)
    if update_node is not None:
        inner.append(_convert_expression_stmt(update_node))
    out.append(hir.HirWhile(test=cond, body=inner))
    return out


def _convert_local_var_decl(node: Node) -> list[hir.HirNode]:
    type_node = required_field(node, "type")
    annotation = _type_text(type_node)
    out: list[hir.HirNode] = []
    for c in named_children(node):
        if c.type == "variable_declarator":
            name_node = required_field(c, "name")
            value_node = c.child_by_field_name("value")
            value = (
                _convert_expr(value_node) if value_node is not None else hir.HirIntLiteral(value=0)
            )
            out.append(hir.HirAssign(target=text(name_node), value=value, annotation=annotation))
    return out


def _convert_expression_stmt(node: Node) -> hir.HirNode:
    """Expression at statement position — must be one of: assignment, update,
    method call. Bare expressions are refused (they'd be dead code anyway)."""
    if node.type == "assignment_expression":
        return _convert_assignment(node)
    if node.type == "update_expression":
        return _convert_update(node)
    if node.type == "method_invocation":
        return _convert_expr(node)
    raise UnsupportedConstruct(f"expression statement {node.type}")


def _convert_assignment(node: Node) -> hir.HirNode:
    left = required_field(node, "left")
    right = required_field(node, "right")
    op_node = required_field(node, "operator")
    op = text(op_node)
    if left.type != "identifier":
        raise UnsupportedConstruct(f"java assignment lhs {left.type}")
    aug = None if op == "=" else op[:-1]
    return hir.HirAssign(
        target=text(left), value=_convert_expr(right), annotation=None, augmented_op=aug
    )


def _convert_update(node: Node) -> hir.HirNode:
    """`i++` / `i--` / `++i` / `--i`."""
    operand = None
    op = None
    for c in node.children:
        if c.is_named:
            operand = c
        else:
            op = text(c)
    if operand is None or operand.type != "identifier" or op not in ("++", "--"):
        raise UnsupportedConstruct(f"java update {op!r}")
    sign = "+" if op == "++" else "-"
    return hir.HirAssign(
        target=text(operand), value=hir.HirIntLiteral(value=1), annotation=None, augmented_op=sign
    )


# ---------- expressions ----------

def _convert_expr(node: Node) -> hir.HirNode:
    kind = node.type
    if kind == "decimal_integer_literal" or kind == "hex_integer_literal" or kind == "binary_integer_literal":
        return hir.HirIntLiteral(value=int(text(node).rstrip("lL").replace("_", ""), 0))
    if kind == "decimal_floating_point_literal" or kind == "hex_floating_point_literal":
        return hir.HirFloatLiteral(value=float(text(node).rstrip("fFdD").replace("_", "")))
    if kind == "true":
        return hir.HirBoolLiteral(value=True)
    if kind == "false":
        return hir.HirBoolLiteral(value=False)
    if kind == "string_literal":
        raw = text(node)
        return hir.HirStringLiteral(value=raw[1:-1])
    if kind == "identifier":
        return hir.HirName(name=text(node))
    if kind == "parenthesized_expression":
        kids = named_children(node)
        if len(kids) == 1:
            return _convert_expr(kids[0])
    if kind == "binary_expression":
        return _convert_binary(node)
    if kind == "unary_expression":
        return _convert_unary(node)
    if kind == "update_expression":
        # Update at expression position (e.g., `i + i++`) — semantics differ
        # from statement position; refuse.
        raise UnsupportedConstruct("java update at expression position")
    if kind == "method_invocation":
        return _convert_call(node)
    raise UnsupportedConstruct(f"java expr {kind}")


def _convert_binary(node: Node) -> hir.HirNode:
    left = _convert_expr(required_field(node, "left"))
    right = _convert_expr(required_field(node, "right"))
    op = text(required_field(node, "operator"))
    if op in COMPARE_OPS:
        return hir.HirCompare(op=op, left=left, right=right)
    if op in LOGICAL_OPS:
        return hir.HirBoolOp(op="and" if op == "&&" else "or", left=left, right=right)
    if op in ARITH_OPS:
        return hir.HirBinOp(op=op, left=left, right=right)
    raise UnsupportedConstruct(f"java binary op {op!r}")


def _convert_unary(node: Node) -> hir.HirNode:
    operand = None
    op = None
    for c in node.children:
        if c.is_named:
            operand = c
        else:
            op = text(c)
    if operand is None or op is None:
        raise UnsupportedConstruct("java unary missing parts")
    if op == "!":
        return hir.HirUnaryOp(op="not", operand=_convert_expr(operand))
    if op == "-":
        return hir.HirUnaryOp(op="-", operand=_convert_expr(operand))
    raise UnsupportedConstruct(f"java unary {op!r}")


def _convert_call(node: Node) -> hir.HirNode:
    name_node = required_field(node, "name")
    args_node = required_field(node, "arguments")
    args = [_convert_expr(c) for c in named_children(args_node)]
    return hir.HirCall(func=text(name_node), args=args)


COMPARE_OPS = {"==", "!=", "<", "<=", ">", ">="}
ARITH_OPS = {"+", "-", "*", "/", "%"}
LOGICAL_OPS = {"&&", "||"}


# ---------- type text ----------

def _type_text(node: Node) -> str:
    if node.type == "void_type":
        return "None"
    if node.type == "integral_type":
        kids = node.children
        # The integral kind keyword is the first (and usually only) child.
        keyword = text(kids[0]) if kids else "int"
        return JAVA_TYPE_ALIASES.get(keyword, "int")
    if node.type == "floating_point_type":
        kids = node.children
        keyword = text(kids[0]) if kids else "double"
        return JAVA_TYPE_ALIASES.get(keyword, "float")
    if node.type == "boolean_type":
        return "bool"
    if node.type == "type_identifier":
        spelling = text(node)
        return JAVA_TYPE_ALIASES.get(spelling, spelling)
    raise UnsupportedConstruct(f"java type {node.type}")
