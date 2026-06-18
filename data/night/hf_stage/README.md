---
license: bsd-3-clause
task_categories:
  - text-generation
  - translation
language:
  - en
tags:
  - code
  - mojo
  - cpp
  - transpilation
  - energyplus
  - code-translation
pretty_name: EnergyPlus C++ → Mojo (behaviorally verified)
size_categories:
  - n<1K
configs:
  - config_name: default
    data_files:
      - split: train
        path: train_translation_ep_v3.jsonl
  - config_name: nocomment
    data_files:
      - split: train
        path: train_translation_ep_v3_nocomment.jsonl
---

# EnergyPlus C++ → Mojo translation pairs (behaviorally verified)

43 C++→Mojo function-translation pairs mined from the
[NREL EnergyPlus](https://github.com/NREL/EnergyPlus) building-simulation
engine, each one **verified by construction**: the C++ original and the Mojo
translation are compiled standalone, run on ~125 sampled inputs, and accepted
only if every output agrees to **relative error ≤ 1e-9** with **full
computational branch coverage** of the C++ body (gcov-gated). Worst max
relative error across the set: 7.9e-10.

The Mojo follows the **latest Mojo syntax**, validated against Modular's
official [`modular/skills`](https://github.com/modular/skills) `mojo-syntax`
agent skill: `std.`-prefixed imports (`from std.math import exp`), prelude
`pow`/`abs`/`min`/`max` without imports, `def`-only functions, `mut` argument
convention, list literals. All pairs were re-verified through the behavioral
gate *after* syntax migration.

## Configs

| Config | Records | Description |
|---|---|---|
| `default` | 43 | C++ with original comments in the instruction |
| `nocomment` | 43 | Same pairs, comment-stripped C++ (second training view) |

## Schema (Alpaca / LLaMA-Factory compatible)

```json
{
  "instruction": "Transpile the provided C++ implementation into a functionally equivalent implementation in Mojo.\n\n```cpp\n<C++ function>\n```",
  "input": "",
  "system": "<Mojo transpiler system prompt>",
  "output": "```mojo\n<Mojo function>\n```"
}
```

## What's in the pairs

- **28 scalar functions** (`Real64/int/bool f(scalars...)`) — convection
  correlations, psychrometrics, date/solar utilities, window optics.
- **15 functions with reference out-params** — C++ `Real64 &x` ↔ Mojo
  `mut x: Float64` (geometry clipping, solar position Fourier series, film
  coefficients, lookup-grid indexers). A shape most code-translation sets lack.
- Several pairs encode **semantic traps**: C++ unqualified `abs(double)`
  resolving to integer `abs` (truncation faithfully reproduced), `std::fmod`
  emulation (no `fmod` in Mojo's stdlib), C++ truncated vs Mojo floored
  integer division, dependency-bundled multi-function units.

## Provenance & verification

- 18 pairs: algorithmic transpiler output ([transpilers](https://github.com/Tokarzewski/transpilers) project), behaviorally verified.
- 25 pairs: LLM-translated, then verified through the **same** gate — provenance differs, fidelity doesn't.
- 4 pairs used domain-restricted sampling because the C++ has undefined
  behavior outside its natural domain (`% 0`, out-of-range array indexing);
  marked in the manifest.
- 21 distinct EnergyPlus source files; zero overlap with the project's
  held-out evaluation set.

`ep_pairs_v3_final_manifest.jsonl` carries per-pair metadata: source file,
provenance, verification method, sample counts, max relative error, branch
coverage.

## Licensing

The C++ functions originate from EnergyPlus, © U.S. Department of Energy /
NREL, released under a BSD-3-Clause-style license. Mojo translations are
machine-generated derivative works distributed under the same terms.

## Intended use

Fine-tuning code models (e.g. DiffusionGemma, Qwen-Coder) for C++→Mojo
transpilation. Mix with a Mojo-acquisition corpus when the base model has not
seen Mojo.
