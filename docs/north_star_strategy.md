# North-star — bootstrap the verified Mojo ecosystem

Strategy for issue #56. "Winning" = making **real codebases migratable to Mojo**.
Software is ~95% dependencies, so this is **not** "translate a file" — it is
**bootstrapping the verified Mojo package ecosystem**. The transpiler is the
*factory*; the **verified Mojo registry is the moat** (network effects + lock-in
— `crates.io` for a novel language, built by automation instead of years of
hand-ports).

## Primary metric — dependency-closure coverage

For a target codebase: the **% of its import/link dependency closure that
resolves to a verified Mojo package** (transpiled-native *or* interop-wrapped).

> *"Can this app run on Mojo, and how much of its closure resolved?"*

Everything below is instrumented against this single number. It subsumes
compile-rate (a file can compile and be wrong) and pass@1 (a function can pass
and its callees not exist) — closure coverage only counts a dependency *resolved*
when it is **verified** and its own closure resolves.

## Three reinforcing tracks — do all, instrument each, let data pick the emphasis

### 1. Ecosystem (the moat) — mass-produce a verified Mojo registry
- **Two tiers:** *wrap* (Mojo↔Python/C FFI — instant breadth, deps resolve
  day-1, no perf gain) + *transpile-native* (pure Mojo, perf, expensive).
- **Prioritize by dependents** — rank packages by how many things depend on them
  (the ecosystem analog of inbound-`#include` ranking; the directed-graph
  foundation from #64/#67/#68 already computes fan-in).
- Run **ecosystem-wide** (top-N PyPI / most-used C++ libs) **and**
  **own-closure-first** (the deps `energyplus-mojo` + ModelTok actually need) in
  parallel; measure which yields usable coverage faster.
- Instrument: `data/mojo_ecosystem_coverage.{json,md}`, `data/ecosystem_map.py`.

### 2. Engine (factory quality) — best automated *source → verified Mojo*
- **Beat frontier LLMs on verified Mojo pass-rate.** Mojo's training-data scarcity
  is the moat; a model fine-tuned on *verified* pairs + a compile/behavior gate
  wins where general models are weakest. This is also the marketing proof (#55).
- **Flywheel:** transpile → verify → add pairs → retrain (3B→7B cloud). One
  emitter fix unblocks many files. Assets: `scripts/sft/flywheel_run.py`,
  `flywheel_metrics.py`, `promote_repair.py`, and the new #57 generator that
  mints verified pairs with no compiler in the loop.

### 3. Performance (the reason to go native) — native Mojo must beat the source
- Wrapping gives coverage but **no speed**; going native is only justified if the
  Mojo is **faster** than the original. Measure native-vs-source on real
  benchmarks (`examples/speed-comparison`, the EnergyPlus kernels) and **gate
  "native" spend on the perf win**. Until a package shows a win, wrap it.

## "Do everything and measure" — the per-direction scoreboard

Pursue wrap + transpile-native, ecosystem-wide + own-closure, **in parallel**.
Instrument each and let the scoreboard decide where to lean — no premature
commitment to coverage-vs-perf or wide-vs-narrow.

| direction | metric | where it lives |
|-----------|--------|----------------|
| closure coverage gained | % of a target's closure now verified-Mojo | per-target report (build) |
| verified pass-rate | compile + behavior match % | `eval_transbench.py`, `behavioral.py` (#48) |
| perf delta | native-Mojo vs source runtime | `examples/speed-comparison`, EP kernels |
| human-hours saved / KLOC | analyst time vs auto-migrate | flywheel + sweep logs |

## How the existing pieces ladder up to closure coverage

The dependency-closure epic (#64) already attacks the two coupled sub-problems
that gate coverage on real code:

- **Verify-closure** (a callee must produce real values to confirm a caller) →
  decoupled by record/replay (#65) so correctness never waits on porting order.
- **Compile-closure** (every referenced symbol/type must exist) → a build-ordering
  chore solved by the shim library (#66), SCC/cycle breaking (#67), fan-in
  ordering (#68), and god-object vertical slicing (#69).

Top-down defines the seams (runtime path, god-object slice, trait boundaries);
bottom-up fills and verifies leaves along that path; the C++ numeric oracle
(`/home/bart/Github/EnergyPlus/`) guarantees correctness at every step.

## Sequencing (own-closure first, instrument from day 1)

1. **Stand up the closure-coverage metric** on one real target (EnergyPlus C++
   or a top-10 PyPI package's closure). A number, even if low, beats none.
2. **Wrap the high-fan-in deps** of that target → instant coverage; record the %.
3. **Transpile-native only where perf is the point** (profiled hot leaves) →
   record the perf delta; promote verified pairs into the SFT flywheel.
4. **Retrain (cloud) → re-measure pass-rate → re-measure coverage.** Repeat.
5. **Publish the scoreboard** — coverage %, pass@1 vs frontier, perf delta — as
   both the internal compass and the external proof (#55).

## What would prove the north-star

A real application whose dependency closure resolves to **verified** Mojo above a
threshold (e.g. ≥80%), running on Mojo, with the resolved-native fraction
demonstrably faster than the source. The registry that made it possible is the
moat; the transpiler that filled it is the factory.
