"""Draft every routine of a set with `transpile-llm`, one named run per call.

    python generate.py --set-dir DIR --runs RUNS --run NAME [--model transpiler-15b-v2] \\
        [--endpoint http://localhost:11434/v1] [-- extra transpile-llm arguments]

Drafts land in `RUNS/NAME/out/<tag>.mojo` (raw model responses in `RUNS/NAME/raw/`). Anything after `--`
goes to `transpile-llm`, e.g. `--temperature 0.8`, `--postpass`, `--domain-prompts`, or best-of-n with
`--samples 8 --verify-cmd "python benchmarks/epmojo_eval/verify_one.py {target} --set-dir DIR"`.

The default (no guidance flag, no `--postpass`) stores the model's raw answer, which is what `score.py`
needs to measure both the raw and the post-passed variants.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import harness as h  # noqa: E402


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--set-dir", required=True, type=Path)
    ap.add_argument("--runs", required=True, type=Path, help="directory that holds one subdirectory per run")
    ap.add_argument("--run", required=True, help="name of this run")
    ap.add_argument("--model", default="transpiler-15b-v2")
    ap.add_argument("--endpoint", default="http://localhost:11434/v1")
    ap.add_argument("--timeout", type=int, default=600)
    ap.add_argument("extra", nargs="*", help="arguments for transpile-llm (put them after --)")
    args = ap.parse_args()

    _, routines = h.read_set(args.set_dir)
    rd = (args.runs / args.run).resolve()
    (rd / "raw").mkdir(parents=True, exist_ok=True)
    config = [
        {
            "id": i + 1,
            "source": str(h.source_path(args.set_dir, r).resolve()),
            "target": str(rd / "out" / f"{r.tag}.mojo"),
            "decision": "pending",
        }
        for i, r in enumerate(routines)
    ]
    (rd / "config.json").write_text(json.dumps(config, indent=1), encoding="utf-8")
    cmd = [
        sys.executable, "-m", "transpilers.cli.transpile", str(rd / "config.json"),
        "--endpoint", args.endpoint, "--model", args.model,
        "--max-retries", "0", "--timeout", str(args.timeout), "--raw-dir", str(rd / "raw"), *args.extra,
    ]
    print(" ".join(cmd), flush=True)
    return subprocess.run(cmd, cwd=rd).returncode


if __name__ == "__main__":
    raise SystemExit(main())
