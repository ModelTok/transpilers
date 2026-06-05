# crust — vendored C/C++ → Rust fixtures

- **Upstream:** https://github.com/NishanthSpShetty/crust
- **Commit:** `3d621dd2b92eb78d8927ad54c63c9f42706ac921`
- **License:** Apache-2.0 (see `LICENSE` in this directory)
- **Vendored:** `testset/` copied unmodified.

## What this is

crust is an Apache-2.0 C/C++ → Rust transpiler (written in Rust). Its
`testset/` is a set of paired fixtures — a C/C++ input (`*.cpp`) and the
expected Rust output (`*.rs`) — covering: `class`, `for`, `func`, `if`,
`main`, `prog`, `struct`, `while` (15 files; a couple inputs lack a paired
`.rs`).

## How it relates to this repo

This repo's C++ frontend (`frontends/cpp/`) targets Rust among others. These
pairs are a ready-made **behavioral/shape corpus** for the C++→Rust path: feed
each `*.cpp` through `transpile_cpp_to_rust` and compare against (or learn
from) the expected `*.rs`. The crust transpiler itself is Rust and is not
vendored — only the language-agnostic fixture data is.

Per Apache-2.0 §4(b): these files are unmodified. Mark any future edits here.
