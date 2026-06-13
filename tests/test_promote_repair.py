"""Tests for the data-flywheel promotion step (issue #51).

These cover:

* the stdlib_maps YAML roundtrip preserves the existing entries
* only frontier-only outcomes seed new mappings; the SFT corpus accepts
  any passing verdict (priority-weighted)
* idempotency: re-running with the same log does not re-write existing
  entries
* the script's CLI surface (--dry-run, --std-only, --sft-only, --since-ts)
* the load_yaml / dump_yaml roundtrip
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
import promote_repair as pr  # noqa: E402  # noqa: E402


# ---------------------------------------------------------------------------
# YAML roundtrip
# ---------------------------------------------------------------------------


def test_yaml_roundtrip_preserves_entries(tmp_path: Path):
    src = tmp_path / "in.yaml"
    src.write_text(
        "# header\n"
        "cpp_to_python:\n"
        '  "std::sort": ["sorted", "list.sort"]\n'
        '  "std::vector": ["list"]\n'
        "\n"
        "python_to_rust:\n"
        '  "len": ["x.len() as i32"]\n'
    )
    mapping = pr._load_yaml(src)
    assert mapping["cpp_to_python"]["std::sort"] == ["sorted", "list.sort"]
    assert mapping["python_to_rust"]["len"] == ["x.len() as i32"]

    out = tmp_path / "out.yaml"
    pr._dump_yaml(out, mapping, header="# roundtrip test\n")
    again = pr._load_yaml(out)
    assert again == mapping


def test_yaml_parser_skips_blank_and_comment_lines(tmp_path: Path):
    f = tmp_path / "x.yaml"
    f.write_text("# only comments and blank lines\n\n\n# another\n")
    assert pr._load_yaml(f) == {}


def test_yaml_loader_returns_empty_when_missing(tmp_path: Path):
    assert pr._load_yaml(tmp_path / "nope.yaml") == {}


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _frontier_outcome(
    *, construct: str, notes: str, fingerprint: str = "fp1", target: str = "mojo"
) -> RepairOutcome:
    """A minimal frontier-only outcome carrying the fields promote_stdlib_maps reads."""
    return RepairOutcome(
        source_lang="cpp",
        target=target,
        fingerprint=fingerprint,
        construct=construct,
        notes=notes,
        verdict="llm",
        n_llm_calls=1,
    )


# ---------------------------------------------------------------------------
# Promotion
# ---------------------------------------------------------------------------


def test_promote_stdlib_maps_appends_frontier_only(tmp_path: Path):
    stdlib = tmp_path / "auto_generated.yaml"
    stdlib.write_text('cpp_to_mojo:\n  "std::vector": ["List[T]"]\n')
    plog = tmp_path / "promotions.jsonl"

    outcomes = [
        _frontier_outcome(construct="std::pow", notes="math.pow"),
        _frontier_outcome(construct="std::sqrt", notes="math.sqrt", fingerprint="fp2"),
        RepairOutcome(
            source_lang="cpp",
            target="mojo",
            fingerprint="alg1",
            construct="std::sort",
            notes="sort()",
            verdict="algorithmic",
        ),
        RepairOutcome(
            source_lang="cpp",
            target="mojo",
            fingerprint="lr1",
            construct="std::copy",
            notes="list.copy()",
            verdict="llm",
            n_llm_calls=1,
            n_rule_passes=1,
        ),
    ]
    added = pr.promote_stdlib_maps(outcomes, stdlib_path=stdlib, promotion_log=plog)
    assert added == {("cpp", "mojo"): 2}

    again = pr._load_yaml(stdlib)
    assert "math.pow" in again["cpp_to_mojo"]["std::pow"]
    assert "math.sqrt" in again["cpp_to_mojo"]["std::sqrt"]
    assert again["cpp_to_mojo"]["std::vector"] == ["List[T]"]
    assert "sort" not in again["cpp_to_mojo"].get("std::sort", [])
    assert "list.copy" not in again["cpp_to_mojo"].get("std::copy", [])


def test_promote_stdlib_maps_is_idempotent(tmp_path: Path):
    stdlib = tmp_path / "auto_generated.yaml"
    plog = tmp_path / "promotions.jsonl"
    outcomes = [_frontier_outcome(construct="std::pow", notes="math.pow")]

    pr.promote_stdlib_maps(outcomes, stdlib_path=stdlib, promotion_log=plog)
    added = pr.promote_stdlib_maps(outcomes, stdlib_path=stdlib, promotion_log=plog)
    assert added == {}


def test_promote_stdlib_maps_dry_run_writes_nothing(tmp_path: Path):
    stdlib = tmp_path / "auto_generated.yaml"
    plog = tmp_path / "promotions.jsonl"
    # Pre-populate so we can read pre_yaml; the test asserts dry-run doesn't touch it
    stdlib.write_text('cpp_to_mojo:\n  "std::vector": ["List[T]"]\n')
    pre_yaml = stdlib.read_text()
    # plog does not exist pre-test
    assert not plog.exists()

    added = pr.promote_stdlib_maps(
        [_frontier_outcome(construct="std::pow", notes="math.pow")],
        stdlib_path=stdlib,
        promotion_log=plog,
        dry_run=True,
    )
    assert added == {("cpp", "mojo"): 1}
    assert stdlib.read_text() == pre_yaml
    assert not plog.exists()


def test_promote_stdlib_maps_rejects_unparseable_construct(tmp_path: Path):
    stdlib = tmp_path / "auto_generated.yaml"
    plog = tmp_path / "promotions.jsonl"
    outcomes = [
        _frontier_outcome(construct="!@#$%^", notes="ignored"),
        _frontier_outcome(construct="", notes="ignored", fingerprint="blank"),
    ]
    added = pr.promote_stdlib_maps(outcomes, stdlib_path=stdlib, promotion_log=plog)
    assert added == {}


# ---------------------------------------------------------------------------
# SFT promotion
# ---------------------------------------------------------------------------


def test_promote_sft_corpus_priority_weights(tmp_path: Path):
    sft = tmp_path / "sft.jsonl"
    plog = tmp_path / "promotions.jsonl"
    outcomes = [
        RepairOutcome(
            source_lang="cpp",
            target="mojo",
            fingerprint="fp1",
            verdict="llm",
            n_llm_calls=1,
        ),
        RepairOutcome(
            source_lang="cpp",
            target="mojo",
            fingerprint="fp2",
            verdict="llm",
            n_llm_calls=2,
            n_rule_passes=1,
        ),
        RepairOutcome(
            source_lang="cpp",
            target="mojo",
            fingerprint="fp3",
            verdict="rule",
            n_rule_passes=1,
        ),
        RepairOutcome(
            source_lang="cpp", target="mojo", fingerprint="fp4", verdict="algorithmic"
        ),
        RepairOutcome(
            source_lang="cpp",
            target="mojo",
            fingerprint="fp5",
            verdict="unrepaired",
            n_llm_calls=3,
        ),
    ]
    src = {fp: f"// {fp}" for fp in ("fp1", "fp2", "fp3", "fp4", "fp5")}
    tgt = {
        (fp, "mojo"): f"def {fp}(): pass" for fp in ("fp1", "fp2", "fp3", "fp4", "fp5")
    }

    added = pr.promote_sft_corpus(
        outcomes,
        sft_path=sft,
        promotion_log=plog,
        source_lookup=src,
        target_lookup=tgt,
    )
    assert added == {"llm": 2, "rule": 1, "algorithmic": 1}

    lines = [json.loads(line) for line in sft.read_text().splitlines() if line.strip()]
    by_fp = {r["metadata"]["fingerprint"]: r for r in lines}
    assert by_fp["fp1"]["metadata"]["weight"] == 4
    assert by_fp["fp2"]["metadata"]["weight"] == 3
    assert by_fp["fp3"]["metadata"]["weight"] == 2
    assert by_fp["fp4"]["metadata"]["weight"] == 1
    assert "fp5" not in by_fp
    assert by_fp["fp1"]["metadata"]["frontier_only"] is True
    assert by_fp["fp4"]["metadata"]["frontier_only"] is False


def test_promote_sft_corpus_skips_missing_lookups(tmp_path: Path):
    sft = tmp_path / "sft.jsonl"
    plog = tmp_path / "promotions.jsonl"
    outcomes = [
        RepairOutcome(
            source_lang="cpp",
            target="mojo",
            fingerprint="missing",
            verdict="algorithmic",
        ),
    ]
    added = pr.promote_sft_corpus(
        outcomes,
        sft_path=sft,
        promotion_log=plog,
    )
    assert added == {}
    assert not sft.exists()


def test_promote_sft_corpus_is_idempotent(tmp_path: Path):
    sft = tmp_path / "sft.jsonl"
    plog = tmp_path / "promotions.jsonl"
    outcomes = [_frontier_outcome(construct="", notes="", fingerprint="fp1")]
    src = {"fp1": "// source"}
    tgt = {("fp1", "mojo"): "def fp1(): pass"}

    pr.promote_sft_corpus(
        outcomes, sft_path=sft, promotion_log=plog, source_lookup=src, target_lookup=tgt
    )
    n_after_first = sum(1 for _ in sft.read_text().splitlines() if _.strip())
    pr.promote_sft_corpus(
        outcomes, sft_path=sft, promotion_log=plog, source_lookup=src, target_lookup=tgt
    )
    n_after_second = sum(1 for _ in sft.read_text().splitlines() if _.strip())
    assert n_after_first == n_after_second == 1


# ---------------------------------------------------------------------------
# CLI smoke
# ---------------------------------------------------------------------------


def test_cli_dry_run_writes_nothing(tmp_path: Path):
    log = tmp_path / "log.jsonl"
    stdlib = tmp_path / "stdlib.yaml"
    sft = tmp_path / "sft.jsonl"
    plog = tmp_path / "promotions.jsonl"
    stdlib.write_text('cpp_to_mojo:\n  "std::vector": ["List[T]"]\n')

    with RepairTracker(log_path=log, create_dirs=False) as t:
        t.record(_frontier_outcome(construct="std::pow", notes="math.pow"))

    assert not plog.exists()
    rc = subprocess.run(
        [
            sys.executable,
            str(SCRIPTS_SFT / "promote_repair.py"),
            "--log",
            str(log),
            "--stdlib",
            str(stdlib),
            "--sft",
            str(sft),
            "--promotion-log",
            str(plog),
            "--dry-run",
        ],
        capture_output=True,
        text=True,
    )
    assert rc.returncode == 0, rc.stderr
    assert "math.pow" not in stdlib.read_text()
    assert not plog.exists()
