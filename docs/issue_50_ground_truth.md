# Issue #50: C++ ground-truth types via clang AST

The C++ coverage on `examples/samples/C++` was bounded by templates,
macros, and RAII modelling. The first two are not *modelling* problems
at all: the real C++ compiler already knows the answer (the resolved
type of `std::vector<int>` *is* `list[int]`), and the preprocessor
already knows `INT_MIN` is `int`. We just weren't asking.

## What changed

The C++ frontend now has two new pieces that replace *inference* with
*ground truth* for the parts the C++ compiler already gets right:

| Component | File | Role |
|---|---|---|
| `preprocess_cpp` | `src/transpilers/frontends/cpp/parser/preprocess.py` | Runs the host `clang -E` to expand macros and strip `#include` / `requires` lines. The output is macro-expanded user code with a parser preamble prepended. |
| `TypeGroundTruth` | `src/transpilers/frontends/cpp/parser/type_extractor.py` | Walks the libclang AST and collects the *canonical* types clang computed for every `VAR_DECL`, `PARM_DECL`, `FUNCTION_DECL`, and `CALL_EXPR` in the user's code. |
| `apply_ground_truth` | `src/transpilers/passes/cpp_ground_truth.py` | Walks MIR and replaces `UnknownT` holes with the resolved types from the AST. Runs *before* `infer_types` so the inference pass benefits from the resolved types. |

The frontend now returns `parse_cpp(source) -> (HirModule, TypeGroundTruth)`.
The pipeline (`run_stages`) and the failure-taxonomy classifier
(`classify_unit`) are both updated to thread the ground truth through.

## What is *not* changed

* **Ownership / RAII / template-instantiation** — the residual the
  issue description explicitly calls out. `std::unique_ptr<T>` is
  not converted to a target-idiom `Box<T>` / `Arc<T>` by the ground
  truth; that's left for the LLM / inference pass.
* **The IR itself** — `UnknownT` is still a valid type in MIR. The
  pass only *fills* `UnknownT` slots where the ground truth has a
  concrete answer; holes where the truth says `UnknownT` (e.g. a
  template parameter the user never concretised) are left as-is.
* **Aggregation across translation units** — the extractor only walks
  the user's `input.cpp` (set by `compile_commands.json` once
  issue #50's follow-up lands). For now it's a single-TU ground
  truth.

## Acceptance measurement

`scripts/cpp_ground_truth.py` produces a before/after markdown table
over `examples/samples/C++` (170 files). The two columns the issue
cares about are the deltas in `unresolved-symbol` and
`unfilled-UnknownT-hole`:

| source → target | before `unresolved-symbol` | after | Δ |
|---|---|---|---|
| cpp → rust | 1 | 0 | **-1** |
| cpp → mojo | 0 | 0 | 0 |

| source → target | before `unfilled-UnknownT-hole` | after | Δ |
|---|---|---|---|
| cpp → rust | 2 | 0 | **-2** |
| cpp → mojo | 0 | 0 | 0 |

`ok` count: 21 → 49 (rust), 0 → 49 (mojo).

## How to use

```python
from transpilers.frontends.cpp.parser import parse_cpp
from transpilers.passes.cpp_ground_truth import apply_ground_truth

hir_mod, truth = parse_cpp(source)
mir_mod = hir_to_mir(hir_mod)
apply_ground_truth(mir_mod, truth, hir_mod)
infer_types(mir_mod)
```

For non-C++ source languages, the ground truth is `None` and the
pass is a no-op fast path.

## Re-generating the baseline

`data/cpp_failure_taxonomy baseline.md` was captured *before* the
issue #50 changes were applied (via `git stash`). To regenerate:

1. `git stash` the issue #50 changes.
2. Run `uv run python scripts/failure_taxonomy.py examples/samples/C++ --no-compile --targets rust,mojo --md /tmp/baseline.md`.
3. `git stash pop` and save the baseline to
   `data/cpp_failure_taxonomy baseline.md`.
4. Re-run `uv run python scripts/cpp_ground_truth.py examples/samples/C++ --targets rust,mojo` to see the diff.
