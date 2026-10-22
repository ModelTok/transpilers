"""Score drafts against the verbatim C++ oracle, raw and after the post-pass.

    python score.py --set-dir DIR --runs RUNS RUN [RUN ...] [--partial] [--jobs 8] [--out results.json]

Run it where Mojo and g++ work (Linux, or WSL on Windows), with numpy available; inside EnergyPlusMojo's
pixi environment that is `pixi run python benchmarks/epmojo_eval/score.py ...`.

Per routine and variant the status is one of
  exact       builds and every result is bit-identical on the edge-case inputs
  mismatch    builds, some results differ (the detail is the number of differing rows)
  build_fail  Mojo rejected the draft (the detail is the first error)
  no_function the draft defines no function with the routine's name
  arity       the function takes a different number of parameters than the C++ routine
`raw` is the model's answer as written; `postpass` is `transpilers.repair.mojo_postpass` applied to it
with the C++ source as context.
"""

from __future__ import annotations

import argparse
import json
import sys
import tempfile
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import harness as h  # noqa: E402


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--set-dir", required=True, type=Path)
    ap.add_argument("--runs", required=True, type=Path)
    ap.add_argument("runs_to_score", nargs="+", metavar="RUN")
    ap.add_argument("--epmojo", help="EnergyPlusMojo checkout (default: $EPMOJO_DIR or a sibling directory)")
    ap.add_argument("--partial", action="store_true", help="skip routines that have no draft yet")
    ap.add_argument("--jobs", type=int, default=8, help="parallel Mojo builds")
    ap.add_argument("--cases", type=int, default=h.N_CASES)
    ap.add_argument("--out", type=Path, help="write the per-routine results here as JSON")
    args = ap.parse_args()

    root = h.epmojo_dir(args.epmojo)
    postpass = h.load_postpass().postpass
    _, routines = h.read_set(args.set_dir)
    work = Path(tempfile.mkdtemp(prefix="epmojo_eval_"))

    oracles = {}
    for r in routines:
        try:
            oracles[r.tag] = h.Oracle(root, args.set_dir, r, work, args.cases)
        except RuntimeError as e:
            print(f"skipping {r.tag}: {e}", file=sys.stderr)

    jobs = []
    for run in args.runs_to_score:
        for r in routines:
            if r.tag not in oracles:
                continue
            f = args.runs / run / "out" / f"{r.tag}.mojo"
            if not f.exists():
                if args.partial:
                    continue
                jobs += [(run, r, "raw", ""), (run, r, "postpass", "")]
                continue
            code = f.read_text(encoding="utf-8")
            source = h.source_path(args.set_dir, r).read_text(encoding="utf-8")
            jobs += [(run, r, "raw", code), (run, r, "postpass", postpass(code, source=source).code)]

    def one(job):
        run, r, variant, code = job
        status, detail = h.evaluate(code, r, oracles[r.tag], root, work)
        return run, variant, r.tag, status, detail

    with ThreadPoolExecutor(args.jobs) as ex:
        results = list(ex.map(one, jobs))

    table: dict[tuple[str, str], list[tuple[str, str, str]]] = {}
    for run, variant, tag, status, detail in results:
        table.setdefault((run, variant), []).append((tag, status, detail))
    for (run, variant), rows in sorted(table.items()):
        c = h.summarise(rows)
        print(
            f"{run:16} {variant:9} routines={c['routines']} built={c['built']} exact={c[h.EXACT]} "
            f"mismatch={c[h.MISMATCH]} build_fail={c[h.BUILD_FAIL]} no_function={c[h.NO_FUNCTION]} arity={c[h.ARITY]}"
        )
        for msg, n in Counter(d for _, s, d in rows if s == h.BUILD_FAIL).most_common(4):
            print(f"      {n:2}x {msg}")
    if args.out:
        args.out.write_text(
            json.dumps({f"{run}|{variant}": rows for (run, variant), rows in table.items()}, indent=1),
            encoding="utf-8",
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
