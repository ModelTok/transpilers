#!/usr/bin/env python3
"""Stateless batch transpiler — one isolated completion per EnergyPlus file.

Flat toolkit: this script + batch_transpile.md + transpile_manifest.json live in
one folder. Each file becomes a single completion whose ONLY input is that file's
.cc/.hh + skeleton + the prompt — no tools, no other files, no conversation.

Backends:
  --backend claude    (default)  one `claude -p --tools ""` completion per file
  --backend lmstudio             OpenAI-compatible endpoints (LM Studio), with
                                 round-robin across --endpoints (your machines)

Usage:
  python3 batch_transpile.py --tier 1 --workers 6
  python3 batch_transpile.py --all --backend lmstudio \
      --endpoints http://192.168.1.50:1234/v1 http://192.168.1.51:1234/v1 \
      --model qwen2.5-coder-32b-instruct --workers 2 --timeout 1800
  python3 batch_transpile.py --files DataSizing --force
"""

from __future__ import annotations

import argparse
import concurrent.futures as cf
import json
import os
import queue
import re
import subprocess
from pathlib import Path

try:  # load OPENROUTER_API_KEY (and friends) from .env if python-dotenv is present
    from dotenv import load_dotenv

    load_dotenv()
except ImportError:
    pass

BASE = Path(__file__).resolve().parent
PROMPT_TEMPLATE = (BASE / "2_transpile.md").read_text()
MANIFEST = BASE / "1_manifest.json"
_MANIFEST = json.loads(MANIFEST.read_text()) if MANIFEST.exists() else {"files": []}
_BY_NAME = {r["name"]: r for r in _MANIFEST["files"]}
ORACLE = Path("C:/Github/EnergyPlus")  # fallback only

# Generated outputs live under out/ (subdirs are runtime artifacts, not tooling).
OUT = BASE / "out"
PY_OUT, MOJO_OUT, TEST_OUT = OUT / "python", OUT / "mojo", OUT / "tests"

_BODY = PROMPT_TEMPLATE.split("---", 1)[1] if "---" in PROMPT_TEMPLATE else PROMPT_TEMPLATE
FILE_BLOCK = re.compile(r"<<<FILE\s+(?P<path>[^>]+?)>>>\n(?P<body>.*?)\n<<<END>>>", re.DOTALL)
# ~4 chars/token; skip files whose prompt would blow a local context window.
DEFAULT_MAX_CHARS = 480_000


def snake(name: str) -> str:
    return re.sub(r"(?<!^)(?=[A-Z])", "_", name).lower()


def read(path: Path | None, limit: int | None = None) -> str:
    if not path or not Path(path).exists():
        return ""
    txt = Path(path).read_text(errors="ignore")
    return txt if limit is None else txt[:limit]


def _resolve_oracle(p: str | None) -> Path | None:
    """Resolve a manifest source path, remapping cross-machine paths onto ORACLE.

    The manifest may carry paths from another machine (e.g. Linux
    /home/bart/Github/EnergyPlus/...). If the literal path is missing, remap its
    repo-relative tail (after .../Github/EnergyPlus/) onto the local ORACLE root.
    """
    if not p:
        return None
    path = Path(p)
    if path.exists():
        return path
    tail = p.replace("\\", "/").split("/Github/EnergyPlus/", 1)
    return ORACLE / tail[1] if len(tail) == 2 else path


def _oracle_paths(file: str) -> tuple[Path, Path | None]:
    rec = _BY_NAME.get(file)
    if rec:
        return _resolve_oracle(rec["cc_path"]), _resolve_oracle(rec.get("hh_path"))
    return ORACLE / f"{file}.cc", ORACLE / f"{file}.hh"


def build_prompt(file: str) -> str:
    cc_path, hh_path = _oracle_paths(file)
    cc, hh = read(cc_path), read(hh_path)
    lang = (_BY_NAME.get(file) or {}).get("lang", "cpp")
    return (_BODY.replace("{FILE}", file).replace("{snake_file}", snake(file))
            .replace("{LANG}", lang).replace("{CC}", cc).replace("{HH}", hh))


def call_claude(prompt: str, model: str, timeout: int, endpoint: str | None) -> tuple[str, dict]:
    cmd = ["claude", "-p", "--output-format", "json", "--model", model,
           "--max-turns", "1", "--tools", ""]
    proc = subprocess.run(cmd, input=prompt, capture_output=True, text=True, timeout=timeout)
    if proc.returncode != 0:
        raise RuntimeError(f"claude exited {proc.returncode}: {proc.stderr[:400]}")
    p = json.loads(proc.stdout)
    return p.get("result", ""), {"cost_usd": p.get("total_cost_usd"), "usage": p.get("usage", {})}


