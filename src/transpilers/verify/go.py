"""Verify emitted Go source compiles."""

from __future__ import annotations

import shutil
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path


@dataclass
class CompileResult:
    ok: bool
    stderr: str


def go_available() -> bool:
    return shutil.which("go") is not None


def go_compiles(source: str) -> CompileResult:
    if not go_available():
        return CompileResult(ok=False, stderr="go not found on PATH")
    with tempfile.TemporaryDirectory() as td:
        # `go build` for `package main` insists on a `main()` function.
        # Append a trivial one if the source doesn't define it — we're
        # type-checking emitted library code, not linking a binary.
        complete = source if "func main(" in source else source + "\nfunc main() {}\n"
        (Path(td) / "main.go").write_text(complete)
        (Path(td) / "go.mod").write_text("module check\n\ngo 1.21\n")
        out = subprocess.run(
            ["go", "build", "./..."], capture_output=True, text=True, cwd=td, timeout=30
        )
        return CompileResult(ok=out.returncode == 0, stderr=out.stderr)
