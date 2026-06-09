#!/usr/bin/env python3
"""TASK 1: dedupe/clean the Mojo corpus from the hash cache.

Repo-level: a repo whose Mojo-file content-set is a near-superset/duplicate of
modular/modular (or another repo) -> duplicate_of. Keep canonical modular/modular.
Bulk copied-code dumps -> excluded: copied-corpus.
File-level: collapse exact sha256 dups; canonical = repo with most stars (then
modular preference), keep one.
"""
import json, os

ROOT = os.path.dirname(os.path.abspath(__file__))

def load():
    recs = json.load(open(os.path.join(ROOT, "_dedup_cache.json"), encoding="utf-8"))
    manifest = json.load(open(os.path.join(ROOT, "mojo_corpus_manifest.json"), encoding="utf-8"))
    return recs, manifest

def main():
    recs, manifest = load()
    repos_meta = {r["repo"]: r for r in manifest["repos"]}

    # group files by repo
    repo_files = {}   # repo -> {sha: loc}  (set of distinct shas + loc per sha)
    repo_filelist = {}  # repo -> list of (relpath, sha, loc)
    repo_paths = {}   # repo -> set(relpath)
    for rec in recs:
        repo = rec["repo"]
        repo_files.setdefault(repo, {})[rec["sha256"]] = rec["loc"]
        repo_filelist.setdefault(repo, []).append((rec["relpath"], rec["sha256"], rec["loc"]))
        repo_paths.setdefault(repo, set()).add(rec["relpath"])

    repo_shas = {repo: set(d.keys()) for repo, d in repo_files.items()}

    # ---- repo-level duplicate / fork detection ----
    # canonical modular stdlib reference
    MODULAR = "modular/modular"
    modular_shas = repo_shas.get(MODULAR, set())

    # stars for tie-breaking canonical choice
    def stars(repo):
        return repos_meta.get(repo, {}).get("stars", 0) or 0

    status = {}   # repo -> (status, reason, duplicate_of)

    # 1) explicit copied-corpus dumps: huge file count, tiny stars, name signals,
    #    and very low internal cohesion with the rest of the ecosystem.
    COPIED_DUMPS = {"lzumot/mojo_code_ft"}
    for repo in COPIED_DUMPS:
        if repo in repo_shas:
            status[repo] = ("excluded", "copied-corpus (bulk copied-code dump)", None)

    # 2) modular/modular forks. These are snapshots of the modular monorepo at
    #    different commits, so file CONTENT (sha) has drifted, but the directory
    #    PATH structure is a near-superset of modular's. Use path-set containment:
    #    >=70% of the repo's Mojo file paths exist in modular/modular AND the repo
    #    re-ships a substantial chunk of the stdlib (>=500 shared paths).
    modular_paths = repo_paths.get(MODULAR, set())
    for repo, paths in repo_paths.items():
        if repo == MODULAR or repo in status or not modular_paths:
            continue
        if len(paths) < 200:
            continue
        path_overlap = len(paths & modular_paths)
        cont = path_overlap / len(paths)
        if cont >= 0.70 and path_overlap >= 500:
            sha_ov = len(repo_shas[repo] & modular_shas)
            status[repo] = ("duplicate",
                            f"fork of {MODULAR} (re-ships stdlib: {path_overlap} of "
                            f"{len(paths)} Mojo file paths = {cont:.0%} match modular; "
                            f"{sha_ov} identical-content files)", MODULAR)

    # 3) pairwise near-duplicate repos (excluding modular & already-handled).
    #    Order by size; a later repo that is a near-subset/equal of an earlier kept
    #    repo -> duplicate_of that earlier repo. Use Jaccard + containment.
    kept_for_pairwise = [r for r in repo_shas
                         if r not in status and r != MODULAR and len(repo_shas[r]) >= 5]
    # canonical preference: more stars, then more files, then name
    kept_for_pairwise.sort(key=lambda r: (-stars(r), -len(repo_shas[r]), r))
    canon = []  # list of (repo, shas, paths)
    for repo in kept_for_pairwise:
        shas = repo_shas[repo]
        paths = repo_paths[repo]
        dup_of = None
        why = ""
        for crepo, cshas, cpaths in canon:
            inter = len(shas & cshas)
            if inter:
                containment = inter / len(shas)        # content containment
                jacc = inter / len(shas | cshas)
                if containment >= 0.90 or jacc >= 0.85:
                    dup_of = crepo
                    why = f"{containment:.0%} of its Mojo files identical"
                    break
            # path-structure fork (content drifted) for non-trivial repos
            if len(paths) >= 20:
                pinter = len(paths & cpaths)
                pcont = pinter / len(paths)
                if pcont >= 0.90 and pinter >= 20:
                    dup_of = crepo
                    why = f"{pcont:.0%} of its Mojo file paths match (fork, drifted content)"
                    break
        if dup_of:
            status[repo] = ("duplicate", f"near-duplicate of {dup_of} ({why})", dup_of)
        else:
            canon.append((repo, shas, paths))

    # ---- file-level dedup ----
    # canonical owner of each sha = kept repo with most stars (modular preferred),
    # excluding repos that are excluded/duplicate where possible but a sha may only
    # live in excluded repos -> then keep it (don't lose content) attributed to best repo.
    def repo_rank(repo):
        st = status.get(repo, ("keep", "", None))[0]
        # prefer kept > duplicate > excluded; then modular; then stars
        order = {"keep": 0, "duplicate": 1, "excluded": 2}[st]
        modpref = 0 if repo == MODULAR else 1
        return (order, modpref, -stars(repo), repo)

    sha_repos = {}  # sha -> list of repos containing it
    for repo, shas in repo_shas.items():
        for s in shas:
            sha_repos.setdefault(s, []).append(repo)
    sha_canon = {}  # sha -> canonical repo
    sha_dupcount = {}  # sha -> number of repos containing it
    for s, rlist in sha_repos.items():
        sha_dupcount[s] = len(rlist)
        sha_canon[s] = min(rlist, key=repo_rank)

    # distinct loc per sha (loc is identical for identical content)
    sha_loc = {}
    for rec in recs:
        sha_loc.setdefault(rec["sha256"], rec["loc"])

    # ---- per-repo distinct (post file-dedup) counts among KEPT repos ----
    # For a repo, distinct_mojo_files = number of shas for which it is the canonical owner.
    repo_distinct_files = {}
    repo_distinct_loc = {}
    for s, crepo in sha_canon.items():
        repo_distinct_files[crepo] = repo_distinct_files.get(crepo, 0) + 1
        repo_distinct_loc[crepo] = repo_distinct_loc.get(crepo, 0) + sha_loc[s]

    # ---- build clean manifest ----
    out_repos = []
    for rec in manifest["repos"]:
        repo = rec["repo"]
        st, reason, dup_of = status.get(repo, ("keep", "unique Mojo content", None))
        entry = {
            "repo": repo,
            "status": st,
            "reason": reason,
            "duplicate_of": dup_of,
            "stars": rec.get("stars", 0),
            "raw_mojo_files": rec.get("mojo_files", 0),
            "raw_mojo_loc": rec.get("mojo_loc", 0),
            "distinct_mojo_files": repo_distinct_files.get(repo, 0),
            "distinct_mojo_loc": repo_distinct_loc.get(repo, 0),
            "license": rec.get("license"),
        }
        out_repos.append(entry)

    # summary
    raw_loc = manifest["summary"]["total_mojo_loc"]
    distinct_files = len(sha_canon)
    distinct_loc = sum(sha_loc.values())
    kept_repos = sum(1 for e in out_repos if e["status"] == "keep")
    dup_repos = sum(1 for e in out_repos if e["status"] == "duplicate")
    excl_repos = sum(1 for e in out_repos if e["status"] == "excluded")

    summary = {
        "raw_loc": raw_loc,
        "raw_files": manifest["summary"]["total_mojo_files"],
        "distinct_loc_after_dedup": distinct_loc,
        "distinct_files": distinct_files,
        "kept_repos": kept_repos,
        "duplicate_repos": dup_repos,
        "excluded_repos": excl_repos,
        "total_repos": len(out_repos),
    }

    clean = {"summary": summary, "repos": out_repos}
    with open(os.path.join(ROOT, "mojo_corpus_clean_manifest.json"), "w", encoding="utf-8") as f:
        json.dump(clean, f, indent=2)

    # also stash sha_canon-derived data for later tasks (license/coverage)
    aux = {
        "sha_canon": sha_canon,       # sha -> canonical repo
        "sha_loc": sha_loc,           # sha -> loc
        "status": {r: status.get(r, ("keep","",None))[0] for r in repo_shas},
    }
    with open(os.path.join(ROOT, "_clean_aux.json"), "w", encoding="utf-8") as f:
        json.dump(aux, f)

    print(json.dumps(summary, indent=2))
    print("\n-- excluded/duplicate repos (top 20 by raw loc) --")
    flagged = [e for e in out_repos if e["status"] != "keep"]
    flagged.sort(key=lambda e: -e["raw_mojo_loc"])
    for e in flagged[:20]:
        print(f"{e['status']:9} {e['raw_mojo_loc']:>9} loc  {e['repo']}  <- {e['duplicate_of'] or e['reason']}")
    print(f"\ntotal flagged repos: {len(flagged)}")

if __name__ == "__main__":
    main()
