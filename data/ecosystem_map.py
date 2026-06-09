#!/usr/bin/env python3
"""TASK 3: ecosystem-coverage map of KEPT third-party Mojo repos.

Classify each kept repo into a domain via name + README + top-level structure
keyword rules. Aggregate per-domain covering repos, stars, LOC, and a maturity
rating. Cross-reference the most-depended-on Python/C++ categories to build the
GAP list of high-value bootstrap targets.

Outputs: data/mojo_ecosystem_coverage.md, data/mojo_ecosystem_coverage.json
"""
import json, os, re

ROOT = os.path.dirname(os.path.abspath(__file__))

# Domain -> list of (regex keyword) tested against repo name + readme + structure.
# Order matters: first matching domain wins (most-specific first).
DOMAINS = [
    ("ML/DL/tensors", [
        r"\bllama", r"\bllm\b", r"\bgpt\b", r"\btransformer", r"\bneural", r"\bnnet",
        r"deep learning", r"\bautograd\b", r"micrograd", r"\btensor", r"\bmlp\b",
        r"\bcnn\b", r"\brnn\b", r"diffusion", r"stable.?diffusion", r"\bmnist\b",
        r"machine learning", r"\bdl\b", r"\bml\b framework", r"inference engine",
        r"\bmojmelo\b", r"\bbasalt\b", r"\bvoodoo\b", r"backprop", r"gradient descent",
        r"\byolo\b", r"\bbert\b", r"\bgan\b", r"reinforcement", r"\brl\b ",
    ]),
    ("numerics/linalg", [
        r"numeric", r"linear algebra", r"\blinalg\b", r"\bmatrix", r"\bmatmul\b",
        r"\bndarray\b", r"\bnumpy\b", r"\bnumojo\b", r"scientific comput",
        r"\bsimd\b", r"\bblas\b", r"\bvector math", r"\bcalculus\b", r"\bstatistic",
        r"\bnabla\b", r"mojosci", r"\balgebra\b", r"\bfft\b", r"\bsignal process",
        r"\bquaternion", r"\bgeometr",
    ]),
    ("GPU/compute", [
        r"\bgpu\b", r"\bcuda\b", r"\bkernel\b", r"\bmetal\b", r"\bvulkan\b",
        r"compute shader", r"gpu puzzle", r"parallel comput", r"\bptx\b",
        r"\bwarp\b", r"\brocm\b",
    ]),
    ("graphics", [
        r"\bgraphics\b", r"\brender", r"\braytrac", r"ray.?trac", r"\bpath.?trac",
        r"\bsdl\b", r"\bopengl\b", r"\bgame engine\b", r"\bgame\b", r"\bgui\b",
        r"\bgtk\b", r"\bui\b ", r"\bpixel", r"\bimage process", r"\bcanvas\b",
        r"\bshader\b", r"\bvoxel\b", r"\b3d\b",
    ]),
    ("web/HTTP", [
        r"\bhttp\b", r"\bweb\b", r"\bserver\b", r"\brouter\b", r"\bwsgi\b",
        r"\basgi\b", r"\brest\b", r"\bapi server", r"\bframework\b.*web",
        r"lightbug", r"\bnavette\b", r"\bwebsocket", r"\bflask\b", r"\bfastapi\b",
        r"\bbackend\b", r"web framework", r"\burl\b",
    ]),
    ("networking", [
        r"\bsocket", r"\btcp\b", r"\budp\b", r"\bnetwork", r"\brpc\b", r"\bgrpc\b",
        r"\bdns\b", r"\bproxy\b", r"\bclient\b.*server", r"\bmqtt\b",
    ]),
    ("crypto", [
        r"\bcrypto", r"\bhash\b", r"sha256", r"\bsha-?\d", r"\bmd5\b", r"\baes\b",
        r"\brsa\b", r"\bsecp256k1\b", r"\becdsa\b", r"\bsignature", r"\bcipher",
        r"\bblake", r"\bencrypt", r"\bkeccak\b", r"\bbitcoin\b", r"\bblockchain\b",
        r"\bzk\b", r"\bzero.?knowledge\b",
    ]),
    ("data/serialization", [
        r"\bjson\b", r"\byaml\b", r"\bcsv\b", r"\btoml\b", r"\bprotobuf\b",
        r"\bmsgpack\b", r"\bserializ", r"\bparquet\b", r"\barrow\b", r"\bmarrow\b",
        r"emberjson", r"\bdataframe\b", r"\bpandas\b", r"\bencoding\b.*decode",
        r"\bbase64\b", r"\bxml\b",
    ]),
    ("parsing/regex", [
        r"\bregex\b", r"\bparser\b", r"\bparsing\b", r"\blexer\b", r"\btokeniz",
        r"\bgrammar\b", r"\bre2\b", r"\bpeg\b", r"\bast\b", r"\bcompiler\b",
        r"\bbison\b", r"\byacc\b", r"\bfasta\b", r"\bfastq\b", r"blazeseq",
        r"bioinformatic", r"\bsequence pars",
    ]),
    ("db/storage", [
        r"\bdatabase\b", r"\bsql\b", r"\bsqlite\b", r"\bpostgres", r"\bredis\b",
        r"\bkey.?value\b", r"\bstorage\b", r"\bkv.?store\b", r"\bb.?tree\b",
        r"\bdb\b", r"\bduckdb\b", r"\borm\b",
    ]),
    ("CLI", [
        r"\bcli\b", r"command.?line", r"\bargparse", r"\bprism\b", r"\bterminal\b",
        r"\btui\b", r"\bshell\b", r"\bargument pars", r"\bflags?\b parsing",
        r"\bmog\b", r"\bspinner\b", r"\bprompt\b",
    ]),
    ("datetime", [
        r"\bdatetime\b", r"\bdate\b.*time", r"\btime zone", r"\btimezone\b",
        r"\bmorrow\b", r"\bcalendar\b", r"human.?friendly date",
    ]),
    ("testing", [
        r"\btest framework", r"\bpytest\b", r"\bunit test", r"\bassert", r"\bmock\b",
        r"\btesting\b", r"\bbenchmark\b", r"\btest runner",
    ]),
    ("FFI/interop", [
        r"\bffi\b", r"\bbinding", r"\bctypes\b", r"\bextern\b", r"\binterop\b",
        r"calling c", r"\bc library", r"\bpyo3\b", r"python interop", r"\bdlopen\b",
    ]),
    ("audio", [
        r"\baudio\b", r"\bsound\b", r"\bdsp\b", r"\bsynth\b", r"\bmidi\b", r"\bwav\b",
    ]),
    ("stdlib-extensions", [
        r"stdlib", r"std.?lib", r"standard library", r"\butils?\b", r"\bhelpers?\b",
        r"\bcollections?\b", r"\bextensions?\b", r"\btoolbox\b", r"forge.?tools",
        r"\bcommon\b lib",
    ]),
]

