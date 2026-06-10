#!/usr/bin/env python3
"""GitHub repo crawler for the data flywheel.

Searches GitHub for permissively-licensed C++ and Python repos, extracts
self-contained functions, transpiles them to Mojo (or any target), verifies
correctness, and appends verified pairs to a growing JSONL dataset.

Verification gates
------------------
Two gates, matching the quality bar of scripts/build_cpp_mojo_dataset.py
(the pipeline behind data/sft/cpp_mojo/train_translation.jsonl):

1. **Compile gate** — the transpiled output must compile on the target
   toolchain (always on).
2. **Behavioral gate** (default on; ``--no-behavioral`` to disable) — both the
   *source* function and the *target* translation are wrapped in a generated
   ``main()`` harness, compiled as standalone executables, run on ~125
   deterministically-sampled inputs (edge values + spread values + literals
   mined from the source body, seeded from the function fingerprint), and
   their outputs compared line-by-line: 1e-9 tolerance for floats (absolute,
   relaxing to relative above magnitude 1), exact for ints/bools.

Behavioral outcomes:
  * pass            -> pair written with ``metadata.verification = "behavioral"``
  * genuine output mismatch -> pair **dropped** (provably wrong translation)
  * infrastructure failure (missing toolchain, unsupported harness target,
    runtime crash/timeout, unparseable signature) -> pair written with
    ``metadata.verification = "compile-only"`` plus the skip reason, so
    downstream training can filter.

Full behavioral harnesses exist for source langs {cpp, c, python} and target
langs {mojo, rust, c, go, python}; other targets fall back to compile-only.
Missing toolchains (no ``mojo``/``rustc``/``gcc``/``go`` on PATH) are warned
about once and degrade to compile-only — never a silent pass.

Usage (one-shot):
    uv run python scripts/crawl_github.py \
        --targets mojo rust \
        --source cpp \
        --limit-repos 20 \
        --limit-fns 200 \
        --out data/sft/github_crawl/verified.jsonl

Usage (continuous — run forever, collecting pairs):
    uv run python scripts/crawl_github.py --continuous --source cpp --targets mojo

Requirements:
    GITHUB_TOKEN env var (personal access token, read:repo scope)
    ANTHROPIC_API_KEY or OPENAI_API_KEY (optional — enables LLM type filling)

Algorithm:
    1. Search GitHub API for repos: language + permissive license + ≥N stars
    2. Clone each to a temp dir
    3. Extract pure-scalar functions via tree-sitter (primitives only, no custom types)
    4. Feed each through the transpiler pipeline
    5. Run compile gate on each target
    6. Run behavioral gate (generate main() harnesses for source + target,
       execute both, compare outputs to 1e-9) unless --no-behavioral
    7. Append passing pairs to output JSONL (Alpaca schema) tagged
       metadata.verification = "behavioral" | "compile-only"
"""

from __future__ import annotations

import argparse
import ast
import hashlib
import json
import logging
import os
import re
import shutil
import subprocess
import sys
import tempfile
import textwrap
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterator

REPO_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_ROOT / "src"))

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger(__name__)

# GitHub API
_GH_API = "https://api.github.com"
_PERMISSIVE_LICENSES = {"mit", "apache-2.0", "bsd-2-clause", "bsd-3-clause", "isc", "unlicense", "0bsd"}

# Languages to crawl and their file extensions
_LANG_EXT: dict[str, list[str]] = {
    "cpp": [".cpp", ".cc", ".cxx", ".h", ".hpp"],
    "python": [".py"],
    "c": [".c", ".h"],
}

# Primitive C++ types accepted in self-contained function signatures
_CPP_PRIMITIVE_TYPES = {
    "int", "long", "short", "char", "bool", "float", "double",
    "int8_t", "int16_t", "int32_t", "int64_t",
    "uint8_t", "uint16_t", "uint32_t", "uint64_t",
    "Real64", "Real32", "size_t", "ptrdiff_t",
    "unsigned", "signed", "void",
}

# Python primitive annotations accepted in self-contained functions
_PY_PRIMITIVE_TYPES = {"int", "float", "bool", "str", "bytes", "None"}


# ---------------------------------------------------------------------------
# GitHub API helpers
# ---------------------------------------------------------------------------

def _gh_headers() -> dict:
    token = os.getenv("GITHUB_TOKEN")
    h = {"Accept": "application/vnd.github+json", "X-GitHub-Api-Version": "2022-11-28"}
    if token:
        h["Authorization"] = f"Bearer {token}"
    return h


def _gh_get(url: str, params: dict | None = None) -> dict:
    import urllib.request, urllib.parse
    if params:
        url = f"{url}?{urllib.parse.urlencode(params)}"
    req = urllib.request.Request(url, headers=_gh_headers())
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read())


def search_repos(
    language: str,
    min_stars: int = 100,
    max_repos: int = 30,
    page_size: int = 30,
) -> list[dict]:
    """Return up to *max_repos* repo dicts from GitHub code search."""
    results: list[dict] = []
    page = 1
    while len(results) < max_repos:
        data = _gh_get(
            f"{_GH_API}/search/repositories",
            params={
                "q": f"language:{language} stars:>={min_stars} license:mit license:apache-2.0",
                "sort": "stars",
                "order": "desc",
                "per_page": min(page_size, max_repos - len(results)),
                "page": page,
            },
        )
        items = data.get("items", [])
        if not items:
            break
        for item in items:
            lic = (item.get("license") or {}).get("spdx_id", "").lower()
            if any(p in lic for p in _PERMISSIVE_LICENSES):
                results.append(item)
        page += 1
        if len(items) < page_size:
            break
        time.sleep(0.5)
    return results[:max_repos]


# ---------------------------------------------------------------------------
# Function extraction
# ---------------------------------------------------------------------------

