#!/usr/bin/env python3
"""Migration status: compare an upstream/source repo ("before") with its port
("after") - lines of code, file/function counts, migration-map status and test
results - optionally across two git revisions of the port.

Standard library only, Python >= 3.10, so it runs under the system python3
(e.g. inside WSL) as well as under ``uv run``.

Subcommands
-----------
snapshot   Collect metrics for ONE repo/revision -> versioned JSON.
report     Render Markdown from one snapshot, a source/target(/baseline) set,
           or a before/after pair of snapshots with deltas.
compare    Convenience: snapshot source + target (+ a baseline revision of the
           target) and render the report in one go.

Examples
--------
    python scripts/migration_status.py snapshot --root ~/repo --out snap.json
    python scripts/migration_status.py report --source s.json --target t.json
    python scripts/migration_status.py report --before old.json --after new.json
    python scripts/migration_status.py compare --source ~/EnergyPlus \\
        --source-include src/EnergyPlus --target ~/EnergyPlusMojo \\
        --map ~/EnergyPlusMojo/.migration_progress/MIGRATION_MAP.md \\
        --baseline-rev HEAD~200 --target-tests "unit=python -m pytest tests/unit -q"

How the numbers are produced (READ THIS before quoting them)
-------------------------------------------------------------
* Lines of code are split into code / comment / blank by a small per-language
  scanner (line-comment and block-comment markers, string literals skipped, so
  ``"//"`` inside a string is not a comment). Python and Mojo triple-quoted
  strings that START a line are counted as comments (docstrings); other
  multi-line strings are counted as code. Mixed lines (code followed by a
  trailing comment) count as code. The counts are APPROXIMATE: the scanner does
  not lex raw strings, line-continued ``//`` comments, or preprocessor
  conditionals. Spot check: C/C++ code lines were within 0.1% of tokei on
  EnergyPlus src/EnergyPlus; tokei counts Python docstrings as code, so Python
  and Mojo "code" here is lower than tokei's. cloc was not compared. Neither
  tool is invoked or required.
* "Production" versus "test" code is decided by path convention only:
  a ``tests``/``test``/``tst``/``__tests__``/``spec`` directory, ``test_*``,
  ``*_test.*``, ``*.test.*``, ``*.spec.*``, ``*.unit.*``, ``conftest.py``.
* Function and class counts: Python uses ``ast`` (exact for files that parse;
  regex fallback otherwise). Mojo uses regexes on ``fn``/``def``/``struct``/
  ``trait``. C/C++ uses a brace-depth heuristic (no libclang): function bodies
  are recognised by ``) ... {`` at namespace/class scope, so macros that look
  like functions (e.g. gtest ``TEST_F(...) {``) count as functions, only the first branch of each preprocessor
  conditional is counted, and the numbers are labelled approximate. Rust and
  Fortran use simple regexes. Other languages are not counted.
* "Declared test functions" is a STATIC count (Python ``test_*`` functions,
  gtest-style ``TEST*`` macros, Mojo ``test_*``): it does not expand
  parametrisation, so it is not the number of tests pytest would collect.
* Test results are only reported when a test command was actually run now
  (``--tests``) or collected (``--collect``). A pass count is never reported
  when the command timed out or ended before a summary: it is "unknown".
* Migration map: ``| Upstream File | Status | ... |`` Markdown tables. Rows are
  joined to upstream files by file stem (basename without extension), so a
  ``Foo.cc`` row also covers ``Foo.hh``. Same-stem files in different
  directories are all attributed to the row; unmatched files are reported as
  UNMAPPED rather than dropped.
"""

from __future__ import annotations

import argparse
import ast
import base64
import datetime as dt
import fnmatch
import json
import math
import os
import re
import shlex
import signal
import subprocess
import sys
import tarfile
import tempfile
import time
import warnings
import xml.etree.ElementTree as ET
from dataclasses import dataclass, field
from pathlib import Path

SCHEMA_VERSION = 1
TOOL_VERSION = "0.1.0"

MAP_STATUSES = ("COMPLETE", "PARTIAL", "NOT_STARTED")
_STATUS_RANK = {"NOT_STARTED": 0, "PARTIAL": 1, "COMPLETE": 2}

DEFAULT_EXCLUDES = (
    ".git", ".hg", ".svn", ".pixi", ".venv", "venv", "node_modules", "__pycache__",
    ".mypy_cache", ".pytest_cache", ".ruff_cache", ".tox", "build", "dist",
)
DEFAULT_MAX_FILE_BYTES = 5_000_000
TEST_DIR_NAMES = frozenset({"tests", "test", "tst", "__tests__", "spec", "specs"})
DEFAULT_TEST_TIMEOUT = 3600
FUNCTIONS_LABEL = "Production functions (~ = includes heuristic counts)"


# ---------------------------------------------------------------------------
# Language table
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class LangSpec:
    key: str
    label: str
    exts: tuple[str, ...]
    style: str  # "hash" | "c" | "fortran"
    line_markers: tuple[str, ...] = ()
    block: tuple[str, str] | None = None
    nested: bool = False
    quotes: str = ""
    symbols: str | None = None  # "python" | "mojo" | "cpp" | "rust" | "fortran"
    approx_symbols: bool = False


LANGS: tuple[LangSpec, ...] = (
    LangSpec("python", "Python", (".py", ".pyi"), "hash", symbols="python"),
    LangSpec("mojo", "Mojo", (".mojo", ".\U0001F525"), "hash", symbols="mojo", approx_symbols=True),
    LangSpec(
        "c_cpp", "C/C++",
        (".c", ".cc", ".cpp", ".cxx", ".c++", ".h", ".hh", ".hpp", ".hxx", ".h++", ".inl"),
        "c", ("//",), ("/*", "*/"), False, "\"'", symbols="cpp", approx_symbols=True,
    ),
    LangSpec("rust", "Rust", (".rs",), "c", ("//",), ("/*", "*/"), True, '"', "rust", True),
    LangSpec(
        "fortran", "Fortran",
        (".f90", ".f95", ".f03", ".f08", ".f", ".for", ".f77", ".ftn", ".fpp"),
        "fortran", ("!",), None, False, "\"'", "fortran", True,
    ),
    LangSpec("java", "Java", (".java",), "c", ("//",), ("/*", "*/"), False, "\"'"),
    LangSpec("typescript", "TypeScript", (".ts", ".tsx", ".mts", ".cts"), "c", ("//",), ("/*", "*/"), False, "\"'`"),
    LangSpec("javascript", "JavaScript", (".js", ".jsx", ".mjs", ".cjs"), "c", ("//",), ("/*", "*/"), False, "\"'`"),
    LangSpec("csharp", "C#", (".cs",), "c", ("//",), ("/*", "*/"), False, "\"'"),
)
LANG_BY_EXT: dict[str, LangSpec] = {ext: spec for spec in LANGS for ext in spec.exts}
LANG_BY_KEY: dict[str, LangSpec] = {spec.key: spec for spec in LANGS}
FIXED_FORM_EXTS = frozenset({".f", ".for", ".f77", ".ftn"})
C_FAMILY_EXTS = frozenset(LANG_BY_KEY["c_cpp"].exts)


def lang_for(path: str) -> LangSpec | None:
    """Language of a path by (lower-cased) extension, or None if unrecognised."""
    return LANG_BY_EXT.get(Path(path).suffix.lower())


# ---------------------------------------------------------------------------
# Line scanner: code / comment / blank
# ---------------------------------------------------------------------------


@dataclass
class ScanResult:
    code: int = 0
    comment: int = 0
    blank: int = 0
    code_lines: list[str] = field(default_factory=list)  # code with comments removed


def split_lines(text: str) -> list[str]:
    """Split on ``\\n`` only (so form feeds etc. do not add lines), dropping CRs."""
    if not text:
        return []
    lines = text.split("\n")
    if lines[-1] == "":
        lines.pop()
    return [ln[:-1] if ln.endswith("\r") else ln for ln in lines]


_DOC_OPEN = re.compile(r"^[rRuUbBfF]{0,2}(\"\"\"|''')")


def _scan_hash(lines: list[str]) -> ScanResult:
    res = ScanResult()
    delim: str | None = None
    kind = ""
    for line in lines:
        s = line.strip()
        if delim:
            if not s:
                res.blank += 1
                continue
            if kind == "doc":
                res.comment += 1
            else:
                res.code += 1
                res.code_lines.append(line)
            if delim in s:
                delim = None
            continue
        if not s:
            res.blank += 1
        elif s.startswith("#"):
            res.comment += 1
        else:
            m = _DOC_OPEN.match(s)
            if m:
                res.comment += 1
                if m.group(1) not in s[m.end():]:
                    delim, kind = m.group(1), "doc"
                continue
            res.code += 1
            res.code_lines.append(line)
            for d in ('"""', "'''"):
                if line.count(d) % 2 == 1:
                    delim, kind = d, "str"
                    break
    return res


def _string_end(line: str, pos: int, quote: str) -> int:
    """Index just past the closing quote of a string starting before ``pos``."""
    n = len(line)
    while pos < n:
        ch = line[pos]
        if ch == "\\":
            pos += 2
            continue
        if ch == quote:
            return pos + 1
        pos += 1
    return n


def _c_regexes(spec: LangSpec) -> tuple[re.Pattern[str], re.Pattern[str] | None]:
    parts = [re.escape(m) for m in spec.line_markers]
    close_parts: list[str] = []
    if spec.block:
        parts.append(re.escape(spec.block[0]))
        close_parts.append(re.escape(spec.block[1]))
        if spec.nested:
            close_parts.append(re.escape(spec.block[0]))
    parts.extend(re.escape(q) for q in spec.quotes)
    tok = re.compile("|".join(parts))
    return tok, (re.compile("|".join(close_parts)) if close_parts else None)


def _scan_c_like(lines: list[str], spec: LangSpec, fixed_form: bool = False) -> ScanResult:
    res = ScanResult()
    tok_re, close_re = _c_regexes(spec)
    opener = spec.block[0] if spec.block else None
    closer = spec.block[1] if spec.block else None
    depth = 0
    for line in lines:
        if not line.strip():
            res.blank += 1
            continue
        if fixed_form and depth == 0 and line[0] in "cC*!":
            res.comment += 1
            continue
        if depth == 0 and not tok_re.search(line):
            res.code += 1
            res.code_lines.append(line)
            continue
        has_code, has_comment, code_part, depth = _scan_line(
            line, tok_re, close_re, spec, opener, closer, depth
        )
        if has_code:
            res.code += 1
            res.code_lines.append(code_part)
        elif has_comment:
            res.comment += 1
        else:
            res.blank += 1
    return res


def _scan_line(line, tok_re, close_re, spec, opener, closer, depth):
    pos, n = 0, len(line)
    has_code = has_comment = False
    out: list[str] = []
    while pos < n:
        if depth > 0:
            has_comment = True
            m = close_re.search(line, pos) if close_re else None
            if not m:
                break
            depth += -1 if m.group() == closer else 1
            pos = m.end()
            continue
        m = tok_re.search(line, pos)
        seg = line[pos:m.start()] if m else line[pos:]
        if seg.strip():
            has_code = True
        out.append(seg)
        if not m:
            break
        tok = m.group()
        if tok in spec.line_markers:
            has_comment = True
            break
        if opener and tok == opener:
            depth, has_comment, pos = 1, True, m.end()
            continue
        end = _string_end(line, m.end(), tok)  # a quote character
        out.append(line[m.start():end])
        has_code = True
        pos = end
    return has_code, has_comment, "".join(out), depth