NONLIB_HINTS = [  # repos that are not real Mojo libraries / are noise
    "perl", "travis-ci", "this repository is archived", "deprecated",
]

# Repos that are the language/runtime itself, editor tooling, meta-lists, course
# material, or transpilers -- not ecosystem *libraries*. Classified separately so
# they don't inflate library domains.
META_REPOS = {
    "modular/modular", "modular/modular-community", "modular/mojo-syntax",
    "ego/awesome-mojo", "CrossGL/crosstl", "py2many/py2many", "TheAlgorithms/Mojo",
    "bajrangCoder/zed-mojo", "Aaron-212/tree-sitter-mojo", "mojodojodev/mojodojo.dev",
    "Ivo-Balbaert/The_Way_to_Mojo", "coderonion/hello-algo-mojo",
}
META_NAME_PATS = [r"awesome-", r"tree-sitter", r"-syntax$", r"\.dev$", r"zed-mojo",
                  r"mojodojo", r"the_way_to_mojo", r"^mojo$", r"hello-?world",
                  r"learn", r"tutorial", r"playground", r"manual", r"\bdocs?\b",
                  r"advent-of-code", r"aoc\d", r"100days", r"mojolings", r"-gym$"]

def is_meta(repo, readme):
    if repo in META_REPOS:
        return True
    name = repo.split("/", 1)[1].lower()
    for p in META_NAME_PATS:
        if re.search(p, name):
            return True
    rl = readme.lower()[:600]
    if "transpil" in rl or "textmate grammar" in rl or "awesome mojo" in rl:
        return True
    return False

