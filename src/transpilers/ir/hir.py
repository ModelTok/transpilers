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


@dataclass
class HirBoolLiteral(HirNode):
    value: bool


@dataclass
class HirStringLiteral(HirNode):
    value: str


@dataclass
class HirCompare(HirNode):
    op: str
    left: HirNode
    right: HirNode


@dataclass
class HirBoolOp(HirNode):
    op: str  # "and" or "or"
    left: HirNode
    right: HirNode


@dataclass
class HirUnaryOp(HirNode):
    op: str  # "not" or "-"
    operand: HirNode


@dataclass
class HirIf(HirNode):
    test: HirNode
    body: list[HirNode]
    orelse: list[HirNode]


@dataclass
class HirWhile(HirNode):
    test: HirNode
    body: list[HirNode]


@dataclass
class HirFor(HirNode):
    """Restricted to `for <name> in range(...)` for the initial subset."""

    target: str
    iter: HirNode
    body: list[HirNode]


@dataclass
class HirCall(HirNode):
    func: str
    args: list[HirNode]


@dataclass
class HirAssign(HirNode):
    target: str
    value: HirNode
    annotation: str | None
    augmented_op: str | None = None  # "+", "-", "*", "/" for `x += 1` etc.


@dataclass
class HirList(HirNode):
    elements: list[HirNode]


@dataclass
class HirSubscript(HirNode):
    value: HirNode
    index: HirNode
