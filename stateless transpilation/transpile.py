#!/usr/bin/env python3
"""Transpile C++ source files to Mojo via OpenRouter.

Operates on a JSON config file (from build_config.py). For each entry with
"decision": "pending", sends the source file to OpenRouter and writes the
transpiled .mojo to the target path, preserving directory structure.

Usage:
  # Transpile all pending files
  python transpile.py ep_full_config.json

  # Transpile specific entries by id
  python transpile.py ep_full_config.json --ids 1 2 3

  # Transpile specific entries by source path
  python transpile.py ep_full_config.json --files src/EnergyPlus/Pumps.cc

  # Transpile first N pending files (for testing)
  python transpile.py ep_full_config.json --limit 5

  # Dry-run: show what would be done without calling LLM
  python transpile.py ep_full_config.json --dry-run

  # Resolve pending files that failed previously
  python transpile.py ep_full_config.json --resolve

  # Show summary of config
  python transpile.py ep_full_config.json --status

Environment:
  OPENROUTER_API_KEY  — required (also loaded from .env)
"""

from __future__ import annotations

import argparse
import json
import os
import queue
import re
import subprocess
import sys
import threading
from pathlib import Path

try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

from openrouter import OpenRouter

# ---------------------------------------------------------------------------
# Prompt template
# ---------------------------------------------------------------------------

PROMPT_TEMPLATE = """\
Convert this C++ file to Mojo. Faithful 1:1 translation, no refactoring.

SOURCE PATH: {source_path}
TARGET PATH: {target_path}

HEADER CONTEXT ({header_path}):
{header_source}

BODY ({source_path}):
{body_source}

RULES:
- Keep ALL function, variable, class, struct, enum names EXACTLY as in source.
- Keep ALL formulas, coefficient values, branch structure, comments verbatim.
- One file → one .mojo file at the exact TARGET PATH shown above.
- For cross-module calls: import from the .mojo file at the same relative path.
  Example: if this file calls `Psychrometrics::PsyRhoFnTdbW`,
  emit `from "Psychrometrics" import PsyRhoFnTdbW` (same directory)
  or `from "../Psychrometrics" import PsyRhoFnTdbW` (different directory).
- C++ `ClassName::StaticMethod(...)` → `ClassName.StaticMethod(...)` or imported free function.
- ObjexxFCL `()` indexing is 1-based → translate to 0-based Python/Mojo subscript `[]`.
- `std::` namespace qualifiers → drop them (use Mojo stdlib equivalents).
- Reserved-word collisions: if a name is a Mojo keyword, append `_` once and use consistently.
- NO refactoring, NO renaming, NO optimization of any kind.
- Output ONLY the <<<FILE>>> block, no explanation, no markdown outside it.

OUTPUT FORMAT:
<<<FILE {target_path}>>>
...Mojo code...
<<<END>>>"""

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

CPP_EXTS = {".cc", ".cpp", ".cxx"}
HEADER_EXTS = {".hh", ".hpp", ".h"}


def find_header(cc_path: Path) -> Path | None:
    for ext in HEADER_EXTS:
        candidate = cc_path.with_suffix(ext)
        if candidate.exists():
            return candidate
    return None


def read_file(path: Path, max_chars: int = 0) -> str:
    if not path or not path.exists():
        return ""
    text = path.read_text(encoding="utf-8", errors="replace")
    if max_chars and len(text) > max_chars:
        text = text[:max_chars] + "\n// ... [TRUNCATED]"
    return text


def extract_file_block(text: str) -> str | None:
    m = re.search(
        r"<<<\s*FILE\s+(?P<path>[^\n]+?)\s*>>>\n(?P<body>.*?)\n<<<\s*END\s*>>>",
        text,
        re.DOTALL,
    )
    if not m:
        return None
    body = m.group("body")
    body = re.sub(r"^```[a-zA-Z]*\n", "", body)
    body = re.sub(r"\n```\s*$", "", body)
    return body


def mojo_compile(path: Path) -> tuple[bool, str]:
    try:
        p = subprocess.run(
            ["mojo", "build", str(path)],
            capture_output=True, text=True, timeout=120,
        )
        return p.returncode == 0, p.stderr
    except FileNotFoundError:
        return False, "mojo not found on PATH"
    except subprocess.TimeoutExpired:
        return False, "timed out after 120s"


