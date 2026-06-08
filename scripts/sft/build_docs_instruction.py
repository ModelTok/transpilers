#!/usr/bin/env python3
"""SFT source 4: instruction data from the mojo-syntax skill + crawled Mojo docs.

Two parts:
  4a SKILL — the curated mojo-syntax correction layer. Highest quality: each
     removed→current row becomes a "rewrite obsolete syntax" pair AND a Q&A.
     These are exactly the deltas a pretrained model gets wrong.
  4b DOCS  — Mojo stdlib API pages from the crawled ZIM (script/style stripped),
     framed as "documentation for <name>". Capped and weighted low: the eval
     showed doc-prose is the weakest grounding signal, so it's reference, not
     the backbone.

Emits data/sft/docs_instruction.jsonl.
"""
from __future__ import annotations

import glob, html, json, re
from pathlib import Path

SKILL = Path("/home/bart/.claude/skills/mojo-syntax/SKILL.md")
OUT = Path(__file__).resolve().parents[2] / "data/sft/docs_instruction.jsonl"
RAW = OUT.parent / "raw"
# The site publishes clean, LLM-oriented full-content docs — far better than the
# nav-polluted ZIM HTML. Chunk these by section header into concept examples.
LLM_DOCS = ["https://mojolang.org/llms-manual.txt",
            "https://mojolang.org/llms-reference.txt"]


def skill_pairs():
    rows = []
    txt = SKILL.read_text(errors="ignore")
    # parse the removed→replacement table
    for m in re.finditer(r"^\|\s*`([^|]+?)`\s*\|\s*(.+?)\s*\|\s*$", txt, re.M):
        removed = m.group(1).strip()
        repl_raw = m.group(2).strip()
        # take the first backticked token of the replacement as the canonical form
        rm = re.search(r"`([^`]+)`", repl_raw)
        if not rm:
            continue
        repl = rm.group(1).strip()
        if removed.lower().startswith(("removed", "-")) or not repl:
            continue
        rows.append({"instruction": "Rewrite this obsolete Mojo syntax using the "
                     "current Mojo 1.0 form. Output only the corrected code.",
                     "input": removed, "output": repl, "source": "skill"})
        rows.append({"instruction": f"In current Mojo, what replaces `{removed}`?",
                     "input": "", "output": f"`{repl}`", "source": "skill"})
    return rows


def _fetch(url: str) -> str:
    import urllib.request
    RAW.mkdir(parents=True, exist_ok=True)
    cache = RAW / url.rsplit("/", 1)[-1]
    if cache.exists():
        return cache.read_text(errors="ignore")
    with urllib.request.urlopen(url, timeout=60) as r:
        txt = r.read().decode("utf-8", "ignore")
    cache.write_text(txt)
    return txt


def doc_rows():
    """Chunk the clean LLM-oriented Manual + Reference by `##`/`###` section into
    concept-explanation examples."""
    rows = []
    hdr = re.compile(r"^(#{2,3})\s+(.*)$")
    for url in LLM_DOCS:
        try:
            text = _fetch(url)
        except Exception as e:
            print(f"  doc fetch failed {url}: {e}")
            continue
        lines = text.splitlines()
        # collect (title, body) sections
        cur_title, cur = None, []
        sections = []
        for ln in lines:
            m = hdr.match(ln)
            if m:
                if cur_title and cur:
                    sections.append((cur_title, "\n".join(cur).strip()))
                cur_title, cur = m.group(2).strip(), []
            elif cur_title is not None:
                cur.append(ln)
        if cur_title and cur:
            sections.append((cur_title, "\n".join(cur).strip()))
        for title, body in sections:
            if len(body) < 150 or len(title) < 3:
                continue
            rows.append({
                "instruction": f"Explain how {title} works in Mojo, with examples.",
                "input": "", "output": body[:2500], "source": "docs",
                "meta": {"section": title},
            })
    return rows


def main():
    rows = skill_pairs() + doc_rows()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("w") as f:
        for r in rows:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")
    from collections import Counter
    c = Counter(r["source"] for r in rows)
    print(f"docs_instruction: {len(rows)} examples  {dict(c)}")
    print(f"  -> {OUT}")


if __name__ == "__main__":
    main()