@dataclass
class FnCandidate:
    source_code: str
    source_lang: str
    repo_name: str
    file_path: str
    fn_name: str


def _is_primitive_cpp_type(type_str: str) -> bool:
    parts = type_str.replace("*", " ").replace("&", " ").replace("const", " ").split()
    return all(p in _CPP_PRIMITIVE_TYPES for p in parts if p)


def _is_primitive_py_annotation(ann: str) -> bool:
    return ann.strip().rstrip("?") in _PY_PRIMITIVE_TYPES or ann.strip() == ""


def extract_cpp_functions(source: str, repo_name: str, file_path: str) -> list[FnCandidate]:
    """Extract self-contained scalar C++ functions via regex heuristic.

    Accepts only functions whose parameter types are all primitive C++ types.
    This avoids pulling in class methods, templates, and EnergyPlus-data args.
    """
    import re
    # Match: ReturnType FunctionName(args) { body }
    # Simple heuristic: single-line signature, braces balanced, no templates
    pattern = re.compile(
        r'\b((?:inline\s+|static\s+|constexpr\s+)*'
        r'(?:Real64|Real32|double|float|int|long|bool|char|void|unsigned|int\d+_t|uint\d+_t)\s*\*?)\s+'
        r'([A-Za-z_]\w*)\s*\(([^)]*)\)\s*\{',
        re.MULTILINE,
    )
    candidates = []
    for m in pattern.finditer(source):
        ret_type = m.group(1).strip()
        fn_name = m.group(2)
        params_str = m.group(3)

        # Skip constructors, operators, main
        if fn_name in ("main", "operator"):
            continue

        # Check all param types are primitive
        ok = True
        for param in params_str.split(","):
            param = param.strip()
            if not param:
                continue
            # Remove default value
            param = param.split("=")[0].strip()
            # Remove param name (last word)
            parts = param.split()
            type_parts = parts[:-1] if len(parts) > 1 else parts
            type_str = " ".join(type_parts)
            if not _is_primitive_cpp_type(type_str):
                ok = False
                break
        if not ok:
            continue

        # Extract function body via brace matching
        start = m.start()
        brace_start = source.index("{", m.start())
        depth = 0
        end = brace_start
        for i, ch in enumerate(source[brace_start:], start=brace_start):
            if ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
                if depth == 0:
                    end = i + 1
                    break
        fn_source = source[start:end]

        # Skip trivially short or very long functions
        lines = fn_source.count("\n")
        if lines < 3 or lines > 150:
            continue

        candidates.append(FnCandidate(
            source_code=fn_source,
            source_lang="cpp",
            repo_name=repo_name,
            file_path=file_path,
            fn_name=fn_name,
        ))
    return candidates


def extract_python_functions(source: str, repo_name: str, file_path: str) -> list[FnCandidate]:
    """Extract self-contained Python functions with primitive type annotations."""
    import ast
    try:
        tree = ast.parse(source)
    except SyntaxError:
        return []

    candidates = []
    lines = source.splitlines(keepends=True)

    for node in ast.walk(tree):
        if not isinstance(node, ast.FunctionDef):
            continue
        # Require all args to have primitive annotations
        all_primitive = True
        for arg in node.args.args:
            if arg.annotation is None:
                all_primitive = False
                break
            ann = ast.unparse(arg.annotation)
            if not _is_primitive_py_annotation(ann):
                all_primitive = False
                break
        if not all_primitive:
            continue

        # Skip methods (inside class)
        fn_lines = node.end_lineno - node.lineno + 1
        if fn_lines < 3 or fn_lines > 100:
            continue

        fn_source = "".join(lines[node.lineno - 1:node.end_lineno])
        candidates.append(FnCandidate(
            source_code=fn_source,
            source_lang="python",
            repo_name=repo_name,
            file_path=file_path,
            fn_name=node.name,
        ))
    return candidates


def iter_repo_functions(clone_dir: Path, source_lang: str, repo_name: str) -> Iterator[FnCandidate]:
    """Walk all source files in *clone_dir* and yield function candidates."""
    exts = _LANG_EXT.get(source_lang, [])
    extractor = extract_cpp_functions if source_lang in ("cpp", "c") else extract_python_functions

    for fpath in clone_dir.rglob("*"):
        if fpath.suffix not in exts:
            continue
        if any(p in str(fpath) for p in ("test", "Test", "spec", "Spec", "vendor", "third_party", "extern")):
            continue
        try:
            source = fpath.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        rel = str(fpath.relative_to(clone_dir))
        yield from extractor(source, repo_name, rel)


# ---------------------------------------------------------------------------
# Clone helpers
# ---------------------------------------------------------------------------

def clone_repo(clone_url: str, dest: Path, depth: int = 1) -> bool:
    """Shallow-clone *clone_url* into *dest*. Returns True on success."""
    result = subprocess.run(
        ["git", "clone", "--depth", str(depth), "--quiet", clone_url, str(dest)],
        capture_output=True,
        timeout=120,
    )
    return result.returncode == 0


# ---------------------------------------------------------------------------
# Transpile + verify
# ---------------------------------------------------------------------------

@dataclass
class PairResult:
    candidate: FnCandidate
    target: str
    output: str
    compile_ok: bool
    compile_stderr: str = ""


def transpile_and_verify(candidate: FnCandidate, target: str, llm_fill=None) -> PairResult:
    from transpilers.pipeline.stages import TARGETS, run_stages

    try:
        trace = run_stages(
            candidate.source_code,
            source_lang=candidate.source_lang,
            target=target,
            llm_fill=llm_fill,
        )
        output = trace.output
    except Exception as exc:
        return PairResult(candidate=candidate, target=target, output="", compile_ok=False, compile_stderr=str(exc))

    _, _, verify_fn = TARGETS[target]
    cr = verify_fn(output)
    return PairResult(candidate=candidate, target=target, output=output, compile_ok=cr.ok, compile_stderr=cr.stderr)


