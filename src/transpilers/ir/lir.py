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
    items: list[LirNode] = field(default_factory=list)
    # `items` holds RustFn / RustStruct / RustImpl in source order.


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
    # Suffix is optional now — emitter elides it when the surrounding context
    # makes the type unambiguous (a typed `let mut x: i64 = 1;`, a binop
    # with a typed operand, an arg to a typed fn, etc.). Lowering sets this
    # when it can't prove the suffix is redundant.
    suffix: str | None = None


@dataclass
class RustFloatLiteral(LirNode):
    value: float
    suffix: str | None = None


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


@dataclass
class RustStruct(LirNode):
    name: str
    fields: list[tuple[str, str]]   # (field_name, rust_type)


@dataclass
class RustImpl(LirNode):
    struct_name: str
    methods: list["RustFn"]


@dataclass
class RustFieldAccess(LirNode):
    value: LirNode
    field: str


@dataclass
class RustFieldAssign(LirNode):
    obj: LirNode
    field: str
    value: LirNode


@dataclass
class RustStructInit(LirNode):
    """`Point { x: 0, y: 0 }`."""

    name: str
    field_values: list[tuple[str, LirNode]]


@dataclass
class ZigFieldAssign(LirNode):
    obj: LirNode
    field: str
    value: LirNode


@dataclass
class ZigStructInit(LirNode):
    """`Point{ .x = 0, .y = 0 }`."""

    name: str
    field_values: list[tuple[str, LirNode]]


@dataclass
class CFieldAssign(LirNode):
    obj: LirNode
    field: str
    value: LirNode
    via_pointer: bool = False  # `.` for value, `->` for pointer


@dataclass
class CStructInit(LirNode):
    """`(Point){ .x = 0, .y = 0 }` — compound literal."""

    name: str
    field_values: list[tuple[str, LirNode]]


@dataclass
class GoFieldAssign(LirNode):
    obj: LirNode
    field: str
    value: LirNode


@dataclass
class GoStructInit(LirNode):
    """`Point{x: 0, y: 0}`."""

    name: str
    field_values: list[tuple[str, LirNode]]


@dataclass
class MojoFieldAssign(LirNode):
    obj: LirNode
    field: str
    value: LirNode


@dataclass
class MojoStructInit(LirNode):
    """`Point(0, 0)` — positional via @fieldwise_init."""

    name: str
    field_values: list[tuple[str, LirNode]]


@dataclass
class PyFieldAssign(LirNode):
    obj: LirNode
    field: str
    value: LirNode


@dataclass
class PyStructInit(LirNode):
    """`Point(0, 0)` — positional. Requires the class to be a @dataclass or
    expose a fieldwise __init__; we emit the call form regardless and let
    target verification surface the issue."""

    name: str
    field_values: list[tuple[str, LirNode]]


@dataclass
class FortranFieldAssign(LirNode):
    obj: LirNode
    field: str
    value: LirNode


@dataclass
class FortranStructInit(LirNode):
    """`Point(0, 0)` — Fortran derived-type structure constructor."""

    name: str
    field_values: list[tuple[str, LirNode]]


# ---------- subscript-assignment statements (`xs[i] = v`) ----------
# One node per target so each emitter renders the language-specific form.

@dataclass
class RustSubscriptAssign(LirNode):
    obj: LirNode
    index: LirNode
    value: LirNode


@dataclass
class ZigSubscriptAssign(LirNode):
    obj: LirNode
    index: LirNode
    value: LirNode


@dataclass
class CSubscriptAssign(LirNode):
    obj: LirNode
    index: LirNode
    value: LirNode


@dataclass
class GoSubscriptAssign(LirNode):
    obj: LirNode
    index: LirNode
    value: LirNode


@dataclass
class MojoSubscriptAssign(LirNode):
    obj: LirNode
    index: LirNode
    value: LirNode


@dataclass
class PySubscriptAssign(LirNode):
    obj: LirNode
    index: LirNode
    value: LirNode


