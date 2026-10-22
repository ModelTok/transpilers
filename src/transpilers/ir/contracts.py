"""Semantic contracts for MIR nodes.

A *semantic contract* describes how a value or operation behaves at the
semantic level — beyond what the type lattice (IntT, FloatT, ListT, ...)
captures.  Contracts are the bridge between source-language semantics
(Python's arbitrary-precision ints, pass-by-object-reference, no explicit
ownership) and target-language requirements (Rust's fixed-width ints with
overflow-defined ops, borrow-checker, lifetime annotations).

Contracts are *optional* metadata: every node's contract starts as a
wildcard (all-None / all-default) that means "no semantic constraint
known".  The ``infer_contracts`` pass populates as much as it can from
type inference, interprocedural analysis, and—in future—LLM hints.
Backends read the contract to decide how to translate each leaf; if a
contract's constraint is incompatible with the target's guarantees, the
backend must either emit a guard or refuse (never silently wrong).
"""

from __future__ import annotations

from dataclasses import dataclass
from enum import Enum, auto


class OverflowBehavior(Enum):
    """What happens when an integer arithmetic operation overflows.

    The source language guarantees one of these.  The target language must
    match or guard.
    """

    UNSPECIFIED = auto()
    WRAP = auto()
    CHECKED = auto()
    SATURATE = auto()
    ARBITRARY = auto()


class ValueCategory(Enum):
    """Is this node a value, a reference, or an owned pointer?

    Mirrors the ownership taxonomy that languages like Rust and Mojo make
    explicit, while also covering languages where everything is a reference
    (Python, Java) or everything is a value (C int, Fortran).
    """

    UNKNOWN = auto()
    VALUE = auto()
    REF_IMMUTABLE = auto()
    REF_MUTABLE = auto()
    OWNED = auto()


class Ownership(Enum):
    """Ownership regime for a value or binding.

    Only meaningful when ``ValueCategory`` is OWNED or REF_*.
    """

    UNKNOWN = auto()
    OWNED = auto()
    BORROWED = auto()
    MUT_BORROW = auto()
    SHARED = auto()


@dataclass(frozen=True)
class SemanticContract:
    """Semantic contract attached to a MIR node.

    Every field defaults to ``None`` / ``UNSPECIFIED`` / ``UNKNOWN``,
    meaning "not yet inferred; proceed with best-effort defaults or
    refuse".  The ``infer_contracts`` pass fills as many fields as it can.

    Backends must check the contract fields that matter to them and act
    accordingly: emit target-native overflow handling, refuse unsupported
    ownership patterns, insert borrow annotations, etc.
    """

    int_width: int | None = None
    overflow: OverflowBehavior = OverflowBehavior.UNSPECIFIED

    value_category: ValueCategory = ValueCategory.UNKNOWN

    mutable: bool = False

    ownership: Ownership = Ownership.UNKNOWN
    lifetime: str | None = None

    pure: bool = False

    container_ownership: Ownership = Ownership.UNKNOWN


    @staticmethod
    def arbitrary_precision_int() -> SemanticContract:
        """Shortcut: contract for a Python-style arbitrary-precision int."""
        return SemanticContract(
            int_width=None,
            overflow=OverflowBehavior.ARBITRARY,
            value_category=ValueCategory.VALUE,
            mutable=False,
            ownership=Ownership.OWNED,
            pure=True,
        )

    @staticmethod
    def default_local_binding() -> SemanticContract:
        """Shortcut: contract for a local variable binding."""
        return SemanticContract(
            value_category=ValueCategory.VALUE,
            mutable=False,
            ownership=Ownership.OWNED,
            pure=True,
        )

    @staticmethod
    def python_ref() -> SemanticContract:
        """Shortcut: contract for a Python-style reference (shared, GC)."""
        return SemanticContract(
            value_category=ValueCategory.REF_IMMUTABLE,
            mutable=True,
            ownership=Ownership.SHARED,
        )

    def merge(self, other: SemanticContract) -> SemanticContract:
        """Merge two contracts (source + inferred), preferring the more specific.

        Used during interprocedural analysis.
        """
        return SemanticContract(
            int_width=_merge_first(self.int_width, other.int_width),
            overflow=_merge_first(
                self.overflow, other.overflow, skip=OverflowBehavior.UNSPECIFIED
            ),
            value_category=_merge_first(
                self.value_category, other.value_category, skip=ValueCategory.UNKNOWN
            ),
            mutable=self.mutable or other.mutable,
            ownership=_merge_first(
                self.ownership, other.ownership, skip=Ownership.UNKNOWN
            ),
            lifetime=_merge_first(self.lifetime, other.lifetime),
            pure=self.pure and other.pure,
            container_ownership=_merge_first(
                self.container_ownership,
                other.container_ownership,
                skip=Ownership.UNKNOWN,
            ),
        )

    def is_compatible_with(self, target: SemanticContract) -> bool:
        """Check if *self* (source contract) is compatible with *target*.

        Returns ``True`` when the target can safely represent the source
        semantics, ``False`` when a silent miscompilation would occur.
        """
        if self.int_width is not None and target.int_width is not None:
            if self.int_width > target.int_width:
                return False
        if self.overflow is OverflowBehavior.ARBITRARY:
            if target.int_width is not None:
                return False
        if (
            self.overflow is OverflowBehavior.WRAP
            and target.overflow is OverflowBehavior.CHECKED
        ):
            return False
        if self.ownership is Ownership.SHARED and target.ownership is Ownership.OWNED:
            return False
        if self.ownership is Ownership.OWNED and target.ownership is Ownership.BORROWED:
            return False
        return True


def _merge_first(a, b, skip=None):
    """Return the first non-skip value, preferring ``a`` over ``b``."""
    if a is not None and (skip is None or a != skip):
        return a
    if b is not None and (skip is None or b != skip):
        return b
    return a


WILDCARD = SemanticContract()


__all__ = [
    "OverflowBehavior",
    "ValueCategory",
    "Ownership",
    "SemanticContract",
    "WILDCARD",
]
