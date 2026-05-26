#!/usr/bin/env python3
"""translate_granular.py — Granularity-aware C++ → Python/Mojo translation driver.

Implements four granularity strategies for Issue #25:

  function  — parse each function signature from C++ source, translate
              each independently, then recombine the translated units.
  class     — parse each class/struct block, translate each independently.
  file      — translate the whole file at once (baseline).
  folder    — gather all .cpp/.h files, build a dependency order, translate
              in that topological order.

The actual LLM call is stubbed out — see _llm_translate().

Usage examples
--------------
    python scripts/translate_granular.py --input examples/classes/point.cpp
    python scripts/translate_granular.py --granularity function --input src/
    python scripts/translate_granular.py --granularity folder --input examples/ --target mojo

Summary table columns
---------------------
    granularity        — strategy used
    num_units          — number of independent translation units
    approx_tokens      — rough token estimate (chars / 4)
    translation_approach — brief description
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from typing import NamedTuple


# ---------------------------------------------------------------------------
# Token estimation
# ---------------------------------------------------------------------------

def _approx_tokens(text: str) -> int:
    """Very rough token estimate: 1 token ≈ 4 characters."""
    return max(1, len(text) // 4)


# ---------------------------------------------------------------------------
# C++ parser helpers (regex-based, no tree-sitter dependency)
# ---------------------------------------------------------------------------

#: Matches a top-level function definition opening brace.
#  Groups: (return_type_and_name, params)
_FUNC_SIG_RE = re.compile(
    r"""
    ^                                  # start of line
    (?![ \t]*(?:if|for|while|switch|else|do)\b)  # not a control-flow keyword
    (?P<ret>[\w:<>*&\s,]+?)            # return type (lazy)
    \s+
    (?P<name>~?[A-Za-z_][A-Za-z0-9_:~<>]*)  # function/method name
    \s*
    \((?P<params>[^)]*)\)              # parameter list
    \s*(?:const\s*)?                   # optional const qualifier
    \{                                 # opening brace
    """,
    re.VERBOSE | re.MULTILINE,
)

#: Matches a class/struct block (opening brace).
_CLASS_RE = re.compile(
    r"""
    ^[ \t]*
    (?P<kind>class|struct)\s+
    (?P<name>[A-Za-z_][A-Za-z0-9_]*)  # class name
    (?:\s*:\s*[^{]+)?                  # optional base class list
    \s*\{
    """,
    re.VERBOSE | re.MULTILINE,
)

#: Matches a #include directive (for dependency ordering).
_INCLUDE_RE = re.compile(r'^\s*#\s*include\s*[<"]([^>"]+)[>"]', re.MULTILINE)


def _extract_block(source: str, open_brace_pos: int) -> str:
    """Return the substring from open_brace_pos up to (and including) the
    matching closing brace, supporting nested braces."""
    depth = 0
    i = open_brace_pos
    while i < len(source):
        c = source[i]
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return source[open_brace_pos : i + 1]
        i += 1
    # Unbalanced — return the rest of the file.
    return source[open_brace_pos:]


# ---------------------------------------------------------------------------
# LLM stub
# ---------------------------------------------------------------------------

def _llm_translate(unit_source: str, target: str, context: str = "") -> str:
    """Stub for the actual LLM translation call.

    Replace this function with a real implementation that calls your
    preferred LLM API (Anthropic, OpenAI, local vLLM, …).

    Args:
        unit_source: The C++ source fragment to translate.
        target:      Target language ("python" or "mojo").
        context:     Optional surrounding context / imports to prepend.

    Returns:
        Translated source code as a string.
    """
    # --- LLM call goes here ---
    # Example (Anthropic):
    #   import anthropic
    #   client = anthropic.Anthropic()
    #   resp = client.messages.create(
    #       model="claude-opus-4-5",
    #       max_tokens=2048,
    #       messages=[{"role": "user", "content": prompt}],
    #   )
    #   return resp.content[0].text.strip()
    return f"# [TRANSLATED TO {target.upper()}]\n# Source had {_approx_tokens(unit_source)} tokens\n# {unit_source[:80].splitlines()[0]}..."


# ---------------------------------------------------------------------------
# Translation strategies
# ---------------------------------------------------------------------------

class TranslationUnit(NamedTuple):
    name: str       # human-readable label (function name, class name, …)
    source: str     # original C++ source for this unit


def _strategy_function(source: str) -> list[TranslationUnit]:
    """Parse top-level function definitions from *source*."""
    units: list[TranslationUnit] = []
    matches = list(_FUNC_SIG_RE.finditer(source))

    for m in matches:
        # Find the opening brace position in the full source.
        brace_pos = source.index("{", m.start())
        block = _extract_block(source, brace_pos)
        name = m.group("name")
        # Include the signature prefix before the brace.
        full_unit = source[m.start() : m.start() + (brace_pos - m.start())] + block
        units.append(TranslationUnit(name=name, source=full_unit))

    if not units:
        # Fallback: treat the whole file as a single unit.
        units.append(TranslationUnit(name="<file>", source=source))

    return units


def _strategy_class(source: str) -> list[TranslationUnit]:
    """Parse top-level class/struct blocks from *source*."""
    units: list[TranslationUnit] = []
    matches = list(_CLASS_RE.finditer(source))

    for m in matches:
        brace_pos = source.index("{", m.start())
        block = _extract_block(source, brace_pos)
        name = m.group("name")
        full_unit = source[m.start() : m.start() + (brace_pos - m.start())] + block
        units.append(TranslationUnit(name=name, source=full_unit))

    if not units:
        units.append(TranslationUnit(name="<file>", source=source))

    return units


def _strategy_file(path: Path) -> list[TranslationUnit]:
    """Return the whole file as a single translation unit."""
    source = path.read_text(errors="replace")
    return [TranslationUnit(name=path.name, source=source)]


def _strategy_folder(root: Path) -> list[TranslationUnit]:
    """Gather all .cpp/.h files in *root* and order them by dependency.

    Dependency ordering heuristic:
      - Header files (.h, .hpp) first (they are likely included by .cpp files).
      - Within each group, sort alphabetically.
      - When file A #includes file B (by stem match), A comes after B.
    """
    cpp_exts = {".cpp", ".cc", ".cxx", ".hpp", ".hh", ".h"}
    all_files = sorted(
        (f for f in root.rglob("*") if f.is_file() and f.suffix in cpp_exts),
        key=lambda f: (f.suffix not in {".h", ".hpp", ".hh"}, f.name),
    )

    if not all_files:
        return []

    # Build a stem → file map for dependency resolution.
    stem_map: dict[str, Path] = {f.stem: f for f in all_files}

    # Build adjacency list: file → set of files it depends on.
    deps: dict[Path, set[Path]] = {f: set() for f in all_files}
    for f in all_files:
        try:
            source = f.read_text(errors="replace")
        except OSError:
            continue
        for m in _INCLUDE_RE.finditer(source):
            inc = m.group(1)
            inc_stem = Path(inc).stem
            if inc_stem in stem_map and stem_map[inc_stem] != f:
                deps[f].add(stem_map[inc_stem])

    # Topological sort (Kahn's algorithm).
    in_degree: dict[Path, int] = {f: 0 for f in all_files}
    for f, d_set in deps.items():
        for dep in d_set:
            in_degree[f] += 1  # f depends on dep ⟹ dep comes first ⟹ f's in-degree increases

    queue = [f for f in all_files if in_degree[f] == 0]
    order: list[Path] = []
    while queue:
        node = queue.pop(0)
        order.append(node)
        # For every file that depends on `node`, decrement their in-degree.
        for f, d_set in deps.items():
            if node in d_set:
                in_degree[f] -= 1
                if in_degree[f] == 0:
                    queue.append(f)

    # Append any remaining (cyclic) files in original order.
    ordered_set = set(order)
    for f in all_files:
        if f not in ordered_set:
            order.append(f)

    units: list[TranslationUnit] = []
    for f in order:
        try:
            source = f.read_text(errors="replace")
        except OSError:
            continue
        units.append(TranslationUnit(name=str(f), source=source))

    return units


# ---------------------------------------------------------------------------
# Per-file orchestration
# ---------------------------------------------------------------------------

def translate_file(
    path: Path,
    granularity: str,
    target: str,
) -> tuple[list[TranslationUnit], list[str]]:
    """Return (units, translated_outputs) for a single file."""
    source = path.read_text(errors="replace")

    if granularity == "function":
        units = _strategy_function(source)
    elif granularity == "class":
        units = _strategy_class(source)
    else:
        units = _strategy_file(path)  # file-level baseline

    translated = [_llm_translate(u.source, target) for u in units]
    return units, translated


def translate_folder(
    root: Path,
    target: str,
) -> tuple[list[TranslationUnit], list[str]]:
    """Return (units, translated_outputs) for a whole folder."""
    units = _strategy_folder(root)
    translated = [_llm_translate(u.source, target) for u in units]
    return units, translated


# ---------------------------------------------------------------------------
# Summary table
# ---------------------------------------------------------------------------

def _print_summary(
    granularity: str,
    units: list[TranslationUnit],
    translated: list[str],
) -> None:
    approach_map = {
        "function": "Parse each function signature, translate independently, recombine",
        "class":    "Parse each class/struct block, translate independently, recombine",
        "file":     "Translate the whole file as one unit (baseline)",
        "folder":   "Topological dependency order across all files",
    }
    total_tokens = sum(_approx_tokens(u.source) for u in units)
    approach = approach_map.get(granularity, granularity)

    # Column widths
    col = {
        "granularity":           max(len("granularity"), len(granularity)),
        "num_units":             max(len("num_units"), len(str(len(units)))),
        "approx_tokens":         max(len("approx_tokens"), len(str(total_tokens))),
        "translation_approach":  max(len("translation_approach"), len(approach)),
    }

    row_fmt = (
        f"{{:<{col['granularity']}}}  "
        f"{{:>{col['num_units']}}}  "
        f"{{:>{col['approx_tokens']}}}  "
        f"{{:<{col['translation_approach']}}}"
    )
    sep = "  ".join("-" * w for w in col.values())

    print("\n" + row_fmt.format("granularity", "num_units", "approx_tokens", "translation_approach"))
    print(sep)
    print(row_fmt.format(granularity, len(units), total_tokens, approach))
    print()

    # Per-unit details
    if len(units) > 1:
        print("Units:")
        name_w = max(len(u.name) for u in units)
        for u in units:
            tok = _approx_tokens(u.source)
            print(f"  {u.name:<{name_w}}  {tok:>6} tokens")
        print()


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="translate_granular",
        description="Granularity-aware C++ → Python/Mojo translation driver (Issue #25).",
    )
    parser.add_argument(
        "--granularity",
        choices=["function", "class", "file", "folder"],
        default="file",
        help="Translation granularity (default: file).",
    )
    parser.add_argument(
        "--input",
        type=Path,
        required=True,
        help="Path to a .cpp/.h file or a directory containing such files.",
    )
    parser.add_argument(
        "--target",
        choices=["python", "mojo"],
        default="python",
        help="Target language (default: python).",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Write translated output to this file (default: stdout).",
    )
    args = parser.parse_args(argv)

    if not args.input.exists():
        print(f"Error: {args.input} does not exist.", file=sys.stderr)
        return 1

    # ---- Collect translation units ----------------------------------------
    all_units: list[TranslationUnit] = []
    all_translated: list[str] = []

    if args.granularity == "folder":
        root = args.input if args.input.is_dir() else args.input.parent
        units, translated = translate_folder(root, args.target)
        all_units.extend(units)
        all_translated.extend(translated)

    elif args.input.is_dir():
        # For function/class/file granularity applied to a directory:
        # process each eligible file individually.
        cpp_exts = {".cpp", ".cc", ".cxx", ".hpp", ".hh", ".h"}
        files = sorted(
            f for f in args.input.rglob("*")
            if f.is_file() and f.suffix in cpp_exts
        )
        if not files:
            print(f"No C++/header files found under {args.input}.", file=sys.stderr)
            return 1
        for f in files:
            units, translated = translate_file(f, args.granularity, args.target)
            all_units.extend(units)
            all_translated.extend(translated)

    else:
        # Single file.
        units, translated = translate_file(args.input, args.granularity, args.target)
        all_units.extend(units)
        all_translated.extend(translated)

    if not all_units:
        print("No translation units found.", file=sys.stderr)
        return 1

    # ---- Print summary -------------------------------------------------------
    _print_summary(args.granularity, all_units, all_translated)

    # ---- Emit translated output ----------------------------------------------
    combined = "\n\n".join(all_translated)
    if args.output:
        args.output.write_text(combined, encoding="utf-8")
        print(f"Translated output written to {args.output}")
    else:
        print("--- Translated output (stub) ---")
        print(combined)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