def classify(repo, readme, top):
    name = repo.split("/", 1)[1].lower()
    hay = (name + " " + " ".join(top).lower() + " " + readme.lower())
    # quick non-mojo / noise detection handled by caller via loc==0
    for dom, pats in DOMAINS:
        for p in pats:
            if re.search(p, hay):
                return dom
    return None

def rate(repos):
    """Maturity from #repos, max stars, total distinct LOC."""
    if not repos:
        return "none"
    max_stars = max(r["stars"] for r in repos)
    tot_loc = sum(r["distinct_mojo_loc"] for r in repos)
    n = len(repos)
    if (max_stars >= 60 and tot_loc >= 10000) or tot_loc >= 40000:
        return "mature"
    if max_stars >= 20 or tot_loc >= 5000:
        return "nascent"
    return "toy"

# Most-depended-on Python/C++ ecosystem categories for the GAP cross-reference.
# (category, canonical libs, mojo_domain_to_check)
PY_CXX_PILLARS = [
    ("numerics/ndarray (numpy)", "numpy", "numerics/linalg"),
    ("scientific computing (scipy)", "scipy", "numerics/linalg"),
    ("dataframes (pandas/polars)", "pandas, polars", "data/serialization"),
    ("HTTP client (requests/httpx)", "requests, httpx", "web/HTTP"),
    ("web framework (flask/fastapi/django)", "flask, fastapi", "web/HTTP"),
    ("data validation (pydantic)", "pydantic", "data/serialization"),
    ("ORM / SQL toolkit (sqlalchemy)", "sqlalchemy", "db/storage"),
    ("classical ML (scikit-learn)", "scikit-learn", "ML/DL/tensors"),
    ("deep learning (pytorch/tensorflow)", "pytorch, tensorflow", "ML/DL/tensors"),
    ("plotting/viz (matplotlib)", "matplotlib", "graphics"),
    ("regex engine (re/re2)", "re2", "parsing/regex"),
    ("JSON/serialization", "json, msgpack", "data/serialization"),
    ("datetime (arrow/pendulum)", "arrow, pendulum", "datetime"),
    ("CLI framework (click/argparse)", "click, argparse", "CLI"),
    ("testing (pytest)", "pytest", "testing"),
    ("crypto/hashing (cryptography/hashlib)", "cryptography", "crypto"),
    ("async runtime (asyncio/tokio)", "asyncio, tokio", "_async"),
    ("image processing (Pillow/OpenCV)", "Pillow, OpenCV", "graphics"),
    ("Apache Arrow / columnar", "pyarrow", "data/serialization"),
    ("GPU compute (cupy/numba.cuda)", "cupy, numba", "GPU/compute"),
    ("database drivers (psycopg/redis-py)", "psycopg, redis", "db/storage"),
    ("templating (jinja2)", "jinja2", "web/HTTP"),
    ("logging (logging/loguru)", "loguru", "stdlib-extensions"),
    ("config/env (python-dotenv)", "dotenv", "stdlib-extensions"),
    ("compression (zlib/zstd)", "zlib, zstandard", "_compression"),
]