# ---------------------------------------------------------------------------
# Behavioral verification gate
#
# Run-and-compare, mirroring scripts/build_cpp_mojo_dataset.py: compile BOTH
# the source function and the target translation as standalone executables
# with a generated main() harness, run them on ~125 deterministically-sampled
# inputs, and compare outputs to 1e-9. Only pairs that agree numerically earn
# metadata.verification = "behavioral".
# ---------------------------------------------------------------------------

_RUN_TIMEOUT = 5         # seconds per executable run
_COMPILE_TIMEOUT = 120   # seconds per compile (mojo is slow; `mojo run` compiles too)
_FLOAT_TOL = 1e-9        # absolute for |x|<=1, relative above (matches dataset bar)
_MIN_COMPARABLE = 4      # need at least this many finite agreeing points

# Scalar "kinds" drive sampling, literal formatting, and output comparison.
_CPP_KIND = {
    "float": "float", "double": "float", "Real64": "float", "Real32": "float",
    "int": "int", "long": "int", "short": "int", "signed": "int", "unsigned": "int",
    "int8_t": "int", "int16_t": "int", "int32_t": "int", "int64_t": "int",
    "uint8_t": "int", "uint16_t": "int", "uint32_t": "int", "uint64_t": "int",
    "size_t": "int", "ptrdiff_t": "int",
    "bool": "bool",
}
_PY_KIND = {"int": "int", "float": "float", "bool": "bool"}
_MOJO_KIND = {
    "Float64": "float", "Float32": "float",
    "Int": "int", "Int8": "int", "Int16": "int", "Int32": "int", "Int64": "int",
    "UInt8": "int", "UInt16": "int", "UInt32": "int", "UInt64": "int",
    "Bool": "bool",
}
_RUST_KIND = {
    "f64": "float", "f32": "float",
    "i8": "int", "i16": "int", "i32": "int", "i64": "int", "i128": "int",
    "u8": "int", "u16": "int", "u32": "int", "u64": "int", "u128": "int",
    "isize": "int", "usize": "int",
    "bool": "bool",
}
_GO_KIND = {
    "float64": "float", "float32": "float",
    "int": "int", "int8": "int", "int16": "int", "int32": "int", "int64": "int",
    "uint": "int", "uint8": "int", "uint16": "int", "uint32": "int", "uint64": "int",
    "bool": "bool",
}

# Toolchain binary required to *execute* each side. None = always available
# (Python runs via sys.executable).
_SOURCE_TOOL: dict[str, str | None] = {"cpp": "g++", "c": "gcc", "python": None}
_TARGET_TOOL: dict[str, str | None] = {"mojo": "mojo", "rust": "rustc", "c": "gcc", "go": "go", "python": None}

_missing_tool_warned: set[str] = set()


def _toolchain_missing(tool: str | None) -> bool:
    if tool is None:
        return False
    if shutil.which(tool):
        return False
    if tool not in _missing_tool_warned:
        _missing_tool_warned.add(tool)
        log.warning(
            "Behavioral verification: `%s` not found on PATH — affected pairs "
            "will be marked compile-only, not behaviorally verified.", tool,
        )
    return True


@dataclass
class FnSig:
    name: str
    param_kinds: list[str]      # each in {"float","int","bool"}
    ret_kind: str | None        # None = unknown -> generic compare


def _parse_source_sig(candidate: FnCandidate) -> tuple[FnSig | None, str]:
    """Parse (param kinds, return kind) from the SOURCE function signature."""
    if candidate.source_lang == "python":
        try:
            tree = ast.parse(textwrap.dedent(candidate.source_code))
        except SyntaxError:
            return None, "py-parse-error"
        fn = next((n for n in ast.walk(tree) if isinstance(n, ast.FunctionDef)), None)
        if fn is None:
            return None, "no-functiondef"
        if fn.args.posonlyargs or fn.args.kwonlyargs or fn.args.vararg or fn.args.kwarg or fn.args.defaults:
            return None, "non-positional-args"
        kinds = []
        for arg in fn.args.args:
            ann = ast.unparse(arg.annotation).strip() if arg.annotation else ""
            kind = _PY_KIND.get(ann)
            if kind is None:
                return None, f"param-kind-unsupported:{ann or '<missing>'}"
            kinds.append(kind)
        ret = None
        if fn.returns is not None:
            ret = _PY_KIND.get(ast.unparse(fn.returns).strip())
            if ret is None:
                return None, "return-kind-unsupported"
        return FnSig(name=fn.name, param_kinds=kinds, ret_kind=ret), ""

    # cpp / c — the crawler's extraction regex guarantees a single-line
    # primitive-typed signature at the start of source_code.
    m = re.match(
        r"\s*(?:inline\s+|static\s+|constexpr\s+)*([A-Za-z_]\w*(?:\s+[A-Za-z_]\w*)*?)\s+"
        r"([A-Za-z_]\w*)\s*\(([^)]*)\)",
        candidate.source_code,
    )
    if not m:
        return None, "cpp-sig-no-match"
    ret_str, name, params_str = m.group(1).strip(), m.group(2), m.group(3)
    if "*" in candidate.source_code.split("{", 1)[0] or "&" in candidate.source_code.split("{", 1)[0]:
        return None, "pointer-or-ref-params"
    ret = _CPP_KIND.get(ret_str.replace("const", " ").split()[-1])
    if ret is None:
        return None, f"return-kind-unsupported:{ret_str}"
    kinds = []
    for raw in params_str.split(","):
        p = raw.split("=")[0].replace("const", " ").strip()
        if not p or p == "void":
            continue
        toks = p.split()
        type_toks = toks[:-1] if len(toks) > 1 else toks
        kind = _CPP_KIND.get(type_toks[-1]) if type_toks else None
        if kind is None:
            return None, f"param-kind-unsupported:{p}"
        kinds.append(kind)
    return FnSig(name=name, param_kinds=kinds, ret_kind=ret), ""