def scan_text(text: str, spec: LangSpec, fixed_form: bool = False) -> ScanResult:
    """Classify every line of ``text`` as code / comment / blank for ``spec``."""
    lines = split_lines(text)
    if spec.style == "hash":
        return _scan_hash(lines)
    return _scan_c_like(lines, spec, fixed_form)


# ---------------------------------------------------------------------------
# Symbol counting (functions / classes / declared tests)
# ---------------------------------------------------------------------------


@dataclass
class Symbols:
    functions: int | None = None
    classes: int | None = None
    declared_tests: int = 0
    parse_error: bool = False


_PY_DEF = re.compile(r"^\s*(?:async\s+)?def\s+(\w+)", re.MULTILINE)
_PY_CLASS = re.compile(r"^\s*class\s+\w+", re.MULTILINE)


def count_python(text: str, want_tests: bool) -> Symbols:
    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        try:
            tree = ast.parse(text)
        except (SyntaxError, ValueError, RecursionError, MemoryError):
            names = _PY_DEF.findall(text)
            tests = sum(1 for n in names if n.startswith("test"))
            return Symbols(len(names), len(_PY_CLASS.findall(text)), tests if want_tests else 0, True)
    funcs = classes = 0
    for node in ast.walk(tree):
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            funcs += 1
        elif isinstance(node, ast.ClassDef):
            classes += 1
    tests = _python_declared_tests(tree) if want_tests else 0
    return Symbols(funcs, classes, tests)


def _python_declared_tests(tree: ast.Module) -> int:
    """Module-level ``test*`` functions plus ``test*`` methods of ``Test*`` classes."""
    fn_types = (ast.FunctionDef, ast.AsyncFunctionDef)
    total = 0
    for node in tree.body:
        if isinstance(node, fn_types) and node.name.startswith("test"):
            total += 1
        elif isinstance(node, ast.ClassDef) and node.name.startswith("Test"):
            total += sum(
                1 for m in node.body if isinstance(m, fn_types) and m.name.startswith("test")
            )
    return total


_MOJO_FN = re.compile(r"^\s*(?:@\w+(?:\([^)]*\))?\s+)*(?:fn|def)\s+([A-Za-z_]\w*)", re.MULTILINE)
_MOJO_TYPE = re.compile(r"^\s*(?:@\w+(?:\([^)]*\))?\s+)*(?:struct|trait)\s+[A-Za-z_]\w*", re.MULTILINE)


def count_mojo(code_text: str, want_tests: bool) -> Symbols:
    names = _MOJO_FN.findall(code_text)
    tests = sum(1 for n in names if n.startswith("test_")) if want_tests else 0
    return Symbols(len(names), len(_MOJO_TYPE.findall(code_text)), tests)


_RUST_FN = re.compile(r"\bfn\s+[A-Za-z_]\w*")
_RUST_TYPE = re.compile(r"^\s*(?:pub(?:\([^)]*\))?\s+)?(?:struct|enum|trait)\s+[A-Za-z_]\w*", re.MULTILINE)
_RUST_TEST = re.compile(r"#\[(?:\w+::)?test\]")


def count_rust(code_text: str, want_tests: bool) -> Symbols:
    tests = len(_RUST_TEST.findall(code_text)) if want_tests else 0
    return Symbols(len(_RUST_FN.findall(code_text)), len(_RUST_TYPE.findall(code_text)), tests)


_F_PROC = re.compile(
    r"^[ \t]*(?!end\b)(?:[\w()*=,]+[ \t]+)*(?:function|subroutine)[ \t]+[A-Za-z_]\w*",
    re.MULTILINE | re.IGNORECASE,
)


def count_fortran(code_text: str) -> Symbols:
    return Symbols(len(_F_PROC.findall(code_text)), None)


# --- C / C++ -----------------------------------------------------------------

_STR_LITERAL = re.compile(r"\"(?:\\.|[^\"\\\n])*\"|'(?:\\.|[^'\\\n])*'")
_PREPROC = re.compile(r"^[ \t]*#(?:[^\n]*\\\n)*[^\n]*", re.MULTILINE)
_BRACE = re.compile(r"[{};]")
_TEMPLATE_PARAMS = re.compile(r"template\s*<[^<>]*(?:<[^<>]*>[^<>]*)*>")
_OPERATOR = re.compile(r"operator\s*(?:\(\)|[^\s(]+)")
_ASSIGN = re.compile(r"(?<![=!<>])=(?!=)")
_INIT_COLON = re.compile(r"\)\s*(?:(?:const|noexcept\(\)|noexcept|volatile)\s*)*:(?!:)")
_FUNC_TAIL = re.compile(
    r"\)\s*(?:(?:const|volatile|noexcept\(\)|noexcept|override|final|&&|&|=\s*0|"
    r"->\s*[\w:<>\s*&,]+?)\s*)*$"
)
_CONTROL_WORDS = frozenset({"if", "for", "while", "switch", "catch", "else", "do", "return", "sizeof"})
_CPP_TEST_MACRO = re.compile(
    r"^\s*(?:TEST|TEST_F|TEST_P|TYPED_TEST|TYPED_TEST_P|TEST_CASE|BOOST_AUTO_TEST_CASE|SCENARIO)\s*\(",
    re.MULTILINE,
)


def _flatten_parens(header: str) -> str:
    """Drop the contents of balanced parentheses, keeping ``()``."""
    out: list[str] = []
    depth = 0
    for ch in header:
        if ch == "(":
            depth += 1
            if depth == 1:
                out.append("(")
        elif ch == ")":
            if depth == 1:
                out.append(")")
            depth = max(0, depth - 1)
        elif depth == 0:
            out.append(ch)
    return "".join(out)


def classify_cpp_header(header: str) -> str:
    """Return 'ns', 'type', 'func', 'init' or 'block' for the text before a ``{``."""
    flat = _TEMPLATE_PARAMS.sub("", _flatten_parens(header)).strip()
    if not flat:
        return "block"
    if re.match(r'^extern\s*""$', flat):
        return "ns"
    if re.search(r"\bnamespace\b", flat) and "(" not in flat:
        return "ns"
    if re.search(r"\benum\b", flat):
        return "block"
    if re.search(r"\b(?:class|struct|union)\b", flat) and "(" not in flat and "=" not in flat:
        return "type"
    flat = _OPERATOR.sub("operator", flat)
    if _ASSIGN.search(flat):
        return "block"
    if _INIT_COLON.search(flat):
        return "init" if re.search(r"[\w>]$", flat) else "func"
    if "(" in flat and _FUNC_TAIL.search(flat):
        m = re.search(r"([~\w:<>]+)\s*\(", flat)
        if m and m.group(1) not in _CONTROL_WORDS:
            return "func"
    return "block"


_PP_DIRECTIVE = re.compile(r"^\s*#\s*(if|ifdef|ifndef|elif|else|endif)\b\s*(.*)$")


def select_first_branches(lines: list[str]) -> list[str]:
    """Drop ``#else``/``#elif`` branches (and ``#if 0`` bodies) so braces stay balanced.

    The first branch of every conditional is kept, which is what makes
    ``#ifdef X {...} #else {...} #endif`` count once instead of twice.
    """
    out: list[str] = []
    stack: list[list[bool]] = []  # [parent_emitting, branch_emitting, branch_taken]
    emitting = True
    for line in lines:
        m = _PP_DIRECTIVE.match(line)
        if m:
            kind = m.group(1)
            if kind in ("if", "ifdef", "ifndef"):
                live = emitting and m.group(2).split("//")[0].strip() != "0"
                stack.append([emitting, live, live])
            elif kind in ("elif", "else") and stack:
                top = stack[-1]
                top[1] = top[0] and not top[2]
                top[2] = top[2] or top[1]
            elif kind == "endif" and stack:
                stack.pop()
            emitting = stack[-1][1] if stack else True
        if emitting:
            out.append(line)
    return out


def count_cpp(code_text: str, want_tests: bool) -> Symbols:
    """Approximate function/class counts via brace depth (see module docstring)."""
    flattened = "\n".join(select_first_branches(code_text.split("\n")))
    code = _PREPROC.sub("", _STR_LITERAL.sub('""', flattened))
    stack: list[str] = []
    funcs = classes = 0
    start = 0
    for m in _BRACE.finditer(code):
        ch, i = m.group(), m.start()
        inside = bool(stack) and stack[-1] in ("func", "block", "init")
        if ch == ";":
            if not inside:
                start = i + 1
        elif ch == "{":
            kind = "block" if inside else classify_cpp_header(code[start:i])
            funcs += kind == "func"
            if kind == "type" and not re.search(r"\bunion\b", code[start:i]):
                classes += 1
            stack.append(kind)
            if kind in ("ns", "type"):
                start = i + 1
        elif stack:  # "}"
            kind = stack.pop()
            if kind != "init" and not (stack and stack[-1] in ("func", "block", "init")):
                start = i + 1
    tests = len(_CPP_TEST_MACRO.findall(code_text)) if want_tests else 0
    return Symbols(funcs, classes, tests)


def count_symbols(spec: LangSpec, text: str, scan: ScanResult, want_tests: bool) -> Symbols:
    """Dispatch symbol counting by language (None counts for unsupported languages)."""
    if spec.symbols == "python":
        return count_python(text, want_tests)
    code_text = "\n".join(scan.code_lines)
    if spec.symbols == "mojo":
        return count_mojo(code_text, want_tests)
    if spec.symbols == "cpp":
        return count_cpp(code_text, want_tests)
    if spec.symbols == "rust":
        return count_rust(code_text, want_tests)
    if spec.symbols == "fortran":
        return count_fortran(code_text)
    return Symbols()


# ---------------------------------------------------------------------------
# File discovery
# ---------------------------------------------------------------------------


def is_test_path(rel: str) -> bool:
    """True if ``rel`` (posix, relative) looks like test code by path convention."""
    p = Path(rel)
    parts = [x.lower() for x in p.parts]
    if any(x in TEST_DIR_NAMES for x in parts[:-1]):
        return True
    name = p.name.lower()
    stem = name.split(".")[0]
    if name == "conftest.py" or stem.startswith("test_") or stem == "test":
        return True
    if stem.endswith(("_test", "_tests")):
        return True
    if any(f".{tag}." in name for tag in ("test", "spec", "unit")):
        return True
    spec = lang_for(rel)
    return bool(spec and spec.key in ("java", "csharp") and p.stem.endswith(("Test", "Tests")))


def _matches_pattern(rel: str, pattern: str) -> bool:
    pat = pattern.replace("\\", "/").strip("/")
    if "/" not in pat:
        return any(fnmatch.fnmatch(part, pat) for part in rel.split("/"))
    return rel == pat or rel.startswith(pat + "/") or fnmatch.fnmatch(rel, pat)


def in_includes(rel: str, includes: list[str]) -> bool:
    """True if ``rel`` is under one of the root-relative include paths (all if none given)."""
    if not includes:
        return True
    prefixes = [i.replace("\\", "/").strip("/") for i in includes]
    return any(rel == p or rel.startswith(p + "/") for p in prefixes)


def is_excluded(rel: str, patterns: list[str]) -> bool:
    return any(_matches_pattern(rel, p) for p in patterns)


