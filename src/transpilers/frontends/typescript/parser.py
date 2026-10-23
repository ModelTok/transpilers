"""TypeScript source -> HIR via tree-sitter-typescript.

Initial subset:
  - top-level `function name(args): T { ... }` declarations
  - primitive types: number / boolean / string / void (and `bigint` aliasing to int)
  - return, if/else, while, C-style for
  - `let` / `const` / `var` declarations with optional type annotations
  - binary / comparison / logical ops, integer / boolean / string literals,
    method-less call expressions

TypeScript `number` is semantically a 64-bit float, but most code uses it for
integers. To stay inside the existing IntT pipeline (and because explicit
floats are a small follow-up — no HirFloatLiteral yet), we map `number` to
`int`. This is a known approximation; division will be integer division
under that mapping.

Statement and expression conversion is shared with JavaScript
(`transpilers.frontends._ecma`); this module adds the type annotations.
"""

from __future__ import annotations

from tree_sitter import Language, Node
import tree_sitter_typescript

from transpilers.frontends._ecma import EcmaConverter
from transpilers.frontends._treesitter import named_children, required_field, text
from transpilers.frontends.errors import UnsupportedConstruct
from transpilers.ir import hir

TS_TYPE_ALIASES: dict[str, str] = {
    "number": "int",
    "bigint": "int",
    "boolean": "bool",
    "string": "str",
    "void": "None",
    "undefined": "None",
    "null": "None",
}


class _TypeScript(EcmaConverter):
    lang = "ts"
    source_lang = "typescript"
    language = Language(tree_sitter_typescript.language_typescript())
    extra_skipped_top_level = ("type_alias_declaration", "interface_declaration")

    def function_params(self, params_node: Node) -> list[hir.HirParam]:
        return [
            self._convert_param(p)
            for p in named_children(params_node)
            if p.type in ("required_parameter", "optional_parameter")
        ]

    def return_annotation(self, node: Node) -> str | None:
        return_type_node = node.child_by_field_name("return_type")
        if return_type_node is None:
            return None
        return _type_annotation_text(return_type_node)

    def declarator_annotation(self, node: Node) -> str | None:
        type_node = node.child_by_field_name("type")
        return _type_annotation_text(type_node) if type_node is not None else None

    def _convert_param(self, node: Node) -> hir.HirParam:
        pattern = required_field(node, "pattern")
        if pattern.type != "identifier":
            raise UnsupportedConstruct(f"ts param pattern {pattern.type}")
        type_node = node.child_by_field_name("type")
        annotation = _type_annotation_text(type_node) if type_node is not None else None
        return hir.HirParam(name=text(pattern), annotation=annotation)


_CONVERTER = _TypeScript()


def parse_typescript(source: str) -> hir.HirModule:
    return _CONVERTER.parse(source)


def _type_annotation_text(node: Node) -> str:
    if node.type == "type_annotation":
        kids = named_children(node)
        if not kids:
            raise UnsupportedConstruct("ts empty type annotation")
        return _type_text(kids[0])
    return _type_text(node)


def _type_text(node: Node) -> str:
    if node.type == "predefined_type":
        return TS_TYPE_ALIASES.get(text(node), text(node))
    if node.type == "type_identifier":
        spelling = text(node)
        return TS_TYPE_ALIASES.get(spelling, spelling)
    raise UnsupportedConstruct(f"ts type {node.type}")