def step_bar(step: int, total: int, width: int = 40) -> str:
    """Render a progress bar like [########                ]."""
    filled = int(width * step / total) if total else 0
    return f"[{'#' * filled}{'.' * (width - filled)}] {step}/{total}"


# ---------------------------------------------------------------------------
# Core
# ---------------------------------------------------------------------------

def transpile_one(
    entry: dict,
    model: str,
    client: OpenRouter,
    repair: bool,
    max_retries: int,
) -> dict:
    """Transpile one config entry. Returns updated entry dict with status."""
    cc_path = Path(entry["source"])
    target_path = Path(entry["target"])
    result = dict(entry)  # copy, will update

    if not cc_path.exists():
        result["status"] = "error: source not found"
        return result

    cc_source = read_file(cc_path)
    if not cc_source.strip():
        result["status"] = "error: empty source"
        return result

    # Header
    hh_path = find_header(cc_path)
    hh_source = read_file(hh_path) if hh_path else ""
    if not hh_source:
        # Try path from config header field
        hdr = entry.get("header")
        if hdr:
            hh_path = Path(hdr)
            hh_source = read_file(hh_path) if hh_path.exists() else ""

    # Build prompt
    try:
        source_rel = cc_path.relative_to(Path.cwd())
    except ValueError:
        source_rel = cc_path
    try:
        target_rel = target_path.relative_to(Path.cwd())
    except ValueError:
        target_rel = target_path

    prompt = PROMPT_TEMPLATE.format(
        source_path=str(source_rel),
        target_path=str(target_rel),
        header_path=str(hh_path.name) if hh_path else "(none)",
        header_source=hh_source or "(no header file)",
        body_source=cc_source,
    )

    for attempt in range(max_retries + 1):
        # LLM call
        try:
            response = client.chat.send(
                model=model,
                messages=[{"role": "user", "content": prompt}],
                temperature=0.0,
                max_tokens=16000,
            )
            raw = response.choices[0].message.content
        except Exception as e:
            if attempt < max_retries:
                continue
            result["status"] = f"error: LLM ({e})"
            return result

        # Extract file block
        code = extract_file_block(raw)
        if not code:
            if attempt < max_retries:
                continue
            result["status"] = "error: no FILE block"
            return result

        # Write
        target_path.parent.mkdir(parents=True, exist_ok=True)
        target_path.write_text(code)

        # Compile-driven repair
        if repair and mojo_compile(target_path)[0] is False:
            if attempt >= max_retries:
                result["status"] = "error: compile"
                return result
            prompt = (
                f"Fix this Mojo file. It failed to compile.\n\n"
                f"FILE: {target_rel}\n\n"
                f"CODE:\n{code}\n\n"
                f"ERRORS:\n{mojo_compile(target_path)[1][:2000]}\n\n"
                f"Fix errors only, keep structure. Output ONLY the FILE block."
            )
        else:
            result["status"] = "ok"
            return result

    result["status"] = "error: unreachable"
    return result


# ---------------------------------------------------------------------------
# Config persistence — update decision field in config file
# ---------------------------------------------------------------------------

