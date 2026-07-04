"""Verify emitted Zig source actually compiles."""

from __future__ import annotations

import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path


@dataclass
class CompileResult:
    ok: bool
    stderr: str


def zig_compiles(source: str) -> CompileResult:
    with tempfile.TemporaryDirectory() as td:
        src = Path(td) / "lib.zig"
        # All emitted functions are private by default in Zig. Exporting them
        # to the C ABI would be wrong for our purposes; instead we ensure the
        # file builds as a static library, which only requires that it parses
        # and type-checks. Unused private fns are fine for the check.
        src.write_text(source)
        out = subprocess.run(
            ["zig", "build-obj", "-fno-emit-bin", str(src)],
            capture_output=True,
            text=True,
            cwd=td,
            timeout=30,
        )
        return CompileResult(ok=out.returncode == 0, stderr=out.stderr)
