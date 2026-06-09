# Mojo Corpus

A local corpus of (nearly) **all publicly available Mojo source code**, gathered to
bootstrap the Mojo ecosystem work in this repo: it is the raw material for the
procedural transpiler's idiom / API-mapping rules, training data for the fine-tuned
model, and a map of what the Mojo ecosystem already covers.

## What's committed vs. ignored

- **Committed:** this README + [`mojo_corpus_manifest.json`](./mojo_corpus_manifest.json)
  (one entry per repo + a top-level summary).
- **Ignored (NOT committed):** the raw shallow clones under `data/mojo_corpus/`
  (~14 GB, ~60k third-party files under a mix of licenses). They are gitignored to
  avoid committing thousands of third-party files (license + bloat). Re-create them
  from the manifest with the build scripts (also gitignored, see below).

## How it was built

Three sources, deduped by `owner/repo` (host-qualified):

1. **GitHub language + topic search** (main source) via the authenticated `gh` CLI:
   - `gh api search/repositories -f q='language:Mojo' --paginate` → 973 repos
     (under GitHub's 1000-result cap, so this is the *complete* language-tagged set).
   - `topic:mojo`, `topic:mojolang`, `topic:mojo-lang`, `topic:mojo-language`,
     `topic:modular-mojo` → adds repos GitHub didn't auto-classify as Mojo language.
2. **The official Modular repo** — [`modular/modular`](https://github.com/modular/modular)
   (open-source Mojo stdlib + MAX + examples + tests; formerly `modularml/mojo`).
   This is the canonical, highest-quality Mojo code.
3. **modular-community recipe sources** — the upstream `source.git` repo of every
   recipe in `C:/Github/modular-community/recipes/*` (33 package repos, incl. one
   GitLab repo, `hylkedonker/bridge`).

Each repo is cloned shallow (`git clone --depth 1`). Four repos contain filenames
illegal on Windows (e.g. `…:Zone.Identifier`) and were recovered with
`-c core.protectNTFS=false --no-checkout` + best-effort checkout.

Mojo files counted by extension: **`.mojo`** and **`.🔥`** (the emoji extension).

### Regenerating

The build scripts live in `data/` but are **gitignored** (scratch / regenerable):
`build_corpus_list.py` (merge + dedupe sources → worklist),
`clone_corpus.sh` (parallel shallow clone), `analyze_corpus.py` (counts → manifest).

## Summary (see manifest for exact numbers)

- **Repos found / cloned:** 1195 / 1195 (0 permanently failed).
- **Mojo files (`.mojo` + `.🔥`):** ~60.3k.
- **Mojo LOC:** ~16.2M.
- **Disk:** ~14 GB.

### License breakdown (per repo, from GitHub `licenseInfo` / LICENSE file)

| Category | Repos | Notes for downstream / commercial use |
|---|---:|---|
| Permissive (MIT, Apache-2.0, BSD, Unlicense, CC0, MPL, Zlib, …) | 479 | Safe for derived rules / training. MIT (284) + Apache-2.0 (157) dominate. |
| None / all-rights-reserved (no LICENSE) | 619 | **No license = default copyright.** Treat as look-but-don't-redistribute. |
| NOASSERTION (custom / unrecognized, incl. `modular/modular`) | 62 | Needs case-by-case review; `modular/modular` is under the permissive Apache-2.0-with-LLVM-exceptions / Modular community license — verify before redistribution. |
| Copyleft (GPL / AGPL / LGPL) | 29 | Viral; keep out of any permissively-licensed derived artifact. |
| LICENSE file present but uncategorized | 6 | Inspect the file. |

> For any **commercial** reuse of derived rules or training data, prefer the
> permissive + carefully-reviewed-NOASSERTION subset and exclude the
> none/all-rights-reserved and copyleft repos.

## Composition notes (read before using LOC blindly)

- **Not dominated by the official stdlib by file count** — there is real third-party
  breadth (1194 non-official repos). But raw LOC is skewed by a few outliers:
  - `lzumot/mojo_code_ft` alone is ~3.8M LOC / ~18.8k files (~24% of total LOC) — it
    is itself a *fine-tuning dataset* that bundles copied Mojo, not original library code.
  - Several near-duplicate **forks of `modular/modular`** (`Ivan-Vakhula07/modular`,
    `Tharun-Kumar-McW/modular`, `Ammar-Alnagar/modular-rs`, `drobertson-dev/gpt-oss-modular`,
    `Ammar-Alnagar/MAXimus`, …) each re-ship the ~1M-LOC stdlib.
  - The canonical `modular/modular` itself is ~981k LOC (6.1% of total) but is the
    single most valuable repo for quality.
  - **Dedupe forks/dataset-bundles** before training or computing "unique idiom" stats.
- Notable high-signal third-party libs: `NuMojo` (numerics), `lightbug_http` /
  `basalt-org/basalt` (HTTP / DL framework), `tairov/llama2.mojo`,
  `dorjeduck/llm.mojo`, `modular/mojo-gpu-puzzles`, plus the modular-community
  packages (EmberJson, mojo-regex, mojo-websockets, mist, NuMojo, …).

## Manifest schema

`mojo_corpus_manifest.json` = `{ "summary": {...}, "repos": [ {...}, … ] }`.

Per-repo fields: `repo`, `url`, `stars`, `license`, `mojo_files`, `mojo_loc`,
`updated_at`, `archived`, `clone_status`, `sources` (which discovery source(s)
surfaced the repo).
