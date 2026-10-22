"""`transpile` must not crash when stdout is redirected under a legacy code page
(issue: `transpile --help` and non-ASCII output raised UnicodeEncodeError)."""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path


def _run(args: list[str], cwd: Path) -> subprocess.CompletedProcess[bytes]:
    code = "import sys; from transpilers.cli.main import main; sys.exit(main(sys.argv[1:]))"
    env = {**os.environ, "PYTHONIOENCODING": "cp1250", "PYTHONUTF8": "0"}
    return subprocess.run(
        [sys.executable, "-c", code, *args], cwd=cwd, env=env, capture_output=True
    )


def test_help_works_when_stdout_uses_a_legacy_code_page(tmp_path: Path):
    r = _run(["--help"], tmp_path)
    assert r.returncode == 0, r.stderr.decode("utf-8", "replace")[-400:]
    assert b"python_pivot" in r.stdout


def test_non_ascii_output_is_written_as_utf8(tmp_path: Path):
    src = tmp_path / "u.py"
    src.write_text('def f() -> str:\n    return "café → ok"\n', encoding="utf-8")
    r = _run([str(src), "--target", "rust"], tmp_path)
    assert r.returncode == 0, r.stderr.decode("utf-8", "replace")[-400:]
    assert "→".encode("utf-8") in r.stdout
