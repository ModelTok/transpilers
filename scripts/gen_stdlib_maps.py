#!/usr/bin/env python3
"""gen_stdlib_maps.py — Auto-generate stdlib_maps/auto_generated.yaml from Zim archives.

Workflow
--------
1.  Scan D:\\zim (or ZIM_DIR env var) for .zim files matching:
      docs.python.org_*.zim   → Python documentation
      mojolang.org_*.zim      → Mojo documentation

2.  For each entry in CPP_TO_PYTHON_HINTS and CPP_TO_MOJO_HINTS (from
    src/transpilers/rag/zim_rag.py), search the relevant .zim archive via
    libzim to find the best-matching article.  The search terms are the
    hint values (e.g. ["sorted", "list.sort"]).

3.  Write src/transpilers/stdlib_maps/auto_generated.yaml with:

    cpp_to_python:
      "std::sort": ["sorted", "list.sort"]
      ...
    cpp_to_mojo:
      "std::vector": ["List[T]"]
      ...

Graceful fallback
-----------------
If libzim is not installed (ImportError) or no .zim files are found, the
script writes a stub YAML containing the hardcoded hints from CPP_TO_PYTHON_HINTS
and CPP_TO_MOJO_HINTS without performing any Zim search.

Usage
-----
    python scripts/gen_stdlib_maps.py
    python scripts/gen_stdlib_maps.py --zim-dir /mnt/zim --output custom.yaml
    python scripts/gen_stdlib_maps.py --dry-run   # print YAML to stdout

Dependencies
------------
    libzim (optional): pip install libzim
    PyYAML (optional): pip install PyYAML   (fallback: writes raw YAML manually)
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# Locate the package root so we can import from src/
# ---------------------------------------------------------------------------

_REPO_ROOT = Path(__file__).resolve().parent.parent  # transpilers/
_SRC = _REPO_ROOT / "src"
if str(_SRC) not in sys.path:
    sys.path.insert(0, str(_SRC))

try:
    from transpilers.rag.zim_rag import (
        CPP_TO_MOJO_HINTS,
        CPP_TO_PYTHON_HINTS,
        ZIM_DIR_DEFAULT,
        find_zim_files,
    )
except ImportError as _imp_err:
    # Fallback: define inline copies if the package isn't installed.
    ZIM_DIR_DEFAULT = Path(os.environ.get("ZIM_DIR", r"D:\zim"))

    def find_zim_files(zim_dir=ZIM_DIR_DEFAULT):  # type: ignore[misc]
        d = Path(zim_dir)
        if not d.exists():
            return []
        return sorted(d.glob("*.zim"), key=lambda f: f.stat().st_mtime, reverse=True)

    CPP_TO_PYTHON_HINTS: dict[str, list[str]] = {
        "std::sort":            ["sorted", "list.sort"],
        "std::vector":          ["list", "array"],
        "std::unordered_map":   ["dict", "defaultdict"],
        "std::map":             ["dict", "SortedDict"],
        "std::string":          ["str", "string"],
        "std::cout":            ["print"],
        "std::cin":             ["input"],
        "std::max":             ["max"],
        "std::min":             ["min"],
        "std::abs":             ["abs", "math.fabs"],
        "std::sqrt":            ["math.sqrt"],
        "std::pow":             ["pow", "math.pow"],
        "std::floor":           ["math.floor"],
        "std::ceil":            ["math.ceil"],
        "std::round":           ["round", "math.round"],
        "std::find":            ["str.find", "list.index"],
        "std::transform":       ["map", "list comprehension"],
        "std::accumulate":      ["sum", "functools.reduce"],
        "std::fill":            ["list comprehension", "itertools.repeat"],
        "std::copy":            ["list.copy", "copy.copy"],
        "std::set":             ["set"],
        "std::deque":           ["collections.deque"],
        "std::queue":           ["queue.Queue"],
        "std::stack":           ["list"],
        "std::pair":            ["tuple"],
        "std::tuple":           ["tuple"],
        "std::optional":        ["None", "Optional"],
        "std::shared_ptr":      ["object reference"],
        "std::unique_ptr":      ["object reference", "contextlib"],
        "std::move":            ["(no equivalent — Python uses references)"],
        "printf":               ["print", "f-string"],
        "sprintf":              ["f-string", "str.format"],
        "malloc":               ["list", "bytearray"],
        "free":                 ["(automatic — Python GC)"],
        "memcpy":               ["copy", "slice assignment"],
        "strlen":               ["len"],
        "strcmp":               ["== operator"],
        "strcpy":               ["= assignment"],
    }
    CPP_TO_MOJO_HINTS: dict[str, list[str]] = {
        "std::vector":          ["List[T]"],
        "std::unordered_map":   ["Dict[K, V]"],
        "std::map":             ["Dict[K, V]"],
        "std::string":          ["String"],
        "std::sort":            ["sort()"],
        "std::max":             ["max()"],
        "std::min":             ["min()"],
        "std::abs":             ["abs()"],
        "std::sqrt":            ["math.sqrt()"],
        "std::optional":        ["Optional[T]"],
        "std::pair":            ["Tuple[A, B]"],
        "std::tuple":           ["Tuple[...]"],
        "std::shared_ptr":      ["Reference types in Mojo use ownership"],
        "std::unique_ptr":      ["Owned[T]"],
        "printf":               ["print()"],
    }
    print(
        f"Warning: could not import transpilers package ({_imp_err}). "
        "Using inline hint tables.",
        file=sys.stderr,
    )

OUTPUT_DEFAULT = _REPO_ROOT / "src" / "transpilers" / "stdlib_maps" / "auto_generated.yaml"


# ---------------------------------------------------------------------------
# Zim search helpers
# ---------------------------------------------------------------------------

def _open_zim(path: Path) -> object | None:
    """Lazy-open a zim archive. Returns None if libzim not installed."""
    try:
        import libzim  # type: ignore
        return libzim.Archive(str(path))
    except ImportError:
        return None
    except Exception as exc:
        print(f"  Warning: could not open {path.name}: {exc}", file=sys.stderr)
        return None


def _search_article_titles(archive: object, query: str, max_results: int = 5) -> list[str]:
    """Search a zim archive and return a list of matching article titles."""
    try:
        import libzim  # type: ignore
        searcher = libzim.Searcher(archive)
        results = searcher.search(libzim.Query().set_query(query))
        titles: list[str] = []
        for i, entry in enumerate(results):
            if i >= max_results:
                break
            try:
                titles.append(entry.title)
            except Exception:
                pass
        return titles
    except Exception:
        return []


def _best_zim_hints(
    zim_files: list[Path],
    pattern: str,
    search_terms: list[str],
    max_results: int = 3,
) -> list[str]:
    """Search matching .zim archives for *search_terms* and return refined hints.

    Falls back to the original *search_terms* if no better match is found.
    """
    matching = [f for f in zim_files if pattern in f.name.lower()]
    if not matching:
        return search_terms

    archive = _open_zim(matching[0])
    if archive is None:
        return search_terms

    found_titles: list[str] = []
    for term in search_terms:
        titles = _search_article_titles(archive, term, max_results=max_results)
        found_titles.extend(titles)

    # Prefer results that overlap with the original hints.
    refined: list[str] = []
    for t in found_titles:
        if any(h.lower() in t.lower() or t.lower() in h.lower() for h in search_terms):
            if t not in refined:
                refined.append(t)

    return refined if refined else search_terms


# ---------------------------------------------------------------------------
# YAML serialisation (no external dep required)
# ---------------------------------------------------------------------------

def _to_yaml_str(mapping: dict[str, list[str]], key: str) -> str:
    """Produce a YAML block for one top-level mapping key."""
    lines = [f"{key}:"]
    for cpp_api, targets in mapping.items():
        # Inline list representation.
        items = ", ".join(f'"{t}"' for t in targets)
        lines.append(f'  "{cpp_api}": [{items}]')
    return "\n".join(lines)


def _write_yaml(
    cpp_to_python: dict[str, list[str]],
    cpp_to_mojo: dict[str, list[str]],
    output: Path,
) -> None:
    header = (
        "# auto_generated.yaml — generated by scripts/gen_stdlib_maps.py\n"
        "# DO NOT EDIT BY HAND — re-run the script to regenerate.\n"
        "#\n"
        "# Workflow:\n"
        "#   1. Scans D:\\zim for docs.python.org_*.zim and mojolang.org_*.zim\n"
        "#   2. For each entry in CPP_TO_PYTHON_HINTS / CPP_TO_MOJO_HINTS,\n"
        "#      searches the relevant .zim archive via libzim.\n"
        "#   3. Writes the best-matching API names.\n"
        "#\n"
        "# If libzim is not installed, the file contains the hardcoded hints.\n\n"
    )

    body = _to_yaml_str(cpp_to_python, "cpp_to_python")
    body += "\n\n"
    body += _to_yaml_str(cpp_to_mojo, "cpp_to_mojo")
    body += "\n"

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(header + body, encoding="utf-8")


# ---------------------------------------------------------------------------
# Main generation logic
# ---------------------------------------------------------------------------

def generate(
    zim_dir: Path = ZIM_DIR_DEFAULT,
    output: Path = OUTPUT_DEFAULT,
    dry_run: bool = False,
    verbose: bool = False,
) -> None:
    """Generate auto_generated.yaml from Zim archives (or hardcoded hints)."""

    zim_files = find_zim_files(zim_dir)
    has_python_zim = any("docs.python.org" in f.name for f in zim_files)
    has_mojo_zim = any("mojolang.org" in f.name for f in zim_files)

    if not zim_files:
        print(
            f"No .zim files found in {zim_dir}. Writing stub YAML from hardcoded hints.",
            file=sys.stderr,
        )

    libzim_available = False
    try:
        import libzim  # type: ignore  # noqa: F401
        libzim_available = True
    except ImportError:
        print(
            "libzim not installed (pip install libzim). Writing stub YAML from hardcoded hints.",
            file=sys.stderr,
        )

    use_zim = libzim_available and bool(zim_files)

    # Build refined mapping tables.
    cpp_to_python: dict[str, list[str]] = {}
    cpp_to_mojo: dict[str, list[str]] = {}

    for cpp_api, hints in CPP_TO_PYTHON_HINTS.items():
        if use_zim and has_python_zim:
            if verbose:
                print(f"  Searching Python zim for: {cpp_api} -> {hints}")
            refined = _best_zim_hints(zim_files, "docs.python.org", hints)
        else:
            refined = hints
        cpp_to_python[cpp_api] = refined

    for cpp_api, hints in CPP_TO_MOJO_HINTS.items():
        if use_zim and has_mojo_zim:
            if verbose:
                print(f"  Searching Mojo zim for: {cpp_api} -> {hints}")
            refined = _best_zim_hints(zim_files, "mojolang.org", hints)
        else:
            refined = hints
        cpp_to_mojo[cpp_api] = refined

    # Produce YAML content.
    header = (
        "# auto_generated.yaml — generated by scripts/gen_stdlib_maps.py\n"
        "# DO NOT EDIT BY HAND — re-run the script to regenerate.\n"
        "#\n"
        "# Workflow:\n"
        "#   1. Scans D:\\zim for docs.python.org_*.zim and mojolang.org_*.zim\n"
        "#   2. For each entry in CPP_TO_PYTHON_HINTS / CPP_TO_MOJO_HINTS,\n"
        "#      searches the relevant .zim archive via libzim.\n"
        "#   3. Writes the best-matching API names.\n"
        "#\n"
        f"# Source: {'Zim archives' if use_zim else 'Hardcoded hints (libzim not available or no .zim files)'}\n\n"
    )
    body = _to_yaml_str(cpp_to_python, "cpp_to_python")
    body += "\n\n"
    body += _to_yaml_str(cpp_to_mojo, "cpp_to_mojo")
    body += "\n"
    content = header + body

    if dry_run:
        print(content)
        return

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(content, encoding="utf-8")

    n_py = len(cpp_to_python)
    n_mojo = len(cpp_to_mojo)
    print(
        f"Wrote {output}  "
        f"({n_py} C++->Python entries, {n_mojo} C++->Mojo entries)"
        f"{'  [stub - libzim not available]' if not use_zim else '  [from Zim archives]'}"
    )


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="gen_stdlib_maps",
        description="Auto-generate stdlib_maps/auto_generated.yaml from Zim archives (Issue #16).",
    )
    parser.add_argument(
        "--zim-dir",
        type=Path,
        default=ZIM_DIR_DEFAULT,
        help=f"Directory containing .zim files (default: {ZIM_DIR_DEFAULT}).",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=OUTPUT_DEFAULT,
        help=f"Output YAML path (default: {OUTPUT_DEFAULT}).",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print YAML to stdout instead of writing to disk.",
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Print each Zim search query.",
    )
    args = parser.parse_args(argv)

    generate(
        zim_dir=args.zim_dir,
        output=args.output,
        dry_run=args.dry_run,
        verbose=args.verbose,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
