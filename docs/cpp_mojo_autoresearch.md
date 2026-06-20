# C++→Mojo transpilation — autoresearch findings (2026-06-20)

Goal: maximize C++→Mojo transpilation quality, measured on **real EnergyPlus**
code (`/home/bart/Github/EnergyPlus`) and the Mojo port (`/home/bart/Github/`).

## Constraints discovered
- **No GPU** in this environment (`torch.cuda.is_available() == False`), so the
  fine-tuned 1.5B model pipeline (`migrate.py`, `adapter_15b_v2`) can't run. All
  work targeted the **deterministic strict engine** (`transpile --target mojo`),
  which proved strong.
- **Mojo toolchain**: `/home/bart/Github/NuMojo/.pixi/envs/default` (1.0.0b1);
  build with `-Xlinker -ldl -Xlinker -lm`.
- The `/home/bart/Github/EnergyPlusMojo` "port" is a live **Python + 125 Mojo
  kernels** simulator (oracle-validated on 607 IDFs, ~47% faster than C++); the
  pure-Mojo scaffold is ~44% stubs. So C++→Mojo feeds kernels/reference; the
  real frontier is non-scalar/stateful physics, not scalars.

## Method
Built `scripts/sft/bench_strict_ep.py`: for each scalar leaf in the migration
plan, extract the real C++ body from the oracle → `transpile --target mojo` →
compile with the live toolchain → numeric-verify vs the C++ reference on sampled
inputs. Reports a stage funnel (extract → transpile → mojo-compile → verify) +
failure taxonomy. GPU-free; reproducible.

## Result
**111/111 verifiable leaves pass (100%)** on real EnergyPlus, up from a 22/27
(first-30) baseline. The 13 `skip_cpp` are out-of-scope for the scalar harness
(need non-scalar types or redefine a shim), not transpiler failures.

## Improvements implemented (all on `main`)
| Fix | Root cause (found empirically) | Where |
|-----|--------------------------------|-------|
| Header indexing + comment stripping in the migration planner | regex only scanned `.cc` and broke on comments → missed 64% of fns | `scripts/sft/migration_plan.py` |
| `from math import` → `from std.math import` | Mojo-1.0 deprecation in the backend | `passes/mir_to_mojo_lir.py` |
| `-Xlinker -lm` in verify gates | `asin`/`acos`/`cbrt` don't link under `-ldl` alone | `diff_verify_ep.py`, `record_replay.py` |
| `std::clamp` support | parser preamble lacked `clamp` → "no member clamp in std"; no lowering | `frontends/cpp/parser/preprocess.py`, `passes/mir_to_mojo_lir.py` |

## Latent issues surfaced (not yet fixed)
- **Silent constant folding to 0**: when a namespaced constant's value isn't in
  the translation unit, the strict engine emits `0` instead of a symbolic ref or
  a refusal — a silent-correctness risk. (Benign in full-context transpilation;
  dangerous for snippet/closure transpilation.)
- The cpp frontend parses with `-nostdinc++`, so **any std function missing from
  `PARSER_PREAMBLE` is a hard parse failure** — preamble completeness is a
  recurring lever (clamp was one instance).

## Ranked next levers (measure with bench_strict_ep.py + a non-scalar harness)
1. **Frontend parse-refusals on member functions / `override`** — biggest
   `transpile_fail` cluster on non-leaf EnergyPlus methods.
2. **Non-scalar tier**: extend the benchmark to `Array1D`/state functions using
   the `Array1D` shims (#66) + record/replay (#65) for unported deps.
3. **Refuse-or-warn instead of silent 0** for unresolved constants.
4. **Psychrometric `Psy*` functions** (5 of the 13 skips) — high-value, need a
   richer shim/reference context.

## Member-function tier (out-of-line `Class::method`) — validated
After adding out-of-line `CXX_METHOD` support (free-function lowering), the 10
real scalar out-of-line member functions in EnergyPlus went **0/10 → 7/10
transpile** (were all crashing on `top-level CXX_METHOD`). The 3 remaining are:
`TermUnitSizingData::applyTermUnitSizing{Cool,Heat}Flow` and
`CollectorData::CalcConvCoeffBetweenPlates` — they read **member fields**
(`this->member`), the next real blocker. (A 4th apparent failure,
`calc_k_taoalpha`, is harness-only: it calls a sibling method; it verifies in
the closure benchmark.)

Next lever (ranked #2): model **member access in extracted methods** — either
map `this->field` to an added parameter, or keep the receiving struct's fields
in scope. Unlocks stateful scalar methods and is the gateway to the Array/state
tier.

## Container tier progress (loop iterations, std::vector subsystem)
The strict engine gained broad std::vector support, raising transpilation-bench
from 10/40 -> 16/40 while real-EnergyPlus regression held (leaf 111/111, closure
7/7 re-verified). Each fix is also a real EnergyPlus capability:
- indexing read+write, const + non-const, nested 2D (operator[] callee filtering)
- 1D + 2D construction: vector<T>(n[, fill]) -> [fill]*n, vector<vector<T>>(m,..) -> [[..]*n]*m
- push_back/emplace_back -> List.append; .size()/.length() -> len()
- compound subscript-assign arr[i] op= v; return-by-value (copy ctor + v.copy())
- std::sort(v.begin(),v.end()) -> sort(v); by-value container params mutated via
  call -> `var` (owned, accepts literal args)

Bench shape now: t1 3/9, t2 9/13, t3 3/13, t4 1/5. Scalar/array done; remaining
gates are other container families.

## Next major lever: std::map / unordered_map -> Mojo Dict
Requires a new DictT IR type plumbed end-to-end (types.py spelling->text, the
text->Type parser, infer_types, the Mojo emitter) + a map shadow with
operator[]/count/find + count/find idioms (m.count(k) -> k in m). Larger than a
single incremental fix; gates frequency_count/two_sum/set_ops/min_stack. After
that: std::tuple multi-return, and graph/struct DP.