def _parse_target_sig(target: str, output: str, fn_name: str) -> tuple[FnSig | None, str]:
    """Parse the transpiled TARGET signature (for call-literal formatting)."""
    def _kinds(parts: list[str], table: dict, colon: bool) -> list[str] | None:
        kinds = []
        for raw in parts:
            p = raw.strip()
            if not p:
                continue
            if colon:
                if ":" not in p:
                    return None
                ty = p.split(":", 1)[1].strip()
            else:  # go: `name type`
                toks = p.split()
                if len(toks) != 2:
                    return None
                ty = toks[1]
            ty = re.sub(r"^(?:mut|owned|borrowed|read|inout)\s+", "", ty).strip()
            k = table.get(ty)
            if k is None:
                return None
            kinds.append(k)
        return kinds

    if target == "mojo":
        m = re.search(rf"(?:def|fn)\s+{re.escape(fn_name)}\s*\(([^)]*)\)\s*(?:raises\s*)?->\s*(\w+)", output)
        if not m:
            return None, "mojo-sig-no-match"
        params = [re.sub(r"^\s*(?:mut|owned|borrowed|read)\s+", "", p) for p in m.group(1).split(",")]
        kinds = _kinds(params, _MOJO_KIND, colon=True)
        ret = _MOJO_KIND.get(m.group(2))
        if kinds is None or ret is None:
            return None, "mojo-type-unsupported"
        return FnSig(name=fn_name, param_kinds=kinds, ret_kind=ret), ""

    if target == "rust":
        m = re.search(rf"fn\s+{re.escape(fn_name)}\s*\(([^)]*)\)\s*->\s*([\w]+)", output)
        if not m:
            return None, "rust-sig-no-match"
        params = [re.sub(r"^\s*mut\s+", "", p) for p in m.group(1).split(",")]
        kinds = _kinds(params, _RUST_KIND, colon=True)
        ret = _RUST_KIND.get(m.group(2))
        if kinds is None or ret is None:
            return None, "rust-type-unsupported"
        return FnSig(name=fn_name, param_kinds=kinds, ret_kind=ret), ""

    if target == "c":
        m = re.search(rf"([A-Za-z_][\w ]*?)\s+{re.escape(fn_name)}\s*\(([^)]*)\)\s*\{{", output)
        if not m:
            return None, "c-sig-no-match"
        ret = _CPP_KIND.get(m.group(1).replace("const", " ").split()[-1])
        kinds = []
        for raw in m.group(2).split(","):
            p = raw.replace("const", " ").strip()
            if not p or p == "void":
                continue
            toks = p.split()
            k = _CPP_KIND.get(toks[-2]) if len(toks) >= 2 else None
            if k is None:
                return None, "c-type-unsupported"
            kinds.append(k)
        if ret is None:
            return None, "c-type-unsupported"
        return FnSig(name=fn_name, param_kinds=kinds, ret_kind=ret), ""

    if target == "go":
        m = re.search(rf"func\s+{re.escape(fn_name)}\s*\(([^)]*)\)\s*(\w*)\s*\{{", output)
        if not m:
            return None, "go-sig-no-match"
        kinds = _kinds(m.group(1).split(","), _GO_KIND, colon=False)
        ret = _GO_KIND.get(m.group(2))
        if kinds is None or ret is None:
            return None, "go-type-unsupported"
        return FnSig(name=fn_name, param_kinds=kinds, ret_kind=ret), ""

    if target == "python":
        m = re.search(rf"def\s+{re.escape(fn_name)}\s*\(([^)]*)\)\s*(?:->\s*([\w\[\], ]+?))?\s*:", output)
        if not m:
            return None, "python-sig-no-match"
        kinds = _kinds(m.group(1).split(","), _PY_KIND, colon=True)
        ret = _PY_KIND.get((m.group(2) or "").strip()) if m.group(2) else None
        if kinds is None:
            return None, "python-type-unsupported"
        return FnSig(name=fn_name, param_kinds=kinds, ret_kind=ret), ""

    return None, "harness-unsupported"


# --- input sampling (adapted from build_cpp_mojo_dataset._sample_inputs) ----

_NUM_LITERAL = re.compile(r"(?<![A-Za-z_0-9.])(-?\d+\.\d+(?:[eE][-+]?\d+)?|-?\d+(?:[eE][-+]?\d+)?)")


def _source_thresholds(source_code: str) -> list[float]:
    """Numeric literals in the source body — branch predicates compare against
    these, so probing just below / at / just above each exercises branches."""
    vals = set()
    for m in _NUM_LITERAL.finditer(source_code):
        try:
            v = float(m.group(1))
        except ValueError:
            continue
        if abs(v) < 1e12:
            vals.add(v)
    return sorted(vals)


