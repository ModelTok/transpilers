"""Shared pytest configuration.

``requires_sigalrm`` marks a test that depends on a POSIX SIGALRM wall-clock
guard. Both in-tree guards — ``transpilers.verify._exec_timeout.time_limit`` and
``scripts/sft/build_algorithm_pairs._time_limit`` — are explicit no-ops when
``signal.SIGALRM`` is missing. On Windows such a test does not merely fail: it
spins forever inside the very loop the guard is meant to interrupt, hanging the
whole run with no output. Marking them keeps the suite runnable everywhere.
"""

from __future__ import annotations

import signal

import pytest


def pytest_configure(config: pytest.Config) -> None:
    config.addinivalue_line(
        "markers",
        "requires_sigalrm: needs a POSIX SIGALRM wall-clock guard (a documented no-op elsewhere)",
    )


def pytest_collection_modifyitems(config: pytest.Config, items: list[pytest.Item]) -> None:  # noqa: ARG001
    if hasattr(signal, "SIGALRM"):
        return
    skip = pytest.mark.skip(reason="wall-clock guard is a no-op without SIGALRM (POSIX-only)")
    for item in items:
        if "requires_sigalrm" in item.keywords:
            item.add_marker(skip)
