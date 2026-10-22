"""Transpile C++ -> Mojo via OpenRouter (config-driven, per-file, parallel)."""

from __future__ import annotations

import argparse
import concurrent.futures as cf
import json
import os
import re
import subprocess
import sys
import threading
from pathlib import Path

RAW_DIR: Path | None = None

try:
    from dotenv import load_dotenv

    load_dotenv(Path.cwd() / ".env", override=True)
except ImportError:
    pass

from openrouter import OpenRouter  # noqa: E402

from transpilers.cli.domain_prompts import apply_domain_guidance  # noqa: E402
from transpilers.cli.local_client import OpenAICompatClient  # noqa: E402
from transpilers.repair.mojo_postpass import postpass as mojo_postpass  # noqa: E402

DEFAULT_MODEL = "deepseek/deepseek-v4-flash"

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
- One file . one .mojo file at the exact TARGET PATH shown above.
- For cross-module calls: import from the .mojo file at the same relative path.
  Example: if this file calls `Psychrometrics::PsyRhoFnTdbW`,
  emit `from "Psychrometrics" import PsyRhoFnTdbW` (same directory)
  or `from "../Psychrometrics" import PsyRhoFnTdbW` (different directory).
- C++ `ClassName::StaticMethod(...)` -> `ClassName.StaticMethod(...)` or imported free function.
- ObjexxFCL `()` indexing is 1-based -> translate to 0-based Python/Mojo subscript `[]`.
- `std::` namespace qualifiers -> drop them (use Mojo stdlib equivalents).
- Reserved-word collisions: if a name is a Mojo keyword, append `_` once and use consistently.
- NO refactoring, NO renaming, NO optimization of any kind.
- Output ONLY the <<<FILE>>> block, no explanation, no markdown outside it.