def _behavioral_inputs(param_kinds: list[str], source_code: str, fingerprint: str,
                       n: int = 120) -> list[list[float]]:
    """Deterministic threshold- and domain-aware input spread (~n+5 rows).

    Per-arg pool = {domain spread} ∪ {each source literal and literal±eps}.
    Rows are drawn independently per column by an LCG seeded from the function
    *fingerprint* (deterministic per function, NOT random)."""
    domain = [-1.0, -0.95, -0.5, -0.3827, -0.1, 0.0, 0.05, 0.1, 0.3, 0.3827,
              0.5, 0.7, 0.9239, 0.99, 1.0, 1.5, 5.0, 12.0, 23.5, 37.0, 50.0,
              100.0, 250.0, -2.0, -15.0]
    thr = _source_thresholds(source_code)
    eps = 1e-6
    pool = list(domain)
    for t in thr:
        scale = max(abs(t), 1.0)
        pool += [t, t - eps * scale, t + eps * scale]
    seen, uniq = set(), []
    for v in pool:
        k = round(v, 12)
        if k not in seen:
            seen.add(k)
            uniq.append(v)

    rows: list[list[float]] = []
    state = int(fingerprint, 16) & 0x7FFFFFFF or 2463534242
    for _ in range(n):
        row = []
        for kind in param_kinds:
            state = (1103515245 * state + 12345) & 0x7FFFFFFF
            v = uniq[state % len(uniq)]
            if kind == "int":
                v = float(int(abs(v)) % 64)
            elif kind == "bool":
                v = float(state & 1)
            row.append(v)
        rows.append(row)
    # All-args-equal rows hit `(a - b) == 0` style branches.
    for val in (0.0, 1.0, 23.5, 50.0, -2.0):
        rows.append([0.0 if k in ("int", "bool") else val for k in param_kinds])
    return rows


def _fmt_arg(v: float, kind: str, lang: str) -> str:
    """Format one sampled value as a literal in *lang*."""
    if kind == "int":
        return str(int(v))
    if kind == "bool":
        if lang in ("python", "mojo"):
            return "True" if v else "False"
        return "true" if v else "false"
    return repr(v)  # repr(float) always round-trips and always has '.'/'e'


# --- harness generation + execution ----------------------------------------

# Helper preamble for standalone C++ source compilation (trimmed copy of
# build_cpp_mojo_dataset._CPP_HELPERS — keep in sync). Lets EnergyPlus-style
# bodies (pow_2, sign, unqualified min/max, Constant::Pi) link standalone;
# generic GitHub code that redefines these simply fails source-compile and
# falls back to compile-only.
_CPP_BEHAVIORAL_HELPERS = r"""
#include <cstdio>
#include <cmath>
#include <cstdint>
#include <cstdlib>
typedef double Real64;
typedef float Real32;
static inline double pow_2(double x){return x*x;}
static inline double pow_3(double x){return x*x*x;}
static inline double pow_4(double x){return x*x*x*x;}
static inline double pow_5(double x){return x*x*x*x*x;}
static inline double pow_6(double x){double y=x*x*x;return y*y;}
static inline double root_4(double x){return std::sqrt(std::sqrt(x));}
static inline double mod(double a,double b){return std::fmod(a,b);}
static inline int mod(int a,int b){return a%b;}
static inline double sign(double a,double b){return b>=0.0?std::fabs(a):-std::fabs(a);}
static inline double max(double a,double b){return a>b?a:b;}
static inline double min(double a,double b){return a<b?a:b;}
static inline int max(int a,int b){return a>b?a:b;}
static inline int min(int a,int b){return a<b?a:b;}
namespace Constant {
constexpr double Pi=3.14159265358979324; constexpr double PiOvr2=Pi/2.0;
constexpr double TwoPi=2.0*Pi; constexpr double Gravity=9.807;
constexpr double DegToRad=Pi/180.0; constexpr double RadToDeg=180.0/Pi;
constexpr double Kelvin=273.15; constexpr double StefanBoltzmann=5.6697E-8;
constexpr double MaxEXPArg=709.78;
}
"""

_C_BEHAVIORAL_HELPERS = "#include <stdio.h>\n#include <math.h>\n#include <stdint.h>\n#include <stdbool.h>\n#include <stdlib.h>\n"


def _run_proc(cmd: list[str], timeout: int, cwd: Path | None = None) -> subprocess.CompletedProcess | None:
    """Run *cmd*; None on timeout or missing binary."""
    try:
        return subprocess.run(cmd, capture_output=True, text=True, timeout=timeout,
                              cwd=str(cwd) if cwd else None)
    except (subprocess.TimeoutExpired, OSError):
        return None


def _parse_indexed_output(stdout: str) -> dict[str, str]:
    """Parse `<index> <value>` lines into {index: value}."""
    out: dict[str, str] = {}
    for ln in stdout.splitlines():
        parts = ln.split()
        if len(parts) == 2 and parts[0].isdigit():
            out[parts[0]] = parts[1]
    return out


def _py_harness(body: str, sig: FnSig, rows: list[list[float]]) -> str:
    """Module text: dedented source + __main__ block printing repr per index.
    Each call is try-wrapped so one bad input (ZeroDivisionError etc.) only
    drops that index instead of killing the whole run."""
    calls = "\n".join(
        f"    try:\n"
        f"        print({i}, repr({sig.name}("
        + ", ".join(_fmt_arg(v, k, "python") for v, k in zip(row, sig.param_kinds))
        + ")))\n"
        f"    except Exception:\n"
        f"        pass"
        for i, row in enumerate(rows)
    )
    return textwrap.dedent(body) + f'\n\nif __name__ == "__main__":\n{calls}\n'