@dataclass
class SkipCounts:
    binary: int = 0
    too_large: int = 0
    unreadable: int = 0
    symlink: int = 0

    def as_dict(self) -> dict[str, int]:
        return {"binary": self.binary, "too_large": self.too_large,
                "unreadable": self.unreadable, "symlink": self.symlink}


def git_tracked_files(root: Path) -> set[str]:
    """Paths (posix, relative to ``root``) tracked by git in ``root``."""
    out = _git(root, "ls-files", "-z", "--cached")
    return {p for p in out.split("\0") if p}


def walk_files(root: Path, includes: list[str], excludes: list[str],
               tracked: set[str] | None, skips: SkipCounts) -> list[tuple[str, Path]]:
    """Recognised-language files under ``root`` as ``(posix relpath, abspath)``."""
    found: dict[str, Path] = {}
    starts = [root / inc for inc in includes] if includes else [root]
    for start in starts:
        if start.is_file():
            _consider(root, start, excludes, tracked, skips, found)
            continue
        for dirpath, dirnames, filenames in os.walk(start, followlinks=False):
            here = Path(dirpath)
            dirnames[:] = sorted(
                d for d in dirnames if not is_excluded(_rel(root, here / d), excludes)
            )
            for fn in sorted(filenames):
                _consider(root, here / fn, excludes, tracked, skips, found)
    return sorted(found.items())


def _rel(root: Path, path: Path) -> str:
    return path.relative_to(root).as_posix()


def _consider(root, path, excludes, tracked, skips, found) -> None:
    rel = _rel(root, path)
    if lang_for(rel) is None or is_excluded(rel, excludes):
        return
    if tracked is not None and rel not in tracked:
        return
    if path.is_symlink():
        skips.symlink += 1
        return
    found[rel] = path


@dataclass
class FileMetrics:
    rel: str
    lang: str
    is_test: bool
    code: int
    comment: int
    blank: int
    symbols: Symbols


def read_text(path: Path, max_bytes: int, skips: SkipCounts) -> str | None:
    """Decoded file text, or None (and a skip count) if binary/huge/unreadable."""
    try:
        size = path.stat().st_size
        if size > max_bytes:
            skips.too_large += 1
            return None
        data = path.read_bytes()
    except OSError:
        skips.unreadable += 1
        return None
    if b"\0" in data[:8192]:
        skips.binary += 1
        return None
    return data.decode("utf-8", errors="replace")


def analyse_file(rel: str, text: str) -> FileMetrics:
    spec = lang_for(rel)
    assert spec is not None
    fixed = Path(rel).suffix.lower() in FIXED_FORM_EXTS
    scan = scan_text(text, spec, fixed)
    test = is_test_path(rel)
    return FileMetrics(rel, spec.key, test, scan.code, scan.comment, scan.blank,
                       count_symbols(spec, text, scan, test))


# ---------------------------------------------------------------------------
# Git helpers
# ---------------------------------------------------------------------------


def _git(root: Path, *args: str) -> str:
    proc = subprocess.run(
        ["git", "--no-optional-locks", "-C", str(root), *args],
        capture_output=True, text=True, errors="replace",
    )
    if proc.returncode != 0:
        raise RuntimeError(f"git {' '.join(args)} failed in {root}: {proc.stderr.strip()}")
    return proc.stdout


def git_info(root: Path) -> dict | None:
    """Commit, date, branch and dirtiness of ``root`` (read-only), or None."""
    try:
        commit = _git(root, "rev-parse", "HEAD").strip()
        date = _git(root, "log", "-1", "--format=%cI", "HEAD").strip()
        branch = _git(root, "rev-parse", "--abbrev-ref", "HEAD").strip()
        dirty = bool(_git(root, "status", "--porcelain", "--untracked-files=no").strip())
    except (RuntimeError, OSError):
        return None
    return {"commit": commit, "commit_date": date, "branch": branch, "dirty": dirty}


def resolve_revision(root: Path, rev: str) -> dict:
    sha = _git(root, "rev-parse", "--verify", f"{rev}^{{commit}}").strip()
    date = _git(root, "log", "-1", "--format=%cI", sha).strip()
    return {"commit": sha, "commit_date": date, "requested": rev}


def rev_before(root: Path, when: str) -> str:
    """Newest commit reachable from HEAD that is older than ``when`` (git date syntax)."""
    sha = _git(root, "rev-list", "-1", f"--before={when}", "HEAD").strip()
    if not sha:
        raise RuntimeError(f"no commit before {when!r} reachable from HEAD in {root}")
    return sha


def export_revision(root: Path, rev: str, dest: Path, includes: list[str], excludes: list[str],
                    extra: list[str] | None = None) -> int:
    """Extract the files of ``rev`` that pass the include/exclude filter into ``dest``.

    Streams ``git archive`` and writes only regular files; the real worktree is
    never touched. ``extra`` are additional relative paths always extracted.
    Returns the number of files written.
    """
    proc = subprocess.Popen(
        ["git", "-C", str(root), "archive", "--format=tar", rev],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    )
    written = 0
    dest_resolved = dest.resolve()
    keep_extra = {e.replace("\\", "/").strip("/") for e in (extra or [])}
    assert proc.stdout is not None
    with tarfile.open(fileobj=proc.stdout, mode="r|") as tar:
        for member in tar:
            if not member.isreg():
                continue
            rel = member.name.lstrip("./")
            wanted = rel in keep_extra or (
                lang_for(rel) is not None
                and not is_excluded(rel, excludes)
                and in_includes(rel, includes)
            )
            target = (dest / rel).resolve()
            if not wanted or dest_resolved not in target.parents:
                continue
            target.parent.mkdir(parents=True, exist_ok=True)
            src = tar.extractfile(member)
            if src is not None:
                target.write_bytes(src.read())
                written += 1
    err = proc.stderr.read().decode("utf-8", "replace") if proc.stderr else ""
    if proc.wait() != 0:
        raise RuntimeError(f"git archive {rev} failed in {root}: {err.strip()}")
    return written


# ---------------------------------------------------------------------------
# Migration map
# ---------------------------------------------------------------------------

_PIPE_SPLIT = re.compile(r"\|(?=(?:[^`]*`[^`]*`)*[^`]*$)")
_STATUS_RE = re.compile(r"\b(COMPLETE|PARTIAL|NOT[_ -]STARTED)\b", re.IGNORECASE)
_GENERATED_RE = re.compile(r"Generated:\*{0,2}\s*(\d{4}-\d{2}-\d{2})")
_BACKTICK = re.compile(r"`([^`]+)`")
_FILE_LIKE = re.compile(r"[\w+.-]+\.(?:cc|cpp|cxx|c|hh|hpp|hxx|h|f90|f|for)\b", re.IGNORECASE)
_KNOWN_EXTS = tuple(sorted({e.lstrip(".") for s in LANGS for e in s.exts}, key=len, reverse=True))


@dataclass
class MapRow:
    key: str  # file stem
    status: str
    upstream: str
    target_modules: str = ""
    kernels: str = ""


@dataclass
class MapData:
    rows: list[MapRow] = field(default_factory=list)
    malformed: list[str] = field(default_factory=list)
    non_data_rows: int = 0
    generated: str | None = None


def _stem_key(token: str) -> str:
    """Stem of the first file-like word of ``token`` (``Foo.cc`` -> ``Foo``)."""
    word = token.strip().split()[0] if token.strip() else ""
    word = word.replace("\\", "/").rsplit("/", 1)[-1]
    low = word.lower()
    for ext in _KNOWN_EXTS:
        if low.endswith("." + ext):
            return word[: -(len(ext) + 1)]
    return word


def _row_keys(first_cell: str) -> list[str]:
    tokens = _BACKTICK.findall(first_cell) or [first_cell.replace("*", "")]
    keys = [_stem_key(t) for t in tokens if t.strip()]
    return [k for k in keys if re.fullmatch(r"[\w+.-]+", k)]


def parse_migration_map(text: str) -> MapData:
    """Parse ``| Upstream File | Status | Target | ... |`` rows from Markdown.

    Tolerant of extra columns and sections. A row with a file-like first cell but
    an unrecognised status (or too few cells) is recorded as malformed; header,
    separator and summary rows are counted as non-data rows.
    """
    data = MapData()
    stamp = _GENERATED_RE.search(text)
    data.generated = stamp.group(1) if stamp else None
    for raw in text.splitlines():
        line = raw.strip()
        if not line.startswith("|"):
            continue
        cells = [c.strip() for c in _PIPE_SPLIT.split(line)[1:-1]]
        if len(cells) < 2 or set("".join(cells)) <= set("-: "):
            if len(cells) < 2 and _FILE_LIKE.search(line):
                data.malformed.append(line[:160])
            else:
                data.non_data_rows += 1
            continue
        m = _STATUS_RE.search(cells[1].replace("*", "").replace("`", ""))
        keys = _row_keys(cells[0])
        if not m or not keys:
            if _BACKTICK.search(cells[0]) and cells[0].lower() != "upstream file" and not m:
                data.malformed.append(line[:160])
            else:
                data.non_data_rows += 1
            continue
        status = m.group(1).upper().replace(" ", "_").replace("-", "_")
        extra = [c.replace("`", "") for c in cells[2:]]
        for key in keys:
            data.rows.append(MapRow(key, status, cells[0].replace("`", ""),
                                    extra[0] if extra else "", extra[1] if len(extra) > 2 else ""))
    return data


def best_status_by_key(rows: list[MapRow]) -> tuple[dict[str, str], int]:
    """Highest-ranked status per stem (as migraph does) and the duplicate-row count."""
    best: dict[str, str] = {}
    dupes = 0
    for row in rows:
        if row.key in best:
            dupes += 1
            if _STATUS_RANK[row.status] <= _STATUS_RANK[best[row.key]]:
                continue
        best[row.key] = row.status
    return best, dupes


def map_summary(data: MapData, path: str) -> dict:
    best, dupes = best_status_by_key(data.rows)
    counts = {s: 0 for s in MAP_STATUSES}
    for status in best.values():
        counts[status] += 1
    return {
        "path": path,
        "data_rows": len(data.rows),
        "unique_modules": len(best),
        "duplicate_rows": dupes,
        "status_counts": counts,
        "malformed_rows": data.malformed[:10],
        "malformed_row_count": len(data.malformed),
        "non_data_rows": data.non_data_rows,
        "generated_header": data.generated,
        "join": None,
    }


def join_map_to_files(data: MapData, files: list[dict]) -> dict:
    """Attribute upstream production files (by stem) to map statuses.

    ``files`` entries need ``path``, ``code`` and ``is_test``. Test files are
    ignored. Every production file lands in exactly one of COMPLETE / PARTIAL /
    NOT_STARTED / UNMAPPED, so the shares add up to the upstream total.
    """
    best, _ = best_status_by_key(data.rows)
    buckets = {s: {"files": 0, "code": 0} for s in (*MAP_STATUSES, "UNMAPPED")}
    stem_dirs: dict[str, set[str]] = {}
    seen_stems: set[str] = set()
    unmapped_examples: list[tuple[int, str]] = []
    for f in files:
        if f["is_test"]:
            continue
        stem = _stem_key(Path(f["path"]).name)
        stem_dirs.setdefault(stem, set()).add(str(Path(f["path"]).parent))
        seen_stems.add(stem)
        status = best.get(stem, "UNMAPPED")
        buckets[status]["files"] += 1
        buckets[status]["code"] += f["code"]
        if status == "UNMAPPED":
            unmapped_examples.append((f["code"], f["path"]))
    total_code = sum(b["code"] for b in buckets.values())
    total_files = sum(b["files"] for b in buckets.values())
    for b in buckets.values():
        b["code_share"] = (b["code"] / total_code) if total_code else None
    unmapped_examples.sort(reverse=True)
    return {
        "metric": "code lines of production files, joined to map rows by file stem",
        "upstream_files": total_files,
        "upstream_code": total_code,
        "by_status": buckets,
        "map_keys_without_upstream_file": sorted(k for k in best if k not in seen_stems),
        "ambiguous_stems": sum(1 for d in stem_dirs.values() if len(d) > 1),
        "largest_unmapped": [{"path": p, "code": c} for c, p in unmapped_examples[:10]],
    }


