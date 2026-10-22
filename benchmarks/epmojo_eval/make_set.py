"""Build an evaluation set from an EnergyPlusMojo checkout.

    python make_set.py --out DIR [--limit 40] [--exclude other/set.json ...]   # select by the rules below
    python make_set.py --out DIR --from-list sets/dev.json                      # rebuild a published selection

Selection rules: a routine of `tests/oracles/*.upstream.inc` that takes only `Real64` values and returns
a `Real64`, converts with `cpp2mojo` (so it calls no other routine), is 4-45 non-blank lines long, and
whose verbatim oracle builds; at most 3 per extract, each name once, shortest first.

`DIR` receives `set.json` (the routines and the EnergyPlusMojo commit) and `src/<tag>.upstream.inc`
(the verbatim function text read from the checkout; nothing is copied into this repository).
"""

from __future__ import annotations

import argparse
import re
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import harness as h  # noqa: E402


def tag_for(inc: Path, name: str) -> str:
    return re.sub(r"\W", "_", f"{inc.stem.replace('.upstream', '')}__{name}")


def candidates(root: Path, cpp2mojo) -> list[tuple[Path, str, object, str, int]]:
    incs = sorted((root / "tests" / "oracles").glob("*.upstream.inc"))
    units = cpp2mojo.build_units(incs)
    found = []
    for inc in incs:
        text = inc.read_text(encoding="utf-8")
        for name, sig in cpp2mojo.signatures(text).items():
            if not isinstance(sig, cpp2mojo.Signature):
                continue
            if not sig.returns_value or sig.returns_bool or sig.outputs or any(p.is_bool for p in sig.params):
                continue
            if not sig.inputs:
                continue
            try:
                conv = cpp2mojo.convert_unit(text, name, units)
                fn_text = cpp2mojo.function_text(text, name)
            except cpp2mojo.UnsupportedError:
                continue
            if conv.deps:
                continue
            n_lines = len([ln for ln in fn_text.splitlines() if ln.strip()])
            if 4 <= n_lines <= 45:
                found.append((inc, name, sig, fn_text, n_lines))
    return found


def build_ok(root: Path, out: Path, routine: h.Routine) -> bool:
    with tempfile.TemporaryDirectory() as td:
        try:
            h.Oracle(root, out, routine, Path(td))
        except RuntimeError:
            return False
    return True


def select(root: Path, out: Path, limit: int, exclude: set[str]) -> list[h.Routine]:
    cpp2mojo, _ = h.load_epmojo(root)
    chosen: list[h.Routine] = []
    per_file: dict[str, int] = {}
    seen = set(exclude)
    (out / "src").mkdir(parents=True, exist_ok=True)
    for inc, name, sig, fn_text, n_lines in sorted(candidates(root, cpp2mojo), key=lambda c: (c[4], c[0].name, c[1])):
        if per_file.get(inc.name, 0) >= 3 or name in seen:
            continue
        routine = h.Routine(tag_for(inc, name), name, inc.name, list(sig.inputs), n_lines)
        src = h.source_path(out, routine)
        src.write_text(fn_text + "\n", encoding="utf-8", newline="\n")
        if not build_ok(root, out, routine):
            src.unlink()
            continue
        per_file[inc.name] = per_file.get(inc.name, 0) + 1
        seen.add(name)
        chosen.append(routine)
        if len(chosen) >= limit:
            break
    return chosen


def rebuild(root: Path, out: Path, listed: list[h.Routine]) -> list[h.Routine]:
    cpp2mojo, _ = h.load_epmojo(root)
    (out / "src").mkdir(parents=True, exist_ok=True)
    problems = []
    for r in listed:
        inc = root / "tests" / "oracles" / r.file
        if not inc.exists():
            problems.append(f"{r.tag}: {r.file} not in this EnergyPlusMojo checkout")
            continue
        text = inc.read_text(encoding="utf-8")
        sig = cpp2mojo.signatures(text).get(r.name)
        if not isinstance(sig, cpp2mojo.Signature) or list(sig.inputs) != r.inputs:
            problems.append(f"{r.tag}: `{r.name}` not found with inputs {r.inputs}")
            continue
        h.source_path(out, r).write_text(cpp2mojo.function_text(text, r.name) + "\n", encoding="utf-8", newline="\n")
        if not build_ok(root, out, r):
            problems.append(f"{r.tag}: the oracle does not build")
    if problems:
        print("WARNING: the checkout differs from the one this list was made on:\n  " + "\n  ".join(problems), file=sys.stderr)
    return listed


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--out", required=True, type=Path)
    ap.add_argument("--epmojo", help="EnergyPlusMojo checkout (default: $EPMOJO_DIR or a sibling directory)")
    ap.add_argument("--limit", type=int, default=40)
    ap.add_argument("--exclude", nargs="*", default=[], type=Path, help="set.json/list files whose routine names to skip")
    ap.add_argument("--from-list", type=Path, help="rebuild the routines of a published list instead of selecting")
    args = ap.parse_args()
    root = h.epmojo_dir(args.epmojo)
    if args.from_list:
        meta, listed = _read_list(args.from_list)
        routines = rebuild(root, args.out, listed)
        if meta.get("epmojo_commit") not in (None, h.epmojo_commit(root)):
            print(f"note: list made on EnergyPlusMojo {meta['epmojo_commit']}, this checkout is {h.epmojo_commit(root)}", file=sys.stderr)
    else:
        exclude: set[str] = set()
        for f in args.exclude:
            exclude |= {r.name for r in _read_list(f)[1]}
        routines = select(root, args.out, args.limit, exclude)
    h.write_set(args.out, routines, h.epmojo_commit(root))
    print(f"{len(routines)} routines written to {args.out}")
    return 0


def _read_list(path: Path) -> tuple[dict, list[h.Routine]]:
    import json

    data = json.loads(path.read_text(encoding="utf-8"))
    return data, [h.Routine(**r) for r in data["routines"]]


if __name__ == "__main__":
    raise SystemExit(main())