def _exec_source(candidate: FnCandidate, sig: FnSig, rows: list[list[float]],
                 td: Path) -> tuple[dict[str, str] | None, str]:
    """Compile (if needed) + run the SOURCE function harness."""
    lang = candidate.source_lang
    if lang == "python":
        f = td / "src_harness.py"
        f.write_text(_py_harness(candidate.source_code, sig, rows), encoding="utf-8")
        r = _run_proc([sys.executable, str(f)], _RUN_TIMEOUT)
        if r is None:
            return None, "run-timeout"
        if r.returncode != 0:
            return None, f"run-crash:{(r.stderr or '').strip()[:120]}"
        return _parse_indexed_output(r.stdout), ""

    if lang in ("cpp", "c"):
        cxx = lang == "cpp"
        calls = "\n".join(
            f'  printf("%d %.17g\\n", {i}, (double){sig.name}('
            + ", ".join(_fmt_arg(v, k, lang) for v, k in zip(row, sig.param_kinds))
            + "));"
            for i, row in enumerate(rows)
        )
        helpers = _CPP_BEHAVIORAL_HELPERS if cxx else _C_BEHAVIORAL_HELPERS
        src = f"{helpers}\n{candidate.source_code}\nint main(void){{\n{calls}\n  return 0;\n}}\n"
        f = td / ("src_harness.cpp" if cxx else "src_harness.c")
        f.write_text(src, encoding="utf-8")
        exe = td / "src_oracle"
        cmd = (["g++", "-O0", "-std=c++17", "-DNDEBUG"] if cxx
               else ["gcc", "-O0", "-std=c11", "-DNDEBUG"])
        r = _run_proc(cmd + ["-o", str(exe), str(f)] + ([] if cxx else ["-lm"]), _COMPILE_TIMEOUT)
        if r is None:
            return None, "compile-timeout"
        if r.returncode != 0:
            return None, f"compile-failed:{(r.stderr or '').strip().splitlines()[-1][:120] if r.stderr else ''}"
        r = _run_proc([str(exe)], _RUN_TIMEOUT, cwd=td)
        if r is None:
            return None, "run-timeout"
        if r.returncode != 0:
            return None, "run-crash"
        return _parse_indexed_output(r.stdout), ""

    return None, "harness-unsupported"


def _exec_target(target: str, output: str, sig: FnSig, rows: list[list[float]],
                 td: Path) -> tuple[dict[str, str] | None, str]:
    """Compile + run the TARGET translation harness."""
    def args_for(row: list[float]) -> str:
        return ", ".join(_fmt_arg(v, k, target) for v, k in zip(row, sig.param_kinds))

    if target == "python":
        f = td / "tgt_harness.py"
        f.write_text(_py_harness(output, sig, rows), encoding="utf-8")
        r = _run_proc([sys.executable, str(f)], _RUN_TIMEOUT)
        if r is None:
            return None, "run-timeout"
        if r.returncode != 0:
            return None, f"run-crash:{(r.stderr or '').strip()[:120]}"
        return _parse_indexed_output(r.stdout), ""

    if target == "mojo":
        calls = "\n".join(f"    print({i}, {sig.name}({args_for(row)}))" for i, row in enumerate(rows))
        f = td / "tgt_harness.mojo"
        f.write_text(f"{output}\n\ndef main():\n{calls}\n", encoding="utf-8")
        # `mojo run` compiles + executes in one step; use the compile timeout.
        r = _run_proc(["mojo", "run", str(f)], _COMPILE_TIMEOUT, cwd=td)
        if r is None:
            return None, "run-timeout"
        if r.returncode != 0:
            return None, f"run-crash:{(r.stderr or '').strip().splitlines()[-1][:120] if r.stderr else ''}"
        return _parse_indexed_output(r.stdout), ""

    if target == "rust":
        calls = "\n".join(
            '    println!("{} {:?}", ' + str(i) + f", {sig.name}({args_for(row)}));"
            for i, row in enumerate(rows)
        )
        f = td / "tgt_harness.rs"
        f.write_text(f"#![allow(warnings)]\n{output}\nfn main() {{\n{calls}\n}}\n", encoding="utf-8")
        exe = td / "tgt_prog"
        r = _run_proc(["rustc", "--edition", "2021", "-O", str(f), "-o", str(exe)], _COMPILE_TIMEOUT)
        if r is None:
            return None, "compile-timeout"
        if r.returncode != 0:
            return None, f"compile-failed:{(r.stderr or '').strip().splitlines()[-1][:120] if r.stderr else ''}"
        r = _run_proc([str(exe)], _RUN_TIMEOUT, cwd=td)
        if r is None:
            return None, "run-timeout"
        if r.returncode != 0:
            return None, "run-crash"
        return _parse_indexed_output(r.stdout), ""

    if target == "c":
        calls = "\n".join(
            f'  printf("%d %.17g\\n", {i}, (double){sig.name}({args_for(row)}));'
            for i, row in enumerate(rows)
        )
        f = td / "tgt_harness.c"
        f.write_text(f"{output}\n#include <stdio.h>\nint main(void){{\n{calls}\n  return 0;\n}}\n", encoding="utf-8")
        exe = td / "tgt_prog"
        r = _run_proc(["gcc", "-O0", "-std=c11", str(f), "-o", str(exe), "-lm"], _COMPILE_TIMEOUT)
        if r is None:
            return None, "compile-timeout"
        if r.returncode != 0:
            return None, f"compile-failed:{(r.stderr or '').strip().splitlines()[-1][:120] if r.stderr else ''}"
        r = _run_proc([str(exe)], _RUN_TIMEOUT, cwd=td)
        if r is None:
            return None, "run-timeout"
        if r.returncode != 0:
            return None, "run-crash"
        return _parse_indexed_output(r.stdout), ""

    if target == "go":
        if '"fmt"' in output:
            return None, "go-already-imports-fmt"
        src = output.replace("package main", 'package main\n\nimport "fmt"', 1)
        calls = "\n".join(f"    fmt.Println({i}, {sig.name}({args_for(row)}))" for i, row in enumerate(rows))
        src += f"\n\nfunc main() {{\n{calls}\n}}\n"
        f = td / "tgt_harness.go"
        f.write_text(src, encoding="utf-8")
        exe = td / "tgt_prog"
        r = _run_proc(["go", "build", "-o", str(exe), str(f)], _COMPILE_TIMEOUT, cwd=td)
        if r is None:
            return None, "compile-timeout"
        if r.returncode != 0:
            return None, f"compile-failed:{(r.stderr or '').strip().splitlines()[-1][:120] if r.stderr else ''}"
        r = _run_proc([str(exe)], _RUN_TIMEOUT, cwd=td)
        if r is None:
            return None, "run-timeout"
        if r.returncode != 0:
            return None, "run-crash"
        return _parse_indexed_output(r.stdout), ""

    return None, "harness-unsupported"