def find_default_map(target_root: Path) -> Path | None:
    for rel in (".migration_progress/MIGRATION_MAP.md", "MIGRATION_MAP.md",
                "docs/MIGRATION_MAP.md"):
        if (target_root / rel).is_file():
            return target_root / rel
    return None


# ---------------------------------------------------------------------------
# Test running and result parsing
# ---------------------------------------------------------------------------

_COUNT_RE = re.compile(
    r"(\d+) (passed|failed|skipped|errors?|xfailed|xpassed|warnings?|deselected|rerun)\b"
)
_DURATION_TAIL = re.compile(r"\bin (\d+(?:\.\d+)?)s\b(?: \((\d+:\d{2}:\d{2})\))?\s*$")
_COLLECTED_RE = re.compile(r"(\d+)(?:/(\d+))? tests? collected")


def _normalise_counts(pairs: list[tuple[str, str]]) -> dict[str, int]:
    keys = {"passed": "passed", "failed": "failed", "skipped": "skipped", "error": "errors",
            "errors": "errors", "xfailed": "xfailed", "xpassed": "xpassed",
            "warning": "warnings", "warnings": "warnings", "deselected": "deselected",
            "rerun": "rerun"}
    out: dict[str, int] = {}
    for num, word in pairs:
        out[keys[word]] = out.get(keys[word], 0) + int(num)
    return out


def parse_pytest_summary(output: str) -> dict | None:
    """Parse pytest's final summary line (``=== 3 failed, 5 passed in 1.2s ===``).

    Returns ``{"counts": {...}, "duration_s": float, "line": str}``; counts that
    pytest omits are absent (treat as zero). ``None`` if no summary was found
    (crash, timeout, collection abort without a summary). ``no tests ran`` gives
    empty counts.
    """
    for raw in reversed(output.splitlines()[-300:]):
        line = raw.strip().strip("=").strip()
        dur = _DURATION_TAIL.search(line)
        if not dur:
            continue
        head = line[: dur.start()].strip()
        if head.startswith("no tests ran"):
            return {"counts": {}, "duration_s": float(dur.group(1)), "line": line}
        if re.match(r"^\d+ (passed|failed|skipped|errors?|xfailed|xpassed|deselected|warnings?)\b", head):
            counts = _normalise_counts(_COUNT_RE.findall(head))
            return {"counts": counts, "duration_s": float(dur.group(1)), "line": line}
    return None


def parse_collect_output(output: str) -> dict | None:
    """Parse ``--collect-only`` output: ``N tests collected in Xs`` (also ``N/M ... (K deselected)``)."""
    for raw in reversed(output.splitlines()[-300:]):
        line = raw.strip().strip("=").strip()
        if "no tests collected" in line:
            return {"collected": 0, "errors": _errors_in(line), "line": line}
        m = _COLLECTED_RE.search(line)
        if m:
            return {"collected": int(m.group(1)), "errors": _errors_in(line), "line": line}
    ids = [ln for ln in output.splitlines() if "::" in ln and not ln.startswith((" ", "ERROR", "FAILED"))]
    if ids and re.search(r"\b(?:passed|failed|collected)\b|in \d", output) is None:
        return {"collected": len(ids), "errors": 0, "line": "(counted node ids; no summary line)"}
    return None


def _errors_in(line: str) -> int:
    m = re.search(r"(\d+) errors?\b", line)
    return int(m.group(1)) if m else 0


def parse_junit(xml_text: str) -> dict | None:
    """Sum testsuite attributes from a pytest ``--junitxml`` report, or None if unparsable."""
    try:
        root = ET.fromstring(xml_text)
    except ET.ParseError:
        return None
    suites = [root] if root.tag == "testsuite" else list(root.iter("testsuite"))
    if not suites:
        return None
    totals = {"tests": 0, "failures": 0, "errors": 0, "skipped": 0}
    for suite in suites:
        for key in totals:
            totals[key] += int(float(suite.get(key, "0") or 0))
    passed = totals["tests"] - totals["failures"] - totals["errors"] - totals["skipped"]
    return {"collected": totals["tests"], "passed": max(passed, 0), "failed": totals["failures"],
            "errors": totals["errors"], "skipped": totals["skipped"]}


def extract_failure_excerpt(output: str, max_lines: int = 30) -> list[str]:
    """First lines of failure output: the short-summary FAILED/ERROR lines, else the FAILURES block."""
    lines = output.splitlines()
    picked: list[str] = []
    for i, ln in enumerate(lines):
        if "short test summary info" in ln:
            picked = [x for x in lines[i + 1:] if x.startswith(("FAILED", "ERROR"))]
            break
    if not picked:
        for i, ln in enumerate(lines):
            if re.match(r"^=+ (FAILURES|ERRORS) =+$", ln.strip()):
                picked = lines[i: i + max_lines]
                break
    if not picked:
        picked = [x for x in lines if x.strip()][-max_lines:]
    return [x[:300] for x in picked[:max_lines]]


def to_wsl_path(path: str) -> str:
    """Translate a Windows or WSL-UNC path to the in-distro POSIX path."""
    p = path.replace("/", "\\") if re.match(r"^[A-Za-z]:|^\\\\", path) else path
    unc = re.match(r"^\\\\(?:wsl\$|wsl\.localhost)\\[^\\]+(\\.*)?$", p, re.IGNORECASE)
    if unc:
        return (unc.group(1) or "\\").replace("\\", "/")
    drive = re.match(r"^([A-Za-z]):(\\.*)?$", p)
    if drive:
        return f"/mnt/{drive.group(1).lower()}{(drive.group(2) or '').replace(chr(92), '/')}"
    return path


@dataclass
class WslSpec:
    distro: str
    user: str | None = None

    @classmethod
    def parse(cls, text: str) -> WslSpec:
        distro, _, user = text.partition(":")
        if not distro:
            raise ValueError("--wsl needs DISTRO or DISTRO:USER")
        return cls(distro, user or None)

    def argv(self, cwd: str, script: str) -> list[str]:
        """``wsl.exe`` argv running ``script`` in ``cwd`` (script passed base64-encoded to avoid quoting)."""
        b64 = base64.b64encode(script.encode()).decode()
        out = ["wsl.exe", "-d", self.distro]
        if self.user:
            out += ["-u", self.user]
        return out + ["--cd", to_wsl_path(cwd), "-e", "bash", "-lc", f'eval "$(echo {b64} | base64 -d)"']


def _kill_tree(proc: subprocess.Popen) -> None:
    if os.name == "nt":
        subprocess.run(["taskkill", "/F", "/T", "/PID", str(proc.pid)], capture_output=True)
        return
    for sig in (signal.SIGTERM, signal.SIGKILL):
        try:
            os.killpg(proc.pid, sig)
        except (ProcessLookupError, PermissionError):
            return
        try:
            proc.wait(timeout=5)
            return
        except subprocess.TimeoutExpired:
            continue


def run_shell(argv_or_cmd, *, shell: bool, cwd: str | None, env: dict, timeout: float) -> dict:
    """Run a command, return ``exit_code``, combined ``output``, ``duration_s``, ``timed_out``."""
    kwargs: dict = {"shell": shell, "cwd": cwd, "env": env, "stdin": subprocess.DEVNULL,
                    "stdout": subprocess.PIPE, "stderr": subprocess.STDOUT,
                    "text": True, "errors": "replace"}
    if os.name == "posix":
        kwargs["start_new_session"] = True
        if shell and os.path.exists("/bin/bash"):
            kwargs["executable"] = "/bin/bash"
    t0 = time.monotonic()
    proc = subprocess.Popen(argv_or_cmd, **kwargs)
    timed_out = False
    try:
        output, _ = proc.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        timed_out = True
        _kill_tree(proc)
        try:
            output, _ = proc.communicate(timeout=10)
        except subprocess.TimeoutExpired:
            output = ""
    return {"exit_code": None if timed_out else proc.returncode, "output": output or "",
            "duration_s": round(time.monotonic() - t0, 2), "timed_out": timed_out}


def _pytest_addopts(collect_only: bool, junit_path: str | None) -> str:
    opts = ["-p", "no:cacheprovider"]
    if collect_only:
        opts.append("--collect-only")
    if junit_path:
        opts.append(shlex.quote(f"--junitxml={junit_path}"))
    return " ".join(opts)


def _classify_run(exit_code, timed_out, summary, junit, collect_only, output, timeout) -> dict:
    """Decide status/counts/reason. Never emits a pass count without a summary or junit."""
    res = {"status": "unknown", "counts": {}, "counts_source": "none", "reason": "",
           "summary_line": summary["line"] if summary else None}
    if timed_out:
        res["reason"] = (f"timed out after {timeout:g}s before a final summary; "
                         "no counts reported (pass count unknown)")
        res["status"] = "timeout"
        return res
    if collect_only:
        return _classify_collect(res, exit_code, output)
    counts = None
    if junit is not None:
        counts = {k: junit[k] for k in ("collected", "passed", "failed", "errors", "skipped")}
        res["counts_source"] = "junit"
        if summary:
            for key in ("xfailed", "xpassed", "deselected"):
                if key in summary["counts"]:
                    counts[key] = summary["counts"][key]
            diff = _junit_summary_mismatch(junit, summary["counts"])
            if diff:
                res["reason"] = diff
    elif summary is not None:
        c = summary["counts"]
        counts = {k: c.get(k, 0) for k in ("passed", "failed", "errors", "skipped")}
        counts["collected"] = sum(counts.values())
        counts.update({k: c[k] for k in ("xfailed", "xpassed", "deselected") if k in c})
        res["counts_source"] = "summary"
    if counts is None:
        res["status"] = "error" if exit_code else "unknown"
        res["reason"] = (f"no pytest summary or junit report found (exit code {exit_code}); "
                         "pass count unknown")
        return res
    res["counts"] = counts
    res["status"] = _status_from_counts(counts, exit_code)
    if res["status"] == "no_tests":
        res["reason"] = res["reason"] or "no tests ran"
    elif exit_code not in (0, 1, 5) and not res["reason"]:
        res["reason"] = f"pytest exit code {exit_code} (interrupted or internal error)"
    return res


def _status_from_counts(counts: dict, exit_code) -> str:
    if exit_code == 2:
        return "collection_error" if counts.get("errors") else "interrupted"
    if exit_code in (3, 4):
        return "error"
    if counts.get("failed", 0) or counts.get("errors", 0):
        return "failed"
    if counts.get("collected", 0) == 0:
        return "no_tests"
    return "ok" if exit_code in (0, None) else "failed"


