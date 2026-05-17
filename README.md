# transpilers

Hybrid algorithmic + LLM source-to-source transpiler. Goal: N-to-M across
**Fortran, C, C++, Visual Basic, Python** → **Rust, Zig, C, Mojo**.

## Status

Three source frontends (**Python**, **C**, **C++**) and four targets
(**Rust**, **Zig**, **C**, **Mojo**) — twelve source-target pairs working
end-to-end with compiler-verified output. C → C is the round-trip case.
Full algorithmic + interprocedural type inference for Python; C and C++
use their native annotations. Fortran and VB sources are stubbed.

## Why hybrid

Pure-algorithmic transpilers can't translate idioms or fill type holes; pure-
LLM transpilers (TransCoder et al.) produce unverifiable output. The split:

| Algorithmic | LLM |
| --- | --- |
| Parse, symbol resolution, dataflow, emission, verification | Type-inference holes, ownership inference, idiom mapping, naming, comments |

Three rules the codebase enforces:

1. **LLMs operate on typed holes, never free-form text.** Every call declares
   an expected response shape and validator.
2. **Every LLM output is verified** — syntactic (parse), semantic (compile),
   behavioral (tests / property checks).
3. **All LLM calls are cached** by `hash(prompt + model + temperature)` so the
   pipeline is reproducible.

A promoted LLM answer lands in `stdlib_maps/` as data — over time the system
bends from LLM-heavy toward algorithmic-heavy.

## Architecture: three-tier IR

```
Frontend (per source language)  →  HIR  (source-faithful, preserves idioms)
                                    ↓
                                   MIR  (normalized, typed, language-agnostic)
                                    ↓
                                   LIR  (target-shaped: Rust dialect, Zig dialect, …)
                                    ↓
Backend (per target language)   →  source text
                                    ↓
                                   verify (parse + compile + behavioral)
```

The single most important boundary: **HIR→MIR may not invent types it doesn't
know.** Missing information becomes an `UnknownT` hole that a later pass —
algorithmic inference first, LLM fallback — must fill explicitly.

## Layout

```
src/transpilers/
├── frontends/   python/ c/ cpp/ fortran/ vb/   (only python implemented)
├── ir/          hir.py mir.py lir.py types.py
├── passes/      hir_to_mir.py mir_to_rust_lir.py
├── backends/    rust/ zig/ c/ mojo/            (only rust implemented)
├── llm/         client.py prompts/ cache/      (typed-hole client, cached)
├── stdlib_maps/ python_to_rust.toml …          (data — promoted mappings)
├── verify/      rust.py                        (rustc invocation)
└── cli/         main.py                        (transpile <src> --target rust)
```

## Try it

The project uses `uv` for Python deps, `just` as the task runner, and `direnv`
for shell activation.

```sh
direnv allow              # one-time: auto-activates .venv on `cd`
just setup                # uv sync
just example              # transpile examples/add.py, verify with rustc
just test                 # full test suite
just check                # lint + tests
```

Without `direnv`/`just`:

```sh
uv sync
uv run transpile examples/add.py --target rust --verify
uv run pytest
```

## Roadmap (rough)

Done:
- Python / C / C++ frontends (C-like subset for C++ — no classes/templates)
- Rust / Zig / C / Mojo backends
- Type inference: algorithmic dataflow + interprocedural + LLM fallback
- String concat with target-specific handling (format!, native, refused)
- C-style for loops desugared at frontend → re-emerge native when target wants

Next:
- Float-literal HIR/MIR/LIR nodes
- Classes / structs (Python class → Rust struct / Mojo struct)
- C pointer & array support
- C++ classes, references, std::vector
- Fortran frontend (start from transpyle fork's parser)
- More LLM-augmented passes: idiom rewrites, stdlib mapping
