#!/usr/bin/env python3
"""Few-shot example retrieval — the 'vector DB' half of RAG for migration.

For a query C++ function, retrieve the most SIMILAR already-verified C++->Mojo
pairs and offer them as in-context examples, so a small model sees relevant,
known-correct patterns. Uses TF-IDF cosine (rare tokens weighted higher) — a
dependency-free stand-in for embeddings; swap in a real embedding index later for
better recall, but token-TFIDF already captures most of the signal for code.

  retrieve(cpp, k=3) -> list[{name, cpp, mojo, score}]
"""
import json, math, re, functools
from collections import Counter
from pathlib import Path
REPO = Path("/home/bart/Github/transpilers")
SRC = REPO / "data/sft/diverse/verified.jsonl"

def toks(s): return re.findall(r"[A-Za-z_]\w+", s)

@functools.lru_cache(maxsize=1)
def _corpus():
    pairs = [json.loads(l) for l in SRC.read_text().splitlines() if l.strip()]
    docs = [Counter(toks(p.get("cpp_unit", ""))) for p in pairs]
    df = Counter()
    for d in docs:
        df.update(d.keys())
    n = len(docs)
    idf = {t: math.log((n + 1) / (df[t] + 1)) + 1 for t in df}
    def vec(c):
        v = {t: c[t] * idf.get(t, 1.0) for t in c}
        nrm = math.sqrt(sum(x * x for x in v.values())) or 1.0
        return {t: x / nrm for t, x in v.items()}
    return pairs, [vec(d) for d in docs], idf, vec

def retrieve(cpp, k=3):
    pairs, vecs, idf, vec = _corpus()
    q = vec(Counter(toks(cpp)))
    scored = []
    for i, dv in enumerate(vecs):
        # cosine = dot of two L2-normalised sparse vectors
        s = sum(q[t] * dv.get(t, 0.0) for t in q)
        scored.append((s, i))
    scored.sort(reverse=True)
    out = []
    for s, i in scored[:k]:
        p = pairs[i]
        cu = p.get("cpp_unit", ""); mu = p.get("mojo_unit", "")
        if cu.strip() == cpp.strip():   # skip an exact self-match
            continue
        out.append({"name": p["name"], "cpp": cu, "mojo": mu, "score": round(s, 3)})
    return out[:k]

def fewshot_block(cpp, k=3):
    ex = retrieve(cpp, k)
    if not ex:
        return ""
    parts = ["Here are similar verified C++ -> Mojo translations for reference:"]
    for e in ex:
        parts.append(f"```cpp\n{e['cpp'].strip()}\n```\n```mojo\n{e['mojo'].strip()}\n```")
    return "\n".join(parts) + "\n\n"

if __name__ == "__main__":
    recs = [json.loads(l) for l in (REPO/"data/sft/cpp_mojo/prod_test_cpp.jsonl").read_text().splitlines() if l.strip()]
    for r in recs[:4]:
        print(f"=== {r['function_name']} — top-3 similar verified pairs ===")
        for e in retrieve(r["cpp"], 3):
            print(f"  {e['score']:.3f}  [{e['name']}]")
        print()
