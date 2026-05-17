# Speed-comparison corpus

Sources copied from [niklas-heer/speed-comparison](https://github.com/niklas-heer/speed-comparison)
(MIT, © Niklas Heer). The upstream LICENSE is preserved as
[`LICENSE.upstream`](LICENSE.upstream).

Each file implements the Leibniz formula for π in a different language —
useful as a cross-language corpus for stress-testing the transpiler
pipeline.

## Current coverage: 0 / 15 of the supported-extension files transpile

This is the honest baseline. Run

```sh
uv run python scripts/transpile_matrix.py examples/speed-comparison rust
```

to reproduce. Every file fails — each on a real subset gap:

| Gap | Files affected |
|-----|---------------|
| `import ...` / `from ... import` | leibniz.py, leibniz_np.py, leibniz_numba.py, leibniz_mypyc.py |
| top-level `program`/`main` statements (not just function defs) | leibniz.go, leibniz.cs, leibniz.js, leibniz.ts, leibniz.f90 |
| C `#include` directives needing the preprocessor | leibniz.c |
| C++ system headers without configured search path | leibniz.cpp, leibniz_avx2.cpp |
| Python `with` statements | leibniz.py, leibniz_mypyc.py |
| Java array types | leibniz.java, leibnizVecOps.java |
| C# `global using` / top-level statements | leibniz.cs, leibniz-simd.cs |
| Go multi-value short-var declarations (`a, b := ...`) | leibniz.go |

These are exactly the constructs to add next if you want the corpus to
transpile end-to-end. The corpus is preserved here so the matrix-run
script can re-measure coverage as features land.