OUTPUT FORMAT:
<<<FILE {target_path}>>>
...Mojo code...
<<<END>>>"""

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
        m = re.search(
            r"<<<\s*FILE\s+(?P<path>[^\n]+?)\s*>>>\n(?P<body>.*)\Z",
            text,
            re.DOTALL,
        )
    if not m:
        return _single_mojo_fence(text)
    body = m.group("body")
    body = re.sub(r"^```[a-zA-Z]*\n", "", body)
    body = re.sub(r"\n```\s*$", "", body)
    return body


_FENCE = re.compile(r"```(?P<lang>[^\n`]*)\n(?P<body>.*?)\n```", re.DOTALL)


def _single_mojo_fence(text: str) -> str | None:
    """Fallback for models that answer with one fenced mojo block instead of <<<FILE>>>.

    The repo's fine-tuned adapter was trained to reply with "a single ```mojo fenced block".
    Only a closed fence tagged ``mojo`` counts, and only when there is exactly one: with
    several (code plus examples) it is unclear which is the file, so none is taken.
    """
    blocks = [
        m.group("body")
        for m in _FENCE.finditer(text)
        if m.group("lang").strip().lower() in ("mojo", "\U0001f525")
    ]
    return blocks[0] if len(blocks) == 1 else None


def mojo_compile(path: Path) -> tuple[bool, str]:
    try:
        p = subprocess.run(
            ["mojo", "build", str(path)],
            capture_output=True,
            text=True,
            timeout=120,
        )
        return p.returncode == 0, p.stderr
    except FileNotFoundError:
        return False, "mojo not found"
    except subprocess.TimeoutExpired:
        return False, "timed out"


def transpile_one(
    entry: dict,
    model: str,
    client: OpenRouter,
    repair: bool,
    max_retries: int,
    domain_prompts: bool = False,
    postpass: bool = False,
    temperature: float = 0.0,
) -> dict:
    cc_path = Path(entry["source"])
    target_path = Path(entry["target"])
    result = dict(entry)

    if not cc_path.exists():
        result["status"] = "error: source not found"
        return result
    cc_source = read_file(cc_path)
    if not cc_source.strip():
        result["status"] = "error: empty source"
        return result

    hh_path = find_header(cc_path)
    hh_source = read_file(hh_path) if hh_path else ""
    if not hh_source and entry.get("header"):
        hh_path = Path(entry["header"])
        hh_source = read_file(hh_path) if hh_path.exists() else ""

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
    if domain_prompts:
        prompt = apply_domain_guidance(prompt, cc_source, str(cc_path))

    for attempt in range(max_retries + 1):
        try:
            response = client.chat.send(
                model=model,
                messages=[{"role": "user", "content": prompt}],
                temperature=temperature,
                max_tokens=16000,
            )
            raw = response.choices[0].message.content

            if RAW_DIR:
                raw_dir = Path(RAW_DIR)
                raw_dir.mkdir(parents=True, exist_ok=True)
                raw_path = raw_dir / f"{Path(entry['source']).stem}.raw.txt"
                raw_path.write_text(raw)

        except Exception as e:
            if attempt < max_retries:
                continue
            result["status"] = f"error: LLM ({e})"
            return result

        code = extract_file_block(raw)
        if not code:
            target_path.parent.mkdir(parents=True, exist_ok=True)
            target_path.write_text(raw)
            if attempt < max_retries:
                continue
            result["status"] = "error: no FILE block"
            return result

        if postpass:
            fixed = mojo_postpass(code, source=cc_source)
            code = fixed.code
            result["postpass_changes"] = len(fixed.changes)
            if fixed.unresolved:
                result["postpass_unresolved"] = fixed.unresolved

        target_path.parent.mkdir(parents=True, exist_ok=True)
        target_path.write_text(code)

        if repair:
            ok, err = mojo_compile(target_path)
            if ok:
                result["status"] = "ok"
                return result
            if attempt >= max_retries:
                result["status"] = "error: compile"
                return result
            prompt = (
                f"Fix this Mojo file. It failed to compile.\n\n"
                f"FILE: {target_rel}\n\nCODE:\n{code}\n\n"
                f"ERRORS:\n{err[:2000]}\n\n"
                f"Fix errors only, keep structure. Output ONLY the FILE block."
            )
        else:
            result["status"] = "ok"
            return result

    result["status"] = "error: unreachable"
    return result


def run_verify(cmd: str, entry: dict, timeout: float) -> tuple[bool, str]:
    """Run the user's verification command on a written draft; exit status 0 accepts it.

    `{target}` and `{source}` in `cmd` are replaced by the draft and source paths."""
    shell_cmd = cmd.replace("{target}", entry["target"]).replace("{source}", entry["source"])
    try:
        p = subprocess.run(shell_cmd, shell=True, capture_output=True, text=True, timeout=timeout)
    except subprocess.TimeoutExpired:
        return False, "timed out"
    tail = (p.stdout + p.stderr).strip().splitlines()
    return p.returncode == 0, (tail[-1] if tail else "")[:160]


def transpile_verified(
    entry: dict,
    samples: int,
    verify_cmd: str | None,
    verify_timeout: float,
    **kwargs,
) -> dict:
    """`transpile_one` up to `samples` times, stopping at the first draft that `verify_cmd` accepts.

    Each attempt overwrites the target; when none passes the last draft stays and the status says so."""
    if not verify_cmd or samples <= 1:
        return transpile_one(entry, **kwargs)
    result: dict = {}
    for attempt in range(1, samples + 1):
        result = transpile_one(dict(entry), **kwargs)
        result["attempts"] = attempt
        if result["status"] != "ok":
            continue
        ok, detail = run_verify(verify_cmd, entry, verify_timeout)
        result["verified"] = ok
        if ok:
            return result
        result["verify"] = detail
    if result.get("status") == "ok":
        result["status"] = f"error: no verified draft in {samples} samples"
    return result


def make_client(endpoint: str | None, api_key: str, timeout: float):
    """OpenRouter SDK client, or a local OpenAI-compatible one when ``endpoint`` is set."""
    if endpoint:
        return OpenAICompatClient(endpoint, api_key, timeout)
    return OpenRouter(api_key=api_key)


def save_config(config_path: Path, config: list[dict]) -> None:
    tmp = config_path.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(config, indent=2))
    tmp.replace(config_path)


def step_bar(step: int, total: int, width: int = 40) -> str:
    filled = int(width * step / total) if total else 0
    return f"[{'#' * filled}{'.' * (width - filled)}] {step}/{total}"


def main() -> int:
    global RAW_DIR
    ap = argparse.ArgumentParser(
        description=(
            "Transpile C++/Fortran to Mojo from a JSON config, via OpenRouter or a local "
            "OpenAI-compatible server (--endpoint)"
        ),
    )
    ap.add_argument("config", help="JSON config file from build_config.py")
    ap.add_argument(
        "--model",
        default=None,
        help=f"Model name (default {DEFAULT_MODEL} on OpenRouter; required with --endpoint)",
    )
    ap.add_argument(
        "--endpoint",
        default=None,
        help=(
            "Base URL of an OpenAI-compatible server (e.g. http://localhost:11434/v1 for "
            "Ollama, http://localhost:1234/v1 for LM Studio). No OpenRouter key needed; "
            "LLM_API_KEY is sent if set."
        ),
    )
    ap.add_argument(
        "--repair", action="store_true", help="Enable compile-driven repair loop"
    )
    ap.add_argument("--max-retries", type=int, default=3)
    ap.add_argument(
        "--timeout", type=int, default=600, help="Timeout in seconds per file"
    )
    ap.add_argument("--workers", type=int, default=1, help="Number of parallel workers")
    ap.add_argument(
        "--limit", type=int, default=0, help="Transpile first N pending files"
    )
    ap.add_argument(
        "--ids",
        type=int,
        nargs="+",
        default=None,
        help="Transpile only these entry ids",
    )
    ap.add_argument(
        "--files",
        nargs="+",
        default=None,
        help="Transpile only these source paths (substring match)",
    )
    ap.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be done without calling LLM",
    )
    ap.add_argument(
        "--status", action="store_true", help="Show config summary and exit"
    )
    ap.add_argument(
        "--resolve",
        action="store_true",
        help="Retry entries with decision=done but missing .mojo",
    )
    ap.add_argument(
        "--raw-dir",
        default=None,
        help="Directory to save raw LLM responses for debugging",
    )
    ap.add_argument(
        "--force", action="store_true", help="Re-transpile even if decision=done"
    )
    ap.add_argument(
        "--temperature",
        type=float,
        default=0.0,
        help="Sampling temperature (default 0.0); above 0 gives a different draft per run, for best-of-n selection",
    )
    ap.add_argument(
        "--samples",
        type=int,
        default=1,
        help="Best-of-n: draw up to N drafts per file and keep the first that --verify-cmd accepts "
        "(needs --temperature above 0)",
    )
    ap.add_argument(
        "--verify-cmd",
        default=None,
        help="Shell command that accepts a draft with exit status 0; {target} and {source} are replaced "
        "by the draft and source paths (e.g. a compile-and-compare script)",
    )
    ap.add_argument("--verify-timeout", type=float, default=600.0, help="Seconds allowed per verification")
    ap.add_argument(
        "--postpass",
        action="store_true",
        help=(
            "Apply the deterministic Mojo post-pass (syntax, struct/Array1D rewrites, `mut`, glibc-exact "
            "maths, nc_mul guards; see transpile-postpass) to each draft before it is written"
        ),
    )
    ap.add_argument(
        "--domain-prompts",
        action="store_true",
        help=(
            "Add gtest / Eigen-specific guidance when those sources are detected, and "
            "EnergyPlusMojo kernel rules for sources named *.upstream.inc"
        ),
    )
    args = ap.parse_args()
    if args.samples > 1 and not args.verify_cmd:
        ap.error("--samples needs --verify-cmd (there is nothing to choose a draft by otherwise)")
    if args.samples > 1 and args.temperature <= 0:
        ap.error("--samples needs --temperature above 0 (every sample would be identical)")

    config_path = Path(args.config)
    if not config_path.exists():
        print(f"ERROR: config not found: {config_path}", file=sys.stderr)
        return 1
    config = json.loads(config_path.read_text())

    if args.status:
        by_decision = {}
        for e in config:
            d = e.get("decision", "pending")
            by_decision[d] = by_decision.get(d, 0) + 1
        by_dir = {}
        for e in config:
            p = Path(e["source"]).parent
            by_dir[str(p)] = by_dir.get(str(p), 0) + 1
        print(f"Config: {len(config)} entries")
        print("Decisions:")
        for d, c in sorted(by_decision.items()):
            print(f"  {d}: {c}")
        print("\nTop directories:")
        for p, c in sorted(by_dir.items(), key=lambda x: -x[1])[:10]:
            print(f"  {p}: {c}")
        return 0

    if args.ids:
        id_set = set(args.ids)
        entries = [e for e in config if e.get("id") in id_set]
    elif args.files:
        entries = []
        for pat in args.files:
            for e in config:
                if pat in e["source"] and e not in entries:
                    entries.append(e)
    elif args.resolve:
        entries = [
            e
            for e in config
            if e.get("decision") == "done" and not Path(e["target"]).exists()
        ]
    elif args.force:
        entries = list(config)
    else:
        entries = [e for e in config if e.get("decision") != "done"]

    if args.limit and len(entries) > args.limit:
        entries = entries[: args.limit]

    if not entries:
        print("No entries to transpile")
        return 0

    if args.endpoint:
        if not args.model:
            print("ERROR: --model is required with --endpoint", file=sys.stderr)
            return 1
        api_key = os.environ.get("LLM_API_KEY") or "local"
    else:
        args.model = args.model or DEFAULT_MODEL
        api_key = os.environ.get("OPENROUTER_API_KEY")
        if not api_key:
            print("ERROR: OPENROUTER_API_KEY not set", file=sys.stderr)
            return 1

    if args.dry_run:
        print(f"Dry run: {len(entries)} file(s)")
        for e in entries:
            hdr = f" (header: {e.get('header', 'none')})" if e.get("header") else ""
            print(f"  id={e.get('id', '?')}: {e['source']} -> {e['target']}{hdr}")
        return 0

    RAW_DIR = Path(args.raw_dir).resolve() if args.raw_dir else None

    print(
        f"Transpiling {len(entries)} file(s) with model={args.model} "
        f"repair={'on' if args.repair else 'off'} "
        f"workers={args.workers} timeout={args.timeout}s"
        + (f" raw_dir={RAW_DIR}" if RAW_DIR else "")
    )

    config_lock = threading.Lock()
    ok_count = 0
    total = len(entries)
    completed = 0

    def work(entry: dict) -> dict:
        nonlocal ok_count, completed
        with make_client(args.endpoint, api_key, args.timeout) as client:
            result = transpile_verified(
                entry,
                args.samples,
                args.verify_cmd,
                args.verify_timeout,
                model=args.model,
                client=client,
                repair=args.repair,
                max_retries=args.max_retries,
                domain_prompts=args.domain_prompts,
                postpass=args.postpass,
                temperature=args.temperature,
            )
        status = result["status"]
        with config_lock:
            entry["decision"] = "done" if status == "ok" else "error"
            if status == "ok":
                ok_count += 1
            completed += 1
            bar = step_bar(completed, total)
            eid = entry.get("id", "?")
            short_src = Path(entry["source"]).name
            print(
                f"  {bar} id={eid} {short_src} {'OK' if status == 'ok' else 'FAIL'} {status}",
                flush=True,
            )
            save_config(config_path, config)
        return result

    with cf.ThreadPoolExecutor(max_workers=args.workers) as ex:
        futs = [ex.submit(work, e) for e in entries]
        cf.wait(futs, timeout=args.timeout * len(entries))

    print(f"\nDone: {ok_count}/{total}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