# --- output comparison -------------------------------------------------------

_BOOL_NORM = {"True": "1", "true": "1", "False": "0", "false": "0"}


def _compare_outputs(src_out: dict[str, str], tgt_out: dict[str, str],
                     ret_kind: str | None) -> tuple[bool, str]:
    """Align by index (robust to crashed/skipped points) and compare.

    Floats: |a-b| <= 1e-9 * max(1, |a|, |b|) — absolute 1e-9 for magnitudes
    up to 1, relaxing to relative 1e-9 above (the dataset bar). Ints/bools:
    exact. NaN==NaN accepted; mixed finite/non-finite points are skipped as
    domain edges (same policy as build_cpp_mojo_dataset.verify)."""
    comparable = 0
    for idx, a_raw in src_out.items():
        b_raw = tgt_out.get(idx)
        if b_raw is None:
            continue
        a, b = _BOOL_NORM.get(a_raw, a_raw), _BOOL_NORM.get(b_raw, b_raw)
        if ret_kind in ("int", "bool"):
            try:
                ia, ib = int(float(a)), int(float(b))
            except (ValueError, OverflowError):
                return False, f"mismatch@{idx}: unparseable {a_raw!r} vs {b_raw!r}"
            if ia != ib:
                return False, f"mismatch@{idx}: {a_raw} vs {b_raw}"
            comparable += 1
            continue
        # float or unknown return kind
        try:
            fa, fb = float(a), float(b)
        except ValueError:
            if a != b:
                return False, f"mismatch@{idx}: {a_raw!r} vs {b_raw!r}"
            comparable += 1
            continue
        a_nan, b_nan = fa != fa, fb != fb
        if a_nan or b_nan:
            if a_nan and b_nan:
                comparable += 1
            continue
        if abs(fa) == float("inf") or abs(fb) == float("inf"):
            continue  # domain edge — skip, like the dataset builder
        if abs(fa - fb) > _FLOAT_TOL * max(1.0, abs(fa), abs(fb)):
            return False, f"mismatch@{idx}: {a_raw} vs {b_raw}"
        comparable += 1
    if comparable < _MIN_COMPARABLE:
        return False, f"too-few-comparable:{comparable}"
    return True, "behavioral"


def behavioral_verify(candidate: FnCandidate, target: str, output: str) -> tuple[bool, str]:
    """Behavioral gate: run source + target on sampled inputs, compare to 1e-9.

    Returns (True, "behavioral") on a verified match, else (False, reason).
    Reasons starting with "mismatch" indicate a *provably wrong* translation;
    everything else is an infrastructure limitation (missing toolchain,
    unsupported harness, crash/timeout) and should fall back to compile-only.
    """
    ssig, why = _parse_source_sig(candidate)
    if ssig is None:
        return False, f"source-sig:{why}"
    tsig, why = _parse_target_sig(target, output, candidate.fn_name)
    if tsig is None:
        return False, f"target-sig:{why}"
    if len(tsig.param_kinds) != len(ssig.param_kinds):
        return False, "param-count-mismatch"
    if _toolchain_missing(_SOURCE_TOOL.get(candidate.source_lang)):
        return False, f"toolchain-missing:{_SOURCE_TOOL[candidate.source_lang]}"
    if _toolchain_missing(_TARGET_TOOL.get(target)):
        return False, f"toolchain-missing:{_TARGET_TOOL[target]}"

    fingerprint = hashlib.sha256(candidate.source_code.encode()).hexdigest()[:16]
    rows = _behavioral_inputs(ssig.param_kinds, candidate.source_code, fingerprint)

    with tempfile.TemporaryDirectory(prefix="transpilers_bv_") as td:
        tdp = Path(td)
        src_out, why = _exec_source(candidate, ssig, rows, tdp)
        if src_out is None:
            return False, f"source:{why}"
        tgt_out, why = _exec_target(target, output, tsig, rows, tdp)
        if tgt_out is None:
            return False, f"target:{why}"
    return _compare_outputs(src_out, tgt_out, ssig.ret_kind)


# ---------------------------------------------------------------------------
# SFT output helpers
# ---------------------------------------------------------------------------

def _pair_to_alpaca(pair: PairResult, verification: str = "compile-only",
                    verify_reason: str | None = None) -> dict:
    lang_name = {"cpp": "C++", "python": "Python", "c": "C"}.get(pair.candidate.source_lang, pair.candidate.source_lang)
    target_name = pair.target.capitalize()
    metadata = {
        "source_lang": pair.candidate.source_lang,
        "target": pair.target,
        "repo": pair.candidate.repo_name,
        "file": pair.candidate.file_path,
        "fn": pair.candidate.fn_name,
        "fingerprint": hashlib.sha256(pair.candidate.source_code.encode()).hexdigest()[:16],
        "verification": verification,
    }
    if verification != "behavioral" and verify_reason:
        metadata["behavioral_skip_reason"] = verify_reason
    return {
        "instruction": (
            f"Transpile the provided {lang_name} implementation into a functionally "
            f"equivalent implementation in {target_name}.\n\n"
            f"```{pair.candidate.source_lang}\n{pair.candidate.source_code}\n```"
        ),
        "input": "",
        "output": pair.output,
        "metadata": metadata,
    }


