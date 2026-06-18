"""Tests for the data flywheel (issue #51): RepairOutcome + RepairTracker.

These cover:

* verdict coercion (free-form strings -> canonical 4-value set)
* the convenience predicates (``is_pass`` / ``is_algorithmic_or_rule`` /
  ``is_frontier_only``) - the heart of the algorithmic-vs-LLM ratio
* append + re-aggregate roundtrip
* the trend bins and the frontier-only count
* graceful handling of corrupted log lines
"""

from __future__ import annotations

import json
import textwrap
from pathlib import Path

import pytest

from transpilers.repair.outcomes import (
    DEFAULT_LOG_PATH,
    DEFAULT_METRICS_PATH,
    RepairOutcome,
    RepairTracker,
    VALID_VERDICTS,
    rollup,
)


# -----------------------------------------------------------------------
# Verdict coercion
# -----------------------------------------------------------------------


def test_coerce_canonical_passthrough():
    for v in VALID_VERDICTS:
        o = RepairOutcome(source_lang="cpp", target="mojo", fingerprint="x", verdict=v)
        assert o.verdict == v


def test_coerce_freeform_synonyms():
    o = RepairOutcome(source_lang="cpp", target="mojo", fingerprint="x", verdict="PASS")
    assert o.verdict == "PASS"  # coerced lazily on .is_pass
    assert o.is_pass is True
    assert o.is_algorithmic_or_rule is True

    o.verdict = "skip"
    assert o.is_pass is False
    assert o.is_algorithmic_or_rule is False

    o.verdict = "totally-unknown"
    assert o.is_pass is False


def test_frontier_only_predicate():
    o = RepairOutcome(
        source_lang="cpp", target="mojo", fingerprint="x", verdict="llm", n_llm_calls=1
    )
    assert o.is_frontier_only is True

    # Once a rule patch helped, it isn't frontier-only anymore.
    o2 = RepairOutcome(
        source_lang="cpp",
        target="mojo",
        fingerprint="x",
        verdict="llm",
        n_llm_calls=2,
        n_rule_passes=1,
    )
    assert o2.is_frontier_only is False

    # Algorithmic / rule verdicts are by definition not frontier-only.
    o3 = RepairOutcome(
        source_lang="cpp", target="mojo", fingerprint="x", verdict="algorithmic"
    )
    assert o3.is_frontier_only is False


# -----------------------------------------------------------------------
# Serialisation roundtrip
# -----------------------------------------------------------------------


def test_to_from_json_roundtrip():
    o = RepairOutcome(
        source_lang="cpp",
        target="mojo",
        fingerprint="deadbeef",
        source_id="EnergyPlus/foo.cpp",
        construct="std::pow",
        bucket="unresolved-symbol",
        verdict="llm",
        n_llm_calls=2,
        n_rule_passes=0,
        n_repair_passes=2,
        wallclock_ms=1234,
        notes="cache-key=abc",
    )
    j = o.to_json()
    d = json.loads(j)
    assert d["source_lang"] == "cpp"
    assert d["target"] == "mojo"
    assert d["fingerprint"] == "deadbeef"
    assert d["construct"] == "std::pow"
    assert d["bucket"] == "unresolved-symbol"
    assert d["n_llm_calls"] == 2
    o2 = RepairOutcome.from_json(j)
    assert o2 == o


def test_from_json_tolerates_legacy_fields():
    legacy = json.dumps(
        {
            "source_lang": "cpp",
            "target": "rust",
            "fingerprint": "abc",
            "verdict": "algorithmic",
            "n_llm_calls": 0,
            "n_rule_passes": 0,
            "n_repair_passes": 0,
            "wallclock_ms": 0,
        }
    )
    o = RepairOutcome.from_json(legacy)
    assert o.ts == 0.0
    assert o.notes == ""


# -----------------------------------------------------------------------
# Tracker: write + aggregate
# -----------------------------------------------------------------------


def test_tracker_writes_one_json_per_line(tmp_path: Path):
    log = tmp_path / "log.jsonl"
    with RepairTracker(log_path=log, create_dirs=False) as t:
        t.record(
            RepairOutcome(
                source_lang="cpp", target="mojo", fingerprint="a", verdict="algorithmic"
            )
        )
        t.record(
            RepairOutcome(
                source_lang="cpp",
                target="mojo",
                fingerprint="b",
                verdict="llm",
                n_llm_calls=1,
            )
        )
    lines = log.read_text().splitlines()
    assert len(lines) == 2
    for line in lines:
        json.loads(line)


