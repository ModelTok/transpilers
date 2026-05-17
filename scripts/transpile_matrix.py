"""Try transpiling every supported-extension file under a directory tree
and print a PASS/FAIL matrix. Useful for stress-testing the pipeline
against a real-world corpus (currently `examples/speed-comparison/`).

Usage:
    uv run python scripts/transpile_matrix.py <root> [<target>]

Defaults: root=examples/speed-comparison, target=rust.
"""

from __future__ import annotations

import pathlib
import subprocess
import sys


EXT_MAP = {
    "c": "c", "cpp": "cpp", "cs": "csharp", "f90": "fortran",
    "go": "go", "java": "java", "js": "javascript", "py": "python",
    "ts": "typescript", "vb": "vb",
}


def main(argv: list[str]) -> int:
    root = pathlib.Path(argv[1] if len(argv) > 1 else "examples/speed-comparison")
    target = argv[2] if len(argv) > 2 else "rust"
    results: list[tuple[str, str, str]] = []
    for f in sorted(root.rglob("*")):
        if not f.is_file():
            continue
        src = EXT_MAP.get(f.suffix.lstrip("."))
        if not src:
            continue
        proc = subprocess.run(
            ["uv", "run", "transpile", str(f), "--source", src, "--target", target],
            capture_output=True, text=True, timeout=60,
        )
        ok = proc.returncode == 0
        if ok:
            status = "PASS"
        else:
            stderr = (proc.stderr or proc.stdout).strip().splitlines()
            first_err = next((l for l in stderr[::-1] if l.strip()), "")[:80]
            status = f"FAIL  {first_err}"
        results.append((str(f.relative_to(root)), src, status))

    print(f"{'file':<32} {'source':<11} status")
    print("-" * 110)
    for name, src, status in results:
        print(f"{name:<32} {src:<11} {status}")
    passes = sum(1 for _, _, s in results if s == "PASS")
    print(f"\n{passes} / {len(results)} files transpile to {target}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