def _junit_summary_mismatch(junit: dict, counts: dict) -> str:
    pairs = (("passed", "passed"), ("failed", "failed"), ("skipped", "skipped"))
    bad = [f"{k}: junit {junit[k]} vs summary {counts.get(s, 0)}"
           for k, s in pairs if junit[k] != counts.get(s, 0)]
    # pytest reports xfail as skipped in junit but separately in its summary line
    if bad and (counts.get("xfailed") or counts.get("xpassed")):
        return ""
    return ("junit and summary line disagree (" + "; ".join(bad) + "); junit used") if bad else ""


def _classify_collect(res: dict, exit_code, output: str) -> dict:
    parsed = parse_collect_output(output)
    if parsed is None:
        res["status"] = "error" if exit_code else "unknown"
        res["reason"] = f"no collection summary found (exit code {exit_code}); count unknown"
        return res
    res["summary_line"] = parsed["line"]
    res["counts"] = {"collected": parsed["collected"], "errors": parsed["errors"]}
    res["counts_source"] = "collect-only"
    if parsed["errors"] or exit_code == 2:
        res["status"] = "collection_error"
        res["reason"] = f"{parsed['errors']} collection error(s); collected count may be incomplete"
    else:
        res["status"] = "ok" if parsed["collected"] else "no_tests"
    return res


def run_test_spec(name: str, command: str, *, cwd: Path, collect_only: bool, timeout: float,
                  wsl: WslSpec | None, revision: str, extra_env: dict[str, str] | None = None) -> dict:
    """Execute one ``name=command`` test spec and return a result record.

    pytest is steered through ``PYTEST_ADDOPTS`` (no cache provider, optional
    ``--collect-only``, ``--junitxml``), which works through ``pixi run``/``just``
    wrappers and shell pipelines. ``MIGRATION_STATUS_ROOT`` is exported so a
    command can refer to the tree under test (needed for baseline revisions).
    """
    if wsl:
        junit_path = None if collect_only else f"/tmp/migration_status_{os.getpid()}_{name}.xml"
    else:
        junit_path = None
        if not collect_only:
            fd, junit_path = tempfile.mkstemp(prefix="migration_status_", suffix=".xml")
            os.close(fd)
    addopts = _pytest_addopts(collect_only, junit_path)
    env_vars = {"MIGRATION_STATUS_ROOT": str(cwd), "PYTHONDONTWRITEBYTECODE": "1", **(extra_env or {})}
    started = dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds")
    try:
        if wsl:
            raw = _run_wsl(wsl, command, str(cwd), env_vars, addopts, timeout, junit_path)
        else:
            env = {**os.environ, **env_vars,
                   "PYTEST_ADDOPTS": (os.environ.get("PYTEST_ADDOPTS", "") + " " + addopts).strip()}
            raw = run_shell(command, shell=True, cwd=str(cwd), env=env, timeout=timeout)
            raw["junit_text"] = _read_and_remove(junit_path)
    except OSError as exc:
        raw = {"exit_code": None, "output": "", "duration_s": 0.0, "timed_out": False,
               "junit_text": None, "launch_error": str(exc)}
    return _build_record(name, command, cwd, collect_only, timeout, wsl, revision, started, raw)


def _run_wsl(wsl: WslSpec, command: str, cwd: str, env_vars: dict, addopts: str,
             timeout: float, junit_path: str | None) -> dict:
    exports = "".join(f"export {k}={shlex.quote(v)}; " for k, v in env_vars.items())
    exports += f'export PYTEST_ADDOPTS="${{PYTEST_ADDOPTS:-}} {addopts}"; '
    guard = f"timeout -k 15 {int(timeout)} bash -c {shlex.quote(command)}"
    script = f"{exports}if command -v timeout >/dev/null; then {guard}; else {command}; fi"
    raw = run_shell(wsl.argv(cwd, script), shell=False, cwd=None, env=dict(os.environ),
                    timeout=timeout + 60)
    if raw["exit_code"] == 124:  # GNU timeout: the command was killed inside the distro
        raw["timed_out"], raw["exit_code"] = True, None
    raw["junit_text"] = None
    if junit_path and not raw["timed_out"]:
        read = run_shell(wsl.argv("/", f"cat {shlex.quote(junit_path)}; rm -f {shlex.quote(junit_path)}"),
                         shell=False, cwd=None, env=dict(os.environ), timeout=60)
        raw["junit_text"] = read["output"] if read["exit_code"] == 0 else None
    return raw


def _read_and_remove(path: str | None) -> str | None:
    if not path:
        return None
    try:
        text = Path(path).read_text(encoding="utf-8", errors="replace")
    except OSError:
        text = None
    try:
        os.unlink(path)
    except OSError:
        pass
    return text or None


def _build_record(name, command, cwd, collect_only, timeout, wsl, revision, started, raw) -> dict:
    output = raw["output"]
    summary = None if collect_only else parse_pytest_summary(output)
    junit = parse_junit(raw["junit_text"]) if raw.get("junit_text") else None
    verdict = _classify_run(raw["exit_code"], raw["timed_out"], summary, junit, collect_only,
                            output, timeout)
    if raw.get("launch_error"):
        verdict.update(status="error", reason=f"could not launch command: {raw['launch_error']}")
    lines = output.splitlines()
    excerpt = extract_failure_excerpt(output) if verdict["status"] not in ("ok",) else []
    return {
        "name": name, "command": command, "mode": "collect-only" if collect_only else "run",
        "cwd": str(cwd), "wrapper": (f"wsl:{wsl.distro}" + (f":{wsl.user}" if wsl.user else "")) if wsl else None,
        "revision": revision, "measured_at": started, "timeout_s": timeout,
        "exit_code": raw["exit_code"], "duration_s": raw["duration_s"], "timed_out": raw["timed_out"],
        "status": verdict["status"], "counts": verdict["counts"],
        "counts_source": verdict["counts_source"], "summary_line": verdict["summary_line"],
        "reason": verdict["reason"], "failure_excerpt": excerpt,
        "output_tail": [x[:300] for x in lines[-15:]],
    }


def parse_test_specs(specs: list[str]) -> list[tuple[str, str]]:
    """``name=command`` (or a bare command, named ``tests1``, ``tests2`` ...)."""
    out: list[tuple[str, str]] = []
    for i, spec in enumerate(specs, 1):
        m = re.match(r"^([A-Za-z0-9_.-]+)=(.+)$", spec, re.DOTALL)
        out.append((m.group(1), m.group(2).strip()) if m else (f"tests{i}", spec.strip()))
    return out


# ---------------------------------------------------------------------------
# Snapshot
# ---------------------------------------------------------------------------


def _part() -> dict:
    return {"files": 0, "code": 0, "comment": 0, "blank": 0}


def aggregate_files(metrics: list[FileMetrics]) -> dict:
    """Roll per-file metrics up into totals, per-language and per-directory tables."""
    loc = {"production": _part(), "test": _part()}
    langs: dict[str, dict] = {}
    dirs: dict[tuple[str, str], dict] = {}
    symbols = {"production": {"functions": None, "classes": None},
               "test": {"functions": None, "classes": None}}
    declared = 0
    approximate = {"production": False, "test": False}
    parse_errors = 0
    for fm in metrics:
        part = "test" if fm.is_test else "production"
        spec = LANG_BY_KEY[fm.lang]
        for target in (loc[part], langs.setdefault(fm.lang, {}).setdefault(part, _part())):
            target["files"] += 1
            target["code"] += fm.code
            target["comment"] += fm.comment
            target["blank"] += fm.blank
        d = dirs.setdefault((part, "/".join(fm.rel.split("/")[:2]) if "/" in fm.rel else "."), _part())
        d["files"] += 1
        d["code"] += fm.code
        d["comment"] += fm.comment
        d["blank"] += fm.blank
        _add_symbols(fm, part, spec, symbols, langs[fm.lang])
        declared += fm.symbols.declared_tests
        approximate[part] |= spec.approx_symbols and fm.symbols.functions is not None
        parse_errors += fm.symbols.parse_error
    for part in loc:
        loc[part]["lines"] = loc[part]["code"] + loc[part]["comment"] + loc[part]["blank"]
    for key, entry in langs.items():
        entry["label"] = LANG_BY_KEY[key].label
        entry["symbols_approximate"] = LANG_BY_KEY[key].approx_symbols
    total = {k: loc["production"][k] + loc["test"][k] for k in ("files", "code", "comment", "blank", "lines")}
    by_dir = [{"part": part, "path": path, **vals} for (part, path), vals in dirs.items()]
    by_dir.sort(key=lambda d: (-d["code"], d["part"], d["path"]))
    return {"loc": {**loc, "total": total}, "languages": langs,
            "symbols": {**symbols, "approximate": approximate, "python_parse_fallbacks": parse_errors},
            "declared_tests": declared, "by_dir": by_dir[:30]}


def _add_symbols(fm: FileMetrics, part: str, spec: LangSpec, symbols: dict, lang_entry: dict) -> None:
    s = fm.symbols
    for what in ("functions", "classes"):
        val = getattr(s, what)
        if val is None:
            continue
        symbols[part][what] = (symbols[part][what] or 0) + val
        sym = lang_entry.setdefault("symbols", {}).setdefault(part, {"functions": 0, "classes": 0})
        sym[what] += val


def collect_static(root: Path, *, includes: list[str], excludes: list[str],
                   tracked: set[str] | None, max_bytes: int) -> tuple[dict, list[FileMetrics]]:
    skips = SkipCounts()
    metrics: list[FileMetrics] = []
    for rel, path in walk_files(root, includes, excludes, tracked, skips):
        text = read_text(path, max_bytes, skips)
        if text is not None:
            metrics.append(analyse_file(rel, text))
    body = aggregate_files(metrics)
    body["skipped_files"] = skips.as_dict()
    return body, metrics


def file_records(metrics: list[FileMetrics]) -> list[dict]:
    return [{"path": m.rel, "lang": m.lang, "is_test": m.is_test, "code": m.code,
             "comment": m.comment, "blank": m.blank} for m in metrics]


@dataclass
class SideOptions:
    root: Path
    label: str
    role: str = "target"
    includes: list[str] = field(default_factory=list)
    excludes: list[str] = field(default_factory=list)
    default_excludes: bool = True
    tracked_only: bool = False
    max_bytes: int = DEFAULT_MAX_FILE_BYTES
    map_path: Path | None = None
    join_files: list[dict] | None = None
    tests: list[tuple[str, str]] = field(default_factory=list)
    collects: list[tuple[str, str]] = field(default_factory=list)
    collect_only: bool = False
    timeout: float = DEFAULT_TEST_TIMEOUT
    wsl: WslSpec | None = None
    per_file: bool = False

    def all_excludes(self) -> list[str]:
        return ([*DEFAULT_EXCLUDES] if self.default_excludes else []) + list(self.excludes)


def _scope(opts: SideOptions) -> dict:
    return {"include": list(opts.includes), "exclude": opts.all_excludes(),
            "tracked_only": opts.tracked_only, "max_file_bytes": opts.max_bytes}


def _load_map(map_path: Path | None, join_files: list[dict] | None) -> dict | None:
    if map_path is None:
        return None
    try:
        text = map_path.read_text(encoding="utf-8", errors="replace")
    except OSError as exc:
        return {"path": str(map_path), "error": str(exc)}
    data = parse_migration_map(text)
    summary = map_summary(data, str(map_path))
    if join_files is not None:
        summary["join"] = join_map_to_files(data, join_files)
    return summary