def main():
    sig = json.load(open(os.path.join(ROOT, "_repo_signals.json"), encoding="utf-8"))
    for s in sig:
        s["stars"] = s.get("stars") or 0

    # exclude obvious non-Mojo noise: 0 distinct mojo loc -> not a covering Mojo lib
    real = [s for s in sig if s["distinct_mojo_loc"] > 0]
    noise = [s for s in sig if s["distinct_mojo_loc"] == 0]

    domain_repos = {d: [] for d, _ in DOMAINS}
    domain_repos["language-core/tooling"] = []
    uncategorized = []
    for s in real:
        entry = {
            "repo": s["repo"], "stars": s["stars"],
            "distinct_mojo_loc": s["distinct_mojo_loc"],
            "license": s["license"],
        }
        if is_meta(s["repo"], s["readme"]):
            domain_repos["language-core/tooling"].append(entry)
            continue
        dom = classify(s["repo"], s["readme"], s["top"])
        if dom:
            domain_repos[dom].append(entry)
        else:
            uncategorized.append(entry)

    # sort each domain by stars then loc
    for d in domain_repos:
        domain_repos[d].sort(key=lambda r: (-r["stars"], -r["distinct_mojo_loc"]))

    all_domains = [d for d, _ in DOMAINS] + ["language-core/tooling"]
    domain_summary = {}
    for d in all_domains:
        reps = domain_repos[d]
        domain_summary[d] = {
            "rating": rate(reps),
            "num_repos": len(reps),
            "total_distinct_loc": sum(r["distinct_mojo_loc"] for r in reps),
            "max_stars": max((r["stars"] for r in reps), default=0),
            "repos": reps[:12],
        }

    # ---- GAP analysis (evidence-driven, NAME-anchored) ----
    # For each Python/C++ pillar, find the best DEDICATED Mojo repo. Match the
    # keyword against the repo NAME first (high precision); only fall back to a
    # rare readme keyword. This avoids big-README libs (lightbug, Mojmelo) being
    # falsely credited to unrelated pillars (datetime/json/plotting/compression).
    def best_dedicated(name_kws, readme_kws=None, minloc=150):
        hits = []
        for s in real:
            if s["distinct_mojo_loc"] < minloc or is_meta(s["repo"], s["readme"]):
                continue
            nm = s["repo"].split("/", 1)[1].lower()
            rd = s["readme"].lower()[:1500]
            hit = any(re.search(k, nm) for k in name_kws)
            if not hit and readme_kws:
                hit = any(re.search(k, rd) for k in readme_kws)
            if hit:
                hits.append((s["stars"], s["distinct_mojo_loc"], s["repo"]))
        hits.sort(reverse=True)
        return hits

    def pillar_rating(hits):
        if not hits:
            return "none"
        stars, loc, _ = hits[0]
        ndedicated = len(hits)
        if (stars >= 50 and loc >= 8000) or (loc >= 25000 and stars >= 10):
            return "mature"
        if stars >= 10 or loc >= 5000:
            return "nascent"
        return "toy"

    # (category, py/cpp libs, NAME keyword regexes, [optional rare README keywords])
    PILLARS = [
        ("numerics / ndarray (numpy)", "numpy", [r"numojo", r"nabla", r"ndarray", r"matrix", r"linalg"], [r"n-?dimensional array", r"numpy.?like"]),
        ("scientific computing (scipy)", "scipy", [r"mojosci", r"scipy", r"hepjo"], [r"scientific comput", r"special function"]),
        ("dataframes (pandas / polars)", "pandas, polars", [r"frame", r"polars", r"pandas", r"dataframe"], [r"\bdataframe\b"]),
        ("Apache Arrow / columnar", "pyarrow", [r"arrow", r"marrow", r"parquet"], [r"apache arrow", r"columnar"]),
        ("HTTP client (requests / httpx)", "requests, httpx", [r"http", r"floki", r"requests", r"httpx"], [r"http client"]),
        ("web framework (flask / fastapi)", "flask, fastapi", [r"lightbug", r"navette", r"web", r"server", r"http"], [r"web framework"]),
        ("data validation (pydantic)", "pydantic", [r"valid", r"pydantic", r"schema"], None),
        ("ORM / SQL toolkit (sqlalchemy)", "sqlalchemy", [r"sql", r"orm", r"sqlite", r"postgres", r"\bdb\b"], None),
        ("classical ML (scikit-learn)", "scikit-learn", [r"mojmelo", r"sklearn", r"scikit", r"mlalgorithm", r"machine.?learning"], [r"scikit-learn", r"random forest"]),
        ("deep learning (pytorch / tensorflow)", "pytorch, tensorflow", [r"basalt", r"voodoo", r"torch", r"\bnn\b", r"neural"], [r"deep learning framework", r"autograd"]),
        ("plotting / viz (matplotlib)", "matplotlib", [r"plot", r"chart", r"matplot", r"\bviz\b", r"asciichart"], [r"plotting library", r"data visualiz"]),
        ("regex engine (re / re2)", "re2", [r"regex", r"re2", r"yoho"], [r"regular expression engine"]),
        ("JSON / serialization", "json, msgpack", [r"json", r"msgpack", r"flatbuffer", r"\bflx\b"], None),
        ("datetime (arrow / pendulum)", "arrow, pendulum", [r"morrow", r"datetime", r"-time", r"_time", r"chrono", r"small-time"], [r"date and time"]),
        ("CLI framework (click / argparse)", "click, argparse", [r"prism", r"\bcli\b", r"clap", r"argparse"], [r"cli library"]),
        ("testing (pytest)", "pytest", [r"pytest", r"test-?suite", r"testkit", r"testing"], [r"test framework", r"test runner"]),
        ("crypto / hashing (cryptography)", "cryptography, hashlib", [r"crypto", r"hash", r"keccak", r"secp", r"aes", r"sha\d", r"thistle", r"cipher"], None),
        ("async runtime (asyncio / tokio)", "asyncio, tokio", [r"async", r"uring", r"tokio", r"coroutine"], [r"async runtime", r"event loop"]),
        ("image processing (Pillow / OpenCV)", "Pillow, OpenCV", [r"image", r"mimage", r"opencv", r"pillow", r"png", r"jpeg"], None),
        ("GPU compute (cupy / numba.cuda)", "cupy, numba", [r"gpu", r"cuda", r"kernel", r"puzzle"], [r"gpu kernel"]),
        ("database drivers (psycopg / redis)", "psycopg, redis", [r"redis", r"psycopg", r"mongo", r"postgres", r"sqlite", r"driver"], None),
        ("templating (jinja2)", "jinja2", [r"template", r"jinja"], [r"template engine"]),
        ("logging (logging / loguru)", "loguru", [r"log", r"stump", r"firehose"], [r"logging library"]),
        ("config / env (python-dotenv)", "python-dotenv", [r"dotenv", r"config", r"env"], [r"\.env file"]),
        ("compression (zlib / zstd)", "zlib, zstandard", [r"zlib", r"zstd", r"gzip", r"compress", r"deflate"], [r"compression library"]),
    ]

    gaps = []
    covered = []
    for cat, libs, name_kws, readme_kws in PILLARS:
        hits = best_dedicated(name_kws, readme_kws)
        rating = pillar_rating(hits)
        best = hits[0] if hits else None
        rec = {
            "category": cat, "python_cpp_libs": libs,
            "best_existing": (best[2] if best else None),
            "best_stars": (best[0] if best else 0),
            "best_loc": (best[1] if best else 0),
            "n_dedicated_repos": len(hits),
            "rating": rating,
        }
        if rating in ("none", "toy"):
            # no real lib (or only a 0-9 star toy) => highest-value bootstrap target
            rec["priority"] = "HIGH"
            gaps.append(rec)
        elif rating == "nascent":
            # exists but thin. <30 stars => MEDIUM; >=30 => LOW (hardening, not greenfield)
            rec["priority"] = "MEDIUM" if rec["best_stars"] < 30 else "LOW"
            gaps.append(rec)
        else:  # mature
            covered.append(rec)

    prio_order = {"HIGH": 0, "MEDIUM": 1, "LOW": 2}
    gaps.sort(key=lambda g: (prio_order[g["priority"]], g["best_stars"]))

    # spec-shape: {domain: {repos:[...], rating}} as required by the task
    domains_simple = {d: {"rating": domain_summary[d]["rating"],
                          "repos": [r["repo"] for r in domain_repos[d]]}
                      for d in all_domains}

    out = {
        "summary": {
            "kept_repos_classified": len(real),
            "noise_repos_zero_mojo": len(noise),
            "uncategorized": len(uncategorized),
        },
        # required spec shape: {domain:{repos[],rating}} + gaps[]
        "domain_repos": domains_simple,
        # richer per-domain stats (stars/loc/top repos)
        "domains": {d: domain_summary[d] for d in all_domains},
        "uncategorized_top": sorted(uncategorized, key=lambda r: -r["stars"])[:25],
        "noise_examples": [{"repo": s["repo"], "stars": s["stars"]}
                           for s in sorted(noise, key=lambda x: -x["stars"])[:15]],
        "gaps": gaps,
        "covered_pillars": covered,
    }
    with open(os.path.join(ROOT, "mojo_ecosystem_coverage.json"), "w", encoding="utf-8") as f:
        json.dump(out, f, indent=2)

    print("DOMAIN COVERAGE:")
    for d in all_domains:
        s = domain_summary[d]
        print(f"  {d:22} {s['rating']:8} repos={s['num_repos']:>3} loc={s['total_distinct_loc']:>8} maxstars={s['max_stars']}")
    print(f"\nuncategorized real repos: {len(uncategorized)}  | zero-mojo noise: {len(noise)}")
    print(f"\nGAPS ({len(gaps)}):")
    for g in gaps:
        print(f"  [{g['priority']:6}] {g['category']:40} best={g['best_existing']} ({g['best_stars']}*, {g['rating']})")

if __name__ == "__main__":
    main()
