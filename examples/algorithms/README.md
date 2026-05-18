# Classic algorithms corpus

Hand-curated Python implementations of canonical algorithms — used as a
cross-target stress test. Each file is intentionally simple: explicit
types, basic control flow, no dependencies. The goal is to test how
well the pipeline carries algorithmic structure across all seven
targets, not to push language-specific features.

```sh
# Single target
uv run transpile examples/algorithms/fibonacci.py --target mojo --verify

# Full matrix across all targets
for target in rust zig c go mojo python fortran; do
    uv run python scripts/transpile_matrix.py examples/algorithms "$target"
done
```

| File | Pattern |
|------|---------|
| `fibonacci.py` | recursion + iteration (interprocedural inference exercise) |
| `fizzbuzz.py` | branching + boolean composition |
| `is_prime.py` | nested loops with early return |
| `gcd.py` | Euclid's algorithm — destructive while loop |
| `binary_search.py` | list parameter, subscript, integer division (`//`) |
| `sum_list.py` | accumulator pattern over a list |
