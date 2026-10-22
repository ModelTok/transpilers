"""Shared pieces of the EnergyPlusMojo evaluation harness.

The harness measures whether drafts of Mojo kernels are bit-for-bit identical to the verbatim C++
they came from. It borrows three things from an EnergyPlusMojo checkout and changes none of them:
the extracted upstream routines (`tests/oracles/*.upstream.inc`), the oracle shim header, and the
`cpp2mojo` signature parser / oracle driver generator in `scripts/module_parity/`.

A draft is scored by building the verbatim routine with g++ (`-ffp-contract=off`, assertions off) and
the draft with Mojo behind a thin batch wrapper, then comparing the bits of every result on
EnergyPlusMojo's own edge-case input generator (magnitudes from 1e-2 to 1e3, negatives, 0, 1 and IEEE
specials).
"""

from __future__ import annotations

import ctypes
import importlib.util
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SETS = Path(__file__).resolve().parent / "sets"

EXACT, MISMATCH, BUILD_FAIL, NO_FUNCTION, ARITY = "exact", "mismatch", "build_fail", "no_function", "arity"
N_CASES = 3000


@dataclass(frozen=True)
class Routine:
    tag: str
    name: str
    file: str
    inputs: list[str]
    lines: int = 0

    @property
    def arity(self) -> int:
        return len(self.inputs)


# --------------------------------------------------------------------------------------------
# environment
# --------------------------------------------------------------------------------------------


def epmojo_dir(arg: str | os.PathLike | None = None) -> Path:
    """The EnergyPlusMojo checkout: `arg`, else $EPMOJO_DIR, else a sibling `EnergyPlusMojo`."""
    root = Path(arg or os.environ.get("EPMOJO_DIR") or REPO.parent / "EnergyPlusMojo")
    if not (root / "tests" / "oracles").is_dir() or not (root / "scripts" / "module_parity" / "cpp2mojo.py").exists():
        raise SystemExit(
            f"{root} is not an EnergyPlusMojo checkout (no tests/oracles or scripts/module_parity/cpp2mojo.py); "
            "pass --epmojo DIR or set EPMOJO_DIR"
        )
    return root


def epmojo_commit(root: Path) -> str:
    try:
        r = subprocess.run(["git", "-C", str(root), "rev-parse", "--short", "HEAD"], capture_output=True, text=True)
        return r.stdout.strip() or "unknown"
    except OSError:
        return "unknown"


def load_epmojo(root: Path):
    """Import EnergyPlusMojo's `cpp2mojo` and `cpp2mojo_sweep` from its checkout (read only)."""
    mp = str(root / "scripts" / "module_parity")
    if mp not in sys.path:
        sys.path.insert(0, mp)
    import cpp2mojo
    import cpp2mojo_sweep

    return cpp2mojo, cpp2mojo_sweep


def load_postpass():
    """The repo's post-pass, loaded by path (it needs only the standard library)."""
    path = REPO / "src" / "transpilers" / "repair" / "mojo_postpass.py"
    spec = importlib.util.spec_from_file_location("mojo_postpass", path)
    mod = importlib.util.module_from_spec(spec)
    sys.modules.setdefault("mojo_postpass", mod)
    spec.loader.exec_module(mod)
    return mod


# --------------------------------------------------------------------------------------------
# sets
# --------------------------------------------------------------------------------------------


def read_set(set_dir: Path) -> tuple[dict, list[Routine]]:
    """`<set_dir>/set.json`: {"epmojo_commit": ..., "routines": [...]}."""
    data = json.loads((Path(set_dir) / "set.json").read_text(encoding="utf-8"))
    return data, [Routine(**r) for r in data["routines"]]


def write_set(set_dir: Path, routines: list[Routine], commit: str) -> None:
    Path(set_dir).mkdir(parents=True, exist_ok=True)
    payload = {
        "epmojo_commit": commit,
        "routines": [r.__dict__ for r in routines],
    }
    (Path(set_dir) / "set.json").write_text(json.dumps(payload, indent=1) + "\n", encoding="utf-8", newline="\n")


def source_path(set_dir: Path, routine: Routine) -> Path:
    return Path(set_dir) / "src" / f"{routine.tag}.upstream.inc"


# --------------------------------------------------------------------------------------------
# interface check and wrapper
# --------------------------------------------------------------------------------------------


def check_interface(code: str, routine: Routine) -> str | None:
    """`no_function` when the draft defines no `def`/`fn` of the routine's name, `arity` when the
    parameter count differs from the C++ routine's; None when it can be called."""
    m = re.search(rf"\b(?:def|fn)\s+{re.escape(routine.name)}\s*\(([^)]*)\)", code)
    if not m:
        return NO_FUNCTION
    if len([p for p in m.group(1).split(",") if p.strip()]) != routine.arity:
        return ARITY
    return None


def wrapper_source(name: str, n_inputs: int) -> str:
    """A batch entry that calls the draft's `name` once per row of packed `Float64` inputs."""
    args = ", ".join(f"inp[{n_inputs} * c + {j}]" for j in range(n_inputs))
    return (
        "\n\n@export\ndef eval_batch(n: Int, in_ptr: Int, out_ptr: Int):\n"
        "    var inp = UnsafePointer[Float64, MutAnyOrigin](unsafe_from_address=in_ptr)\n"
        "    var outp = UnsafePointer[Float64, MutAnyOrigin](unsafe_from_address=out_ptr)\n"
        f"    for c in range(n):\n        outp[c] = {name}({args})  # fma: ok\n"
    )


