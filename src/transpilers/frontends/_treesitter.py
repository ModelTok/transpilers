"""Shared helpers for tree-sitter-based frontends (Java, C#, TypeScript, JavaScript).

Tree-sitter exposes a uniform parse-tree shape across grammars; the frontends
differ only in their node-type names and field conventions. These helpers
keep the boilerplate (load language, parse, walk by field, text extraction)
out of each per-language parser.
"""

from __future__ import annotations

from tree_sitter import Language, Node, Parser


def make_parser(language: Language) -> Parser:
    return Parser(language)


def text(node: Node) -> str:
    return node.text.decode("utf-8")


def field(node: Node, name: str) -> Node | None:
    return node.child_by_field_name(name)


def required_field(node: Node, name: str) -> Node:
    f = node.child_by_field_name(name)
    if f is None:
        raise ValueError(f"required field {name!r} missing from {node.type}")
    return f


def named_children(node: Node) -> list[Node]:
    return list(node.named_children)
