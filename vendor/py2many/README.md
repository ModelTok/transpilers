# py2many — vendored mapping tables

- **Upstream:** https://github.com/adsharma/py2many
- **Commit:** `37635a96b8a9f218706421f72f45fe025b18b8f1`
- **License:** MIT (see `LICENSE` in this directory)
- **Vendored:** unmodified except filenames (`<target>/plugins.py` →
  `plugins/<target>_plugins.py`).

## What this is

py2many is a mature MIT-licensed Python→many-languages transpiler. Each target
backend ships a `plugins.py` carrying the distilled **mapping knowledge** of
how a Python builtin/stdlib idiom renders in that language:

- `SMALL_DISPATCH_MAP` — one-liner builtins (`len`, `enumerate`, `sum`, `map`,
  `filter`, `int`/`float` casts, …) as lambdas producing target source.
- `DISPATCH_MAP` — richer builtins needing a method (`range`, `min`/`max`,
  `print`).
- `MODULE_DISPATCH_TABLE`, `FUNC_USINGS_MAP`, `CLASS_DISPATCH_TABLE` — module
  imports, required `use`/`import` lines, and class-level rewrites.

Targets vendored here that overlap this repo's backends:
`pyrs_plugins.py` (Rust), `pycpp_plugins.py` (C++), `pygo_plugins.py` (Go),
`pyzig_plugins.py` (Zig), `pymojo_plugins.py` (Mojo).

## How it relates to this repo

These tables are tied to py2many's own `ast`-visitor architecture (the lambdas
take py2many node/vargs), so they are **not** drop-in modules for the
HIR→MIR→LIR pipeline. They are a *reference* for enriching `stdlib_maps/`:
the Rust column of `pyrs_plugins.py` (e.g. `len(x)` → `x.len() as i32`,
`enumerate(x)` → `x.iter().enumerate()`) is exactly the kind of mapping the
`python_to_rust.toml`-style data is meant to capture. Re-expressing them as
this repo's data is a clean-room step, kept separate from this verbatim copy.
