"""Tests for the flywheel_metrics report (issue #51).

These cover the text + markdown rendering of the algorithmic-vs-LLM ratio
plus the trend arrow. We seed a synthetic repair-outcomes log and assert
the report contains the expected numbers.
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path


REPO = Path(__file__).resolve().parents[1]
SCRIPTS_SFT = REPO / "scripts" / "sft"
sys.path.insert(0, str(REPO / "src"))
sys.path.insert(0, str(SCRIPTS_SFT))

from transpilers.repair.outcomes import RepairOutcome, RepairTracker  # noqa: E402
import flywheel_metrics as fm  # noqa: E402


def _seed_log(
    log: Path, n_alg: int, n_llm: int, n_rule: int = 0, n_unrepaired: int = 0
) -> None:
    """Write a synthetic mix of outcomes to *log*."""
    i = 0
    with RepairTracker(log_path=log, create_dirs=False) as t:
        for _ in range(n_alg):
            t.record(
                RepairOutcome(
                    source_lang="cpp",
                    target="mojo",
                    fingerprint=f"alg{i}",
                    verdict="algorithmic",
                )
            )
            i += 1
        for _ in range(n_llm):
            t.record(
                RepairOutcome(
                    source_lang="cpp",
                    target="mojo",
                    fingerprint=f"llm{i}",
                    verdict="llm",
                    n_llm_calls=1,
                )
            )
            i += 1
        for _ in range(n_rule):
            t.record(
                RepairOutcome(
                    source_lang="python",
                    target="rust",
                    fingerprint=f"rle{i}",
                    verdict="rule",
                    n_rule_passes=1,
                )
            )
            i += 1
        for _ in range(n_unrepaired):
            t.record(
                RepairOutcome(
                    source_lang="python",
                    target="rust",
                    fingerprint=f"unr{i}",
                    verdict="unrepaired",
                    n_llm_calls=2,
                )
            )
            i += 1


# ---------------------------------------------------------------------------
# Text rendering
# ---------------------------------------------------------------------------


def test_text_report_handles_empty_log():
    snap = {
        "total": 0,
        "passed": 0,
        "by_verdict": {},
        "llm_fraction": 0.0,
        "algorithmic_fraction": 0.0,
        "by_source_lang": {},
        "by_target": {},
        "frontier_only": 0,
        "n_llm_calls": 0,
        "trend": [],
    }
    out = fm.render_text(snap)
    assert "no outcomes yet" in out


def test_text_report_summarises_a_balanced_mix(tmp_path: Path):
    log = tmp_path / "log.jsonl"
    _seed_log(log, n_alg=10, n_llm=5, n_rule=3, n_unrepaired=2)
    snap = fm.rollup(log_path=log)
    out = fm.render_text(snap)
    assert "Total outcomes" in out
    assert "algorithmic" in out
    assert "By verdict:" in out
    assert "Total outcomes       : 20" in out
    assert "Passed               : 18" in out


def test_text_report_marks_improving_trend(tmp_path: Path):
    log = tmp_path / "log.jsonl"
    _seed_log(log, n_alg=30, n_llm=20)
    with RepairTracker(log_path=log, create_dirs=False) as t:
        for i in range(100, 140):
            t.record(
                RepairOutcome(
                    source_lang="cpp",
                    target="mojo",
                    fingerprint=f"alg2_{i}",
                    verdict="algorithmic",
                )
            )
        for i in range(100, 110):
            t.record(
                RepairOutcome(
                    source_lang="cpp",
                    target="mojo",
                    fingerprint=f"llm2_{i}",
                    verdict="llm",
                    n_llm_calls=1,
                )
            )
    snap = fm.rollup(log_path=log)
    out = fm.render_text(snap)
    assert "[good]" in out
    assert "delta=" in out


def test_text_report_marks_worsening_trend(tmp_path: Path):
    log = tmp_path / "log.jsonl"
    _seed_log(log, n_alg=40, n_llm=10)
    with RepairTracker(log_path=log, create_dirs=False) as t:
        for i in range(200, 230):
            t.record(
                RepairOutcome(
                    source_lang="cpp",
                    target="mojo",
                    fingerprint=f"alg2_{i}",
                    verdict="algorithmic",
                )
            )
        for i in range(200, 220):
            t.record(
                RepairOutcome(
                    source_lang="cpp",
                    target="mojo",
                    fingerprint=f"llm2_{i}",
                    verdict="llm",
                    n_llm_calls=1,
                )
            )
    snap = fm.rollup(log_path=log)
    out = fm.render_text(snap)
    assert "[warn]" in out


# ---------------------------------------------------------------------------
# Markdown rendering
# ---------------------------------------------------------------------------


def test_markdown_renders_a_table(tmp_path: Path):
    log = tmp_path / "log.jsonl"
    _seed_log(log, n_alg=10, n_llm=5, n_rule=3, n_unrepaired=2)
    snap = fm.rollup(log_path=log)
    md = fm.render_markdown(snap)
    assert "# Data Flywheel metrics" in md
    assert "**Total outcomes**" in md
    assert "| target | pass | llm_fraction | frontier_only |" in md
    assert "| mojo |" in md
    assert "| rust |" in md


def test_markdown_handles_empty():
    snap = {
        "total": 0,
        "passed": 0,
        "by_verdict": {},
        "llm_fraction": 0.0,
        "algorithmic_fraction": 0.0,
        "by_source_lang": {},
        "by_target": {},
        "frontier_only": 0,
        "n_llm_calls": 0,
        "trend": [],
    }
    md = fm.render_markdown(snap)
    assert "No repair outcomes recorded yet" in md


# ---------------------------------------------------------------------------
# CLI smoke
# ---------------------------------------------------------------------------


def test_cli_refreshes_metrics_file(tmp_path: Path):
    log = tmp_path / "log.jsonl"
    metrics = tmp_path / "metrics.json"
    md = tmp_path / "out.md"
    _seed_log(log, n_alg=10, n_llm=5)

    rc = subprocess.run(
        [
            sys.executable,
            str(SCRIPTS_SFT / "flywheel_metrics.py"),
            "--log",
            str(log),
            "--metrics",
            str(metrics),
            "--md",
            str(md),
            "--quiet",
        ],
        capture_output=True,
        text=True,
    )
    assert rc.returncode == 0, rc.stderr
    assert metrics.exists()
    assert md.exists()
    on_disk = json.loads(metrics.read_text())
    assert on_disk["total"] == 15
    assert on_disk["passed"] == 15


def test_cli_trend_only_prints_bins(tmp_path: Path):
    log = tmp_path / "log.jsonl"
    metrics = tmp_path / "metrics.json"
    _seed_log(log, n_alg=70, n_llm=30)
    rc = subprocess.run(
        [
            sys.executable,
            str(SCRIPTS_SFT / "flywheel_metrics.py"),
            "--log",
            str(log),
            "--metrics",
            str(metrics),
            "--trend-only",
        ],
        capture_output=True,
        text=True,
    )
    assert rc.returncode == 0, rc.stderr
    out = rc.stdout
    assert "bin" in out
    assert "llm_frac" in out
