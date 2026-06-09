#!/usr/bin/env python3
"""TASK 2: license split of the DEDUPED corpus.

Buckets: permissive | copyleft | unlicensed | noassertion.
- manifest SPDX license id -> bucket via map.
- modular/modular forced to permissive (Apache-2.0-WITH-LLVM-exception, read LICENSE).
- NOASSERTION / FILE:* -> read the repo's LICENSE file and classify by content.
- None (no LICENSE detected) -> unlicensed (all-rights-reserved).
Distinct files/LOC per bucket use file-level dedup (sha canonical ownership).
"""
import json, os, re

ROOT = os.path.dirname(os.path.abspath(__file__))
CORPUS = os.path.join(ROOT, "mojo_corpus")

PERMISSIVE = {"MIT", "Apache-2.0", "BSD-3-Clause", "BSD-2-Clause", "Unlicense",
              "CC0-1.0", "MPL-2.0", "Zlib", "ISC", "0BSD", "BSL-1.0"}
COPYLEFT = {"GPL-3.0", "GPL-2.0", "AGPL-3.0", "LGPL-3.0", "LGPL-2.1", "EPL-2.0"}
# Artistic-2.0 is permissive-ish (FSF/OSI free, weak copyleft) -> treat permissive-leaning?
# Keep it explicit: Artistic-2.0 -> permissive (commercially usable).
PERMISSIVE |= {"Artistic-2.0"}

LICENSE_FILENAMES = ["LICENSE", "LICENSE.txt", "LICENSE.md", "LICENSE-APACHE",
                     "LICENSE-MIT", "COPYING", "COPYING.txt", "LICENSE.rst",
                     "license", "license.txt", "UNLICENSE", "LICENCE"]

def classify_license_text(text):
    """Return (bucket, spdx_guess) from raw LICENSE text."""
    t = text.lower()
    if "gnu affero general public license" in t or "agpl" in t:
        return "copyleft", "AGPL"
    if "gnu lesser general public license" in t or "lgpl" in t:
        return "copyleft", "LGPL"
    if "gnu general public license" in t or re.search(r"\bgpl\b", t):
        return "copyleft", "GPL"
    if "mozilla public license" in t:
        return "permissive", "MPL-2.0"
    if "apache license" in t:
        return "permissive", "Apache-2.0"
    if "mit license" in t or ("permission is hereby granted, free of charge" in t):
        return "permissive", "MIT"
    if "bsd" in t and "redistribution and use in source and binary" in t:
        return "permissive", "BSD"
    if "redistribution and use in source and binary" in t:
        return "permissive", "BSD"
    if "this is free and unencumbered software released into the public domain" in t:
        return "permissive", "Unlicense"
    if "creative commons" in t and "cc0" in t:
        return "permissive", "CC0-1.0"
    if "zlib" in t or "this software is provided 'as-is'" in t:
        return "permissive", "Zlib"
    if "isc license" in t:
        return "permissive", "ISC"
    if "boost software license" in t:
        return "permissive", "BSL-1.0"
    return "noassertion", "custom"

def read_repo_license(repo):
    d = os.path.join(CORPUS, repo.replace("/", "__"))
    if not os.path.isdir(d):
        return None
    # check root + one level
    candidates = []
    for fn in os.listdir(d):
        if any(fn.lower() == lf.lower() or fn.lower().startswith("license")
               or fn.lower().startswith("copying") or fn.lower() == "unlicense"
               for lf in LICENSE_FILENAMES):
            candidates.append(os.path.join(d, fn))
    for fp in candidates:
        if os.path.isfile(fp):
            try:
                with open(fp, "r", encoding="utf-8", errors="ignore") as f:
                    return f.read()
            except OSError:
                pass
    return None

def bucket_for(spdx):
    if spdx in PERMISSIVE:
        return "permissive"
    if spdx in COPYLEFT:
        return "copyleft"
    return None