def run_tests_for(opts: SideOptions, cwd: Path, revision: str) -> dict:
    jobs = [(n, c, opts.collect_only) for n, c in opts.tests] + [(n, c, True) for n, c in opts.collects]
    runs: list[dict] = []
    for name, command, collect_only in jobs:
        print(f"[migration_status] {opts.label}: {'collecting' if collect_only else 'running'} "
              f"suite {name!r} (timeout {opts.timeout:g}s)", file=sys.stderr, flush=True)
        rec = run_test_spec(name, command, cwd=cwd, collect_only=collect_only, timeout=opts.timeout,
                            wsl=opts.wsl, revision=revision)
        print(f"[migration_status] {opts.label}: suite {name!r} -> {rec['status']} "
              f"{rec['counts']} in {rec['duration_s']}s", file=sys.stderr, flush=True)
        runs.append(rec)
    return {"runs": runs}


def build_snapshot(opts: SideOptions, *, rev: str | None = None, run_tests_at_rev: bool = False
                   ) -> tuple[dict, list[FileMetrics]]:
    """Collect a snapshot of ``opts.root`` (working tree) or of git revision ``rev``."""
    root = opts.root.resolve()
    notes: list[str] = []
    if rev is None:
        tracked = git_tracked_files(root) if opts.tracked_only else None
        body, metrics = collect_static(root, includes=opts.includes, excludes=opts.all_excludes(),
                                       tracked=tracked, max_bytes=opts.max_bytes)
        revision_info, label_rev = git_info(root), "WORKTREE"
        map_info = _load_map(opts.map_path or find_default_map(root), opts.join_files)
        tests = run_tests_for(opts, root, label_rev) if (opts.tests or opts.collects) else {"runs": []}
    else:
        revision_info = resolve_revision(root, rev)
        label_rev = revision_info["commit"][:12]
        with tempfile.TemporaryDirectory(prefix="migration_status_rev_") as tmp:
            tmp_root = Path(tmp)
            map_rel = _map_relpath(root, opts.map_path)
            export_revision(root, revision_info["commit"], tmp_root, opts.includes,
                            opts.all_excludes(), extra=[map_rel] if map_rel else [])
            body, metrics = collect_static(tmp_root, includes=[], excludes=[], tracked=None,
                                           max_bytes=opts.max_bytes)
            at_rev = tmp_root / map_rel if map_rel and (tmp_root / map_rel).is_file() else None
            map_info = _load_map(at_rev, opts.join_files)
            if map_info is not None:
                map_info["path"] = f"{map_rel} @ {label_rev}"
            if (opts.tests or opts.collects) and run_tests_at_rev:
                tests = run_tests_for(opts, tmp_root, label_rev)
                notes.append("Tests were run in a clean git export of this revision: untracked or "
                             "built artefacts (compiled kernels, local oracle binaries, data) are "
                             "absent, so failures may reflect that rather than the code.")
            else:
                tests = {"runs": []}
                if opts.tests or opts.collects:
                    notes.append("Test commands were NOT run at this revision "
                                 "(static metrics only; pass --run-tests-at-rev to opt in).")
    body["migration_map"] = map_info
    snap = {
        "schema_version": SCHEMA_VERSION,
        "tool": {"name": "migration_status", "version": TOOL_VERSION},
        "generated_at": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
        "label": opts.label, "role": opts.role, "root": str(root),
        "revision": label_rev, "git": revision_info, "scope": _scope(opts),
        **body, "tests": tests, "notes": notes,
    }
    if opts.per_file:
        snap["files"] = file_records(metrics)
    return snap, metrics


def _map_relpath(root: Path, map_path: Path | None) -> str | None:
    """Repo-relative posix path of the migration map (default location if not given)."""
    if map_path is None:
        found = find_default_map(root)
        return _rel(root, found) if found else None
    try:
        return _rel(root, map_path.resolve())
    except ValueError:
        return None


# ---------------------------------------------------------------------------
# Report rendering
# ---------------------------------------------------------------------------


def fmt_int(n) -> str:
    return "n/a" if n is None else f"{n:,}"


def fmt_pct(x, digits: int = 1) -> str:
    return "n/a" if x is None else f"{100 * x:.{digits}f}%"


def fmt_rate(x) -> str:
    """Percentage floored to 2 decimals so 12,163 of 12,168 never displays as 100%."""
    return "n/a" if x is None else f"{math.floor(x * 10000) / 100:.2f}%"


def fmt_ratio(a, b) -> str:
    return "n/a" if not b or a is None else f"{a / b:.2f}x"


def fmt_delta(old, new, pct: bool = True) -> str:
    if old is None or new is None:
        return "n/a"
    diff = new - old
    text = f"{diff:+,}"
    if pct and old:
        text += f" ({100 * diff / old:+.1f}%)"
    return text


def md_table(headers: list[str], rows: list[list[str]], right_from: int = 1) -> str:
    align = ["---" if i < right_from else "---:" for i in range(len(headers))]
    lines = ["| " + " | ".join(headers) + " |", "| " + " | ".join(align) + " |"]
    lines += ["| " + " | ".join(r) + " |" for r in rows]
    return "\n".join(lines)


def aggregate_tests(snap: dict) -> dict:
    """Suite roll-up: an executed run supersedes a collect-only run of the same name."""
    best: dict[str, dict] = {}
    for run in snap.get("tests", {}).get("runs", []):
        prev = best.get(run["name"])
        if prev is None or (run["mode"] == "run" and prev["mode"] != "run"):
            best[run["name"]] = run
    out = {"runs": list(best.values()), "collected": None, "passed": None, "failed": None,
           "skipped": None, "errors": None, "unknown": [], "collect_only": [], "executed": [],
           "executed_collected": 0}
    for run in best.values():
        counts = run["counts"]
        if run["mode"] == "run" and "passed" in counts:
            out["executed"].append(run["name"])
            out["executed_collected"] += counts.get("collected", 0)
            for key in ("collected", "passed", "failed", "skipped", "errors"):
                out[key] = (out[key] or 0) + counts.get(key, 0)
        elif run["mode"] == "collect-only" and "collected" in counts:
            out["collect_only"].append(run["name"])
            out["collected"] = (out["collected"] or 0) + counts["collected"]
        else:
            out["unknown"].append(run["name"])
    ran = (out["passed"] or 0) + (out["failed"] or 0) + (out["errors"] or 0)
    out["pass_rate"] = (out["passed"] / ran) if out["executed"] and ran else None
    out["passed_share_of_collected"] = (
        out["passed"] / out["executed_collected"] if out["executed"] and out["executed_collected"] else None)
    return out


def _sym(snap: dict, part: str, what: str):
    return snap["symbols"][part][what]


def _headline_rows(side_snaps: list[dict]) -> list[tuple[str, list[str]]]:
    rows: list[tuple[str, list[str]]] = []

    def add(label: str, fn) -> None:
        rows.append((label, [fn(s) for s in side_snaps]))

    add("Production files", lambda s: fmt_int(s["loc"]["production"]["files"]))
    add("Production LOC - code", lambda s: fmt_int(s["loc"]["production"]["code"]))
    add("Production LOC - comment", lambda s: fmt_int(s["loc"]["production"]["comment"]))
    add("Production LOC - blank", lambda s: fmt_int(s["loc"]["production"]["blank"]))
    add("Production LOC - all lines", lambda s: fmt_int(s["loc"]["production"]["lines"]))
    add(FUNCTIONS_LABEL, lambda s: _fmt_sym(s, "production", "functions"))
    add("Production classes/structs", lambda s: _fmt_sym(s, "production", "classes"))
    add("Test files", lambda s: fmt_int(s["loc"]["test"]["files"]))
    add("Test LOC - code", lambda s: fmt_int(s["loc"]["test"]["code"]))
    add("Test functions declared (static count)", lambda s: fmt_int(s["declared_tests"]))
    agg = [aggregate_tests(s) for s in side_snaps]
    rows.append(("Tests collected", [_test_cell(a, "collected") for a in agg]))
    for key in ("passed", "failed", "skipped", "errors"):
        rows.append((f"Tests {key}", [_test_cell(a, key) for a in agg]))
    rows.append(("Pass rate (passed / (passed+failed+errors))", [fmt_rate(a["pass_rate"]) for a in agg]))
    rows.append(("Passed as share of collected (executed suites)",
                 [fmt_pct(a["passed_share_of_collected"]) for a in agg]))
    return rows


def _fmt_sym(snap: dict, part: str, what: str) -> str:
    val = _sym(snap, part, what)
    if val is None:
        return "n/a"
    approx = snap["symbols"]["approximate"][part]
    return f"~{val:,}" if approx else f"{val:,}"


def _test_cell(agg: dict, key: str) -> str:
    if not agg["runs"]:
        return "not measured"
    val = agg[key]
    if val is None:
        return "unknown" if agg["unknown"] else "not executed"
    return fmt_int(val) + ("*" if agg["unknown"] else "")


def render_headline(source: dict | None, target: dict, baseline: dict | None) -> str:
    snaps = [x for x in (source, target, baseline) if x]
    heads = []
    if source:
        heads.append(f"Source: {source['label']} (before)")
    heads.append(f"Target: {target['label']} (now)")
    if baseline:
        heads.append(f"Target @ {baseline['revision']} (baseline)")
    rows = []
    for label, cells in _headline_rows(snaps):
        row = [label, *cells]
        if source:
            row.append(_ratio_cell(label, source, target))
        if baseline:
            row.append(_delta_cell(label, baseline, target))
        rows.append(row)
    headers = ["Metric", *heads]
    if source:
        headers.append("Target / source")
    if baseline:
        headers.append("Delta vs baseline")
    return md_table(headers, rows)


_METRIC_GETTERS = {
    "Production files": lambda s: s["loc"]["production"]["files"],
    "Production LOC - code": lambda s: s["loc"]["production"]["code"],
    "Production LOC - comment": lambda s: s["loc"]["production"]["comment"],
    "Production LOC - blank": lambda s: s["loc"]["production"]["blank"],
    "Production LOC - all lines": lambda s: s["loc"]["production"]["lines"],
    FUNCTIONS_LABEL: lambda s: _sym(s, "production", "functions"),
    "Production classes/structs": lambda s: _sym(s, "production", "classes"),
    "Test files": lambda s: s["loc"]["test"]["files"],
    "Test LOC - code": lambda s: s["loc"]["test"]["code"],
    "Test functions declared (static count)": lambda s: s["declared_tests"],
    "Tests collected": lambda s: aggregate_tests(s)["collected"],
    "Tests passed": lambda s: aggregate_tests(s)["passed"],
    "Tests failed": lambda s: aggregate_tests(s)["failed"],
    "Tests skipped": lambda s: aggregate_tests(s)["skipped"],
    "Tests errors": lambda s: aggregate_tests(s)["errors"],
}


def _ratio_cell(label: str, source: dict, target: dict) -> str:
    getter = _METRIC_GETTERS.get(label)
    if not getter or label.startswith("Tests"):
        return ""
    return fmt_ratio(getter(target), getter(source))


def _delta_cell(label: str, baseline: dict, target: dict) -> str:
    getter = _METRIC_GETTERS.get(label)
    if not getter:
        return ""
    return fmt_delta(getter(baseline), getter(target))


