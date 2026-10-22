# transpilers

Hybrid algorithmic + LLM source-to-source transpiler. **N-to-M** across many
languages through a single shared IR pipeline.

**10 frontends**: Python, C, C++, Java, C#, TypeScript, JavaScript, Fortran,
Visual Basic, and Assembly (via PyGhidra → C-like pseudocode).
**5 targets**: Rust, C, Mojo, Python, Fortran.

It is built for migrating large C++ codebases (EnergyPlus → Mojo and Python is the
main driver), so besides the translator itself it ships batch drivers, a verification
stack, a migration-progress tool, an NVIDIA fine-tuning toolchain for a C++/Python → Mojo
model, and the machinery to make that model's drafts usable: a deterministic post-pass,
best-of-n selection against an oracle, and a bit-exactness evaluation harness.

## Contents

- [Requirements](#requirements) · [Quick start](#quick-start) · [Command-line tools](#command-line-tools)
- [How it works](#how-it-works) · [Fidelity dial](#fidelity-dial) · [Status](#status)
- [Verification and reporting](#verification-and-reporting)
- [Migrating a large codebase](#migrating-a-large-codebase)
- [Using the local fine-tuned model](#using-the-local-fine-tuned-model)
- [Mojo fine-tuning (NVIDIA)](#mojo-fine-tuning-nvidia) · [Documentation](#documentation)
- [Layout](#layout) · [Development](#development) · [Roadmap](#roadmap) · [Licence](#licence)

## Requirements

- **Python 3.14 or newer** and **[uv](https://docs.astral.sh/uv/)**. [just](https://github.com/casey/just)
  and direnv are optional conveniences.
- **Target toolchains** only for `--verify` and the end-to-end matrix: `rustc`, a C
  compiler, `gfortran`, `mojo`. Cells whose toolchain is missing report `SKIP`, not `PASS`.
- **API keys**, only for the LLM paths:
  - `ANTHROPIC_API_KEY` for `transpile --infer-with-llm` and `--llm-rename`.
  - An OpenRouter key (`OPENROUTER_API_KEY`) for `transpile-llm` and the stateless
    runner's `openrouter` backend. `transpile-llm --endpoint URL` talks to a local
    OpenAI-compatible server instead (Ollama, LM Studio, llama.cpp, vLLM) and needs no key.
- **Optional extras:** `clang` for `--ir-augment`; the `codebase-memory-mcp` CLI for
  `--cbm`; `uv sync --group api` for `transpile-api`.
- **A CUDA build of PyTorch and an NVIDIA GPU** only for fine-tuning (see
  [Mojo fine-tuning](#mojo-fine-tuning-nvidia)).

## Quick start

```sh
direnv allow      # one-time: auto-activates .venv on cd
just setup        # uv sync
just example      # transpile examples/add.py to Rust and verify it
just check        # lint + full test suite
```

Without `direnv`/`just`:

```sh
uv sync
uv run transpile examples/add.py --target rust            # print the Rust translation
uv run transpile examples/add.py --target rust --verify   # also compile it with rustc
uv run pytest
```

## Command-line tools

`uv sync` installs these entry points:

| Command | What it does |
|---|---|
| `transpile` | Translate one file through the strict HIR → MIR → LIR pipeline. Choose `--source`/`--target`, `--verify`, `--fidelity`, `--path`. |
| `transpile-levels` | Run at object · file · module · folder granularity, with `--engine {strict\|lift}`. |
| `transpile-llm` | Batch C++/Fortran → Mojo from a JSON config, through OpenRouter or a local server (`--endpoint`). Repair loop, parallel workers, `--postpass`, best-of-n with `--samples`/`--verify-cmd`, `--domain-prompts`. |
| `transpile-postpass` | Deterministic fixes for LLM-drafted Mojo kernels: C++/pre-1.0 syntax, `Array1D` loops, glibc-exact maths, `nc_mul` guards. See [below](#using-the-local-fine-tuned-model). |
| `transpile-build-config` | Scan a source tree and write the JSON config that `transpile-llm` consumes. |
| `transpile-comments` | Strip C++ comments from the sources referenced by a config, or from a single file. |
| `transpile-api` | HTTP API server. Needs `uv sync --group api`. |

Useful `transpile` options beyond the basics:

| Option | Effect |
|---|---|
| `--path python_pivot` | Route C++ → Python → target, with Python as a shared IR (C++ sources only). |
| `--ir-augment` | Compile C/C++ to LLVM IR to pre-fill type holes without LLM calls (needs `clang`). |
| `--trace-types` | Run Python under `sys.settrace` and use the recorded runtime types to fill holes. |
| `--infer-with-llm`, `--llm-rename` | Ask the LLM for what algorithmic inference could not resolve, or to rename opaque locals (Ghidra `local_10`). |
| `-I DIR`, `--include-impls` | C/C++: inline local `#include "X.h"` headers (and their sibling `.cpp`) into one translation unit. |
| `--cbm REPO_ROOT` | C++: recover the cross-file class/method/macro surface from a codebase-memory-mcp graph. |
| `--provenance FILE` | Write a JSON sidecar mapping every LIR node to its originating HIR node. |

Examples:

```sh
uv run transpile examples/example.cpp --path python_pivot --target rust
uv run transpile-levels examples/example.cpp --level file --engine lift
```

Run any command with `--help` for the full option list.

## How it works

### Why hybrid

Pure-algorithmic transpilers can't infer types or map idioms; pure-LLM ones
(TransCoder et al.) produce unverifiable output. So the work is split:

| Algorithmic | LLM |
|-------------|-----|
| Parse, symbol resolution, dataflow, emission, verification | Type-hole filling, idiom mapping, naming, comments |

Three rules the codebase enforces:

1. **LLMs operate on typed holes, never free-form text.** Every call declares a
   response shape and a validator.
2. **Every LLM output is verified**: parse, compile, and behaviourally (tests).
3. **All LLM calls are cached** by `hash(prompt + model + temperature)`, so the
   pipeline is reproducible.

Promoted LLM answers land in `stdlib_maps/` as data, so the system bends from
LLM-heavy toward algorithmic-heavy over time.

### Three-tier IR

```
Frontend  →  HIR (source-faithful)  →  MIR (normalised, typed)  →  LIR (target-shaped)  →  Backend  →  verify
```

The key invariant: **HIR → MIR may not invent types it doesn't know.** Missing
information becomes an `UnknownT` hole that a later pass (algorithmic inference
first, LLM fallback) must explicitly fill. The pipeline refuses constructs it
can't model rather than emit wrong code.

### The never-refuse lift

A second engine, the **never-refuse lift** (`transpilers.lift`), does whole-file
C++ → Python 1:1, emitting `# TODO[lift]` stubs for gaps (about 96% mechanical on
EnergyPlus). Run any granularity (object · file · module · folder/repo) with
`transpile-levels --engine {strict|lift}`: `strict` is the verified HIR pipeline,
`lift` never refuses.

## Fidelity dial

`transpile --fidelity {structural|idiomatic}` (default `structural`) controls how
faithful the output must be to the source's architecture. Under `structural`,
`--verify` additionally runs the **structural-fidelity verifier**: the output's
module/function/struct skeleton and control-flow nesting must be isomorphic to the
source's. Idiom mapping is allowed only at the statement/expression level, for example
foreach → indexed loop, Rust's struct+impl split, or Fortran methods as free
functions. Added, dropped, merged or renamed functions and flattened control flow
fail the gate. `idiomatic` skips the skeleton gate, permitting parent-level rewrites.
It applies to the direct path only.

## Status

These figures were recorded in earlier runs and have not been re-run for this
README; re-run the commands in [Verification and reporting](#verification-and-reporting)
to reproduce them.

Verified end-to-end (compile + run + output match) on `examples/algorithms/`
(18 Python files): **Rust, Mojo, Python, Fortran all 18/18; C 17/18**
(needs dynamic-array growth for `sieve.py`).

Real-world corpus (`examples/samples/`, transpile-only → Rust): JavaScript
26/27, C++ 78/170, Python 32/57, Java 27/74, C 20/70.

The end-to-end Mojo and C++ numbers are *compile-and-run* results that require
those toolchains to be installed. The engine itself (parse → IR → emit, type
inference, the verifiers, and all pure-Python paths) is exercised by the pytest
suite, which runs without any target toolchain. Mojo target verification is gated
on a working `mojo` install; where it is absent, the matrix reports those cells as
`SKIP` rather than `PASS`, so the Mojo figures are not reproducible in a
toolchain-less CI.

## Verification and reporting

End-to-end matrix: compile every output and verify it matches Python's stdout.

```sh
uv run python scripts/run_matrix.py examples/algorithms
uv run python scripts/transpile_matrix.py examples/samples/Python rust   # transpile only
```

Failure taxonomy: classify every verify-gate failure over a corpus into
`parse · unresolved-symbol · unfilled-UnknownT-hole · type-inference-miss ·
target-compile-error · output-mismatch · structural-divergence · timeout`
and roll it up per (source, target) pair (CSV + markdown):

```sh
uv run python scripts/failure_taxonomy.py examples/samples --targets rust,mojo --csv out.csv
```

`src/transpilers/verify/behavioral.py` additionally classifies semantic divergences
in verified output, for example floored versus truncated integer division.

## Migrating a large codebase

For whole-repository migrations such as EnergyPlus:

1. **Plan the batch:** `transpile-build-config <source_dir> -o config.json` (use
   `--exclude`, `--min-lines`/`--max-lines`, `--tier`, `--sort`).
2. **Transpile:** `transpile-llm config.json` (add `--repair` for the compile-driven
   repair loop, `--dry-run` or `--status` to inspect first, `--resolve` to retry
   entries marked done but missing their `.mojo`). `--endpoint URL --model NAME` uses
   a local server instead of OpenRouter; `--postpass` applies the deterministic fixes
   to each draft; `--samples N --verify-cmd CMD` keeps the first of up to N drafts that
   a verifier accepts. `--domain-prompts` adds GoogleTest or Eigen guidance when those
   sources are detected. See [Using the local fine-tuned model](#using-the-local-fine-tuned-model).
3. **Stateless one-shot runner:** `stateless transpilation/2_transpile.py` produces a
   Python and a Mojo port per file in one completion. Backends: `claude`, `lmstudio`
   (load-balanced across endpoints) and `openrouter` (retries with backoff, and model
   failover via `OPENROUTER_FAILOVER`). `--chunk` compresses or splits oversize files
   and stitches the result. See `stateless transpilation/0_inference.md` to serve the
   fine-tuned model locally.
4. **Track progress:** `scripts/migration_status.py` compares the upstream repository
   with its port (lines of code, file/function counts, migration-map status, test
   results), optionally across two git revisions; see [docs/migration_status.md](docs/migration_status.md).
   `tools/migraph/` renders the migration as an interactive graph you can scrub through
   git history.
5. **Benchmark models:** `benchmarks/` holds `transpilation-bench`, a 40-task
   C++/Python → Mojo suite ([benchmarks/README.md](benchmarks/README.md)), and
   `benchmarks/epmojo_eval/`, which scores drafts by whether they are bit-for-bit identical
   to the verbatim C++ ([benchmarks/epmojo_eval/README.md](benchmarks/epmojo_eval/README.md)).

## Using the local fine-tuned model

The repo ships the LoRA adapter (`data/sft/cpp_mojo/adapter_15b_v2`, on
`Qwen/Qwen2.5-Coder-1.5B-Instruct`), not the base weights. To serve it, merge the adapter
into the base and convert it to GGUF for Ollama, llama.cpp or LM Studio
(`stateless transpilation/0_inference.md` has the recipe). Then:

```sh
uv run transpile-llm config.json --endpoint http://localhost:11434/v1 \
    --model <the name you gave the model> --postpass
```

Things worth knowing, all measured on this adapter:

- **It answers with one fenced `mojo` block**, which `transpile-llm` accepts when there are no
  `<<<FILE>>>` markers (exactly one closed `mojo` fence; several fences are refused as ambiguous).
- **Leave `--domain-prompts` off for it.** With the EnergyPlusMojo guidance the model often copies the
  guidance's example function instead of translating the routine.
- **Raw drafts are rarely bit-exact; the post-pass is what makes them usable.** It is
  `transpilers.repair.mojo_postpass`, also available as `transpile-postpass FILE`, and every rule can be
  switched off (`--no-syntax`, `--no-structs`, `--no-arrays`, `--no-mut`, `--no-libm`, `--no-fma`):
  - C++ and pre-1.0 Mojo habits become Mojo 1.0 (`//` comments, `fn`, `let`, `alias`, `&&`, `const`, quoted imports);
  - a field-less struct with one method is lifted to a function named after the C++ routine;
  - `Array1D` parameters become `List` only when every use is the canonical `for i in range(a.l(), a.u() + 1)`
    loop with the variable used solely as `x[i]`; anything else is reported, never guessed;
  - `std.math` calls (`exp`, `pow`, `log`, ...) are routed to glibc, `pow(x, 2)` becomes `nc_mul(x, x)`,
    ObjexxFCL's `pow_N` and `max`/`min` follow the upstream spelling (pass `--source` the C++ text);
  - `mut` is added to `List`-like parameters the body index-assigns;
  - products that feed an add or subtract are wrapped in `nc_mul`, including products bound to variables,
    because Mojo fuses `a*b + c` into an FMA that the oracle build (`-ffp-contract=off`) does not.
  Anything it cannot fix (C++ braces, unknown types, no `@export` entry) is listed in the report.
- **Best-of-n when a verifier exists.** `--samples N --temperature 0.8 --verify-cmd CMD` draws up to N drafts
  per file and keeps the first that `CMD` accepts with exit status 0 (`{target}` and `{source}` are
  substituted). `benchmarks/epmojo_eval/verify_one.py` is such a verifier for routines extracted from
  EnergyPlusMojo: it accepts a draft only if it is bit-exact.

Measured with the harness in `benchmarks/epmojo_eval/` (3,000 edge-case inputs per routine, bit for bit
against the verbatim C++, no guidance, temperature 0 unless stated):

| Set | Raw output | With the post-pass |
|---|---|---|
| Development, 40 routines (31 unique) | 8 exact | 39 exact |
| Held-out, 21 unique routines | 1 exact | 16 exact (19 after the struct rule, which was written after seeing that pattern) |
| The 3 routines greedy decoding fails, best-of-8 with the oracle | | 2 recovered |

Read these numbers narrowly: the routines are short, stateless, numeric `Real64 → Real64` functions (52
unique in total); the development set was used while writing the rules, so the held-out 16 of 21 is the fair
figure; routines with arrays, state, output parameters or callees were not measured; and the post-pass is
meant for model drafts, not for rewriting existing kernels. Best-of-n needs an oracle for the routine.

## Mojo fine-tuning (NVIDIA)

A toolchain-free data and fine-tune stack bootstraps the C++/Python → Mojo translator
adapter. It runs on NVIDIA GPUs with a CUDA build of PyTorch.

- **Run or retrain the adapter:** [RUN.md](RUN.md) covers setup and the LLaMA-Factory
  recipe. `scripts/sft/train_3b_cuda_local.sh` is the local two-phase 3B run for an NVIDIA
  GPU; `scripts/sft/cloud_train.sh` and `tools/cloud/` are for a rented NVIDIA box
  (`scripts/sft/cloud_bundle.md`).
- **Shipped adapter:** `data/sft/cpp_mojo/adapter_15b_v2` (LoRA on
  `Qwen/Qwen2.5-Coder-1.5B-Instruct`), plus the training pairs in `data/sft/`.
- **Algorithm dataset generator:** `scripts/sft/build_algorithm_pairs.py` emits verified
  C/C++/Python → Mojo (plus Rust/C bonus) pairs into `data/sft/algorithms/` from the
  seed corpus in `examples/`, with a rejects channel for unmappable constructs.
- **Record/replay shims:** `scripts/sft/record_replay.py` with bool/int normalisation so
  captured fixtures replay deterministically.
- **Psychrometric shims:** `scripts/sft/psychro_shims.py` provides a real
  `PsyPsatFnTemp` implementation (replacing the earlier `pvstar` stub) for
  EnergyPlus-flavoured ports.
- **God-object slicing:** `scripts/sft/god_object_slice.py` emits per-module sub-state
  Mojo structs from a god-object slice.
- **Data flywheel:** `just flywheel` pipes verified repairs back into `stdlib_maps/` and
  the SFT corpus ([docs/data_flywheel.md](docs/data_flywheel.md)).

## Documentation

| Topic | Where |
|---|---|
| Running and retraining the Mojo model | [RUN.md](RUN.md), [docs/fine_tuning_guide.md](docs/fine_tuning_guide.md), [docs/finetune_qwen7b.md](docs/finetune_qwen7b.md) |
| Cloud/NVIDIA training bundle | [tools/cloud/README.md](tools/cloud/README.md), [scripts/sft/cloud_bundle.md](scripts/sft/cloud_bundle.md) |
| Migration status report | [docs/migration_status.md](docs/migration_status.md) |
| Data flywheel | [docs/data_flywheel.md](docs/data_flywheel.md) |
| LLVM IR grounding and IR-pair datasets | [docs/llvm_ir_pipeline.md](docs/llvm_ir_pipeline.md), [docs/ir_pair_pipeline.md](docs/ir_pair_pipeline.md) |
| Multi-LLM pipeline | [docs/multi_llm_pipeline.md](docs/multi_llm_pipeline.md) |
| Migrating Topologic | [docs/topologic_migration.md](docs/topologic_migration.md) |
| Strategy and research | [docs/north_star_strategy.md](docs/north_star_strategy.md), [docs/transpilation-methods-research.md](docs/transpilation-methods-research.md), [docs/related_projects.md](docs/related_projects.md) |
| Benchmarks | [benchmarks/README.md](benchmarks/README.md) |
| Bit-exactness evaluation harness | [benchmarks/epmojo_eval/README.md](benchmarks/epmojo_eval/README.md) |
| Post-pass rules | [src/transpilers/repair/mojo_postpass.py](src/transpilers/repair/mojo_postpass.py) (module docstring) |

## Layout

```
src/transpilers/   frontends · ir (hir/mir/lir) · passes · backends · llm · verify · repair · rag · graph · cli
scripts/           dataset builders · sft/ (fine-tune + eval) · rag/ · migration_status.py
data/              datasets · the shipped Mojo LoRA adapter · codebase RAG index
examples/          verified corpus (algorithms/ + per-language samples)
tests/             engine test suite (Mojo-gated and GPU/ML cases skip automatically)
benchmarks/        transpilation-bench (40-task C++/Python → Mojo) · epmojo_eval/ (bit-exactness harness)
tools/             migraph (migration dashboard) · cloud (portable NVIDIA training bundle)
stateless transpilation/   one-shot per-file runner for large batches
deploy/            Dockerfile for the HTTP API
```

## Development

```sh
just --list       # every recipe
just test         # pytest
just lint         # ruff check src tests
just fmt          # ruff format src tests
just check        # lint + test (what CI should run)
```

The pytest suite needs no target toolchain; Mojo-gated and ML/torch tests skip
automatically when their dependencies are absent. Core tooling: **uv** (Python
dependencies), **just** (task runner), **direnv** (shell activation) and the Hugging
Face stack (Transformers / PEFT / LLaMA-Factory) for fine-tuning.

## Roadmap

Tracked in [GitHub Issues](https://github.com/ModelTok/transpilers/issues).
Highlights: dynamic array growth on Fortran (done on C), `OptionT`/`RefT` in the type
lattice, and statement-expression sequencing in HIR (to lift postfix `i++`/`i--` out of
expression contexts).

## Licence

Copyright (c) 2026 Bartlomiej Tokarzewski. All Rights Reserved. No copying,
distribution or modification without prior written permission; see [LICENSE](LICENSE).
