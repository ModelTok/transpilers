---
name: transpilers-dev-loop
description: Use when building, testing or verifying a change in the transpilers repo (a frontend, IR pass, backend, verifier, repair post-pass or LLM path), or when quoting transpile pass rates.
---

# transpilers: build, test and verify a change

Rule: a translation counts only when it was compiled and run, and a missing toolchain is a `SKIP`, never a `PASS`. Quote pass rates with the command that produced them; the README's Status figures are old runs.

## Set-up and the routine loop (from `justfile` and `pyproject.toml`)
- Python 3.14+ and uv. `just setup` (= `uv sync`). The HTTP API needs `uv sync --group api`; fine-tuning needs the `ml` group plus a CUDA torch installed by hand (see `RUN.md`). Neither is part of routine work.
- `just test` (= `uv run pytest`, pass args through: `just test tests/test_python_to_rust.py -q`).
- `just lint` (`ruff check src tests`), `just fmt` (`ruff format src tests`), `just check` (lint + test).
- One file end to end: `uv run transpile <file> --target rust --verify` (`just transpile <file> <target>`). Targets: rust, c, mojo, python, fortran.
- `scripts/` is not in the pytest run (`testpaths = ["tests"]`); its ML probes need the `ml` group.

## Corpus checks when a change can move many files
- Compile-and-run matrix: `uv run python scripts/run_matrix.py examples/algorithms`.
- Transpile only: `uv run python scripts/transpile_matrix.py examples/samples/Python rust`.
- Failure taxonomy: `uv run python scripts/failure_taxonomy.py examples/samples --targets rust,mojo --csv out.csv` (`--limit N` for a smoke run, `--no-compile` to skip the compiler gate). Write outputs under `out/` (gitignored), not the repo root.
- Compare before and after on the same corpus and targets, and report per (source, target) pair, not one total.

## Traps
- Windows: tests marked `requires_sigalrm` are skipped because the wall-clock guard is a POSIX no-op; without the skip they spin forever. A new test that relies on `transpilers.verify._exec_timeout.time_limit` needs that marker (`tests/conftest.py`).
- Mojo-gated and torch tests skip when the toolchain or package is absent. A green run on a machine without `mojo` says nothing about Mojo output; say so.
- LLM calls are cached by prompt + model + temperature under `src/transpilers/llm/cache/` (gitignored apart from `.gitkeep`). A stale cache can hide a prompt change; never commit cache files.
- API keys: `ANTHROPIC_API_KEY` for `--infer-with-llm` / `--llm-rename`, `OPENROUTER_API_KEY` for `transpile-llm` and the stateless runner. Tests must not need them. Copy `.env.example`; never commit `.env`.
- Promoted LLM answers go into `src/transpilers/stdlib_maps/` as data (`just flywheel-promote`); `auto_generated.yaml` is written by the flywheel, so don't hand-edit it.
- The pre-commit hook lives in `.githooks/` and is enabled with `git config core.hooksPath .githooks`; it only syntax-checks staged files, so it is not a substitute for `just check`.
- Generated sweep files `scripts/ep_*.json`, `third_party/CodePivot/` (12 GB) and adapters other than `data/sft/cpp_mojo/adapter_15b_v2/` are gitignored on purpose.
