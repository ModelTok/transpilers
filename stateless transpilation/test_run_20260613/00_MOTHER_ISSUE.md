# TEST RUN on ENERGYPLUS — stateless 100% LLM transpilation (mother issue)

**TL;DR** — Tested the stateless 100% LLM C++→Mojo transpiler pipeline against the EnergyPlus oracle. **1,962/2,404 files transpiled (60.1% by LOC) for ~$5–$200 of cloud LLM spend.** Remaining work is concentrated in 2 families (tst/EnergyPlus unit tests and third_party/ssc thermal models). Then ran a batch auto-repair over all 2,400 .mojo files in `EnergyPlus-Mojo/` — **2,345 files modified in 3.5s, 53,000 lines touched** — which cleans the LLM-emission artefacts but exposes a deeper structural problem: Mojo 1.0's package system requires a wholesale re-layout, not a textual fix.

## 1. Baseline (frozen at 2026-06-13)

- Oracle: `/home/bart/Github/EnergyPlus/` — 2,549 source files / 2,143,669 LOC (per `1_manifest.json`)
- Transpiler target: `/home/bart/Github/EnergyPlus-Mojo/` (2,400 `.mojo` files, mostly C++→Mojo ports)
- `ep_full_config.json` (older `transpile.py` Mojo-only run, 2,404 entries / 1,942,299 LOC):
  - **done = 1,962 (60.1% by LOC)**
  - 410 "no FILE block" failures
  - 10 "compile" failures
  - 6 LLM errors (4 EOF/validate, 2 context-length > 1M tokens)
  - 14 still pending
  - 2 empty-source