def render_test_table(snaps: list[tuple[str, dict]]) -> str:
    rows: list[list[str]] = []
    for side, snap in snaps:
        for run in snap.get("tests", {}).get("runs", []):
            c = run["counts"]
            rows.append([
                side, f"`{run['name']}`", run["mode"], run["revision"], run["status"],
                fmt_int(c.get("collected")), fmt_int(c.get("passed")), fmt_int(c.get("failed")),
                fmt_int(c.get("skipped")), fmt_int(c.get("errors")),
                f"{run['duration_s']:.0f}s", run["measured_at"],
            ])
    if not rows:
        return "_No test commands were run or collected for any side._"
    headers = ["Side", "Suite", "Mode", "Revision", "Status", "Collected", "Passed", "Failed",
               "Skipped", "Errors", "Duration", "Measured at (UTC)"]
    return md_table(headers, rows, right_from=5)


def render_map(snap: dict | None) -> str:
    m = (snap or {}).get("migration_map")
    if not m:
        return "_No migration map supplied._"
    if "error" in m:
        return f"_Migration map `{m['path']}` could not be read: {m['error']}_"
    total_modules = m["unique_modules"] or 0
    join = m.get("join")
    rows = []
    for status in MAP_STATUSES:
        n = m["status_counts"][status]
        row = [status, fmt_int(n), fmt_pct(n / total_modules if total_modules else None)]
        if join:
            b = join["by_status"][status]
            row += [fmt_int(b["files"]), fmt_int(b["code"]), fmt_pct(b["code_share"])]
        rows.append(row)
    headers = ["Status", "Map modules", "% of map modules"]
    if join:
        b = join["by_status"]["UNMAPPED"]
        rows.append(["UNMAPPED (no map row)", "-", "-", fmt_int(b["files"]), fmt_int(b["code"]),
                     fmt_pct(b["code_share"])])
        rows.append(["**Total**", fmt_int(total_modules), "100.0%", fmt_int(join["upstream_files"]),
                     fmt_int(join["upstream_code"]), "100.0%"])
        headers += ["Upstream files", "Upstream code LOC", "% of upstream code LOC"]
    dupes = f", {m['duplicate_rows']} duplicate rows (highest status kept)" if m["duplicate_rows"] else ""
    stamp = f" Map header says generated {m['generated_header']}." if m.get("generated_header") else ""
    out = [f"Map: `{m['path']}` ({m['data_rows']} data rows, {total_modules} unique modules{dupes}).{stamp} "
           "Statuses are as written by the port's authors; this tool does not verify them.",
           "", md_table(headers, rows)]
    if join:
        out += ["", f"Join: {join['metric']}. {join['ambiguous_stems']} stem(s) occur in more than one "
                    f"directory; {len(join['map_keys_without_upstream_file'])} map row(s) matched no upstream file."]
        if join["largest_unmapped"]:
            top = ", ".join(f"`{x['path']}` ({x['code']:,})" for x in join["largest_unmapped"][:5])
            out.append(f"Largest unmapped files (code LOC): {top}.")
    return "\n".join(out)


def render_languages(snap: dict, title: str) -> str:
    rows = []
    for key, entry in sorted(snap["languages"].items(), key=lambda kv: -sum(
            entry_p["code"] for entry_p in (kv[1].get("production", _part()), kv[1].get("test", _part())))):
        for part in ("production", "test"):
            p = entry.get(part)
            if not p:
                continue
            sym = entry.get("symbols", {}).get(part)
            approx = "~" if entry["symbols_approximate"] else ""
            rows.append([entry["label"], part, fmt_int(p["files"]), fmt_int(p["code"]),
                         fmt_int(p["comment"]), fmt_int(p["blank"]),
                         f"{approx}{sym['functions']:,}" if sym else "n/a",
                         f"{approx}{sym['classes']:,}" if sym else "n/a"])
    if not rows:
        return f"_{title}: no recognised source files._"
    headers = ["Language", "Part", "Files", "Code", "Comment", "Blank", "Functions", "Classes"]
    return f"**{title}**\n\n" + md_table(headers, rows, right_from=2)


def render_dirs(snap: dict, title: str, limit: int = 12) -> str:
    rows = [[f"`{d['path']}`", d["part"], fmt_int(d["files"]), fmt_int(d["code"])]
            for d in snap["by_dir"][:limit]]
    return f"**{title}** (top {len(rows)} directories by code LOC)\n\n" + md_table(
        ["Directory", "Part", "Files", "Code LOC"], rows, right_from=2)


def render_pair_deltas(before: dict, after: dict) -> str:
    rows = []
    for label, getter in _METRIC_GETTERS.items():
        old, new = getter(before), getter(after)
        rows.append([label, fmt_int(old), fmt_int(new), fmt_delta(old, new)])
    for key in ("pass_rate",):
        old, new = aggregate_tests(before)[key], aggregate_tests(after)[key]
        diff = "n/a" if old is None or new is None else f"{100 * (new - old):+.1f} pp"
        rows.append(["Pass rate", fmt_rate(old), fmt_rate(new), diff])
    headers = ["Metric", f"Before ({before['revision']})", f"After ({after['revision']})", "Delta"]
    return md_table(headers, rows)


def render_map_deltas(before: dict, after: dict) -> str:
    mb, ma = before.get("migration_map"), after.get("migration_map")
    if not mb or not ma or "error" in mb or "error" in ma:
        return ""
    with_join = bool(mb.get("join") and ma.get("join"))
    rows = []
    for status in MAP_STATUSES:
        old, new = mb["status_counts"][status], ma["status_counts"][status]
        row = [status, fmt_int(old), fmt_int(new), fmt_delta(old, new, pct=False)]
        if with_join:
            row += [fmt_pct(mb["join"]["by_status"][status]["code_share"]),
                    fmt_pct(ma["join"]["by_status"][status]["code_share"])]
        rows.append(row)
    headers = ["Status", "Map modules before", "after", "Delta"]
    if with_join:
        headers += ["% upstream LOC before", "% upstream LOC after"]
    return md_table(headers, rows)


# --- caveats -----------------------------------------------------------------


def build_caveats(source: dict | None, target: dict, baseline: dict | None) -> list[str]:
    out = [
        "Lines of code come from a small heuristic scanner (comment markers, string literals, "
        "Python/Mojo docstrings counted as comments); they are approximate and will differ "
        "slightly from tokei or cloc. Production/test split is by path convention only.",
        "C/C++ and Mojo function/class counts are regex or brace-depth heuristics (no compiler "
        "front end), marked with `~`; macros that look like functions are counted. Python counts "
        "use `ast`.",
        "'Test functions declared' is a static count and does not expand parametrisation; it is "
        "not the number of tests a runner would collect.",
    ]
    sides = [("source", source), ("target", target), ("baseline", baseline)]
    for side, snap in sides:
        if snap:
            out += _side_caveats(side, snap)
    if source and not aggregate_tests(source)["runs"]:
        out.append("Source test results: not measured (source tests were not run or collected).")
    if baseline and not baseline.get("tests", {}).get("runs"):
        out.append("Baseline revision: static metrics only; tests were not run there, so test "
                   "deltas are not available.")
    return out


def _side_caveats(side: str, snap: dict) -> list[str]:
    out: list[str] = []
    name = f"{side} ({snap['label']}, revision {snap['revision']})"
    sc = snap["scope"]
    out.append(f"Scope of {name}: include {sc['include'] or ['(whole root)']}, exclude "
               f"{[e for e in sc['exclude'] if e not in DEFAULT_EXCLUDES] or '(defaults only)'}"
               f"{', tracked files only' if sc['tracked_only'] else ''}.")
    skipped = snap.get("skipped_files", {})
    if any(skipped.values()):
        out.append(f"Files skipped in {name}: " + ", ".join(f"{v} {k}" for k, v in skipped.items() if v)
                   + f" (max file size {sc['max_file_bytes']:,} bytes).")
    git = snap.get("git")
    if side != "baseline" and git and git.get("dirty"):
        out.append(f"The {side} working tree has uncommitted changes to tracked files; they are included.")
    if snap["symbols"].get("python_parse_fallbacks"):
        out.append(f"{snap['symbols']['python_parse_fallbacks']} Python file(s) in {name} did not parse "
                   "with this interpreter's `ast`; regex counts were used for them.")
    out += snap.get("notes", [])
    agg = aggregate_tests(snap)
    for run in agg["runs"]:
        out += _run_caveats(side, snap, run)
    m = snap.get("migration_map")
    if m and "error" not in m:
        if m["malformed_row_count"]:
            out.append(f"Migration map for {name}: {m['malformed_row_count']} malformed row(s) skipped, "
                       f"e.g. `{m['malformed_rows'][0]}`.")
        if m.get("join") and m["join"]["by_status"]["UNMAPPED"]["files"]:
            out.append("Migration map join is by file stem: files with no map row are reported as "
                       "UNMAPPED, not dropped, and are not necessarily 'not started'.")
    return out


def _run_caveats(side: str, snap: dict, run: dict) -> list[str]:
    tag = f"{side} suite `{run['name']}`"
    out = []
    if run["mode"] == "collect-only":
        out.append(f"{tag}: collected only (no execution) - pass/fail unknown.")
    if run["status"] in ("timeout", "error", "unknown", "interrupted", "collection_error", "no_tests"):
        out.append(f"{tag}: status {run['status']} - {run['reason'] or 'see output'}")
    elif run["reason"]:
        out.append(f"{tag}: {run['reason']}")
    if run["status"] == "failed":
        shown = [x.replace("FAILED ", "").replace("ERROR ", "") for x in run["failure_excerpt"][:5]]
        out.append(f"{tag}: {run['counts'].get('failed', 0)} failed, {run['counts'].get('errors', 0)} errors"
                   + (f"; first: {'; '.join(f'`{x}`' for x in shown)}" if shown else "") + ".")
    xf, xp = run["counts"].get("xfailed"), run["counts"].get("xpassed")
    if run["mode"] == "run" and (xf or xp):
        out.append(f"{tag}: pytest's junit report counts {xf or 0} xfailed as skipped and {xp or 0} xpassed "
                   "as passed, so the 'skipped' and 'passed' figures include them.")
    if run["revision"] != "WORKTREE" and run["mode"] == "run":
        out.append(f"{tag}: executed at revision {run['revision']} in a git export (flagged: "
                   "built artefacts absent).")
    agg = aggregate_tests(snap)
    if agg["unknown"] and run["name"] in agg["unknown"]:
        out.append(f"Headline test totals for the {side} side marked * exclude suite `{run['name']}`.")
    return out


# --- top level ---------------------------------------------------------------


def render_report(*, source: dict | None = None, target: dict | None = None,
                  baseline: dict | None = None, before: dict | None = None,
                  after: dict | None = None) -> str:
    if before is not None and after is not None:
        return _render_pair(before, after)
    if target is None:
        raise ValueError("report needs --target (optionally --source/--baseline), --before/--after or --snapshot")
    title = f"# Migration status: {source['label']} -> {target['label']}" if source else \
        f"# Migration status: {target['label']}"
    parts = [title, "", _provenance(source, target, baseline), "", "## Headline", "",
             render_headline(source, target, baseline)]
    partial = [s for s in (source, target, baseline) if s and aggregate_tests(s)["unknown"]]
    if partial:
        parts += ["", "`*` partial: at least one suite on that side has no measured counts "
                      "(see Caveats); the total covers measured suites only."]
    sides = [(n, s) for n, s in (("source", source), ("target", target), ("baseline", baseline)) if s]
    parts += ["", "## Tests", "", render_test_table(sides)]
    map_snap = source if source and source.get("migration_map") else target
    parts += ["", "## Migration map", "", render_map(map_snap)]
    if baseline:
        parts += ["", "## Progress vs baseline", "", render_pair_deltas(baseline, target)]
        md = render_map_deltas(baseline, target)
        if md:
            parts += ["", "**Migration map status**", "", md]
    parts += ["", "## Language breakdown", ""]
    for snap, title_ in ((source, "Source"), (target, "Target")):
        if snap:
            parts += [render_languages(snap, f"{title_}: {snap['label']}"), ""]
            parts += [render_dirs(snap, f"{title_} directories"), ""]
    parts += ["## Caveats", ""] + [f"- {c}" for c in build_caveats(source, target, baseline)]
    return "\n".join(parts) + "\n"


