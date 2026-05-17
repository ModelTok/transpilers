"""LIR — target-shaped IR.

Each backend defines its own LIR dialect. Rust LIR has explicit lifetimes and
Result-based error handling; Zig LIR has error unions; C LIR is flat; Mojo LIR
distinguishes var/let/fn. Keeping these separate prevents the MIR from
absorbing target-specific concerns.

For the initial Python -> Rust slice, only the Rust dialect is populated.
"""

from __future__ import annotations

from dataclasses import dataclass, field


class LirNode:
    pass


@dataclass
class RustModule(LirNode):
    items: list["RustFn"] = field(default_factory=list)


@dataclass
class RustFn(LirNode):
    name: str
    params: list[tuple[str, str]]  # (name, rust_type)
    return_type: str
    body: list[LirNode]


@dataclass
class RustReturn(LirNode):
    value: LirNode | None


@dataclass
class RustBinOp(LirNode):
    op: str
    left: LirNode
    right: LirNode


@dataclass
class RustName(LirNode):
    name: str


@dataclass
class RustIntLiteral(LirNode):
    value: int
    suffix: str = "i64"