@dataclass
class FortranSubscriptAssign(LirNode):
    """Fortran arrays are 1-indexed — the emitter adds the +1 offset."""

    obj: LirNode
    index: LirNode
    value: LirNode


@dataclass
class RustFormat(LirNode):
    """`format!("{}{}...", arg1, arg2, ...)` — produced when MIR binop `+` has
    two StrT operands. format! accepts both String and &str via Display, so
    it's the safest emission for string concat regardless of operand
    ownership."""

    args: list[LirNode]


@dataclass
class RustMacro(LirNode):
    """Rust macro-call emission: `name!(<rendered args>)`. Used for
    builtins that map to macros (`println!`, `print!`, `format!`,
    `vec!`, ...). The args are rendered as-is between the parens."""

    name: str       # without the trailing `!`
    template: str   # format spec, e.g. "{} {}" — empty when no template
    args: list[LirNode]


@dataclass
class RustMethodChain(LirNode):
    """`receiver.method(args)` shorthand for stdlib-builtin lowering.
    Different from RustMethodCall (which carries a `cast_to` for length-
    style emission) — this is a plain method call, no cast."""

    receiver: LirNode
    method: str
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
    items: list[LirNode] = field(default_factory=list)


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
class ZigFloatLiteral(LirNode):
    value: float


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


@dataclass
class ZigStruct(LirNode):
    name: str
    fields: list[tuple[str, str]]
    methods: list["ZigFn"]


@dataclass
class ZigFieldAccess(LirNode):
    value: LirNode
    field: str


# ---------------- C dialect ----------------
#
# C and Rust LIR look superficially similar but differ in real ways:
# declarations are type-prefixed rather than `let`-keyword, there's no
# `mut`/`const` split (everything's mutable), there's no `format!`, and
# strings need an allocator for concat. Keeping a separate dialect avoids
# polluting Rust emission with C-shaped concerns.


@dataclass
class CModule(LirNode):
    items: list[LirNode] = field(default_factory=list)


@dataclass
class CFn(LirNode):
    name: str
    params: list[tuple[str, str]]
    return_type: str
    body: list[LirNode]


@dataclass
class CReturn(LirNode):
    value: LirNode | None


@dataclass
class CBinOp(LirNode):
    op: str
    left: LirNode
    right: LirNode


@dataclass
class CCompare(LirNode):
    op: str
    left: LirNode
    right: LirNode


@dataclass
class CBoolOp(LirNode):
    op: str  # "&&" / "||"
    left: LirNode
    right: LirNode


@dataclass
class CUnary(LirNode):
    op: str
    operand: LirNode


@dataclass
class CName(LirNode):
    name: str


@dataclass
class CIntLiteral(LirNode):
    value: int


@dataclass
class CFloatLiteral(LirNode):
    value: float


@dataclass
class CBoolLiteral(LirNode):
    value: bool


@dataclass
class CStringLiteral(LirNode):
    value: str


@dataclass
class CIf(LirNode):
    test: LirNode
    body: list[LirNode]
    orelse: list[LirNode]


@dataclass
class CWhile(LirNode):
    test: LirNode
    body: list[LirNode]


@dataclass
class CForRange(LirNode):
    """C-style `for (int64_t i = start; i < stop; i++)`. step != 1 emits the
    explicit step expression."""

    target: str
    start: LirNode
    stop: LirNode
    step: LirNode | None
    body: list[LirNode]


@dataclass
class CDecl(LirNode):
    """`<ty> <name> = <value>;` — single-line declaration with initializer."""

    name: str
    ty: str
    value: LirNode


@dataclass
class CReassign(LirNode):
    name: str
    value: LirNode


@dataclass
class CIndex(LirNode):
    value: LirNode
    index: LirNode


@dataclass
class CCall(LirNode):
    func: str
    args: list[LirNode]


@dataclass
class CTernary(LirNode):
    """`<test> ? <then_> : <else_>` — C ternary expression."""

    test: LirNode
    then_: LirNode
    else_: LirNode


