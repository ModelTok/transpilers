"""Run `verify_one.py` inside WSL from Windows, so it can serve as a `transpile-llm --verify-cmd`.

    python verify_wsl.py DRAFT.mojo --set-dir DIR [...] --python /root/epm/.pixi/envs/default/bin/python3 \\
        --epmojo /root/epm [--distro Ubuntu] [--user root]

Windows paths are converted to `/mnt/<drive>/...`; the exit status and the last line of output come back.
`--python` must be a WSL Python with numpy (EnergyPlusMojo's pixi environment has one) and `--epmojo` the
EnergyPlusMojo checkout as seen from WSL.
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import harness as h  # noqa: E402


def build_command(args: argparse.Namespace) -> list[str]:
    verify = h.to_wsl_path(Path(__file__).resolve().with_name("verify_one.py"))
    cmd = ["wsl", "-d", args.distro, "-u", args.user, "--", args.python, verify, h.to_wsl_path(args.draft)]
    for d in args.set_dir:
        cmd += ["--set-dir", h.to_wsl_path(Path(d).resolve())]
    cmd += ["--epmojo", args.epmojo]
    return cmd


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("draft", type=Path)
    ap.add_argument("--set-dir", action="append", required=True, type=Path)
    ap.add_argument("--python", required=True, help="a WSL python with numpy")
    ap.add_argument("--epmojo", required=True, help="the EnergyPlusMojo checkout, as a WSL path")
    ap.add_argument("--distro", default="Ubuntu")
    ap.add_argument("--user", default="root")
    args = ap.parse_args()
    r = subprocess.run(build_command(args), capture_output=True, text=True)
    lines = [ln for ln in (r.stdout + r.stderr).replace("\x00", "").splitlines() if ln.strip() and "PyTorch was not found" not in ln]
    print(lines[-1] if lines else "")
    return r.returncode


if __name__ == "__main__":
    raise SystemExit(main())