def call_openai(prompt: str, model: str, timeout: int, endpoint: str) -> tuple[str, dict]:
    """One completion against an OpenAI-compatible endpoint (LM Studio, vLLM, RunPod)."""
    import os, urllib.request

    # API key from env (RunPod etc.); falls back to LM Studio's dummy token.
    key = os.environ.get("LLM_API_KEY") or "lm-studio"
    # Cap output so prompt+completion stays within the served model's context
    # (Qwen2.5-Coder-32B = 32768). Overridable via LLM_MAX_TOKENS.
    max_tokens = int(os.environ.get("LLM_MAX_TOKENS", "16000"))

    url = endpoint.rstrip("/") + "/chat/completions"
    body = json.dumps({
        "model": model or "local-model",
        "messages": [{"role": "user", "content": prompt}],
        "temperature": 0.0, "max_tokens": max_tokens, "stream": False,
    }).encode()
    req = urllib.request.Request(url, data=body, headers={
        "Content-Type": "application/json", "Authorization": f"Bearer {key}"})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        p = json.loads(resp.read())
    return p["choices"][0]["message"]["content"], {
        "cost_usd": 0.0, "usage": p.get("usage", {}), "endpoint": endpoint}


# Transient upstream failures worth retrying: rate limits (429) and gateway/
# provider errors (5xx). OpenRouter surfaces a 504 as a body with no `choices`,
# which the SDK raises as a *validation* error — so we also match on that shape.
_RETRY_HINTS = ("429", "500", "502", "503", "504", "rate limit", "timeout",
                "overloaded", "temporarily", "validation")
_RETRIES = int(os.environ.get("OPENROUTER_RETRIES", "4"))


def _transient(exc: Exception) -> bool:
    s = f"{type(exc).__name__} {exc}".lower()
    return any(h in s for h in _RETRY_HINTS)


def call_openrouter(prompt: str, model: str, timeout: int, endpoint: str | None) -> tuple[str, dict]:
    """One completion against OpenRouter via the official SDK, with backoff.

    Key comes from OPENROUTER_API_KEY (loaded from .env). `endpoint` is unused —
    OpenRouter is a single cloud endpoint, so lanes behave like the claude backend.
    Transient errors (429 rate limit, 5xx/504 provider timeout) are retried with
    exponential backoff; non-transient errors (auth, payment) fail fast.
    """
    import time

    from openrouter import OpenRouter

    key = os.environ.get("OPENROUTER_API_KEY")
    if not key:
        raise RuntimeError("OPENROUTER_API_KEY not set (add it to .env)")

    last = None
    for attempt in range(_RETRIES):
        try:
            with OpenRouter(api_key=key) as client:
                resp = client.chat.send(
                    model=model,
                    messages=[{"role": "user", "content": prompt}],
                )
            usage = getattr(resp, "usage", None)
            cost = getattr(usage, "cost", None) if usage is not None else None
            usage_dict = usage.model_dump() if hasattr(usage, "model_dump") else {}
            return resp.choices[0].message.content, {"cost_usd": cost or 0.0, "usage": usage_dict}
        except Exception as e:  # noqa: BLE001
            last = e
            if attempt == _RETRIES - 1 or not _transient(e):
                raise
            time.sleep(2 ** attempt)  # 1, 2, 4, 8s
    raise last  # unreachable, satisfies type checkers


def write_blocks(text: str) -> list[str]:
    written = []
    for m in FILE_BLOCK.finditer(text):
        body = re.sub(r"\n```\s*$", "", re.sub(r"^```[a-zA-Z]*\n", "", m.group("body")))
        out = BASE / m.group("path").strip()
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(body.rstrip() + "\n")
        written.append(m.group("path").strip())
    return written


def is_real(file: str) -> bool:
    p = PY_OUT / f"{file}.py"
    if not p.exists():
        return False
    t = p.read_text(errors="ignore")
    return "__todo__" not in t and "Phase-1 C++->Python lift" not in t


def transpile_one(file, backend, model, timeout, force, endpoint, max_chars) -> dict:
    # Skip only files whose manifest status is "done" (BOTH ports present).
    # "partial" (one port missing) must re-run to complete; is_real() alone is
    # python-only and would wrongly skip partials.
    rec = _BY_NAME.get(file)
    if rec and rec.get("status") == "done" and not force:
        return {"file": file, "status": "skipped (already done)", "written": []}
    try:
        cc_path, _ = _oracle_paths(file)
        prompt = build_prompt(file)
        if not prompt.strip() or not cc_path.exists():
            return {"file": file, "status": "no oracle .cc", "written": []}
        if len(prompt) > max_chars:
            return {"file": file, "status": f"skip: prompt {len(prompt):,} chars > limit "
                    f"(use cloud/chunk)", "written": []}
        fn = {"lmstudio": call_openai, "openrouter": call_openrouter}.get(backend, call_claude)
        text, meta = fn(prompt, model, timeout, endpoint)
        written = write_blocks(text)
        return {"file": file, "status": "ok" if written else "no file blocks in output",
                "written": written, **meta}
    except Exception as e:  # noqa: BLE001
        return {"file": file, "status": f"error: {e}", "written": []}