def _provenance(source, target, baseline) -> str:
    lines = []
    for role, snap in (("Source", source), ("Target", target), ("Baseline target", baseline)):
        if not snap:
            continue
        git = snap.get("git") or {}
        sha = (git.get("commit") or "n/a")[:12]
        lines.append(f"- {role}: `{snap['root']}` revision `{snap['revision']}` (commit `{sha}`, "
                     f"{git.get('commit_date', 'no git info')}); snapshot taken {snap['generated_at']}")
    return "\n".join(lines)


def _render_pair(before: dict, after: dict) -> str:
    parts = [f"# Migration progress: {after['label']}", "",
             _provenance(before, after, None).replace("Source:", "Before:").replace("Target:", "After:"),
             "", "## Change between snapshots", "", render_pair_deltas(before, after)]
    md = render_map_deltas(before, after)
    if md:
        parts += ["", "## Migration map status", "", md]
    parts += ["", "## Tests", "", render_test_table([("before", before), ("after", after)]),
              "", "## Caveats", ""]
    parts += [f"- {c}" for c in build_caveats(None, after, before)[:3]]
    for side, snap in (("before", before), ("after", after)):
        parts += [f"- {c}" for c in _side_caveats(side, snap)]
    return "\n".join(parts) + "\n"


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def _add_scope_args(p: argparse.ArgumentParser, prefix: str = "", ) -> None:
    p.add_argument(f"--{prefix}include", action="append", default=[], metavar="SUBPATH",
                   help="restrict to this path relative to the root (repeatable; default: whole root)")
    p.add_argument(f"--{prefix}exclude", action="append", default=[], metavar="PATTERN",
                   help="exclude a directory/file name glob or root-relative path prefix (repeatable)")


def _add_test_args(p: argparse.ArgumentParser, prefix: str = "") -> None:
    p.add_argument(f"--{prefix}tests", action="append", default=[], metavar="NAME=COMMAND",
                   help="run this test command through a shell (repeatable)")
    p.add_argument(f"--{prefix}collect", action="append", default=[], metavar="NAME=COMMAND",
                   help="count tests only (adds --collect-only to pytest; nothing is executed)")


def build_parser() -> argparse.ArgumentParser:
    ap = argparse.ArgumentParser(
        prog="migration_status.py", description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)

    snap = sub.add_parser("snapshot", help="collect metrics for one repo/revision -> JSON")
    snap.add_argument("--root", required=True, type=Path)
    snap.add_argument("--label", help="display name (default: directory name)")
    snap.add_argument("--role", choices=("source", "target"), default="target")
    _add_scope_args(snap)
    snap.add_argument("--no-default-excludes", action="store_true",
                      help=f"do not skip {', '.join(DEFAULT_EXCLUDES)}")
    snap.add_argument("--tracked-only", action="store_true", help="only files tracked by git")
    snap.add_argument("--rev", help="measure this git revision instead of the working tree")
    snap.add_argument("--run-tests-at-rev", action="store_true",
                      help="with --rev: also run test commands in the exported tree (off by default)")
    snap.add_argument("--map", type=Path, help="MIGRATION_MAP.md (default: auto-detect in root)")
    snap.add_argument("--join-snapshot", type=Path,
                      help="source snapshot JSON (made with --per-file) to join the map to")
    snap.add_argument("--per-file", action="store_true", help="include per-file records in the JSON")
    snap.add_argument("--max-file-bytes", type=int, default=DEFAULT_MAX_FILE_BYTES)
    _add_test_args(snap)
    snap.add_argument("--collect-only", action="store_true", help="treat every --tests as collect-only")
    snap.add_argument("--timeout", type=float, default=DEFAULT_TEST_TIMEOUT, help="per test command, seconds")
    snap.add_argument("--wsl", metavar="DISTRO[:USER]", help="run test commands inside this WSL distro")
    snap.add_argument("--out", type=Path, help="write JSON here (default: stdout)")

    rep = sub.add_parser("report", help="render Markdown from snapshot JSON")
    rep.add_argument("--snapshot", type=Path, help="a single snapshot")
    rep.add_argument("--source", type=Path)
    rep.add_argument("--target", type=Path)
    rep.add_argument("--baseline", type=Path, help="earlier snapshot of the target (deltas)")
    rep.add_argument("--before", type=Path, help="earlier snapshot of one repo (with --after)")
    rep.add_argument("--after", type=Path, help="later snapshot of the same repo")
    rep.add_argument("--out", type=Path, help="write Markdown here (default: stdout)")

    cmp_ = sub.add_parser("compare", help="snapshot source + target (+ baseline) and report")
    cmp_.add_argument("--source", required=True, type=Path)
    cmp_.add_argument("--target", required=True, type=Path)
    cmp_.add_argument("--source-label")
    cmp_.add_argument("--target-label")
    _add_scope_args(cmp_, "source-")
    _add_scope_args(cmp_, "target-")
    cmp_.add_argument("--no-default-excludes", action="store_true")
    cmp_.add_argument("--map", type=Path, help="MIGRATION_MAP.md (default: auto-detect in target)")
    baseline = cmp_.add_mutually_exclusive_group()
    baseline.add_argument("--baseline-rev", help="git revision of the target for the static baseline")
    baseline.add_argument("--baseline-before", metavar="DATE",
                          help='newest target commit before this date, e.g. "1 month ago"')
    cmp_.add_argument("--baseline-run-tests", action="store_true",
                      help="also run the target test commands at the baseline revision (off by default)")
    _add_test_args(cmp_, "source-")
    _add_test_args(cmp_, "target-")
    cmp_.add_argument("--collect-only", action="store_true", help="treat every --*-tests as collect-only")
    cmp_.add_argument("--timeout", type=float, default=DEFAULT_TEST_TIMEOUT)
    cmp_.add_argument("--source-wsl", metavar="DISTRO[:USER]")
    cmp_.add_argument("--target-wsl", metavar="DISTRO[:USER]")
    cmp_.add_argument("--max-file-bytes", type=int, default=DEFAULT_MAX_FILE_BYTES)
    cmp_.add_argument("--save-snapshots", type=Path, metavar="DIR", help="write the snapshot JSON files here")
    cmp_.add_argument("--out", type=Path, help="write Markdown here (default: stdout)")
    return ap


def _wsl(text: str | None) -> WslSpec | None:
    return WslSpec.parse(text) if text else None


def _load_json(path: Path) -> dict:
    snap = json.loads(path.read_text(encoding="utf-8"))
    if snap.get("schema_version") != SCHEMA_VERSION:
        raise SystemExit(f"{path}: unsupported schema_version {snap.get('schema_version')!r} "
                         f"(this tool writes {SCHEMA_VERSION})")
    return snap


def _dump_json(snap: dict) -> str:
    return json.dumps(snap, indent=2, sort_keys=True, ensure_ascii=False) + "\n"


def _write(text: str, out: Path | None) -> None:
    if out is None:
        sys.stdout.write(text)
        return
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(text, encoding="utf-8", newline="\n")
    print(f"wrote {out}", file=sys.stderr)


def cmd_snapshot(args: argparse.Namespace) -> int:
    join_files = None
    if args.join_snapshot:
        join_files = _load_json(args.join_snapshot).get("files")
        if join_files is None:
            raise SystemExit("--join-snapshot needs a snapshot made with --per-file")
    opts = SideOptions(
        root=args.root, label=args.label or args.root.resolve().name, role=args.role,
        includes=args.include, excludes=args.exclude, default_excludes=not args.no_default_excludes,
        tracked_only=args.tracked_only, max_bytes=args.max_file_bytes, map_path=args.map,
        join_files=join_files, tests=parse_test_specs(args.tests), collects=parse_test_specs(args.collect),
        collect_only=args.collect_only, timeout=args.timeout, wsl=_wsl(args.wsl), per_file=args.per_file)
    snap, _ = build_snapshot(opts, rev=args.rev, run_tests_at_rev=args.run_tests_at_rev)
    _write(_dump_json(snap), args.out)
    return 0


def cmd_report(args: argparse.Namespace) -> int:
    load = lambda p: _load_json(p) if p else None  # noqa: E731
    if args.before or args.after:
        if not (args.before and args.after):
            raise SystemExit("--before and --after must be given together")
        text = render_report(before=load(args.before), after=load(args.after))
    elif args.snapshot:
        text = render_report(target=load(args.snapshot))
    else:
        if not args.target:
            raise SystemExit("report needs --target (with optional --source/--baseline), "
                             "--before/--after, or --snapshot")
        text = render_report(source=load(args.source), target=load(args.target),
                             baseline=load(args.baseline))
    _write(text, args.out)
    return 0


def cmd_compare(args: argparse.Namespace) -> int:
    default_excl = not args.no_default_excludes
    src = SideOptions(
        root=args.source, label=args.source_label or args.source.resolve().name, role="source",
        includes=args.source_include, excludes=args.source_exclude, default_excludes=default_excl,
        max_bytes=args.max_file_bytes, tests=parse_test_specs(args.source_tests),
        collects=parse_test_specs(args.source_collect), collect_only=args.collect_only,
        timeout=args.timeout, wsl=_wsl(args.source_wsl), per_file=True)
    use_baseline = bool(args.baseline_rev or args.baseline_before)
    tgt = SideOptions(
        root=args.target, label=args.target_label or args.target.resolve().name, role="target",
        includes=args.target_include, excludes=args.target_exclude, default_excludes=default_excl,
        tracked_only=use_baseline, max_bytes=args.max_file_bytes, map_path=args.map,
        tests=parse_test_specs(args.target_tests), collects=parse_test_specs(args.target_collect),
        collect_only=args.collect_only, timeout=args.timeout, wsl=_wsl(args.target_wsl))
    source_snap, _ = build_snapshot(src)
    join_files = source_snap["files"]
    tgt.join_files = join_files
    target_snap, _ = build_snapshot(tgt)
    baseline_snap = None
    if use_baseline:
        rev = args.baseline_rev or rev_before(args.target.resolve(), args.baseline_before)
        baseline_snap, _ = build_snapshot(tgt, rev=rev, run_tests_at_rev=args.baseline_run_tests)
        target_snap["notes"].append("Target measured over git-tracked files only so that it is "
                                    "comparable with the baseline export.")
    if args.save_snapshots:
        _save_snapshots(args.save_snapshots, source_snap, target_snap, baseline_snap)
    source_snap.pop("files", None)
    _write(render_report(source=source_snap, target=target_snap, baseline=baseline_snap), args.out)
    return 0


def _save_snapshots(directory: Path, source: dict, target: dict, baseline: dict | None) -> None:
    for name, snap in (("source", source), ("target", target), ("target_baseline", baseline)):
        if snap:
            _write(_dump_json(snap), directory / f"{name}.json")


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        return {"snapshot": cmd_snapshot, "report": cmd_report, "compare": cmd_compare}[args.cmd](args)
    except (RuntimeError, ValueError, OSError) as exc:
        print(f"migration_status: error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
