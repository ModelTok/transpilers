#!/usr/bin/env python3
"""Stage 2: embed the codebase chunks + build the turbovec index.

Loads data/rag/chunks.jsonl, embeds each chunk with a code-aware model, builds a
turbovec TurboQuantIndex (4-bit quantized — the whole point: compressed + fast at
scale), and writes the index + id->chunk metadata. At >1M LOC this is where
turbovec's 16x compression pays off; for the 6k-chunk prototype it just validates
the pipeline.

Outputs: data/rag/index.tv  (turbovec)  +  data/rag/meta.json (id -> chunk).
"""
import json, sys, time
from pathlib import Path
import numpy as np
import torch
from turbovec import TurboQuantIndex

RAG = Path(__file__).resolve().parents[2] / "data" / "rag"  # scripts/rag/<this file> -> repo root
MODELS = ["jinaai/jina-embeddings-v2-base-code", "BAAI/bge-small-en-v1.5"]

def load_model():
    from sentence_transformers import SentenceTransformer
    dev = "cuda" if torch.cuda.is_available() else "cpu"
    for m in MODELS:
        try:
            mod = SentenceTransformer(m, device=dev, trust_remote_code=True)
            print(f"embedding model: {m} ({mod.get_sentence_embedding_dimension()}d) on {dev}", flush=True)
            return mod
        except Exception as e:
            print(f"  {m} failed: {str(e)[:80]}", flush=True)
    raise SystemExit("no embedding model could load")

def main():
    chunks = [json.loads(l) for l in (RAG/"chunks.jsonl").read_text().splitlines() if l.strip()]
    model = load_model()
    texts = [f"{c['lang']} {c['kind']} {c['name']}\n{c['text'][:1200]}" for c in chunks]
    t0 = time.time()
    emb = model.encode(texts, batch_size=64, normalize_embeddings=True,
                       show_progress_bar=True, convert_to_numpy=True).astype(np.float32)
    print(f"embedded {len(emb)} chunks in {time.time()-t0:.0f}s, dim={emb.shape[1]}", flush=True)

    idx = TurboQuantIndex(dim=emb.shape[1], bit_width=4)
    idx.add(emb)
    try: idx.prepare()
    except Exception: pass
    idx.write(str(RAG/"index.tv"))
    json.dump({str(c["id"]): {k: c[k] for k in ("lang","kind","name","file")} for c in chunks},
              open(RAG/"meta.json","w"))
    # keep the texts separately (meta stays small)
    json.dump({str(c["id"]): c["text"] for c in chunks}, open(RAG/"texts.json","w"))
    json.dump({"model": model.tokenizer.name_or_path if hasattr(model,"tokenizer") else MODELS[0], "dim": int(emb.shape[1]), "n": len(chunks)}, open(RAG/"index_info.json","w"))
    print(f"turbovec index written -> {RAG/'index.tv'} ({len(chunks)} chunks, {emb.shape[1]}d, 4-bit)")
    print(f"raw float32 would be {len(chunks)*emb.shape[1]*4/1e6:.1f}MB; index.tv = {(RAG/'index.tv').stat().st_size/1e6:.1f}MB")

if __name__ == "__main__":
    main()
