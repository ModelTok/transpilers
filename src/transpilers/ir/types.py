"""Shared type lattice used across HIR/MIR/LIR.

MIR types are language-agnostic. LIR types are target-shaped (i64 vs isize,
Result vs error-union, etc.) and live next to each backend.
"""

from __future__ import annotations

from dataclasses import dataclass


class Type:
    """Marker base for the MIR type lattice."""


@dataclass(frozen=True)
class IntT(Type):
    bits: int = 64
    signed: bool = True


@dataclass(frozen=True)
class FloatT(Type):
    bits: int = 64


@dataclass(frozen=True)
class BoolT(Type):
    pass


@dataclass(frozen=True)
class StrT(Type):
    pass


@dataclass(frozen=True)
class NoneT(Type):
    pass


@dataclass(frozen=True)
class ListT(Type):
    elem: Type


@dataclass(frozen=True)
class RangeT(Type):
    """The result of Python `range(...)`. Only valid as a for-loop iterator —
    using a range outside that context is unsupported until we have a real
    iterator lowering."""


@dataclass(frozen=True)
class StructT(Type):
    """User-defined struct/class type. The name resolves to a HirStruct /
    target-specific struct emission. We don't store the field list here —
    that's looked up via the module's struct registry."""

    name: str


@dataclass(frozen=True)
class UnknownT(Type):
    """A typed hole. LLM passes are allowed to fill these; algorithmic passes must not invent."""

    hint: str | None = None
