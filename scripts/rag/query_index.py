#!/usr/bin/env python3
"""Stage 3: query the turbovec codebase index.

This is what the migration agent calls to solve dependency closure: given a query
(a symbol name, a function body, or an idiom question), retrieve the most relevant
C++ definitions / sibling functions / already-ported Mojo / idiom docs.

  retrieve("pvstar", k=5)                 -> the C++ def + anything referencing it
  retrieve(cpp_body_of_Qv, k=5)           -> similar/dependent functions + Mojo
  retrieve("how to translate std::map", k=3, lang="doc")

CLI: query_index.py "<query>" [k] [lang-filter]
"""
import json, sys, functools
from pathlib import Path
import numpy as np
from turbovec import TurboQuantIndex

RAG = Path(__file__).resolve().parents[2] / "data" / "rag"  # scripts/rag/<this file> -> repo root

@functools.lru_cache(maxsize=1)
def _load():
    info = json.load(open(RAG/"index_info.json"))
    idx = TurboQuantIndex.load(str(RAG/"index.tv"))   # static method -> returns the index
    meta = json.load(open(RAG/"meta.json"))
    texts = json.load(open(RAG/"texts.json"))
    from sentence_transformers import SentenceTransformer
    import torch
    dev = "cuda" if torch.cuda.is_available() else "cpu"
    model = SentenceTransformer(info["model"], device=dev, trust_remote_code=True)
    return idx, meta, texts, model

def retrieve(query, k=5, lang=None):
    idx, meta, texts, model = _load()
    q = model.encode([query], normalize_embeddings=True, convert_to_numpy=True).astype(np.float32)
    kk = k * 4 if lang else k                      # over-fetch then filter by lang
    scores, ids = idx.search(np.ascontiguousarray(q), kk)   # search wants 2D batched queries
    out = []
    for s, i in zip(np.asarray(scores).ravel().tolist(), np.asarray(ids).ravel().tolist()):
        m = meta.get(str(i))
        if not m: continue
        if lang and m["lang"] != lang: continue
        out.append({"score": round(float(s), 3), **m, "text": texts.get(str(i), "")})
        if len(out) >= k: break
    return out

def main():
    if len(sys.argv) < 2:
        print("usage: query_index.py '<query>' [k] [lang]"); return
    q = sys.argv[1]; k = int(sys.argv[2]) if len(sys.argv) > 2 else 5
    lang = sys.argv[3] if len(sys.argv) > 3 else None
    for r in retrieve(q, k, lang):
        print(f"[{r['score']}] {r['lang']:4s} {r['kind']:9s} {r['name']:28s} ({r['file']})")
        print("    " + r["text"].strip().replace("\n", "\n    ")[:300])
        print()

if __name__ == "__main__":
    main()