@dataclass
class CStruct(LirNode):
    """`typedef struct { ... } Name;` — methods emitted as separate
    free functions named `Name_method` with a `Name *self` first param."""

    name: str
    fields: list[tuple[str, str]]
    methods: list["CFn"]


@dataclass
class CFieldAccess(LirNode):
    """`self->field` (pointer access — C methods take Self*) vs `value.field`
    on a struct value. We always emit via pointer for method bodies, which is
    what our current lowering produces."""

    value: LirNode
    field: str
    via_pointer: bool = True


# ---------------- Mojo dialect ----------------
#
# Mojo is Python-indented, brace-free, and uses `def` (no `fn` keyword in
# current syntax) with explicit types. Only `var` for bindings — `let` was
# removed. Types are `Int`, `Float64`, `Bool`, `String`, `List[T]`. Closer
# to Python LIR shape than to Rust/Zig/C, so its emission story is the
# inverse: indentation matters, brackets don't.


@dataclass
class MojoStruct(LirNode):
    name: str
    fields: list[tuple[str, str]]
    methods: list["MojoFn"]


@dataclass
class MojoFieldAccess(LirNode):
    value: LirNode
    field: str


@dataclass
class MojoModule(LirNode):
    items: list[LirNode] = field(default_factory=list)


@dataclass
class MojoFn(LirNode):
    name: str
    params: list[tuple[str, str]]
    return_type: str
    body: list[LirNode]


@dataclass
class MojoReturn(LirNode):
    value: LirNode | None


@dataclass
class MojoBinOp(LirNode):
    op: str
    left: LirNode
    right: LirNode


@dataclass
class MojoCompare(LirNode):
    op: str
    left: LirNode
    right: LirNode


@dataclass
class MojoBoolOp(LirNode):
    op: str  # "and" / "or"
    left: LirNode
    right: LirNode


@dataclass
class MojoUnary(LirNode):
    op: str  # "not" / "-"
    operand: LirNode


@dataclass
class MojoName(LirNode):
    name: str


@dataclass
class MojoIntLiteral(LirNode):
    value: int


@dataclass
class MojoFloatLiteral(LirNode):
    value: float


@dataclass
class MojoBoolLiteral(LirNode):
    value: bool


@dataclass
class MojoStringLiteral(LirNode):
    value: str


@dataclass
class MojoIf(LirNode):
    test: LirNode
    body: list[LirNode]
    orelse: list[LirNode]


@dataclass
class MojoWhile(LirNode):
    test: LirNode
    body: list[LirNode]


@dataclass
class MojoForRange(LirNode):
    """`for <target> in range(<start>, <stop>[, <step>]):` — Python-style."""

    target: str
    start: LirNode
    stop: LirNode
    step: LirNode | None
    body: list[LirNode]


@dataclass
class MojoVar(LirNode):
    """`var <name>: <ty> = <value>` — Mojo has no `let`, only `var`."""

    name: str
    ty: str | None
    value: LirNode


@dataclass
class MojoReassign(LirNode):
    name: str
    value: LirNode


@dataclass
class MojoList(LirNode):
    """`[a, b, c]` — bracket literal, types inferred."""

    elements: list[LirNode]


@dataclass
class MojoIndex(LirNode):
    value: LirNode
    index: LirNode


@dataclass
class MojoCall(LirNode):
    func: str
    args: list[LirNode]


@dataclass
class MojoMethodCall(LirNode):
    """Property-style `.len` (no parens) for slice length; other zero-arg
    methods can reuse this."""

    receiver: LirNode
    method: str
    args: list[LirNode]
    paren: bool = True


# ---------------- Go dialect ----------------
#
# Go is brace-based, statically typed, with `var name type = value` and
# `name := value` short-declarations. No `mut`/`const`; everything's mutable.
# Native `for init; cond; update {}` matches our MIR for-range nicely.


@dataclass
class GoModule(LirNode):
    items: list[LirNode] = field(default_factory=list)


