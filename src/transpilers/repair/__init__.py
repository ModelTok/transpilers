"""Iterative compile-and-repair loop for transpiled code.

Two repair surfaces live here:

* :mod:`transpilers.repair.repair` — the legacy one-shot repair loop
  (preserved for API backward compatibility; the FastAPI ``/transpile/repair``
  endpoint wraps it).
* :mod:`transpilers.repair.loop` — the new verification-driven repair
  loop with escalating model tiers (issue #47). The CLI
  ``--escalating-repair`` flag and the FastAPI
  ``/transpile/escalating-repair`` endpoint wrap it.

The signal helper (:mod:`transpilers.repair.signal`) and the flywheel
recorder (:mod:`transpilers.repair.flywheel`) are shared between both.

Issue #51 also adds :mod:`transpilers.repair.outcomes` (the
``RepairOutcome`` / ``RepairTracker`` pair + the algorithmic-vs-LLM
ratio aggregator) and the scripts that pipe those into ``stdlib_maps/``
and the SFT corpus; see ``scripts/sft/promote_repair.py`` and
``docs/data_flywheel.md``.
"""

from .flywheel import Flywheel, FlywheelRecord, merge_dedup, read_flywheel
from .loop import (
    EscalatingRepairAttempt,
    EscalatingRepairResult,
    VerificationOutcome,
    Verifier,
    escalating_repair,
)
from .outcomes import (
    DEFAULT_LOG_PATH,
    DEFAULT_METRICS_PATH,
    RepairOutcome,
    RepairTracker,
    VALID_VERDICTS,
    rollup,
)
from .repair import RepairPass, RepairResult, repair
from .signal import (
    RepairSignal,
    signal_from_compile,
    signal_from_hole,
    signal_from_internal,
    signal_from_run,
    signal_from_structural,
)

__all__ = [
    # legacy
    "repair",
    "RepairResult",
    "RepairPass",
    # new (issue #47)
    "escalating_repair",
    "EscalatingRepairResult",
    "EscalatingRepairAttempt",
    "VerificationOutcome",
    "Verifier",
    # shared
    "RepairSignal",
    "signal_from_compile",
    "signal_from_hole",
    "signal_from_internal",
    "signal_from_run",
    "signal_from_structural",
    "Flywheel",
    "FlywheelRecord",
    "read_flywheel",
    "merge_dedup",
    # data flywheel (issue #51)
    "RepairOutcome",
    "RepairTracker",
    "rollup",
    "VALID_VERDICTS",
    "DEFAULT_LOG_PATH",
    "DEFAULT_METRICS_PATH",
]
