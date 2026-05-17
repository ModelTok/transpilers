"""Verify emitted Mojo source compiles."""

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


def mojo_available() -> bool:
    return shutil.which("mojo") is not None


def mojo_compiles(source: str) -> CompileResult:
    if not mojo_available():
        return CompileResult(ok=False, stderr="mojo not found on PATH")
    with tempfile.TemporaryDirectory() as td:
        src = Path(td) / "lib.mojo"
        src.write_text(source)
        # `mojo build` requires a main(); for library-style code we use
        # `mojo build -o` writing to /dev/null is awkward, so we wrap the
        # file's defs by adding a trivial main if absent. The shorter and
        # more robust path is `mojo run` against a wrapper that imports
        # — but for emit-level testing we just type-check by building.
        # Trick: append a tiny `def main(): pass` so the file is buildable.
        if "def main" not in source:
            (src).write_text(source + "\ndef main():\n    pass\n")
        out = subprocess.run(
            ["mojo", "build", str(src), "-o", str(Path(td) / "out")],
            capture_output=True,
            text=True,
        )
        return CompileResult(ok=out.returncode == 0, stderr=out.stderr)
