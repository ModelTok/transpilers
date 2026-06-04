# transpilers

Hybrid algorithmic + LLM source-to-source transpiler. **N-to-M** across
many languages with a single shared IR pipeline.

## Two engines, four granularities

- **Strict pipeline** (`transpile`, `transpilers.cli.main`): source → HIR → MIR
  (typed; `infer_types` + LLM fill) → LIR → target. **Verified** — refuses
  constructs it can't model rather than emit wrong code. Best for kernels.
- **Never-refuse lift** (`transpilers.lift`): whole-file C++ → Python 1:1,
  emitting `# TODO[lift]` stubs for gaps instead of refusing. Built for
  "lift the whole repo now, refactor later"; ~96% mechanical on EnergyPlus.

Run at any granularity with `transpile-levels` (`transpilers.levels`):
**object** (one class/function/method/var) · **file** · **module** (`.hh`+`.cc`)
· **folder/repo** (`#include`-ordered). `--engine {strict|lift}`.

## Status

**Eleven frontends**: Python, C, C++, Java, C#, TypeScript, JavaScript,
Fortran, Go, Visual Basic, plus Assembly via PyGhidra (staged: PyGhidra
emits C-like pseudocode that feeds the existing C frontend).

**Seven targets**: Rust, Zig, C, Mojo, Go, Python, Fortran.

### Verified end-to-end (compile + run + output match)

On the curated `examples/algorithms/` corpus (18 Python files):

| Target | Pass rate |
|--------|-----------|
| Rust   | 18 / 18 |
| Go     | 18 / 18 |
| Mojo   | 18 / 18 |
| Python | 18 / 18 |
| Fortran| 18 / 18 |
| C      | 18 / 18 |
| Zig    | 17 / 18 |

One remaining gap (sieve.py on Zig) needs dynamic-array growth support
(ArrayList in Zig). The C target now ships realloc-backed growable slices,
closing `sieve.py` on C. A float-precision rounding diff remains on Zig
newton_sqrt.

### Real-world corpus (transpile-only, → Rust)

Stress-tested against `examples/samples/` (the
[amanmehara/programming](https://github.com/amanmehara/programming)
corpus, Apache 2.0):

| Frontend | Pass rate |
|----------|-----------|
| JavaScript | 26 / 27 |
| C++        | 78 / 170 |
| Python     | 32 / 57  |
| Java       | 27 / 74  |
| C          | 20 / 70  |
| Go         | 1 / 9    |

## Why hybrid

Pure-algorithmic transpilers can't infer types or map idioms; pure-LLM
transpilers (TransCoder et al.) produce unverifiable output. The split:

| Algorithmic | LLM |
|-------------|-----|
| Parse, symbol resolution, dataflow, emission, verification | Type-hole filling, idiom mapping, naming, comments |

Three rules the codebase enforces:

1. **LLMs operate on typed holes, never free-form text.** Every call
   declares an expected response shape and a validator.
2. **Every LLM output is verified** — syntactic (parse), semantic
   (compile), and behavioral (tests / property checks).
3. **All LLM calls are cached** by `hash(prompt + model + temperature)`
   so the pipeline is reproducible.

A promoted LLM answer lands in `stdlib_maps/` as data; over time the
system bends from LLM-heavy toward algorithmic-heavy.

## Architecture: three-tier IR

```
Frontend (per source language)  →  HIR  (source-faithful, preserves idioms)
                                    ↓
                                   MIR  (normalized, typed, language-agnostic)
                                    ↓
                                   LIR  (target-shaped per backend)
                                    ↓
Backend (per target language)   →  source text
                                    ↓
                                   verify (parse + compile + behavioral)
```

The single most important boundary: **HIR→MIR may not invent types it
doesn't know.** Missing information becomes an `UnknownT` hole that
a later pass — algorithmic inference first, LLM fallback — must
explicitly fill.

## Layout

```
src/transpilers/
├── frontends/    python/ c/ cpp/ java/ csharp/ javascript/ typescript/
│                 fortran/ go/ vb/ asm/  (+ _markers.py shared helpers)
├── ir/           hir.py  mir.py  lir.py  types.py
├── passes/       hir_to_mir.py  mir_to_<target>_lir.py  infer_types.py
├── backends/     rust/ zig/ c/ mojo/ go/ python/ fortran/
│                 (+ _precedence.py — shared paren-aware emit)
├── llm/          client.py  prompts/  cache/   (typed-hole client, cached)
├── stdlib_maps/  python_to_rust.toml …          (promoted mappings)
├── verify/       rust.py  zig.py  c.py  …       (per-target compile checks)
└── cli/          main.py                         (transpile <src> --target …)

scripts/
├── transpile_matrix.py    transpile a corpus & optionally compile output
├── run_matrix.py          end-to-end: compile + run + diff against Python
└── …

examples/
├── algorithms/            curated cross-target stress test (Python)
├── speed-comparison/      Leibniz-π implementations across languages
├── classes/               Python class → struct lowering
└── samples/               amanmehara/programming (Apache 2.0)
```

## Try it

The project uses `uv` for Python deps, `just` as the task runner, and
`direnv` for shell activation.

```sh
direnv allow             # one-time: auto-activates .venv on `cd`
just setup               # uv sync
just example             # transpile examples/algorithms/fibonacci.py
just test                # 175 tests
just check               # lint + tests
```

Without `direnv`/`just`:

```sh
uv sync
uv run transpile examples/algorithms/fibonacci.py --target rust --verify
uv run pytest
```

### Cross-target matrix

```sh
# End-to-end: compile every output and verify it matches Python's stdout.
uv run python scripts/run_matrix.py examples/algorithms

# Transpile only (faster, supports any corpus dir).
uv run python scripts/transpile_matrix.py examples/samples/Python rust
```

## Capability highlights

- **Precedence-aware emission** (shared across all 7 backends).
  `n * (n + 1) // 2` survives round-trip.
- **Python's print semantics** preserved: `print(True)` → `"True"` (not
  `true`) and `print(12.0)` → `"12.0"` (not `12`) on every target via
  per-target `_pyprint` helpers.