def test_aggregate_rolls_up_correctly(tmp_path: Path):
    log = tmp_path / "log.jsonl"
    cases = [
        RepairOutcome(
            source_lang="cpp", target="mojo", fingerprint="1", verdict="algorithmic"
        ),
        RepairOutcome(
            source_lang="cpp",
            target="mojo",
            fingerprint="2",
            verdict="rule",
            n_rule_passes=1,
        ),
        RepairOutcome(
            source_lang="cpp",
            target="mojo",
            fingerprint="3",
            verdict="llm",
            n_llm_calls=1,
        ),
        RepairOutcome(
            source_lang="cpp",
            target="mojo",
            fingerprint="4",
            verdict="llm",
            n_llm_calls=2,
        ),
        RepairOutcome(
            source_lang="cpp",
            target="mojo",
            fingerprint="5",
            verdict="unrepaired",
            n_llm_calls=3,
        ),
        RepairOutcome(
            source_lang="python", target="rust", fingerprint="6", verdict="algorithmic"
        ),
        RepairOutcome(
            source_lang="python",
            target="rust",
            fingerprint="7",
            verdict="llm",
            n_llm_calls=1,
        ),
    ]
    with RepairTracker(log_path=log, create_dirs=False) as t:
        t.record_many(cases)
        snap = t.aggregate()

    assert snap["total"] == 7
    assert snap["passed"] == 6
    assert snap["by_verdict"]["algorithmic"] == 2
    assert snap["by_verdict"]["rule"] == 1
    assert snap["by_verdict"]["llm"] == 3
    assert snap["by_verdict"]["unrepaired"] == 1
    assert snap["llm_fraction"] == pytest.approx(0.5)
    assert snap["algorithmic_fraction"] == pytest.approx(0.5)
    # LLM verdicts (cases 3, 4, 7) with n_llm_calls 1+2+1 = 4
    # (unrepaired case 5 is excluded from the LLM-call counter)
    assert snap["n_llm_calls"] == 4
    assert snap["frontier_only"] == 3

    assert snap["by_source_lang"]["cpp"]["llm"] == 2
    assert snap["by_source_lang"]["python"]["llm"] == 1
    assert snap["by_target"]["mojo"]["algorithmic"] == 1
    assert snap["by_target"]["rust"]["algorithmic"] == 1


def test_aggregate_trend_window_bucketing(tmp_path: Path):
    """The trend array bins the log into windows so the dashboard can plot.

    Layout: 75 algorithmic first, then 75 LLM. Across 50-outcome windows:
      bin 1 (first 50):  all algorithmic -> 0% LLM
      bin 2 (next 50):   25 alg + 25 LLM   -> 50% LLM
      bin 3 (last 50):   all LLM           -> 100% LLM
    """
    log = tmp_path / "log.jsonl"
    with RepairTracker(log_path=log, create_dirs=False) as t:
        for i in range(75):
            t.record(
                RepairOutcome(
                    source_lang="cpp",
                    target="mojo",
                    fingerprint=f"alg{i}",
                    verdict="algorithmic",
                )
            )
        for i in range(75):
            t.record(
                RepairOutcome(
                    source_lang="cpp",
                    target="mojo",
                    fingerprint=f"llm{i}",
                    verdict="llm",
                    n_llm_calls=1,
                )
            )
        snap = t.aggregate()
    assert len(snap["trend"]) == 3
    expected = [(50, 50, 0, 0.0), (50, 50, 25, 0.5), (50, 50, 50, 1.0)]
    for bin_, (total, passed, llm, frac) in zip(snap["trend"], expected):
        assert bin_["total"] == total
        assert bin_["passed"] == passed
        assert bin_["llm"] == llm
        assert bin_["llm_fraction"] == pytest.approx(frac)


def test_aggregate_skips_corrupted_lines(tmp_path: Path):
    log = tmp_path / "log.jsonl"
    log.write_text(
        textwrap.dedent("""\
        {"source_lang":"cpp","target":"mojo","fingerprint":"a","verdict":"algorithmic","n_llm_calls":0,"n_rule_passes":0,"n_repair_passes":0,"wallclock_ms":0,"ts":0.0,"notes":""}
        THIS IS NOT JSON
        {"source_lang":"python","target":"rust","fingerprint":"b","verdict":"llm","n_llm_calls":1,"n_rule_passes":0,"n_repair_passes":1,"wallclock_ms":0,"ts":0.0,"notes":""}
        """)
    )
    with RepairTracker(log_path=log, create_dirs=False) as t:
        snap = t.aggregate()
    assert snap["total"] == 2
    assert snap["passed"] == 2


def test_flush_metrics_writes_snapshot_file(tmp_path: Path):
    log = tmp_path / "log.jsonl"
    metrics = tmp_path / "metrics.json"
    with RepairTracker(log_path=log, metrics_path=metrics, create_dirs=False) as t:
        t.record(
            RepairOutcome(
                source_lang="cpp", target="mojo", fingerprint="a", verdict="algorithmic"
            )
        )
        snap = t.flush_metrics()
    assert metrics.exists()
    on_disk = json.loads(metrics.read_text())
    assert on_disk["total"] == 1
    assert on_disk["passed"] == 1
    assert snap["total"] == on_disk["total"]
    assert on_disk["log_path"] == str(log)


def test_rollup_convenience_is_context_manager_clean(tmp_path: Path):
    log = tmp_path / "log.jsonl"
    metrics = tmp_path / "metrics.json"
    with RepairTracker(log_path=log, metrics_path=metrics, create_dirs=False) as t:
        t.record(
            RepairOutcome(
                source_lang="cpp", target="mojo", fingerprint="a", verdict="algorithmic"
            )
        )
    snap = rollup(log_path=log, metrics_path=metrics)
    assert snap["passed"] == 1


def test_default_paths_are_under_data():
    """DEFAULT_LOG_PATH and DEFAULT_METRICS_PATH are the documented locations."""
    # Use as_posix() so the assertion holds regardless of the OS path
    # separator (Windows renders these with backslashes).
    assert DEFAULT_LOG_PATH.as_posix().startswith("data/")
    assert DEFAULT_LOG_PATH.name == "repair_outcomes.jsonl"
    assert DEFAULT_METRICS_PATH.as_posix().startswith("data/")
    assert DEFAULT_METRICS_PATH.name == "flywheel_metrics.json"
