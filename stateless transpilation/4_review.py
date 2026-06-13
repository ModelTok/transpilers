#!/usr/bin/env python3
"""Step 4 — independent faithfulness review by a DIFFERENT model.

The transpiler (2_transpile.py) only produces ports. This step fires each file's
Python AND Mojo ports + the C++ oracle at a separate model that did NOT write
them, asking for a structured faithfulness verdict (and python/mojo agreement).
Same blind spots aren't shared, so this catches wrong-coefficient / wrong-branch
/ dropped-clamp errors a self-test would miss.

One stateless completion per file (no tools). Self-contained. Emits
4_review_report.json with the defect list -> feed back to the transpiler:
    python3 2_transpile.py --files <defective> --force --model <stronger>

Usage:
  python3 4_review.py --tier 1 --model opus
  python3 4_review.py --all --backend lmstudio \
      --endpoints http://m2:1234/v1 --model qwen/qwen3.6-27b --per-endpoint 2
"""

from __future__ import annotations

import argparse
import concurrent.futures as cf
import json
import queue
import re
import subprocess
import urllib.request
from pathlib import Path

BASE = Path(__file__).resolve().parent
PROMPT = (BASE / "4_review.md").read_text()
_BODY = PROMPT.split("---", 1)[1] if "---" in PROMPT else PROMPT
MANIFEST = BASE / "1_manifest.json"
_MANIFEST = json.loads(MANIFEST.read_text()) if MANIFEST.exists() else {"files": []}
_BY_NAME = {r["name"]: r for r in _MANIFEST["files"]}
PY_OUT, MOJO_OUT = BASE / "out" / "python", BASE / "out" / "mojo"
DEFAULT_MAX_CHARS = 480_000


def read(p: Path | None) -> str:
    return Path(p).read_text(errors="ignore") if p and Path(p).exists() else ""


def snake(name: str) -> str:
    return re.sub(r"(?<!^)(?=[A-Z])", "_", name).lower()


def _oracle(file: str) -> tuple[Path, Path | None]:
    r = _BY_NAME.get(file)
    if r:
        return Path(r["cc_path"]), (Path(r["hh_path"]) if r.get("hh_path") else None)
    return Path(), None


# ---- transport (mirrors 2_transpile.py; duplicated so each step stands alone) ----
def call_claude(prompt, model, timeout, endpoint):
    cmd = ["claude", "-p", "--output-format", "json", "--model", model,
           "--max-turns", "1", "--tools", ""]
    proc = subprocess.run(cmd, input=prompt, capture_output=True, text=True, timeout=timeout)
    if proc.returncode != 0:
        raise RuntimeError(f"claude exited {proc.returncode}: {proc.stderr[:400]}")
    p = json.loads(proc.stdout)
    return p.get("result", ""), {"cost_usd": p.get("total_cost_usd")}


def call_openai(prompt, model, timeout, endpoint):
    body = json.dumps({"model": model or "local-model",
                       "messages": [{"role": "user", "content": prompt}],
                       "temperature": 0.0, "max_tokens": 8000, "stream": False}).encode()
    req = urllib.request.Request(endpoint.rstrip("/") + "/chat/completions", data=body,
                                 headers={"Content-Type": "application/json",
                                          "Authorization": "Bearer lm-studio"})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        p = json.loads(resp.read())
    return p["choices"][0]["message"]["content"], {"cost_usd": 0.0}


def build_prompt(file: str) -> str | None:
    port_py = read(PY_OUT / f"{file}.py")
    if not port_py.strip():
        return None
    port_mojo = read(MOJO_OUT / f"{snake(file)}.mojo") or "(no mojo port produced)"
    cc, hh = _oracle(file)
    return (_BODY.replace("{FILE}", file).replace("{CC}", read(cc))
            .replace("{HH}", read(hh) if hh else "")
            .replace("{LANG}", (_BY_NAME.get(file) or {}).get("lang","cpp")).replace("{PORT_PY}", port_py).replace("{PORT_MOJO}", port_mojo))