def first_error(text: str) -> str:
    """The first compiler error with quoted names blanked, so equal errors group together."""
    for line in text.splitlines():
        if "error:" in line:
            return re.sub(r"'[^']*'", "'_'", line.split("error:", 1)[1].strip())[:90]
    return "unknown"


# --------------------------------------------------------------------------------------------
# oracle and draft builds
# --------------------------------------------------------------------------------------------


class Oracle:
    """The verbatim routine built with g++, with the inputs and expected bits for it."""

    def __init__(self, root: Path, set_dir: Path, routine: Routine, workdir: Path, n_cases: int = N_CASES, seed: int = 1):
        import numpy as np

        cpp2mojo, sweep = load_epmojo(root)
        inc = source_path(set_dir, routine)
        sig = cpp2mojo.signatures(inc.read_text(encoding="utf-8"))[routine.name]
        cc = workdir / f"{routine.tag}_oracle.cc"
        cc.write_text(sweep.oracle_source(inc, sig, routine.tag), encoding="utf-8")
        so = workdir / f"{routine.tag}_oracle.so"
        r = subprocess.run(
            ["g++", "-O2", "-DNDEBUG", "-fPIC", "-shared", "-ffp-contract=off", f"-I{root / 'tests' / 'oracles'}", str(cc), "-o", str(so)],
            capture_output=True,
            text=True,
        )
        if r.returncode:
            raise RuntimeError(f"oracle for {routine.tag} did not build: {r.stderr[:300]}")
        self.sweep = sweep
        self.n = n_cases
        self.inputs = sweep.inputs(n_cases, [False] * routine.arity, seed)
        fn = getattr(ctypes.CDLL(str(so)), f"cm_{routine.tag}")
        fn.argtypes = [ctypes.c_int64, ctypes.c_void_p, ctypes.c_void_p]
        fn.restype = None
        self.expected = np.zeros(n_cases)
        fn(n_cases, sweep._addr(self.inputs), sweep._addr(self.expected))


def mojo_build(root: Path, src: Path, out: Path) -> tuple[bool, str]:
    """Build `src` as a shared library with Mojo; returns (built, compiler output)."""
    cmd = f"PATH=/usr/bin:$PATH mojo build --emit shared-lib {src} -o {out} -Xlinker -ldl -Xlinker -lm"
    if shutil.which("mojo") and not os.environ.get("EPMOJO_USE_PIXI"):
        r = subprocess.run(["bash", "-c", cmd], capture_output=True, text=True)
    else:
        pixi = os.environ.get("EPMOJO_PIXI") or shutil.which("pixi") or str(Path.home() / ".pixi" / "bin" / "pixi")
        r = subprocess.run(
            [pixi, "run", "--manifest-path", str(root / "pixi.toml"), "bash", "-c", cmd],
            capture_output=True,
            text=True,
            cwd=root,
        )
    return out.exists(), r.stdout + r.stderr


def evaluate(code: str, routine: Routine, oracle: Oracle, root: Path, workdir: Path) -> tuple[str, str]:
    """Score one draft: (status, detail)."""
    bad = check_interface(code, routine)
    if bad:
        return bad, ""
    import numpy as np

    d = Path(tempfile.mkdtemp(prefix=f"{routine.tag}_", dir=workdir))
    (d / "fp_strict.mojo").write_text((root / "src" / "kernels" / "fp_strict.mojo").read_text(encoding="utf-8"), encoding="utf-8")
    (d / "k.mojo").write_text(code + wrapper_source(routine.name, routine.arity), encoding="utf-8", newline="\n")
    built, text = mojo_build(root, d / "k.mojo", d / "k.so")
    if not built:
        return BUILD_FAIL, first_error(text)
    fn = ctypes.CDLL(str(d / "k.so")).eval_batch
    fn.argtypes = [ctypes.c_int64, ctypes.c_void_p, ctypes.c_void_p]
    fn.restype = None
    got = np.zeros(oracle.n)
    fn(oracle.n, oracle.sweep._addr(oracle.inputs), oracle.sweep._addr(got))
    bad_rows = int((~oracle.sweep.same_bits(oracle.expected, got)).sum())
    return (EXACT, "0") if bad_rows == 0 else (MISMATCH, str(bad_rows))


# --------------------------------------------------------------------------------------------
# reporting and paths
# --------------------------------------------------------------------------------------------


def summarise(rows: list[tuple[str, str, str]]) -> dict[str, int]:
    """Counts per status for (tag, status, detail) rows, plus `built` (compiled and ran)."""
    counts = {s: 0 for s in (EXACT, MISMATCH, BUILD_FAIL, NO_FUNCTION, ARITY)}
    for _tag, status, _detail in rows:
        counts[status] = counts.get(status, 0) + 1
    counts["routines"] = len(rows)
    counts["built"] = counts[EXACT] + counts[MISMATCH]
    return counts


def to_wsl_path(path: str | os.PathLike) -> str:
    """`C:\\a\\b` -> `/mnt/c/a/b`; other paths are returned with forward slashes."""
    m = re.match(r"^([A-Za-z]):[\\/](.*)$", str(path))
    if not m:
        return str(path).replace("\\", "/")
    return f"/mnt/{m.group(1).lower()}/" + m.group(2).replace("\\", "/")
