"""Tests for the flywheel orchestrator (issue #51).

These exercise ``flywheel_run.run_once`` in --skip-crawl mode against a
synthetic repair-outcomes log, so we can verify the closed loop end-to-end
without invoking GitHub.
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
import flywheel_run as fr  # noqa: E402


def _seed_log(
    log: Path,
    *,
    n_alg: int = 0,
    n_llm: int = 0,
    frontier_construct: str = "std::pow",
    frontier_notes: str = "math.pow",
) -> int:
    """Seed *log* with a deterministic mix of outcomes. Returns total count."""
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
                    construct=frontier_construct,
                    notes=frontier_notes,
                )
            )
            i += 1
    return i


# ---------------------------------------------------------------------------
# End-to-end with --skip-crawl
# ---------------------------------------------------------------------------


def test_run_once_skip_crawl_invokes_promote_and_metrics(tmp_path: Path, monkeypatch):
    log = tmp_path / "log.jsonl"
    stdlib = tmp_path / "stdlib.yaml"
    sft = tmp_path / "sft.jsonl"
    plog = tmp_path / "promotions.jsonl"
    metrics = tmp_path / "metrics.json"
    md = tmp_path / "metrics.md"
    stdlib.write_text('cpp_to_mojo:\n  "std::vector": ["List[T]"]\n')

    n = _seed_log(log, n_alg=2, n_llm=1)

    # Pretend the GITHUB_TOKEN is set so the warning doesn't fire
    monkeypatch.setenv("GITHUB_TOKEN", "dummy")

    summary = fr.run_once(
        source="cpp",
        targets=["mojo"],
        limit_repos=1,
        limit_fns=10,
        use_llm=False,
        no_behavioral=True,
        min_stars=10,
        crawl_out=tmp_path / "crawl.jsonl",
        log=log,
        stdlib=stdlib,
        sft=sft,
        plog=plog,
        metrics=metrics,
        md=md,
        since_ts=None,
        skip_crawl=True,
    )
    assert summary["crawled"] == 0
    assert summary["promoted_returncode"] == 0
    assert summary["metrics_returncode"] == 0
    assert "math.pow" in stdlib.read_text()
    plines = plog.read_text().splitlines()
    assert any("stdlib_map" in line for line in plines)
    assert metrics.exists()
    snap = json.loads(metrics.read_text())
    assert snap["total"] == n
    assert "llm_fraction" in summary
    assert "algorithmic_fraction" in summary


def test_run_once_idempotent_on_rerun(tmp_path: Path, monkeypatch):
    """The second pass on the same log must add nothing new."""
    log = tmp_path / "log.jsonl"
    stdlib = tmp_path / "stdlib.yaml"
    sft = tmp_path / "sft.jsonl"
    plog = tmp_path / "promotions.jsonl"
    metrics = tmp_path / "metrics.json"
    md = tmp_path / "metrics.md"
    stdlib.write_text('cpp_to_mojo:\n  "std::vector": ["List[T]"]\n')
    _seed_log(log, n_alg=1, n_llm=1)

    monkeypatch.setenv("GITHUB_TOKEN", "dummy")

    fr.run_once(
        source="cpp",
        targets=["mojo"],
        limit_repos=1,
        limit_fns=10,
        use_llm=False,
        no_behavioral=True,
        min_stars=10,
        crawl_out=tmp_path / "crawl.jsonl",
        log=log,
        stdlib=stdlib,
        sft=sft,
        plog=plog,
        metrics=metrics,
        md=md,
        since_ts=None,
        skip_crawl=True,
    )
    n_promotions_1 = sum(1 for _ in plog.read_text().splitlines() if _.strip())

    fr.run_once(
        source="cpp",
        targets=["mojo"],
        limit_repos=1,
        limit_fns=10,
        use_llm=False,
        no_behavioral=True,
        min_stars=10,
        crawl_out=tmp_path / "crawl.jsonl",
        log=log,
        stdlib=stdlib,
        sft=sft,
        plog=plog,
        metrics=metrics,
        md=md,
        since_ts=None,
        skip_crawl=True,
    )
    n_promotions_2 = sum(1 for _ in plog.read_text().splitlines() if _.strip())
    assert n_promotions_1 == n_promotions_2


# ---------------------------------------------------------------------------
# CLI smoke
# ---------------------------------------------------------------------------


def test_cli_skip_crawl_runs_to_completion(tmp_path: Path, monkeypatch):
    log = tmp_path / "log.jsonl"
    stdlib = tmp_path / "stdlib.yaml"
    sft = tmp_path / "sft.jsonl"
    plog = tmp_path / "promotions.jsonl"
    metrics = tmp_path / "metrics.json"
    md = tmp_path / "metrics.md"
    stdlib.write_text('cpp_to_mojo:\n  "std::vector": ["List[T]"]\n')
    _seed_log(log, n_alg=2, n_llm=1)

    monkeypatch.setenv("GITHUB_TOKEN", "dummy")
    rc = subprocess.run(
        [
            sys.executable,
            str(SCRIPTS_SFT / "flywheel_run.py"),
            "--skip-crawl",
            "--log",
            str(log),
            "--stdlib",
            str(stdlib),
            "--sft",
            str(sft),
            "--promotion-log",
            str(plog),
            "--metrics",
            str(metrics),
            "--md",
            str(md),
        ],
        capture_output=True,
        text=True,
    )
    assert rc.returncode == 0, rc.stderr
    assert "math.pow" in stdlib.read_text()
    assert metrics.exists()
    assert "pass done" in rc.stdout


# ---------------------------------------------------------------------------
# Bridge: crawler JSONL -> RepairOutcome log
# ---------------------------------------------------------------------------


def test_emit_outcomes_from_crawl_creates_algorithmic_records(tmp_path: Path):
    """Each crawl record with metadata.verification=behavioral should
    become a RepairOutcome(verdict=algorithmic)."""
    crawl = tmp_path / "crawl.jsonl"
    log = tmp_path / "log.jsonl"
    crawl.write_text(
        json.dumps(
            {
                "instruction": "...",
                "output": "def fp1(): pass",
                "metadata": {
                    "fingerprint": "fp1",
                    "source_lang": "cpp",
                    "target": "mojo",
                    "repo": "foo/bar",
                    "file": "x.cpp",
                    "fn": "fp1",
                    "verification": "behavioral",
                },
            }
        )
        + "\n"
        + json.dumps(
            {
                "instruction": "...",
                "output": "def fp2(): pass",
                "metadata": {
                    "fingerprint": "fp2",
                    "source_lang": "cpp",
                    "target": "mojo",
                    "repo": "foo/bar",
                    "file": "y.cpp",
                    "fn": "fp2",
                    "verification": "compile-only",
                },
            }
        )
        + "\n"
    )
    n = fr._emit_outcomes_from_crawl(crawl_out=crawl, log=log)
    assert n == 2
    outcomes = [
        RepairOutcome.from_json(line)
        for line in log.read_text().splitlines()
        if line.strip()
    ]
    by_fp = {o.fingerprint: o for o in outcomes}
    assert by_fp["fp1"].verdict == "algorithmic"
    assert by_fp["fp1"].n_llm_calls == 0
    assert by_fp["fp1"].source_id == "foo/bar::x.cpp::fp1"
    assert by_fp["fp2"].verdict == "rule"
    assert by_fp["fp2"].n_rule_passes == 1


def test_emit_outcomes_from_crawl_is_idempotent(tmp_path: Path):
    crawl = tmp_path / "crawl.jsonl"
    log = tmp_path / "log.jsonl"
    rec = {
        "instruction": "...",
        "output": "def fp1(): pass",
        "metadata": {
            "fingerprint": "fp1",
            "source_lang": "cpp",
            "target": "mojo",
            "verification": "behavioral",
        },
    }
    crawl.write_text(json.dumps(rec) + "\n")
    n1 = fr._emit_outcomes_from_crawl(crawl_out=crawl, log=log)
    n2 = fr._emit_outcomes_from_crawl(crawl_out=crawl, log=log)
    assert n1 == 1
    assert n2 == 0  # already seen
    # And no duplicate in the log
    assert log.read_text().count('"fingerprint": "fp1"') == 1


def test_emit_outcomes_handles_missing_or_malformed_records(tmp_path: Path):
    crawl = tmp_path / "crawl.jsonl"
    log = tmp_path / "log.jsonl"
    crawl.write_text(
        # valid
        json.dumps({"metadata": {"fingerprint": "ok1", "verification": "behavioral"}})
        + "\n"
        # no fingerprint - skip
        + json.dumps({"metadata": {"verification": "behavioral"}})
        + "\n"
        # malformed - skip
        + "{ this is not valid json"
        + "\n"
        # empty line - skip
        + "\n"
    )
    n = fr._emit_outcomes_from_crawl(crawl_out=crawl, log=log)
    assert n == 1