def parse_verdict(text: str) -> dict:
    t = re.sub(r"\n```\s*$", "", re.sub(r"^```[a-zA-Z]*\n", "", text.strip()))
    try:
        return json.loads(t)
    except Exception:
        m = re.search(r"\{.*\}", t, re.DOTALL)
        if m:
            try:
                return json.loads(m.group(0))
            except Exception:
                pass
    return {"verdict": "unparsed", "defects": [], "raw": text[:400]}


def review_one(file, backend, model, timeout, endpoint, max_chars) -> dict:
    try:
        prompt = build_prompt(file)
        if prompt is None:
            return {"file": file, "verdict": "no-port", "defects": []}
        if len(prompt) > max_chars:
            return {"file": file, "verdict": "skip-too-large", "defects": []}
        fn = call_openai if backend == "lmstudio" else call_claude
        text, meta = fn(prompt, model, timeout, endpoint)
        v = parse_verdict(text)
        v.update(file=file, cost_usd=meta.get("cost_usd"))
        v.setdefault("verdict", "unparsed")
        v.setdefault("defects", [])
        return v
    except Exception as e:  # noqa: BLE001
        return {"file": file, "verdict": f"error: {e}", "defects": []}


def files_from_manifest(tier) -> list[str]:
    return [r["name"] for r in _MANIFEST["files"] if tier is None or r["tier"] == tier]


def main() -> int:
    ap = argparse.ArgumentParser()
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--files", nargs="+")
    g.add_argument("--file")
    g.add_argument("--tier", type=int)
    g.add_argument("--all", action="store_true")
    ap.add_argument("--backend", choices=["claude", "lmstudio"], default="claude")
    ap.add_argument("--endpoints", nargs="+", default=["http://localhost:1234/v1"])
    ap.add_argument("--per-endpoint", type=int, default=1)
    ap.add_argument("--model", default="opus", help="REVIEWER model — keep different from the transpiler")
    ap.add_argument("--workers", type=int, default=4)
    ap.add_argument("--timeout", type=int, default=900)
    ap.add_argument("--max-chars", type=int, default=DEFAULT_MAX_CHARS)
    args = ap.parse_args()

    files = (args.files or ([args.file] if args.file else files_from_manifest(args.tier)))
    files = [f for f in files if (PY_OUT / f"{f}.py").exists()]
    print(f"review: {len(files)} ports, reviewer={args.model}, backend={args.backend}")

    lanes = ([ep for ep in args.endpoints for _ in range(args.per_endpoint)]
             if args.backend == "lmstudio" else [None] * args.workers)
    free = queue.Queue()
    for ln in lanes:
        free.put(ln)

    def work(f):
        ln = free.get()
        try:
            return review_one(f, args.backend, args.model, args.timeout, ln, args.max_chars)
        finally:
            free.put(ln)

    results = []
    with cf.ThreadPoolExecutor(max_workers=len(lanes)) as ex:
        for fut in cf.as_completed([ex.submit(work, f) for f in files]):
            r = fut.result()
            results.append(r)
            nd = len(r.get("defects", []))
            hi = sum(1 for d in r.get("defects", []) if d.get("severity") == "high")
            print(f"  [{str(r['verdict'])[:16]:<16}] {r['file']}  defects={nd} (high={hi})")

    defective = [r["file"] for r in results
                 if r.get("defects") or r.get("verdict") not in ("faithful", "no-port")]
    (BASE / "4_review_report.json").write_text(json.dumps(results, indent=2))
    print(f"\nfaithful={sum(1 for r in results if r.get('verdict') == 'faithful')}  "
          f"needs-work={len(defective)} / {len(files)}")
    if defective:
        print("repair:  python3 2_transpile.py --force --model <stronger> --files "
              + " ".join(defective[:20]) + (" ..." if len(defective) > 20 else ""))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
