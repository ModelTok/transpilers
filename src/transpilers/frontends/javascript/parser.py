"""JavaScript source -> HIR via tree-sitter-javascript.

JS has no static types, so every function parameter and return arrives as an
UnknownT — the type-inference pass (algorithmic dataflow + LLM fallback) is
what makes JS transpilation viable. Without inference resolving holes, the
later passes refuse rather than invent.

Subset is otherwise parallel to TypeScript: `function name(args) { ... }`,
return, if/else, while, C-style for, let/const/var, binary/comparison/logical
ops, integer literals, names, calls. The conversion itself is shared with
TypeScript (`transpilers.frontends._ecma`).
"""

from __future__ import annotations

from tree_sitter import Language
import tree_sitter_javascript

from transpilers.frontends._ecma import EcmaConverter
from transpilers.ir import hir


class _JavaScript(EcmaConverter):
    lang = "js"
    source_lang = "javascript"
    language = Language(tree_sitter_javascript.language())


_CONVERTER = _JavaScript()


def parse_javascript(source: str) -> hir.HirModule:
    return _CONVERTER.parse(source)
