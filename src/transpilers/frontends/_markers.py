"""Shared parser-private markers for frontends.

Frontends that desugar one source construct into a sequence of HIR
statements (Python `with` / `pass` / tuple-unpacking, Go tuple-swap)
emit one of these markers; the block converter recognises them and
inlines the constituent statements so downstream passes never see
the wrapper.

Keeping a single shared class set prevents drift between frontends
(see issue #8).
"""

from __future__ import annotations

from transpilers.ir import hir


class FlattenBlock(hir.HirNode):
    """Carries `stmts` to be inlined into the enclosing block. Frontends
    use this for any 1-statement-to-N-statements desugar."""

    def __init__(self, stmts: list[hir.HirNode]) -> None:
        self.stmts = stmts


class PassMarker(hir.HirNode):
    """`pass` statement — filtered out during block conversion."""