- **List subscript-assign** (`xs[i] = v`) plumbed through HIR/MIR/all
  7 LIRs, including the swap idiom `xs[i], xs[j] = xs[j], xs[i]`.
- **`for`-each and `enumerate`** (`for x in xs`, `for i, x in enumerate(xs)`)
  desugar in HIR→MIR to an indexed `range(len(xs))` loop with a *typed*
  `x = xs[i]` binding — so the loop variable carries the iterable's element
  type even on zero-inference targets (C, Rust). Lights up all 7 backends with
  no per-backend code. Side-effecting / non-name iterables and
  `enumerate(seq, start)` are refused rather than miscompiled.
- **C/Java `cond ? a : b`** lowers to a target-native ternary via a
  shared `__ternary__` builtin — and Python's `a if cond else b`
  conditional expression lowers to the same builtin.
- **Keyword-only params** (`def f(*, a, b)`) are flattened to ordinary
  typed params (the call convention relaxes; the computation is identical).
  `*args` / `**kwargs` are refused rather than silently dropped.
- **Module-level constants** (`NAME: T = <literal>` at module scope) inline
  into function bodies at HIR→MIR, so self-contained numeric modules
  transpile without a const-declaration concept in the IR. Locals shadow
  constants by name.
- **`break` / `continue`** with Fortran rendering them as `exit` /
  `cycle`.
- **Null literal** (`None` / `null` / `NULL` / `nil`) distinct from
  integer 0, so reference comparisons aren't silently miscompiled.
- **List types**: Rust `&Vec<T>` / `&mut Vec<T>`, Go `[]T`, C slice
  struct `{data, len}`, Zig `[]T` slices, Fortran assumed-shape
  arrays + array constructor concatenation, Mojo `List[T]` with
  `mut`/`var` argument conventions.
- **C++ competitive-programming idioms**: `while(t--)` desugar,
  range-for → indexed loop, switch → if/elif chain, `cin >> n` /
  `cout << x` dropped to placeholders.

## Roadmap

Tracked in [GitHub Issues](https://github.com/Tokarzewski/transpilers/issues).
Highlights:

- Dynamic array growth — done for C (realloc-backed growable slices,
  `sieve.py` passes). Still pending: ArrayList in Zig and allocatable
  growth in Fortran to close `sieve.py` on those targets too.
- `OptionT` / `RefT` in the type lattice — currently null literals
  collapse to bare sentinels that may or may not type-check
  downstream.
- Statement-expression sequencing in HIR — would let us lift
  postfix `i++` / `i--` out of expression contexts (currently
  refused on principle rather than silently miscompiled).
