"""MIR — normalized typed IR. Language-agnostic.

This is where 80% of the work lives: type inference, dataflow, ownership analysis,
escape analysis, idiom recognition. Every node has a resolved type or an
UnknownT hole that some later pass (algorithmic or LLM) must fill.
"""

from __future__ import annotations

from dataclasses import dataclass, field

from .types import Type, UnknownT


class MirNode:
    pass


@dataclass
class MirModule(MirNode):
    functions: list["MirFunction"] = field(default_factory=list)


@dataclass
class MirFunction(MirNode):
    name: str
    params: list["MirParam"]
    return_type: Type
    body: list[MirNode]


@dataclass
class MirParam(MirNode):
    name: str
    ty: Type


@dataclass
class MirReturn(MirNode):
    value: MirNode | None


@dataclass
class MirBinOp(MirNode):
    op: str
    left: MirNode
    right: MirNode
    ty: Type = field(default_factory=UnknownT)


@dataclass
class MirName(MirNode):
    name: str
    ty: Type = field(default_factory=UnknownT)


@dataclass
class MirIntLiteral(MirNode):
    value: int
    ty: Type = field(default_factory=UnknownT)


@dataclass
class MirBoolLiteral(MirNode):
    value: bool
    ty: Type = field(default_factory=UnknownT)


@dataclass
class MirStringLiteral(MirNode):
    value: str
    ty: Type = field(default_factory=UnknownT)


@dataclass
class MirCompare(MirNode):
    op: str
    left: MirNode
    right: MirNode
    ty: Type = field(default_factory=UnknownT)


@dataclass
class MirBoolOp(MirNode):
    op: str
    left: MirNode
    right: MirNode
    ty: Type = field(default_factory=UnknownT)


@dataclass
class MirUnaryOp(MirNode):
    op: str
    operand: MirNode
    ty: Type = field(default_factory=UnknownT)


@dataclass
class MirIf(MirNode):
    test: MirNode
    body: list[MirNode]
    orelse: list[MirNode]


@dataclass
class MirWhile(MirNode):
    test: MirNode
    body: list[MirNode]


@dataclass
class MirForRange(MirNode):
    """Specialized for-over-range. `start`, `stop`, `step` are MIR int exprs."""

    target: str
    start: MirNode
    stop: MirNode
    step: MirNode | None
    body: list[MirNode]


@dataclass
class MirCall(MirNode):
    func: str
    args: list[MirNode]
    ty: Type = field(default_factory=UnknownT)


@dataclass
class MirAssign(MirNode):
    target: str
    value: MirNode
    ty: Type = field(default_factory=UnknownT)
    augmented_op: str | None = None
    is_declaration: bool = False  # set by mutability inference / scoping


@dataclass
class MirList(MirNode):
    elements: list[MirNode]
    ty: Type = field(default_factory=UnknownT)


@dataclass
class MirSubscript(MirNode):
    value: MirNode
    index: MirNode
    ty: Type = field(default_factory=UnknownT)
