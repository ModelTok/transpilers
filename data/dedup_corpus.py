#!/usr/bin/env python3
"""Hash every .mojo/.🔥 file in the corpus, dump per-file records to a cache.

CPU only. One pass over disk. Output: data/_dedup_cache.json
Record per file: {repo, relpath, sha256, loc}
"""
import json, os, hashlib, sys

ROOT = os.path.dirname(os.path.abspath(__file__))
CORPUS = os.path.join(ROOT, "mojo_corpus")
EXTS = (".mojo", ".\U0001f525")  # .mojo and .🔥

def count_loc(data: bytes) -> int:
    # LOC = number of lines (consistent with cloning report's line count)
    if not data:
        return 0
    n = data.count(b"\n")
    if not data.endswith(b"\n"):
        n += 1
    return n

def main():
    manifest = json.load(open(os.path.join(ROOT, "mojo_corpus_manifest.json"), encoding="utf-8"))
    repos = manifest["repos"]
    records = []
    for i, rec in enumerate(repos):
        repo = rec["repo"]
        d = os.path.join(CORPUS, repo.replace("/", "__"))
        if not os.path.isdir(d):
            continue
        for dirpath, dirnames, filenames in os.walk(d):
            # skip .git
            if ".git" in dirnames:
                dirnames.remove(".git")
            for fn in filenames:
                if fn.endswith(EXTS):
                    fp = os.path.join(dirpath, fn)
                    try:
                        with open(fp, "rb") as f:
                            data = f.read()
                    except OSError:
                        continue
                    sha = hashlib.sha256(data).hexdigest()
                    rel = os.path.relpath(fp, d).replace("\\", "/")
                    records.append({
                        "repo": repo,
                        "relpath": rel,
                        "sha256": sha,
                        "loc": count_loc(data),
                    })
        if (i + 1) % 100 == 0:
            print(f"  {i+1}/{len(repos)} repos, {len(records)} files", file=sys.stderr)
    out = os.path.join(ROOT, "_dedup_cache.json")
    with open(out, "w", encoding="utf-8") as f:
        json.dump(records, f)
    print(f"wrote {len(records)} file records to {out}")

if __name__ == "__main__":
    main()
