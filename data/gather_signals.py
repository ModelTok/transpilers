#!/usr/bin/env python3
"""Gather classification signals per KEPT repo: name, README head, top-level
dir/file names. Output data/_repo_signals.json for ecosystem categorization.
"""
import json, os

ROOT = os.path.dirname(os.path.abspath(__file__))
CORPUS = os.path.join(ROOT, "mojo_corpus")

README_NAMES = ["README.md", "readme.md", "README.rst", "README", "README.txt",
                "Readme.md", "README.MD"]

def read_readme(d):
    for fn in README_NAMES:
        fp = os.path.join(d, fn)
        if os.path.isfile(fp):
            try:
                with open(fp, "r", encoding="utf-8", errors="ignore") as f:
                    return f.read()[:4000]
            except OSError:
                pass
    return ""

def main():
    clean = json.load(open(os.path.join(ROOT, "mojo_corpus_clean_manifest.json"), encoding="utf-8"))
    sig = []
    for e in clean["repos"]:
        if e["status"] != "keep":
            continue
        repo = e["repo"]
        d = os.path.join(CORPUS, repo.replace("/", "__"))
        readme = read_readme(d) if os.path.isdir(d) else ""
        top = []
        if os.path.isdir(d):
            try:
                top = sorted(os.listdir(d))[:40]
            except OSError:
                top = []
        sig.append({
            "repo": repo,
            "stars": e.get("stars", 0),
            "distinct_mojo_loc": e["distinct_mojo_loc"],
            "distinct_mojo_files": e["distinct_mojo_files"],
            "license": e["license"],
            "readme": readme,
            "top": top,
        })
    with open(os.path.join(ROOT, "_repo_signals.json"), "w", encoding="utf-8") as f:
        json.dump(sig, f)
    print(f"wrote signals for {len(sig)} kept repos")

if __name__ == "__main__":
    main()
