#!/usr/bin/env python3
"""Check that every Mojo output of a SFT JSONL file compiles with `mojo build`.

Each row's `output` is read as a Markdown fenced block when it has one (```mojo ... ```),
otherwise as plain code. A row without `def main` gets an empty `def main() raises` appended,
so that `mojo build` can link it. Compile only: behaviour is not checked.

Usage: MOJO_HOME=<pixi env> python scripts/sft/verify_mojo_compile.py train.jsonl results.jsonl
"""
from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import tempfile
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

MOJO_HOME = Path(os.environ.get("MOJO_HOME", "/root/epm/.pixi/envs/default"))
MOJO = MOJO_HOME / "bin" / "mojo"
ENV = dict(os.environ, MODULAR_HOME=str(MOJO_HOME / "share" / "max"),
           PATH=f"/usr/bin:/bin:{MOJO_HOME / 'bin'}")
STUB = "\n\ndef main() raises:\n    pass\n"
FENCE = re.compile(r"```[a-zA-Z]*\n(.*?)\n```", re.S)


def code_of(output: str) -> str:
    m = FENCE.search(output)
    return m.group(1) if m else output


def check(item: tuple[int, dict]) -> dict:
    idx, row = item
    code = code_of(row["output"])
    if "def main" not in code:
        code += STUB
    with tempfile.TemporaryDirectory() as td:
        src = Path(td) / "m.mojo"
        src.write_text(code, encoding="utf-8")
        try:
            r = subprocess.run([str(MOJO), "build", str(src), "-o", str(Path(td) / "m.bin")],
                               capture_output=True, text=True, timeout=240, env=ENV)
            status, err = ("pass", "") if r.returncode == 0 else ("fail", (r.stderr or r.stdout)[-1200:])
        except subprocess.TimeoutExpired:
            status, err = "timeout", ""
    return {"row": idx, "status": status, "error": err}


def main() -> None:
    src, out = Path(sys.argv[1]), Path(sys.argv[2])
    rows = [json.loads(line) for line in src.read_text(encoding="utf-8").splitlines() if line.strip()]
    with ThreadPoolExecutor(max_workers=8) as ex:
        results = list(ex.map(check, enumerate(rows)))
    with out.open("w", encoding="utf-8") as fh:
        for r in results:
            fh.write(json.dumps(r, ensure_ascii=False) + "\n")
    print(Counter(r["status"] for r in results))


if __name__ == "__main__":
    main()
