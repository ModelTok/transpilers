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
