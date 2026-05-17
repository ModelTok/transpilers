"""HIR — source-faithful tree. One per source language.

HIR preserves language idioms (Python comprehensions, Fortran DO, C++ templates)
so a frontend can be lossless within its own language. Normalization happens at
HIR -> MIR, not in the frontend.
"""

from __future__ import annotations

from dataclasses import dataclass, field


class HirNode:
    pass


@dataclass
class HirModule(HirNode):
    source_lang: str
    body: list[HirNode] = field(default_factory=list)


@dataclass
class HirFunction(HirNode):
    name: str
    params: list["HirParam"]
    return_annotation: str | None
    body: list[HirNode]


@dataclass
class HirParam(HirNode):
    name: str
    annotation: str | None


@dataclass
class HirReturn(HirNode):
    value: HirNode | None


@dataclass
class HirBinOp(HirNode):
    op: str
    left: HirNode
    right: HirNode


@dataclass
class HirName(HirNode):
    name: str


@dataclass
class HirIntLiteral(HirNode):
    value: int
