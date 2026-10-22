"""Tracked shell scripts keep their shebang line.

A bulk comment-stripping pass once removed the first line (`#!/usr/bin/env bash`) from 13 shell scripts,
which silently broke running them directly (`./script.sh`). This guards against a repeat.
"""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]

def tracked_shell_scripts() -> list[str]:
    if shutil.which("git") is None or not (ROOT / ".git").exists():
        pytest.skip("needs a git checkout")
    out = subprocess.run(
        ["git", "ls-files", "-z", "--", "*.sh"], cwd=ROOT, capture_output=True, text=True, check=True
    ).stdout
    return [p for p in out.split("\0") if p and not p.startswith(("third_party/", "data/"))]


def first_line(path: str) -> bytes:
    with open(ROOT / path, "rb") as f:
        return f.readline().rstrip(b"\n")


def test_every_tracked_shell_script_starts_with_a_shebang():
    missing = [p for p in tracked_shell_scripts() if (ROOT / p).exists() and not first_line(p).startswith(b"#!")]
    assert not missing, f"no shebang on the first line of: {missing}"


def test_shebang_lines_have_no_carriage_return():
    bad = [p for p in tracked_shell_scripts() if first_line(p).startswith(b"#!") and first_line(p).endswith(b"\r")]
    assert not bad, f"CRLF after the shebang (bash reports a bad interpreter) in: {bad}"