- After `_reconcile_status.py`: 390 files with **both** Python + Mojo dual-ports + 26 partial; 2,133 still pending for the dual-port `2_transpile.py` runs
- **All EnergyPlus engine code (tiers 0-3) is 100% transpiled** (1_manifest.json's 308 files / 709K LOC). All bundled third-party libs (tier 8) are 100% done. **The remaining failures are all in tier 9** (eigen doc/tests, ssc/ssc mostly done, ssc/tcs and ssc/test at 0%).

## 2. Token & cost accounting (existing run)

Calibrated from `2_batch_report.json`'s one OK record: $0.1247 USD for 231,778 prompt + 46,021 completion tokens → implied $0.45/M total.

| Scope | Prompt (M) | Completion (M) | Cost (cheap: dsv4) | Cost (mid: haiku-ish) | Cost (expensive: sonnet) |
|---|---:|---:|---:|---:|---:|
| **Done** (1,962 files / 1.17M LOC) | 22.7 | 7.7 | **$5.32** | $22.82 | $182.89 |
| **Remaining** (no retry) | 17.2 | 6.8 | **$4.32** | $18.81 | $153.68 |
| **Remaining** with 1 retry | 34.4 | 13.6 | **$8.63** | $37.62 | $307.36 |

Calibration: `test_run_20260613/02_token_accounting.json`.

## 3. Auto-repair batch run (this session)

Wrote a Python pipeline that walks every `.mojo` file in `EnergyPlus-Mojo/` and applies 15 deterministic textual rules. Ran in **3.5 seconds**, modified **2,345 / 2,400 files** in place. Top impacts:

| Rule | Count |
|---|---:|
| `fn_to_def` | 25,220 |
| `stripped_orphan_quotes` | 14,254 |
| `quoted_import_to_package` | 9,511 |
| `removed_pass` | 2,297 |
| `dropped_std_prefix` | 748 |
| `dropped_typename` | 210 |
| `stripped_file_markers` | 196 |
| `dropped_cpp_qualifiers` | 178 |
| `nullptr_to_none` | 107 |
| `dropped_using_namespace` | 79 |
| (full table in `auto_repair/inplace_manifest.json`) | |

**Total: 52,956 line edits across 2,345 files. `git diff --shortstat`: 2,345 files changed, 50,650 insertions(+), 52,585 deletions(-).**


## 4. Sample compile audit (post-repair)

Sampled 50 random `.mojo` files, ran `mojo build --emit llvm` on each. **0/50 passed.** Failure-mode breakdown:

| Category | Count | Meaning |
|---|---:|---|
| `unknown` (catch-all) | 30 | regex-uncovered errors, mostly "expected identifier" / "unresolved identifier" |
| `import_unresolved` | 9 | `unable to locate module 'X'` — Mojo 1.0 package system can't resolve the import |
| `global_expr` | 7 | `let X = "..."` or `namespace X:` at global scope |
| `bad_relative_import` | 2 | `from ..X import` in a file Mojo considers top-level |
| `garbled_first_line` | 1 | chat preamble not fully stripped (escape char) |
| `struct_conflict` | 1 | two files both define `struct EnergyPlusData` |

Raw audit: `test_run_20260613/04_audit_results.json`.

**The textual repair cleaned the LLM artefacts but the structural problems require a Mojo 1.0-aware refactor of the package layout.** Two structural pillars needed:

1. **Mojo 1.0 package system**: every directory with `.mojo` files needs an `__init__.mojo`; `src/EnergyPlus/` should be the package root. Currently none exist.
2. **Import graph re-derivation**: re-derive each file's `from` lines from the C++ `#include` graph + transpiled-file locations, using Mojo 1.0's relative-import rules.

The Trash version (`/home/bart/.local/share/Trash/files/energyplus-mojo/`) has a different layout (Python orchestrator + Mojo hot kernels in `src/mojo/<domain>/`) that doesn't share this problem — but it's a different design, not a port of these files.

## 5. Failure classes (per the 440 remaining transpiler failures)

| Class | Count | LOC | Recovery |
|---|---:|---:|---|
| **A — noFB, small (<2K)** | 330 | ~110K | Re-run with stronger model + better prompt format. Cheap. |
| **B — noFB, large (2K-10K)** | 73 | ~340K | Chunked transpile (`levels.object`) per top-level C++ object. |
| **C — noFB, huge (>10K)** | 7 | ~110K | Context-compression plugin OR long-ctx cloud endpoint. |
| **D — compile** (10) | 10 | ~25K | Deterministic repair (`mojo_repair.py`) + 1-shot LLM fix on stderr. |
| **E — LLM ctx wall** (2) | 2 | ~150K | Same as C. The SSC water/CO2 properties. |
| **F — LLM EOF/validate** (4) | 4 | ~8K | Retry with backoff + model failover. |
| **G — Pending** (14) | 14 | ~30K | First run. |
| **H — Empty source** (2) | 2 | 0 | Skip. |

By family: **270 in tst/EnergyPlus** (gtest macros confuse the LLM), **170 in third_party/ssc** (large thermal-system files).

## 6. Next steps (follow-up issues)

Filed as separate drafts in this directory:

1. `issue_01_chunked_transpile.md` — `levels.object` for 73+7 large noFB files (B/C).
2. `issue_02_context_compression.md` — for the 2 1M-token SSC files (E).
3. `issue_03_repair_compile_errors.md` — 10 `error: compile` files (D).
4. `issue_04_retry_with_backoff.md` — 4 EOF/validate errors (F).
5. `issue_05_mojo1_package_layout.md` — **the big one**. Re-layout so Mojo 1.0 can compile these files. ~2,400 files affected.
6. `issue_06_unit_test_specialization.md` — gtest-aware prompt for 270 tst/EnergyPlus failures.
7. `issue_07_ssc_specialization.md` — Eigen-aware prompt for 170 third_party/ssc failures.

## 7. Repro

### Cloud LLM run (one-shot, no local inference)
```bash
export OPENROUTER_API_KEY=sk-...
cd /home/bart/Github/transpilers/stateless\ transpilation
python3 transpile.py ep_full_config.json --status
python3 transpile.py ep_full_config.json --repair --workers 4
```

### Auto-repair batch
```bash
python3 /tmp/auto_repair_inplace.py   # 3.5s, modifies 2,345 files in place
```

### Compile audit
```bash
export MODULAR_HOME=/home/bart/Github/energyplus-mojo/.pixi/envs/default/share/max
MOJO=/home/bart/Github/energyplus-mojo/.pixi/envs/default/bin/mojo
$MOJO build --emit llvm path/to/file.mojo -o /tmp/out.ll
```