@dataclass
class GoFn(LirNode):
    name: str
    params: list[tuple[str, str]]
    return_type: str
    body: list[LirNode]


@dataclass
class GoReturn(LirNode):
    value: LirNode | None


@dataclass
class GoBinOp(LirNode):
    op: str
    left: LirNode
    right: LirNode


@dataclass
class GoCompare(LirNode):
    op: str
    left: LirNode
    right: LirNode


@dataclass
class GoBoolOp(LirNode):
    op: str  # "&&" / "||"
    left: LirNode
    right: LirNode


@dataclass
class GoUnary(LirNode):
    op: str
    operand: LirNode


@dataclass
class GoName(LirNode):
    name: str


@dataclass
class GoIntLiteral(LirNode):
    value: int


@dataclass
class GoFloatLiteral(LirNode):
    value: float


@dataclass
class GoBoolLiteral(LirNode):
    value: bool


@dataclass
class GoStringLiteral(LirNode):
    value: str


@dataclass
class GoIf(LirNode):
    test: LirNode
    body: list[LirNode]
    orelse: list[LirNode]


@dataclass
class GoWhile(LirNode):
    """Go has no `while` — emit as `for cond { ... }`."""

    test: LirNode
    body: list[LirNode]


@dataclass
class GoForRange(LirNode):
    target: str
    start: LirNode
    stop: LirNode
    step: LirNode | None
    body: list[LirNode]


@dataclass
class GoDecl(LirNode):
    """`var <name> <ty> = <value>`."""

    name: str
    ty: str
    value: LirNode


@dataclass
class GoReassign(LirNode):
    name: str
    value: LirNode


@dataclass
class GoCall(LirNode):
    func: str
    args: list[LirNode]


@dataclass
class GoStruct(LirNode):
    name: str
    fields: list[tuple[str, str]]
    methods: list["GoFn"]


@dataclass
class GoFieldAccess(LirNode):
    value: LirNode
    field: str


# ---------------- Python dialect ----------------
#
# Python is Mojo-like in surface syntax (indented, `def`, no braces) but uses
# `def` without explicit-typing required and reads `int`/`float`/`bool`/`str`
# for type hints. Closest to Mojo of the supported targets, but distinct
# enough that conflating them is a footgun.


@dataclass
class PyModule(LirNode):
    items: list[LirNode] = field(default_factory=list)


@dataclass
class PyFn(LirNode):
    name: str
    params: list[tuple[str, str]]
    return_type: str
    body: list[LirNode]


@dataclass
class PyReturn(LirNode):
    value: LirNode | None


@dataclass
class PyBinOp(LirNode):
    op: str
    left: LirNode
    right: LirNode


@dataclass
class PyCompare(LirNode):
    op: str
    left: LirNode
    right: LirNode


@dataclass
class PyBoolOp(LirNode):
    op: str  # "and" / "or"
    left: LirNode
    right: LirNode


@dataclass
class PyUnary(LirNode):
    op: str  # "not" / "-"
    operand: LirNode


@dataclass
class PyName(LirNode):
    name: str


@dataclass
class PyIntLiteral(LirNode):
    value: int


@dataclass
class PyFloatLiteral(LirNode):
    value: float


@dataclass
class PyBoolLiteral(LirNode):
    value: bool


@dataclass
class PyStringLiteral(LirNode):
    value: str


@dataclass
class PyIf(LirNode):
    test: LirNode
    body: list[LirNode]
    orelse: list[LirNode]


@dataclass
class PyWhile(LirNode):
    test: LirNode
    body: list[LirNode]


@dataclass
class PyForRange(LirNode):
    target: str
    start: LirNode
    stop: LirNode
    step: LirNode | None
    body: list[LirNode]


@dataclass
class PyAssign(LirNode):
    """Python doesn't distinguish declaration from reassignment; first use
    counts. We still carry the type annotation when known."""

    name: str
    ty: str | None
    value: LirNode


