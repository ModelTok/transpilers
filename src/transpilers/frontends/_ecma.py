"""Shared tree-sitter -> HIR conversion for the ECMAScript-family frontends (JavaScript, TypeScript).

The two grammars use the same node types for everything this subset covers. TypeScript only adds type
annotations on parameters, returns and declarators, and a couple of declaration kinds that carry no
behaviour. Those differences are the overridable hooks on `EcmaConverter`; everything else is shared.
"""

from __future__ import annotations

from tree_sitter import Language, Node

from transpilers.frontends._treesitter import (
    make_parser,
    named_children,
    required_field,
    text,
)
from transpilers.frontends.errors import UnsupportedConstruct
from transpilers.ir import hir

COMPARE_OPS = {"<", "<=", ">", ">="}
ARITH_OPS = {"+", "-", "*", "/", "%"}
LOGICAL_OPS = {"&&", "||"}


class EcmaConverter:
    """Converts one ECMAScript-family syntax tree to HIR.

    Subclasses set `lang` (the prefix in `UnsupportedConstruct` messages), `source_lang` and `language`,
    and override the `function_params` / `return_annotation` / `declarator_annotation` hooks and
    `extra_skipped_top_level` where their grammar differs."""

    lang: str
    source_lang: str
    language: Language
    # top-level node kinds accepted and ignored, in addition to the JavaScript ones
    extra_skipped_top_level: tuple[str, ...] = ()

    # --- hooks -----------------------------------------------------------------

    def function_params(self, params_node: Node) -> list[hir.HirParam]:
        return [
            hir.HirParam(name=text(p), annotation=None)
            for p in named_children(params_node)
            if p.type == "identifier"
        ]

    def return_annotation(self, node: Node) -> str | None:
        return None

    def declarator_annotation(self, node: Node) -> str | None:
        return None

    # --- module / function -----------------------------------------------------

    def parse(self, source: str) -> hir.HirModule:
        parser = make_parser(self.language)
        tree = parser.parse(bytes(source, "utf-8"))
        body: list[hir.HirNode] = []
        for c in named_children(tree.root_node):
            if c.type == "function_declaration":
                body.append(self.convert_function(c))
                continue
            if c.type in (
                "comment",
                "import_statement",
                "export_statement",
                "hash_bang_line",
            ):
                if c.type == "export_statement":
                    for inner in named_children(c):
                        if inner.type == "function_declaration":
                            body.append(self.convert_function(inner))
                continue
            if c.type in (
                "expression_statement",
                "lexical_declaration",
                "variable_declaration",
                "for_statement",
                "if_statement",
                "while_statement",
                "block_statement",
                *self.extra_skipped_top_level,
            ):
                continue
            raise UnsupportedConstruct(f"top-level {c.type}")
        return hir.HirModule(source_lang=self.source_lang, body=body)

    def convert_function(self, node: Node) -> hir.HirFunction:
        name_node = required_field(node, "name")
        params_node = required_field(node, "parameters")
        body_node = required_field(node, "body")
        params = self.function_params(params_node)
        return hir.HirFunction(
            name=text(name_node),
            params=params,
            return_annotation=self.return_annotation(node),
            body=self.convert_block(body_node),
        )

    # --- statements ------------------------------------------------------------

    def convert_block(self, node: Node) -> list[hir.HirNode]:
        if node.type != "statement_block":
            raise UnsupportedConstruct(f"{self.lang} block {node.type}")
        out: list[hir.HirNode] = []
        for c in named_children(node):
            out.extend(self.convert_stmt(c))
        return out

    def convert_stmt(self, node: Node) -> list[hir.HirNode]:
        kind = node.type
        if kind == "return_statement":
            kids = named_children(node)
            return [hir.HirReturn(value=self.convert_expr(kids[0]) if kids else None)]
        if kind == "if_statement":
            return [self.convert_if(node)]
        if kind == "while_statement":
            return [self.convert_while(node)]
        if kind == "for_statement":
            return self.convert_for(node)
        if kind in ("lexical_declaration", "variable_declaration"):
            return self.convert_variable_declaration(node)
        if kind == "expression_statement":
            kids = named_children(node)
            return [self.convert_expression_stmt(kids[0])] if kids else []
        if kind == "statement_block":
            return self.convert_block(node)
        if kind in ("comment", "empty_statement"):
            return []
        raise UnsupportedConstruct(f"{self.lang} stmt {kind}")

    def convert_if(self, node: Node) -> hir.HirNode:
        cond = self.convert_expr(required_field(node, "condition"))
        body = self.convert_stmt(required_field(node, "consequence"))
        orelse_node = node.child_by_field_name("alternative")
        orelse: list[hir.HirNode] = []
        if orelse_node is not None:
            if orelse_node.type == "else_clause":
                for c in named_children(orelse_node):
                    orelse.extend(self.convert_stmt(c))
            else:
                orelse = self.convert_stmt(orelse_node)
        return hir.HirIf(test=cond, body=body, orelse=orelse)

    def convert_while(self, node: Node) -> hir.HirNode:
        cond = self.convert_expr(required_field(node, "condition"))
        body = self.convert_stmt(required_field(node, "body"))
        return hir.HirWhile(test=cond, body=body)

    def convert_for(self, node: Node) -> list[hir.HirNode]:
        out: list[hir.HirNode] = []
        init_node = node.child_by_field_name("initializer")
        cond_node = node.child_by_field_name("condition")
        update_node = node.child_by_field_name("increment")
        body_node = required_field(node, "body")
        if init_node is not None:
            out.extend(self.convert_stmt(init_node))
        if cond_node is not None and cond_node.type == "expression_statement":
            cond_kids = named_children(cond_node)
            cond_expr = (
                self.convert_expr(cond_kids[0])
                if cond_kids
                else hir.HirBoolLiteral(value=True)
            )
        else:
            cond_expr = (
                self.convert_expr(cond_node)
                if cond_node is not None
                else hir.HirBoolLiteral(value=True)
            )
        inner = self.convert_stmt(body_node)
        if update_node is not None:
            inner.append(self.convert_expression_stmt(update_node))
        out.append(hir.HirWhile(test=cond_expr, body=inner))
        return out

    def convert_variable_declaration(self, node: Node) -> list[hir.HirNode]:
        out: list[hir.HirNode] = []
        for c in named_children(node):
            if c.type == "variable_declarator":
                out.append(self.convert_variable_declarator(c))
        return out

    def convert_variable_declarator(self, node: Node) -> hir.HirNode:
        name_node = required_field(node, "name")
        if name_node.type != "identifier":
            raise UnsupportedConstruct(f"{self.lang} declarator pattern {name_node.type}")
        annotation = self.declarator_annotation(node)
        value_node = node.child_by_field_name("value")
        value = (
            self.convert_expr(value_node)
            if value_node is not None
            else hir.HirIntLiteral(value=0)
        )
        return hir.HirAssign(target=text(name_node), value=value, annotation=annotation)

    def convert_expression_stmt(self, node: Node) -> hir.HirNode:
        if node.type == "assignment_expression":
            return self.convert_assignment(node)
        if node.type == "augmented_assignment_expression":
            return self.convert_aug_assignment(node)
        if node.type == "update_expression":
            return self.convert_update(node)
        if node.type == "call_expression":
            return self.convert_expr(node)
        raise UnsupportedConstruct(f"{self.lang} expression statement {node.type}")

    def convert_assignment(self, node: Node) -> hir.HirNode:
        left = required_field(node, "left")
        right = required_field(node, "right")
        if left.type != "identifier":
            raise UnsupportedConstruct(f"{self.lang} assignment lhs {left.type}")
        return hir.HirAssign(
            target=text(left), value=self.convert_expr(right), annotation=None
        )

    def convert_aug_assignment(self, node: Node) -> hir.HirNode:
        left = required_field(node, "left")
        right = required_field(node, "right")
        op = text(required_field(node, "operator"))
        if left.type != "identifier" or not op.endswith("="):
            raise UnsupportedConstruct(f"{self.lang} aug-assign {op!r}")
        return hir.HirAssign(
            target=text(left),
            value=self.convert_expr(right),
            annotation=None,
            augmented_op=op[:-1],
        )

    def convert_update(self, node: Node) -> hir.HirNode:
        argument = required_field(node, "argument")
        op = text(required_field(node, "operator"))
        if argument.type != "identifier" or op not in ("++", "--"):
            raise UnsupportedConstruct(f"{self.lang} update {op!r}")
        sign = "+" if op == "++" else "-"
        return hir.HirAssign(
            target=text(argument),
            value=hir.HirIntLiteral(value=1),
            annotation=None,
            augmented_op=sign,
        )

    # --- expressions -----------------------------------------------------------

    def convert_expr(self, node: Node) -> hir.HirNode:
        kind = node.type
        if kind == "number":
            raw = text(node)
            if "." in raw or "e" in raw or "E" in raw:
                return hir.HirFloatLiteral(value=float(raw))
            return hir.HirIntLiteral(value=int(raw, 0))
        if kind == "true":
            return hir.HirBoolLiteral(value=True)
        if kind == "false":
            return hir.HirBoolLiteral(value=False)
        if kind == "string":
            raw = text(node)
            return hir.HirStringLiteral(value=raw[1:-1])
        if kind == "identifier":
            return hir.HirName(name=text(node))
        if kind == "parenthesized_expression":
            kids = named_children(node)
            if len(kids) == 1:
                return self.convert_expr(kids[0])
        if kind == "binary_expression":
            return self.convert_binary(node)
        if kind == "unary_expression":
            return self.convert_unary(node)
        if kind == "call_expression":
            return self.convert_call(node)
        if kind == "update_expression":
            raise UnsupportedConstruct(f"{self.lang} update at expression position")
        raise UnsupportedConstruct(f"{self.lang} expr {kind}")

    def convert_binary(self, node: Node) -> hir.HirNode:
        left = self.convert_expr(required_field(node, "left"))
        right = self.convert_expr(required_field(node, "right"))
        op = text(required_field(node, "operator"))
        if op in ("==", "==="):
            return hir.HirCompare(op="==", left=left, right=right)
        if op in ("!=", "!=="):
            return hir.HirCompare(op="!=", left=left, right=right)
        if op in COMPARE_OPS:
            return hir.HirCompare(op=op, left=left, right=right)
        if op in LOGICAL_OPS:
            return hir.HirBoolOp(
                op="and" if op == "&&" else "or", left=left, right=right
            )
        if op in ARITH_OPS:
            return hir.HirBinOp(op=op, left=left, right=right)
        raise UnsupportedConstruct(f"{self.lang} binary {op!r}")

    def convert_unary(self, node: Node) -> hir.HirNode:
        argument = required_field(node, "argument")
        op = text(required_field(node, "operator"))
        if op == "!":
            return hir.HirUnaryOp(op="not", operand=self.convert_expr(argument))
        if op == "-":
            return hir.HirUnaryOp(op="-", operand=self.convert_expr(argument))
        raise UnsupportedConstruct(f"{self.lang} unary {op!r}")

    def convert_call(self, node: Node) -> hir.HirNode:
        func_node = required_field(node, "function")
        args_node = required_field(node, "arguments")
        if func_node.type != "identifier":
            raise UnsupportedConstruct(f"{self.lang} call target {func_node.type}")
        args = [
            self.convert_expr(c)
            for c in named_children(args_node)
            if c.type != "comment"
        ]
        return hir.HirCall(func=text(func_node), args=args)
