"""Acceptance measurement for issue #50.

Compares the C++-to-target failure breakdown between the
pre-issue-#50 baseline and the current run. The output is a
markdown table that makes the ``unresolved-symbol`` and
``unfilled-UnknownT-hole`` deltas obvious -- those are the two
buckets the issue calls out as acceptance criteria.

Usage::

    uv run python scripts/cpp_ground_truth.py examples/samples/C++/ \\
        --targets rust --md /tmp/cpp-diff.md

The "before" baseline is read from
``data/cpp_failure_taxonomy_baseline.md`` when it exists; the
"after" view is the current run of
``scripts/failure_taxonomy.py``.
"""
from __future__ import annotations

import argparse
import pathlib
import subprocess
import sys

THIS = pathlib.Path(__file__).resolve().parent
ROOT = THIS.parent

DEFAULT_ROOT = ROOT / "examples" / "samples" / "C++"
DEFAULT_TARGETS = ["rust", "mojo"]
BASELINE_PATH = ROOT / "data" / "cpp_failure_taxonomy_baseline.md"


def _run_sweep(root: pathlib.Path, targets: list[str]) -> str:
    """Run scripts/failure_taxonomy.py on *root*/*targets* and return the
    markdown rollup as a string. We use ``--no-compile`` so the run is
    fast enough for a side-by-side comparison; the compile gate is
    orthogonal to the unresolved-symbol / unfilled-hole buckets the
    issue cares about."""
    args = [
        sys.executable,
        str(THIS / "failure_taxonomy.py"),
        str(root),
        "--no-compile",
        "--targets",
        ",".join(targets),
    ]
    proc = subprocess.run(args, capture_output=True, text=True, check=False)
    if proc.returncode != 0 and not proc.stdout:
        sys.stderr.write(proc.stderr)
        raise SystemExit(proc.returncode)
    return proc.stdout


def _parse_full(md: str) -> dict[tuple[str, str], dict[str, int]]:
    """Full parse: (source, target) -> {bucket: count, total: N}.

    The taxonomy script emits a markdown table whose first row is the
    header (with bucket names in the columns after the leading
    ``source | target | total`` triple) and whose remaining rows are
    one per (source, target) pair. We split those out, so callers can
    ask "what was the unresolved-symbol count for cpp->rust?" and get
    an integer back.
    """
    cols: list[str] = []
    out: dict[tuple[str, str], dict[str, int]] = {}
    for line in md.splitlines():
        line = line.strip()
        if not line.startswith("|"):
            continue
        if "---" in line:
            continue
        cells = [c.strip() for c in line.strip("|").split("|")]
        if not cols:
            # Header row: capture bucket column order.
            if cells[:3] == ["source", "target", "total"]:
                cols = cells[3:]
            continue
        if len(cells) < 3 + len(cols):
            continue
        try:
            total = int(cells[2])
        except ValueError:
            continue
        src, tgt = cells[0], cells[1]
        rec: dict[str, int] = {"total": total}
        for i, col in enumerate(cols):
            try:
                rec[col] = int(cells[3 + i])
            except (ValueError, IndexError):
                rec[col] = 0
        out[(src, tgt)] = rec
    return out


def _fmt(n: int) -> str:
    """Signed integer for the delta columns."""
    if n > 0:
        return f"+{n}"
    return str(n)


def _make_diff_md(
    root: pathlib.Path,
    targets: list[str],
    before: dict[tuple[str, str], dict[str, int]],
    after: dict[tuple[str, str], dict[str, int]],
) -> str:
    """Markdown table comparing before/after per (source, target) pair.
    The two columns the issue cares about -- ``unresolved-symbol``
    and ``unfilled-UnknownT-hole`` -- get explicit delta columns so
    the acceptance signal is unmistakable in a single glance."""
    keys = sorted(set(before) | set(after))
    cols = [
        "source", "target",
        "before ok", "after ok", "Δok",
        "before unresolved-symbol", "after unresolved-symbol", "Δunresolved-symbol",
        "before unfilled-UnknownT-hole", "after unfilled-UnknownT-hole", "Δunfilled",
    ]
    out = [f"# C++ ground-truth impact (issue #50)", ""]
    out.append(f"Root: `{root}`")
    out.append(f"Targets: {', '.join(targets)}")
    out.append("")
    out.append("| " + " | ".join(cols) + " |")
    out.append("|" + "---|" * len(cols))
    for k in keys:
        b = before.get(k, {})
        a = after.get(k, {})
        before_ok = b.get("ok", 0)
        after_ok = a.get("ok", 0)
        before_un = b.get("unresolved-symbol", 0)
        after_un = a.get("unresolved-symbol", 0)
        before_uh = b.get("unfilled-UnknownT-hole", 0)
        after_uh = a.get("unfilled-UnknownT-hole", 0)
        row = [
            k[0], k[1],
            str(before_ok), str(after_ok), _fmt(after_ok - before_ok),
            str(before_un), str(after_un), _fmt(after_un - before_un),
            str(before_uh), str(after_uh), _fmt(after_uh - before_uh),
        ]
        out.append("| " + " | ".join(row) + " |")
    out.append("")
    out.append("**Acceptance signal for issue #50**: a *decrease* in the "
               "``unresolved-symbol`` and ``unfilled-UnknownT-hole`` columns "
               "between ``before`` and ``after``. The other buckets are "
               "orthogonal to the ground-truth pass and may move up or "
               "down for unrelated reasons.")
    out.append("")
    out.append("**Notes on the numbers**: a baseline of 0 in the "
               "``unresolved-symbol`` or ``unfilled-UnknownT-hole`` columns "
               "for a particular (source, target) pair almost always "
               "means the baseline couldn't reach that stage of the "
               "pipeline at all (a parse refusal short-circuited the "
               "run). In that case the ``after`` count is a *new* "
               "class of failure revealed by the preprocessor, not a "
               "regression -- the test now exercises a code path that "
               "the baseline never could.")
    return "\n".join(out)


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("root", nargs="?", default=str(DEFAULT_ROOT), type=pathlib.Path)
    ap.add_argument("--targets", default=",".join(DEFAULT_TARGETS))
    ap.add_argument("--md", type=pathlib.Path,
                    help="write the diff markdown to this path")
    args = ap.parse_args(argv)
    targets = [t.strip() for t in args.targets.split(",") if t.strip()]

    # "after" = current run.
    after_md = _run_sweep(args.root, targets)
    after = _parse_full(after_md)

    # "before" = saved baseline, if it exists. Without it the script
    # still emits the "after" rows so the user has a record of the
    # current state.
    if BASELINE_PATH.is_file():
        before = _parse_full(BASELINE_PATH.read_text(encoding="utf-8"))
    else:
        sys.stderr.write(
            f"[note] no baseline at {BASELINE_PATH}; showing after only.\n"
        )
        before = {}

    diff_md = _make_diff_md(args.root, targets, before, after)
    print(diff_md)
    if args.md:
        args.md.parent.mkdir(parents=True, exist_ok=True)
        args.md.write_text(diff_md + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
