#!/usr/bin/env python3
"""Emit LLVM IR from C++ source files using clang.

Usage:
    python scripts/emit_llvm_ir.py src/EnergyPlus/ --output ir/
    python scripts/emit_llvm_ir.py file.cpp --output file.ll
    python scripts/emit_llvm_ir.py src/ --output ir/ --std c++17 --includes "third_party/include"
"""

import argparse
import subprocess
import sys
from pathlib import Path


def emit_ir(
    source: Path,
    output: Path,
    std: str = "c++17",
    includes: list[str] | None = None,
    debug_info: bool = True,
    extra_flags: list[str] | None = None,
) -> tuple[bool, str]:
    """Emit LLVM IR from a single C++ source file.

    Args:
        source: Path to the .cpp source file.
        output: Path to write the .ll LLVM IR file.
        std: C++ standard to use (e.g. "c++17").
        includes: List of additional include directories.
        debug_info: Whether to emit debug info (-g flag).
        extra_flags: Additional flags to pass to clang.

    Returns:
        Tuple of (success: bool, message: str).
    """
    cmd = [
        "clang",
        "-S",
        "-emit-llvm",
        "-O0",
        f"-std={std}",
        "-o", str(output),
        str(source),
    ]

    if debug_info:
        cmd.append("-g")

    for inc in (includes or []):
        cmd.extend(["-I", inc])

    for flag in (extra_flags or []):
        cmd.append(flag)

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=60,
        )
        if result.returncode == 0:
            return True, f"OK: {source} -> {output}"
        else:
            stderr = result.stderr.strip()
            return False, f"FAIL: {source}\n  clang error: {stderr[:500]}"
    except FileNotFoundError:
        return False, "ERROR: clang not found — install LLVM/clang and ensure it is on PATH"
    except subprocess.TimeoutExpired:
        return False, f"TIMEOUT: {source} took >60s to compile"
    except Exception as exc:
        return False, f"ERROR: {source}: {exc}"


def process_directory(
    src_dir: Path,
    out_dir: Path,
    std: str,
    includes: list[str],
    debug_info: bool,
    extra_flags: list[str],
) -> tuple[int, int]:
    """Recursively process all .cpp files in src_dir.

    Args:
        src_dir: Root directory containing .cpp files.
        out_dir: Root output directory for .ll files (mirrors source structure).
        std: C++ standard.
        includes: Additional include directories.
        debug_info: Emit debug info.
        extra_flags: Extra clang flags.

    Returns:
        Tuple of (success_count, failure_count).
    """
    cpp_files = sorted(src_dir.rglob("*.cpp"))
    if not cpp_files:
        print(f"No .cpp files found in {src_dir}", file=sys.stderr)
        return 0, 0

    print(f"Found {len(cpp_files)} .cpp files in {src_dir}")
    out_dir.mkdir(parents=True, exist_ok=True)

    success = 0
    failure = 0

    for i, src in enumerate(cpp_files, 1):
        # Mirror directory structure under out_dir
        relative = src.relative_to(src_dir)
        out_path = out_dir / relative.with_suffix(".ll")
        out_path.parent.mkdir(parents=True, exist_ok=True)

        ok, msg = emit_ir(src, out_path, std, includes, debug_info, extra_flags)
        status = "OK  " if ok else "FAIL"
        print(f"[{i:>4}/{len(cpp_files)}] {status} {src.name}")
        if not ok:
            print(f"       {msg}", file=sys.stderr)
            failure += 1
        else:
            success += 1

    return success, failure


def process_single_file(
    src: Path,
    output: Path,
    std: str,
    includes: list[str],
    debug_info: bool,
    extra_flags: list[str],
) -> bool:
    """Emit IR for a single file.

    Returns True on success.
    """
    if output.is_dir():
        output = output / src.with_suffix(".ll").name

    output.parent.mkdir(parents=True, exist_ok=True)
    ok, msg = emit_ir(src, output, std, includes, debug_info, extra_flags)
    print(msg)
    return ok


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Emit LLVM IR from C++ source files using clang.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument(
        "source",
        type=Path,
        help="Path to a .cpp file or directory containing .cpp files.",
    )
    parser.add_argument(
        "--output", "-o",
        type=Path,
        required=True,
        help="Output path: a .ll file (if source is a file) or a directory (if source is a dir).",
    )
    parser.add_argument(
        "--std",
        default="c++17",
        help="C++ standard to compile with (default: c++17).",
    )
    parser.add_argument(
        "--includes",
        default="",
        help="Comma-separated list of additional include directories.",
    )
    parser.add_argument(
        "--no-debug",
        action="store_true",
        help="Disable debug info emission (-g). Default: debug info is included.",
    )
    parser.add_argument(
        "--flag",
        action="append",
        default=[],
        dest="extra_flags",
        help="Extra flag to pass to clang (can be repeated, e.g. --flag -fopenmp).",
    )

    args = parser.parse_args()

    source: Path = args.source
    output: Path = args.output
    includes = [i.strip() for i in args.includes.split(",") if i.strip()]
    debug_info = not args.no_debug

    if not source.exists():
        print(f"ERROR: source path does not exist: {source}", file=sys.stderr)
        return 1

    if source.is_dir():
        success, failure = process_directory(
            source, output, args.std, includes, debug_info, args.extra_flags
        )
        total = success + failure
        print(f"\nSummary: {success}/{total} succeeded, {failure}/{total} failed")
        if failure > 0:
            print(f"WARNING: {failure} file(s) failed — check stderr for details")
        return 0 if failure == 0 else 1

    elif source.suffix == ".cpp":
        ok = process_single_file(
            source, output, args.std, includes, debug_info, args.extra_flags
        )
        return 0 if ok else 1

    else:
        print(f"ERROR: source must be a .cpp file or directory, got: {source}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
