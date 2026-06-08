# Vendored third-party components

This directory contains code and data copied **verbatim** from third-party
open-source projects. Each component remains under its **original license**
(reproduced alongside it). The repository's own MIT `LICENSE` does **not** apply
to anything under `vendor/`.

Only permissively-licensed (MIT / Apache-2.0) sources are vendored here.
Copyleft projects reviewed during this effort — semgrep (LGPL), Coccinelle
(GPL-2.0), Nuitka (AGPL-3.0) — were studied for design only and **no code was
copied** from them, to avoid imposing their license terms on this repository.

| Component | Upstream | License | Commit | What it is |
|-----------|----------|---------|--------|------------|
| `py2many/` | [adsharma/py2many](https://github.com/adsharma/py2many) | MIT | `37635a96` | Per-target Python-idiom → target-language dispatch/mapping tables (Rust, C++, Go, Zig, Mojo). A reference corpus of stdlib/builtin mappings. |
| `crust/`   | [NishanthSpShetty/crust](https://github.com/NishanthSpShetty/crust) | Apache-2.0 | `3d621dd2` | C/C++ → Rust paired fixtures (`*.cpp` + expected `*.rs`) usable as a transpiler test corpus. |

## Compliance notes

- **MIT (py2many):** the upstream `LICENSE` is reproduced at
  `py2many/LICENSE`; the copyright notice is preserved. Files are unmodified
  except for being renamed `<target>_plugins.py` for clarity.
- **Apache-2.0 (crust):** the upstream `LICENSE` is reproduced at
  `crust/LICENSE`. Files are unmodified. No `NOTICE` file was present upstream.
- Nothing here is modified in substance. If a component is later adapted, note
  the modification here and in that component's `README.md` (Apache-2.0 §4(b)
  requires marking changed files).

## Status

These are vendored as **reference material**, not yet wired into the
HIR→MIR→LIR pipeline. The py2many tables are mapping *knowledge* (Python
lambdas tied to py2many's own AST visitor), not drop-in modules; integrating
them into `stdlib_maps/` is a separate (clean-room) step. The crust fixtures
can be consumed directly by the C++→Rust test harness.
