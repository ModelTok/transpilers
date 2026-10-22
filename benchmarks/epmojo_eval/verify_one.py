"""Accept or reject one draft: the verifier for `transpile-llm --samples N --verify-cmd ...`.

    python verify_one.py DRAFT.mojo --set-dir DIR [--set-dir DIR2 ...] [--epmojo DIR]

The draft's file name (without `.mojo`) is the routine's tag in one of the sets. Exit status 0 means the
draft builds and is bit-identical to the verbatim C++ oracle; one line says why not otherwise:
1 mismatch, 2 unknown routine, 3 no function of that name or wrong arity, 4 the oracle did not build,
5 Mojo rejected the draft. Run it where Mojo and g++ work (Linux, or WSL; see `verify_wsl.py`).
"""

from __future__ import annotations

import argparse
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import harness as h  # noqa: E402

EXIT = {h.EXACT: 0, h.MISMATCH: 1, h.NO_FUNCTION: 3, h.ARITY: 3, h.BUILD_FAIL: 5}


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("draft", type=Path)
    ap.add_argument("--set-dir", action="append", required=True, type=Path)
    ap.add_argument("--epmojo", help="EnergyPlusMojo checkout (default: $EPMOJO_DIR or a sibling directory)")
    args = ap.parse_args(argv)

    root = h.epmojo_dir(args.epmojo)
    tag = args.draft.stem
    found = None
    for set_dir in args.set_dir:
        for r in h.read_set(set_dir)[1]:
            if r.tag == tag:
                found = (set_dir, r)
    if found is None:
        print(f"unknown routine {tag}")
        return 2
    set_dir, routine = found
    code = args.draft.read_text(encoding="utf-8")
    bad = h.check_interface(code, routine)
    if bad:
        print("no function " + routine.name if bad == h.NO_FUNCTION else "wrong arity")
        return EXIT[bad]
    work = Path(tempfile.mkdtemp(prefix="verify_"))
    try:
        oracle = h.Oracle(root, set_dir, routine, work)
    except RuntimeError:
        print("oracle did not build")
        return 4
    status, detail = h.evaluate(code, routine, oracle, root, work)
    print("exact" if status == h.EXACT else f"{detail} of {oracle.n} rows differ" if status == h.MISMATCH else "mojo build failed: " + detail)
    return EXIT[status]


if __name__ == "__main__":
    raise SystemExit(main())
