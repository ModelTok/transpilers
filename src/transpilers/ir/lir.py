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


@dataclass
class RustBoolLiteral(LirNode):
    value: bool


@dataclass
class RustStringLiteral(LirNode):
    value: str


@dataclass
class RustCompare(LirNode):
    op: str
    left: LirNode
    right: LirNode


@dataclass
class RustBoolOp(LirNode):
    op: str  # "&&" or "||"
    left: LirNode
    right: LirNode


@dataclass
class RustUnary(LirNode):
    op: str  # "!" or "-"
    operand: LirNode


@dataclass
class RustIf(LirNode):
    test: LirNode
    body: list[LirNode]
    orelse: list[LirNode]


@dataclass
class RustWhile(LirNode):
    test: LirNode
    body: list[LirNode]


@dataclass
class RustForRange(LirNode):
    """Rust `for <target> in <start>..<stop>` (step=None means contiguous).
    `step` set => emit `.step_by(...)`."""

    target: str
    start: LirNode
    stop: LirNode
    step: LirNode | None
    body: list[LirNode]


@dataclass
class RustLet(LirNode):
    """`let [mut] <name>[: <ty>] = <value>;`"""

    name: str
    mutable: bool
    ty: str | None
    value: LirNode


@dataclass
class RustReassign(LirNode):
    """Plain `x = <value>;` for a previously-bound mutable variable."""

    name: str
    value: LirNode


@dataclass
class RustVec(LirNode):
    elements: list[LirNode]


@dataclass
class RustIndex(LirNode):
    value: LirNode
    index: LirNode


@dataclass
class RustMethodCall(LirNode):
    receiver: LirNode
    method: str
    args: list[LirNode]
    cast_to: str | None = None  # e.g., `.len() as i64`


@dataclass
class RustCall(LirNode):
    func: str
    args: list[LirNode]