def _load_seen_fingerprints(out_path: Path) -> set:
    seen: set = set()
    if out_path.exists():
        for line in out_path.read_text().splitlines():
            try:
                entry = json.loads(line)
                fp = (entry.get("metadata") or {}).get("fingerprint")
                if fp:
                    seen.add(fp)
            except json.JSONDecodeError:
                pass
    return seen


# ---------------------------------------------------------------------------
# Main crawl loop
# ---------------------------------------------------------------------------

def crawl(
    source_lang: str,
    targets: list[str],
    limit_repos: int,
    limit_fns: int,
    out_path: Path,
    min_stars: int,
    use_llm: bool,
    behavioral: bool = True,
) -> int:
    """Run one crawl pass. Returns number of new verified pairs written."""
    out_path.parent.mkdir(parents=True, exist_ok=True)
    seen = _load_seen_fingerprints(out_path)
    log.info("Loaded %d already-seen fingerprints from %s", len(seen), out_path)

    llm_fill = None
    if use_llm:
        try:
            from transpilers.llm import LlmClient, make_llm_inferencer
            llm_fill = make_llm_inferencer(LlmClient())
            log.info("LLM inferencer active")
        except Exception as exc:
            log.warning("Could not init LLM client: %s", exc)

    gh_lang = {"cpp": "C++", "python": "Python", "c": "C"}.get(source_lang, source_lang)
    log.info("Searching GitHub for %s repos (min_stars=%d, limit=%d)...", gh_lang, min_stars, limit_repos)

    try:
        repos = search_repos(gh_lang, min_stars=min_stars, max_repos=limit_repos)
    except Exception as exc:
        log.error("GitHub search failed: %s", exc)
        return 0

    log.info("Found %d repos", len(repos))

    new_pairs = 0
    fns_processed = 0

    for repo in repos:
        if fns_processed >= limit_fns:
            break
        repo_name = repo["full_name"]
        clone_url = repo["clone_url"]
        log.info("Cloning %s ...", repo_name)

        with tempfile.TemporaryDirectory(prefix="transpilers_crawl_") as td:
            clone_dir = Path(td) / "repo"
            if not clone_repo(clone_url, clone_dir):
                log.warning("Clone failed: %s", repo_name)
                continue

            fn_count = 0
            for candidate in iter_repo_functions(clone_dir, source_lang, repo_name):
                if fns_processed >= limit_fns:
                    break

                fp = hashlib.sha256(candidate.source_code.encode()).hexdigest()[:16]
                if fp in seen:
                    continue
                seen.add(fp)
                fns_processed += 1
                fn_count += 1

                for target in targets:
                    result = transpile_and_verify(candidate, target, llm_fill=llm_fill)
                    if not result.compile_ok:
                        log.debug("  ✗ %s::%s -> %s  %s", repo_name, candidate.fn_name, target, result.compile_stderr[:80])
                        continue

                    verification = "compile-only"
                    verify_reason = "behavioral-disabled"
                    if behavioral:
                        ok, verify_reason = behavioral_verify(candidate, target, result.output)
                        if ok:
                            verification = "behavioral"
                        elif verify_reason.startswith("mismatch"):
                            # Provably divergent translation — never write it.
                            log.info(
                                "  ✗ %s::%s -> %s  behaviorally divergent (%s) — dropped",
                                repo_name, candidate.fn_name, target, verify_reason[:100],
                            )
                            continue
                        else:
                            log.debug(
                                "  ~ %s::%s -> %s  behavioral skipped (%s), keeping compile-only",
                                repo_name, candidate.fn_name, target, verify_reason[:100],
                            )

                    entry = _pair_to_alpaca(result, verification=verification, verify_reason=verify_reason)
                    with out_path.open("a") as f:
                        f.write(json.dumps(entry) + "\n")
                    new_pairs += 1
                    log.info(
                        "  ✓ %s::%s -> %s  [%s, total=%d]",
                        repo_name, candidate.fn_name, target, verification, new_pairs,
                    )

            log.info("  repo %s: %d fns extracted", repo_name, fn_count)

    log.info("Crawl pass complete: %d new verified pairs written to %s", new_pairs, out_path)
    return new_pairs


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="crawl_github", description=__doc__)
    parser.add_argument("--source", choices=list(_LANG_EXT), default="cpp", help="Source language to crawl")
    parser.add_argument("--targets", nargs="+", default=["mojo"], help="Target language(s) to transpile to")
    parser.add_argument("--limit-repos", type=int, default=20, help="Max repos per crawl pass")
    parser.add_argument("--limit-fns", type=int, default=500, help="Max functions per crawl pass")
    parser.add_argument("--min-stars", type=int, default=200, help="Min GitHub stars filter")
    parser.add_argument("--out", type=Path, default=Path("data/sft/github_crawl/verified.jsonl"))
    parser.add_argument("--use-llm", action="store_true", help="Use LLM inferencer for type holes")
    parser.add_argument(
        "--behavioral",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="Run the behavioral verification gate (run-and-compare to 1e-9); "
        "--no-behavioral keeps the compile gate only",
    )
    parser.add_argument("--continuous", action="store_true", help="Loop forever, sleeping between passes")
    parser.add_argument("--sleep", type=int, default=3600, help="Sleep seconds between continuous passes")
    args = parser.parse_args(argv)

    if not os.getenv("GITHUB_TOKEN"):
        log.warning("GITHUB_TOKEN not set — GitHub API rate limit is 60 req/hr unauthenticated")

    while True:
        crawl(
            source_lang=args.source,
            targets=args.targets,
            limit_repos=args.limit_repos,
            limit_fns=args.limit_fns,
            out_path=args.out,
            min_stars=args.min_stars,
            use_llm=args.use_llm,
            behavioral=args.behavioral,
        )
        if not args.continuous:
            break
        log.info("Sleeping %ds before next pass...", args.sleep)
        time.sleep(args.sleep)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
