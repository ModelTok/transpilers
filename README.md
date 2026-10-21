# transpilers

Hybrid algorithmic + LLM source-to-source transpiler. **N-to-M** across many
languages through a single shared IR pipeline.

**10 frontends**: Python, C, C++, Java, C#, TypeScript, JavaScript, Fortran,
Visual Basic, and Assembly (via PyGhidra → C-like pseudocode).
**5 targets**: Rust, C, Mojo, Python, Fortran.

It is built for migrating large C++ codebases (EnergyPlus → Mojo and Python is the
main driver), so besides the translator itself it ships batch drivers, a verification
stack, a migration-progress tool and an NVIDIA fine-tuning toolchain for a
C++/Python → Mojo model.

## Contents

- [Requirements](#requirements) · [Quick start](#quick-start) · [Command-line tools](#command-line-tools)
- [How it works](#how-it-works) · [Fidelity dial](#fidelity-dial) · [Status](#status)
- [Verification and reporting](#verification-and-reporting)
- [Migrating a large codebase](#migrating-a-large-codebase)
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
    runner's `openrouter` backend.
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
| `transpile-llm` | Batch C++/Fortran → Mojo through OpenRouter from a JSON config (repair loop, parallel workers, `--domain-prompts`). |
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

Run any command with `--help` for the full option list. On a Windows console that
uses a legacy code page, `transpile --help` fails on the `→` in its help text; set
`PYTHONIOENCODING=utf-8` first.

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
   entries marked done but missing their `.mojo`). `--domain-prompts` adds GoogleTest
   or Eigen guidance when those sources are detected.
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
   C++/Python → Mojo suite ([benchmarks/README.md](benchmarks/README.md)).

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
| Benchmark | [benchmarks/README.md](benchmarks/README.md) |

## Layout

```
src/transpilers/   frontends · ir (hir/mir/lir) · passes · backends · llm · verify · repair · rag · graph · cli
scripts/           dataset builders · sft/ (fine-tune + eval) · rag/ · migration_status.py
data/              datasets · the shipped Mojo LoRA adapter · codebase RAG index
examples/          verified corpus (algorithms/ + per-language samples)
tests/             engine test suite (Mojo-gated and GPU/ML cases skip automatically)
benchmarks/        transpilation-bench (40-task C++/Python → Mojo)
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