def main():
    clean = json.load(open(os.path.join(ROOT, "mojo_corpus_clean_manifest.json"), encoding="utf-8"))
    aux = json.load(open(os.path.join(ROOT, "_clean_aux.json"), encoding="utf-8"))
    sha_canon = aux["sha_canon"]   # sha -> canonical repo
    sha_loc = aux["sha_loc"]

    repos = {e["repo"]: e for e in clean["repos"]}

    # distinct files/loc attributed to each repo (canonical owner)
    repo_distinct = {}  # repo -> [files, loc]
    for sha, repo in sha_canon.items():
        d = repo_distinct.setdefault(repo, [0, 0])
        d[0] += 1
        d[1] += sha_loc[sha]

    # ---- determine bucket + final license per repo ----
    repo_bucket = {}
    repo_final_license = {}
    refine_log = []
    for repo, e in repos.items():
        spdx = e["license"]
        # modular/modular: Apache-2.0 WITH LLVM-exception (read & confirmed) -> permissive
        if repo == "modular/modular":
            repo_bucket[repo] = "permissive"
            repo_final_license[repo] = "Apache-2.0-WITH-LLVM-exception"
            continue
        b = bucket_for(spdx) if spdx else None
        if b:
            repo_bucket[repo] = b
            repo_final_license[repo] = spdx
            continue
        # spdx is None / NOASSERTION / FILE:*
        if spdx is None:
            # no LICENSE file detected upstream -> still try to read (gh can miss),
            # else all-rights-reserved.
            txt = read_repo_license(repo)
            if txt:
                bb, guess = classify_license_text(txt)
                repo_bucket[repo] = bb
                repo_final_license[repo] = guess + " (read)"
                refine_log.append((repo, "None", bb, guess))
            else:
                repo_bucket[repo] = "unlicensed"
                repo_final_license[repo] = "all-rights-reserved (no LICENSE)"
            continue
        # NOASSERTION or FILE:* -> read the LICENSE file
        txt = read_repo_license(repo)
        if txt:
            bb, guess = classify_license_text(txt)
            repo_bucket[repo] = bb
            repo_final_license[repo] = guess + " (read)"
            refine_log.append((repo, str(spdx), bb, guess))
        else:
            repo_bucket[repo] = "noassertion"
            repo_final_license[repo] = "noassertion (no readable LICENSE)"

    # ---- aggregate distinct files/loc per bucket (KEEP repos only;
    #      duplicates/excluded are not part of the deduped usable corpus) ----
    buckets = {"permissive": [0, 0], "copyleft": [0, 0],
               "unlicensed": [0, 0], "noassertion": [0, 0]}
    # Distinct files are owned by their canonical repo. Only count a sha if its
    # canonical owner is a KEPT repo; if owned by a duplicate/excluded repo, the
    # content is excluded from the usable deduped corpus.
    for sha, repo in sha_canon.items():
        e = repos.get(repo)
        if not e or e["status"] != "keep":
            continue
        b = repo_bucket.get(repo, "noassertion")
        buckets[b][0] += 1
        buckets[b][1] += sha_loc[sha]

    # write per-repo license bucket back as a small artifact
    per_repo = []
    for repo, e in repos.items():
        if e["status"] != "keep":
            continue
        d = repo_distinct.get(repo, [0, 0])
        per_repo.append({
            "repo": repo,
            "bucket": repo_bucket[repo],
            "license": repo_final_license[repo],
            "distinct_mojo_files": d[0],
            "distinct_mojo_loc": d[1],
            "stars": e.get("stars", 0),
        })
    per_repo.sort(key=lambda x: -x["distinct_mojo_loc"])

    out = {
        "buckets": {k: {"distinct_files": v[0], "distinct_loc": v[1]}
                    for k, v in buckets.items()},
        "headline_permissive_distinct_loc": buckets["permissive"][1],
        "headline_permissive_distinct_files": buckets["permissive"][0],
        "modular_license": "Apache-2.0-WITH-LLVM-exception (read from LICENSE; permissive)",
        "notes": "Buckets cover KEPT (deduped) repos only. distinct files/loc use "
                 "sha256 file-level dedup with canonical ownership. 'unlicensed' = no "
                 "LICENSE file => all-rights-reserved.",
        "repos": per_repo,
    }
    with open(os.path.join(ROOT, "mojo_corpus_license_split.json"), "w", encoding="utf-8") as f:
        json.dump(out, f, indent=2)

    print("LICENSE SPLIT (deduped, kept repos):")
    for k, v in buckets.items():
        print(f"  {k:12} files={v[0]:>6}  loc={v[1]:>10,}")
    tot_loc = sum(v[1] for v in buckets.values())
    print(f"  {'TOTAL':12} loc={tot_loc:,}")
    print(f"\nHEADLINE permissive distinct LOC usable commercially: {buckets['permissive'][1]:,}")
    print(f"\nrefined {len(refine_log)} repos by reading LICENSE; sample:")
    for r in sorted(refine_log)[:15]:
        print("  ", r)

if __name__ == "__main__":
    main()