def save_config(config_path: Path, config: list[dict]) -> None:
    """Write config back to disk atomically."""
    tmp = config_path.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(config, indent=2))
    tmp.replace(config_path)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main() -> int:
    ap = argparse.ArgumentParser(
        description="Transpile C++ to Mojo via OpenRouter from a JSON config",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    ap.add_argument("config", help="JSON config file from build_config.py")
    ap.add_argument("--model", default="deepseek/deepseek-v4-flash",
                    help="OpenRouter model")
    ap.add_argument("--repair", action="store_true",
                    help="Enable compile-driven repair loop")
    ap.add_argument("--max-retries", type=int, default=3)
    ap.add_argument("--limit", type=int, default=0,
                    help="Only transpile first N pending files")
    ap.add_argument("--ids", type=int, nargs="+", default=None,
                    help="Transpile only these entry ids")
    ap.add_argument("--files", nargs="+", default=None,
                    help="Transpile only these source file paths (matched as substring)")
    ap.add_argument("--dry-run", action="store_true",
                    help="Show what would be done without calling LLM")
    ap.add_argument("--status", action="store_true",
                    help="Show config summary and exit")
    ap.add_argument("--resolve", action="store_true",
                    help="Retry entries with decision=done but missing .mojo file")
    ap.add_argument("--force", action="store_true",
                    help="Re-transpile even if decision=done")
    ap.add_argument("--workers", type=int, default=1,
                    help="Number of concurrent workers (default: 1)")
    args = ap.parse_args()

    # --- Load config ---
    config_path = Path(args.config)
    if not config_path.exists():
        print(f"ERROR: config not found: {config_path}", file=sys.stderr)
        return 1
    config = json.loads(config_path.read_text())

    # --- Status mode ---
    if args.status:
        total = len(config)
        by_decision = {}
        for e in config:
            d = e.get("decision", "pending")
            by_decision[d] = by_decision.get(d, 0) + 1
        by_dir = {}
        for e in config:
            p = Path(e["source"]).parent
            by_dir[str(p)] = by_dir.get(str(p), 0) + 1
        print(f"Config: {total} entries")
        print(f"Decisions:")
        for d, c in sorted(by_decision.items()):
            print(f"  {d}: {c}")
        print(f"\nTop directories:")
        for p, c in sorted(by_dir.items(), key=lambda x: -x[1])[:10]:
            print(f"  {p}: {c}")
        return 0

    # --- Filter entries ---
    if args.ids:
        id_set = set(args.ids)
        entries = [e for e in config if e.get("id") in id_set]
        skipped = len([e for e in config if e.get("id") in id_set and e.get("decision") == "done"])
    elif args.files:
        entries = []
        for pat in args.files:
            for e in config:
                if pat in e["source"] and e not in entries:
                    entries.append(e)
        skipped = 0
    elif args.resolve:
        entries = [e for e in config if e.get("decision") == "done" and not Path(e["target"]).exists()]
        skipped = 0
    elif args.force:
        entries = list(config)
        skipped = 0
    else:
        entries = [e for e in config if e.get("decision") != "done"]
        skipped = len([e for e in config if e.get("decision") == "done"])

    if args.limit and len(entries) > args.limit:
        entries = entries[:args.limit]

    if not entries:
        print("No pending entries to transpile")
        return 0

    # --- Validate API key ---
    api_key = os.environ.get("OPENROUTER_API_KEY")
    if not api_key:
        print("ERROR: OPENROUTER_API_KEY not set", file=sys.stderr)
        return 1

    # --- Dry run ---
    if args.dry_run:
        print(f"Dry run: would transpile {len(entries)} file(s)")
        for e in entries:
            src = e["source"]
            tgt = e["target"]
            hdr = f" (header: {e.get('header', 'none')})" if e.get("header") else ""
            print(f"  id={e.get('id','?')}: {src} → {tgt}{hdr}")
        if skipped:
            print(f"  ({skipped} skipped: already done)")
        return 0

    print(f"Transpiling {len(entries)} file(s) with model={args.model} "
          f"repair={'on' if args.repair else 'off'} "
          f"workers={args.workers}"
          + (f" ({skipped} skipped, already done)" if skipped else ""))

    # --- Transpile ---
    total = len(entries)
    ok_count = 0
    lock = __import__('threading').Lock()

    def worker(job_q: queue.Queue) -> None:
        nonlocal ok_count
        with OpenRouter(api_key=api_key) as client:
            while True:
                try:
                    entry = job_q.get_nowait()
                except queue.Empty:
                    return

                src = entry["source"]
                tgt = entry["target"]
                eid = entry.get("id", "?")
                short_src = Path(src).name

                with lock:
                    ok_count_local = ok_count
                    bar = step_bar(ok_count_local + 1, total)
                    print(f"  {bar} id={eid} {short_src}", end=" ", flush=True)

                result = transpile_one(
                    entry,
                    model=args.model,
                    client=client,
                    repair=args.repair,
                    max_retries=args.max_retries,
                )

                status = result["status"]
                entry["decision"] = "done" if status == "ok" else status

                with lock:
                    if status == "ok":
                        ok_count += 1
                        print(f"✓ {tgt}")
                    else:
                        print(f"✗ {status}")
                    save_config(config_path, config)

                job_q.task_done()

    job_q: queue.Queue = queue.Queue()
    for e in entries:
        job_q.put(e)

    threads = []
    for _ in range(args.workers):
        t = __import__('threading').Thread(target=worker, args=(job_q,), daemon=True)
        t.start()
        threads.append(t)

    job_q.join()

    for t in threads:
        t.join()

    save_config(config_path, config)
    print(f"\nDone: {ok_count}/{total} transpiled successfully")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())