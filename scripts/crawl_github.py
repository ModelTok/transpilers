#!/usr/bin/env python3
"""GitHub repo crawler for the data flywheel.

Searches GitHub for permissively-licensed C++ and Python repos, extracts
self-contained functions, transpiles them to Mojo (or any target), verifies
correctness, and appends verified pairs to a growing JSONL dataset.

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
    6. Append compile-passing pairs to output JSONL (Alpaca schema)
"""

from __future__ import annotations

import argparse
import hashlib
import json
import logging
import os
import subprocess
import sys
import tempfile
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
# SFT output helpers
# ---------------------------------------------------------------------------

def _pair_to_alpaca(pair: PairResult) -> dict:
    lang_name = {"cpp": "C++", "python": "Python", "c": "C"}.get(pair.candidate.source_lang, pair.candidate.source_lang)
    target_name = pair.target.capitalize()
    return {
        "instruction": (
            f"Transpile the provided {lang_name} implementation into a functionally "
            f"equivalent implementation in {target_name}.\n\n"
            f"```{pair.candidate.source_lang}\n{pair.candidate.source_code}\n```"
        ),
        "input": "",
        "output": pair.output,
        "metadata": {
            "source_lang": pair.candidate.source_lang,
            "target": pair.target,
            "repo": pair.candidate.repo_name,
            "file": pair.candidate.file_path,
            "fn": pair.candidate.fn_name,
            "fingerprint": hashlib.sha256(pair.candidate.source_code.encode()).hexdigest()[:16],
        },
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
                    if result.compile_ok:
                        entry = _pair_to_alpaca(result)
                        with out_path.open("a") as f:
                            f.write(json.dumps(entry) + "\n")
                        new_pairs += 1
                        log.info(
                            "  ✓ %s::%s -> %s  [total=%d]",
                            repo_name, candidate.fn_name, target, new_pairs,
                        )
                    else:
                        log.debug("  ✗ %s::%s -> %s  %s", repo_name, candidate.fn_name, target, result.compile_stderr[:80])

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
        )
        if not args.continuous:
            break
        log.info("Sleeping %ds before next pass...", args.sleep)
        time.sleep(args.sleep)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