def files_from_manifest(tier, pending_only=True) -> list[str]:
    # Only files marked decision="port" are transpiled by --tier/--all. native/
    # reuse/replace/skip records exist in the manifest (nothing excluded) but are
    # NOT transpiled here. Use explicit --files to override for any record.
    return [r["name"] for r in _MANIFEST["files"]
            if r.get("decision") == "port"
            and (tier is None or r["tier"] == tier)
            and (not pending_only or r.get("status") in (None, "pending", "partial"))]


def main() -> int:
    ap = argparse.ArgumentParser()
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--files", nargs="+")
    g.add_argument("--file")
    g.add_argument("--tier", type=int)
    g.add_argument("--all", action="store_true")
    ap.add_argument("--backend", choices=["claude", "lmstudio", "openrouter"], default="claude")
    ap.add_argument("--endpoints", nargs="+", default=["http://localhost:1234/v1"],
                    help="lmstudio base URLs; load-balanced pull-when-free")
    ap.add_argument("--per-endpoint", type=int, default=1,
                    help="concurrent jobs per lmstudio endpoint")
    ap.add_argument("--model", default="qwen/qwen2.5-coder-14b", help="Model used for inference (e.g., qwen/qwen2.5-coder-14b)")
    ap.add_argument("--workers", type=int, default=4, help="concurrency for --backend claude")
    ap.add_argument("--timeout", type=int, default=900)
    ap.add_argument("--max-chars", type=int, default=DEFAULT_MAX_CHARS)
    ap.add_argument("--force", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    if args.files:
        files = args.files
    elif args.file:
        files = [args.file]
    elif args.tier is not None:
        files = files_from_manifest(args.tier)
    else:
        files = files_from_manifest(None)

    print(f"batch_transpile: {len(files)} files, backend={args.backend}, model={args.model}, "
          f"workers={args.workers}" + (f", endpoints={args.endpoints}" if args.backend == "lmstudio" else ""))
    if args.dry_run:
        for f in files:
            print(f"  would transpile {f}  (real={is_real(f)})")
        return 0

    OUT.mkdir(exist_ok=True)

    # Pull-when-free scheduling: one "lane" per concurrent slot. For lmstudio a
    # lane is an endpoint (each can hold --per-endpoint concurrent jobs); for
    # claude a lane is just a worker. A task grabs a free lane on start and
    # returns it on finish, so a faster endpoint (e.g. the 7700XT) is handed the
    # next file as soon as it frees up — it naturally does MORE work than a
    # slower one, instead of a fixed 50/50 split.
    if args.backend == "lmstudio":
        lanes = [ep for ep in args.endpoints for _ in range(args.per_endpoint)]
    else:
        lanes = [None] * args.workers
    free = queue.Queue()
    for lane in lanes:
        free.put(lane)

    def work(file: str) -> dict:
        lane = free.get()
        try:
            return transpile_one(file, args.backend, args.model, args.timeout,
                                 args.force, lane, args.max_chars)
        finally:
            free.put(lane)

    def _save_manifest():
        # atomic write so a crash/rate-limit mid-flush can't corrupt the manifest
        tmp = MANIFEST.parent / (MANIFEST.name + ".tmp")
        tmp.write_text(json.dumps(_MANIFEST, indent=2))
        tmp.replace(MANIFEST)

    def _mark(file: str, written: list[str]) -> None:
        rec = _BY_NAME.get(file)
        if not rec:
            return
        has_py = any(w.endswith(".py") for w in written)
        has_mj = any(w.endswith(".mojo") for w in written)
        rec["status"] = "done" if (has_py and has_mj) else \
                        ("partial" if (has_py or has_mj) else rec.get("status", "pending"))

    results, cost, n_ok = [], 0.0, 0
    with cf.ThreadPoolExecutor(max_workers=len(lanes)) as ex:
        futs = [ex.submit(work, f) for f in files]
        for fut in cf.as_completed(futs):
            r = fut.result()
            results.append(r)
            cost += r.get("cost_usd") or 0.0
            if r["status"] == "ok":          # write JSON status as files finish
                _mark(r["file"], r["written"])
                n_ok += 1
                if n_ok % 20 == 0:
                    _save_manifest()
            ep = f"  @{r.get('endpoint','')}" if r.get("endpoint") else ""
            print(f"  [{r['status']:<30}] {r['file']}  -> {', '.join(r['written']) or '-'}{ep}", flush=True)
    _save_manifest()

    ok = sum(1 for r in results if r["status"] == "ok")
    print(f"\ndone: {ok}/{len(results)} produced files."
          + (f" approx cost ${cost:.2f}" if cost else " (local, $0)"))
    (BASE / "2_batch_report.json").write_text(json.dumps(results, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
