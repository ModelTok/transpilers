"""Verify emitted Fortran source compiles with gfortran."""

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


def fortran_available() -> bool:
    return shutil.which("gfortran") is not None or shutil.which("flang") is not None


def fortran_compiles(source: str) -> CompileResult:
    compiler = shutil.which("gfortran") or shutil.which("flang")
    if compiler is None:
        return CompileResult(ok=False, stderr="no Fortran compiler on PATH")
    with tempfile.TemporaryDirectory() as td:
        src = Path(td) / "lib.f90"
        src.write_text(source)
        out = subprocess.run(
            [compiler, "-c", "-ffree-form", str(src), "-o", str(Path(td) / "out.o")],
            capture_output=True,
            text=True,
            cwd=td,
            timeout=30,
        )
        return CompileResult(ok=out.returncode == 0, stderr=out.stderr)
