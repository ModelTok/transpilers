#!/usr/bin/env python3
"""Scan a C++ source tree and build a JSON config for transpile.py.

Each .cc/.cpp file gets paired with a .mojo target path that mirrors the
source directory structure under the output root.

Usage:
  # Basic: mirror full source tree
  python build_config.py /home/bart/Github/EnergyPlus \
      --output-root /home/bart/Github/EnergyPlus-Mojo \
      -o transpile_config.json

  # Strip a subdirectory prefix
  python build_config.py /home/bart/Github/EnergyPlus/src/EnergyPlus \
      --source-root /home/bart/Github/EnergyPlus \
      --output-root /home/bart/Github/EnergyPlus-Mojo \
      -o config.json

  # Exclude specific dirs
  python build_config.py /home/bart/Github/EnergyPlus \
      --output-root /home/bart/Github/EnergyPlus-Mojo \
      --exclude test third_party src/EnergyPlus/api \
      -o config.json

  # Limit by file size (skip files over N lines)
  python build_config.py /home/bart/Github/EnergyPlus \
      --output-root /home/bart/Github/EnergyPlus-Mojo \
      --max-lines 500 \
      -o small_files.json

  # Pipe directly to transpile CLI (dry-run first)
  python build_config.py /home/bart/Github/EnergyPlus \
      --output-root /home/bart/Github/EnergyPlus-Mojo \
  | python -c "import json,sys; cfg=json.load(sys.stdin); print(f'{len(cfg)} files')"
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

CPP_EXTS = {".cc", ".cpp", ".cxx", ".c++"}
HEADER_EXTS = {".hh", ".hpp", ".hxx", ".h"}


def find_header(cc_path: Path) -> Path | None:
    """Return the .hh/.hpp/.h file sharing the same stem, or None."""
    for ext in HEADER_EXTS:
        candidate = cc_path.with_suffix(ext)
        if candidate.exists():
            return candidate
    return None


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Build a JSON config of (source → target) pairs for transpile.py",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    ap.add_argument("source_dir", help="Root directory to scan for C++ source files")
    ap.add_argument("--output-root", "-r", required=True,
                    help="Root directory where transpiled .mojo files will live")
    ap.add_argument("--source-root", default=None,
                    help="Source prefix to strip from paths when mirroring. "
                         "If omitted, source_dir is used as the root.")
    ap.add_argument("--output", "-o", default=None,
                    help="Write config to file instead of stdout")
    ap.add_argument("--exclude", nargs="*", default=[],
                    help="Subdirectory names to exclude (e.g. test third_party api)")
    ap.add_argument("--max-lines", type=int, default=0,
                    help="Skip files with more than N lines (0 = no limit)")
    ap.add_argument("--min-lines", type=int, default=0,
                    help="Skip files with fewer than N lines (0 = no limit)")
    ap.add_argument("--header", action="store_true", default=True,
                    help="Include header context path in config (default: True)")
    ap.add_argument("--no-header", action="store_false", dest="header",
                    help="Skip header context")
    ap.add_argument("--tier", action="store_true",
                    help="Use EnergyPlus-Mojo tier system to order files "
                         "(Data=0, stateless=1, components=2, managers=3)")
    ap.add_argument("--sort", choices=["path", "lines", "tier"], default="path",
                    help="Sort order for output entries")
    ap.add_argument("--progress", action="store_true",
                    help="Show progress while scanning")
    args = ap.parse_args()

    source_dir = Path(args.source_dir).resolve()
    if not source_dir.is_dir():
        print(f"ERROR: source directory not found: {source_dir}", file=sys.stderr)
        return 1

    output_root = Path(args.output_root).resolve()
    source_root = Path(args.source_root).resolve() if args.source_root else source_dir

    exclude_set = set(args.exclude)

    # --- Scan for .cc/.cpp files ---
    entries = []
    for f in sorted(source_dir.rglob("*")):
        if not f.is_file() or f.suffix not in CPP_EXTS:
            continue
        # Check exclusions
        rel = f.relative_to(source_dir)
        if any(part in exclude_set for part in rel.parts):
            continue
        # Line count
        try:
            lines = f.read_text(errors="ignore").count("\n")
        except OSError:
            continue
        if args.max_lines and lines > args.max_lines:
            continue
        if args.min_lines and lines < args.min_lines:
            continue

        # Build target path mirroring source structure
        try:
            rel_to_root = f.relative_to(source_root)
        except ValueError:
            # File is outside source_root — use filename only
            rel_to_root = Path(f.name)
        target = output_root / rel_to_root.with_suffix(".mojo")

        entry = {
            "id": len(entries) + 1,
            "source": str(f),
            "target": str(target),
            "decision": "pending",
            "lines": lines,
        }
        if args.header:
            hdr = find_header(f)
            if hdr:
                entry["header"] = str(hdr)
        if args.tier:
            entry["tier"] = infer_tier(f.stem, str(f).lower())
        entries.append(entry)

        if args.progress and len(entries) % 100 == 0:
            print(f"  scanned {len(entries)} files...", file=sys.stderr)

    # --- Sort ---
    if args.sort == "lines":
        entries.sort(key=lambda e: e["lines"])
    elif args.sort == "tier":
        entries.sort(key=lambda e: (e.get("tier", 9), e["lines"]))
    else:
        entries.sort(key=lambda e: e["source"])

    # --- Output ---
    output = json.dumps(entries, indent=2)
    if args.output:
        Path(args.output).write_text(output)
        print(f"Wrote {len(entries)} entries to {args.output}", file=sys.stderr)
    else:
        print(output)

    return 0


def infer_tier(stem: str, path_lower: str) -> int:
    """Rough tier classification matching EnergyPlus-Mojo conventions."""
    n = stem.lower()
    if stem.startswith("Data") or n in ("constant", "datastringglobals", "configuredfunctions"):
        return 0
    if n in ("vectors", "surfaceoctree", "psychrometrics", "general", "curvemanager",
             "convectioncoefficients", "windowmanager", "tarcoggasses90", "fluidproperties"):
        return 1
    if any(k in n for k in (
        "coil", "pump", "fan", "chiller", "boiler", "baseboard", "radiant", "tower",
        "tank", "generator", "pv", "photovolt", "battery", "heatpump", "heater",
    )):
        return 2
    if any(k in n for k in (
        "manager", "balance", "simulation", "hvac", "plant", "airloop", "zoneequip", "branch",
    )):
        return 3
    return 2


if __name__ == "__main__":
    raise SystemExit(main())