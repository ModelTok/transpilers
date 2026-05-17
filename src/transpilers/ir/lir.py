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


# ---------------- Zig dialect ----------------
#
# A separate dialect rather than a shared "C-family LIR": Zig's `var`/`const`
# split, `while (cond) : (step)` for-equivalent, and error-union syntax differ
# enough from Rust that conflating them would force every backend pass to
# branch internally. Per-target dialects keep each emitter and lowering
# focused.


@dataclass
class ZigModule(LirNode):
    items: list["ZigFn"] = field(default_factory=list)


@dataclass
class ZigFn(LirNode):
    name: str
    params: list[tuple[str, str]]
    return_type: str
    body: list[LirNode]


@dataclass
class ZigReturn(LirNode):
    value: LirNode | None


@dataclass
class ZigBinOp(LirNode):
    op: str
    left: LirNode
    right: LirNode


@dataclass
class ZigCompare(LirNode):
    op: str
    left: LirNode
    right: LirNode


@dataclass
class ZigBoolOp(LirNode):
    op: str  # "and" / "or"
    left: LirNode
    right: LirNode


@dataclass
class ZigUnary(LirNode):
    op: str  # "!" / "-"
    operand: LirNode


@dataclass
class ZigName(LirNode):
    name: str


@dataclass
class ZigIntLiteral(LirNode):
    value: int


@dataclass
class ZigBoolLiteral(LirNode):
    value: bool


@dataclass
class ZigStringLiteral(LirNode):
    value: str


@dataclass
class ZigIf(LirNode):
    test: LirNode
    body: list[LirNode]
    orelse: list[LirNode]


@dataclass
class ZigWhile(LirNode):
    test: LirNode
    body: list[LirNode]


@dataclass
class ZigForRange(LirNode):
    """Zig `for (start..stop) |target| { ... }`. `step != 1` is unsupported by
    the `for` syntax — a stepped range lowers to a `while` with explicit
    increment instead, handled in the lowering pass."""

    target: str
    start: LirNode
    stop: LirNode
    body: list[LirNode]


@dataclass
class ZigVar(LirNode):
    """`var <name>: <ty> = <value>;` (mutable) or `const <name>: <ty> = <value>;`."""

    name: str
    mutable: bool
    ty: str | None
    value: LirNode


@dataclass
class ZigReassign(LirNode):
    name: str
    value: LirNode


@dataclass
class ZigArrayLit(LirNode):
    """`[_]T{a, b, c}` — fixed-size inferred-length array. For dynamically
    sized lists we'd need ArrayList, deferred."""

    elem_ty: str
    elements: list[LirNode]


@dataclass
class ZigIndex(LirNode):
    value: LirNode
    index: LirNode


@dataclass
class ZigMethodCall(LirNode):
    receiver: LirNode
    method: str
    args: list[LirNode]
    cast_to: str | None = None


@dataclass
class ZigCall(LirNode):
    func: str
    args: list[LirNode]
