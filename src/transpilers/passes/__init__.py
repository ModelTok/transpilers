"""Pipeline passes between IR tiers. Each pass declares its LLM hooks explicitly."""

from .hir_to_mir import hir_to_mir
from .mir_to_rust_lir import mir_to_rust_lir

__all__ = ["hir_to_mir", "mir_to_rust_lir"]