@dataclass
class PyCall(LirNode):
    func: str
    args: list[LirNode]


@dataclass
class PyClass(LirNode):
    name: str
    fields: list[tuple[str, str | None]]   # (name, optional type annotation)
    methods: list["PyFn"]


@dataclass
class PyFieldAccess(LirNode):
    value: LirNode
    field: str


# ---------------- Fortran dialect ----------------
#
# Fortran's emission shape is genuinely different from the C-family dialects:
#   - Declarations must come before statements (no inline `let` / `var`).
#   - `function NAME(args) result(r)` returns via assignment to `r`.
#   - No braces — `end if`, `end do`, `end function` close blocks.
#   - Operators: `==/!=` work in F95+, but `.and./.or./.not.` are word ops.
#   - For loops: `do i = start, stop` is inclusive both ends.
#
# We carry locals separately from body so the emitter can render the
# declarations block at function entry.


@dataclass
class FortranModule(LirNode):
    items: list[LirNode] = field(default_factory=list)


@dataclass
class FortranFn(LirNode):
    name: str
    params: list[tuple[str, str]]      # (name, fortran_type)
    return_type: str | None             # None for subroutines / void
    result_name: str                     # name of the result variable to assign
    locals: list[tuple[str, str]]      # extra declarations beyond params + result
    body: list[LirNode]


@dataclass
class FortranAssign(LirNode):
    """Plain assignment — no declaration form. Declarations live on FortranFn."""

    name: str
    value: LirNode


@dataclass
class FortranReturn(LirNode):
    """Bare `return` — for early exit. The result variable carries the value."""


@dataclass
class FortranBinOp(LirNode):
    op: str
    left: LirNode
    right: LirNode


@dataclass
class FortranCompare(LirNode):
    op: str
    left: LirNode
    right: LirNode


@dataclass
class FortranBoolOp(LirNode):
    op: str  # ".and." / ".or."
    left: LirNode
    right: LirNode


@dataclass
class FortranUnary(LirNode):
    op: str  # ".not." / "-"
    operand: LirNode


@dataclass
class FortranName(LirNode):
    name: str


@dataclass
class FortranIntLiteral(LirNode):
    value: int


@dataclass
class FortranFloatLiteral(LirNode):
    value: float


@dataclass
class FortranBoolLiteral(LirNode):
    value: bool


@dataclass
class FortranStringLiteral(LirNode):
    value: str


@dataclass
class FortranIf(LirNode):
    test: LirNode
    body: list[LirNode]
    orelse: list[LirNode]


@dataclass
class FortranWhile(LirNode):
    test: LirNode
    body: list[LirNode]


@dataclass
class FortranForRange(LirNode):
    """`do <target> = <start>, <stop - 1>[, <step>]` — exclusive stop, since
    we lower from MIR's exclusive-stop range semantics. The emitter subtracts
    one literally if both are literal ints; otherwise it emits `stop - 1`."""

    target: str
    start: LirNode
    stop: LirNode
    step: LirNode | None
    body: list[LirNode]


@dataclass
class FortranCall(LirNode):
    func: str
    args: list[LirNode]


@dataclass
class FortranType(LirNode):
    """`type :: Name ... end type Name` — Fortran user-defined type. Methods
    aren't bound here (Fortran modules / type-bound procedures need more
    plumbing than the initial slice carries); they emit as free functions
    that take a `type(Name)` first parameter."""

    name: str
    fields: list[tuple[str, str]]
    methods: list["FortranFn"]


@dataclass
class FortranFieldAccess(LirNode):
    """`obj%field` — Fortran uses `%` for field access, not `.`."""

    value: LirNode
    field: str


@dataclass
class FortranArrayLit(LirNode):
    """`[1, 2, 3]` — Fortran 2003 array constructor."""

    elements: list[LirNode]


@dataclass
class FortranSubscript(LirNode):
    """`xs(i + 1)` — Fortran is 1-indexed; emitter adds the +1 offset."""

    value: LirNode
    index: LirNode
