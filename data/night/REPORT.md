# Overnight run — EnergyPlus C++ → Mojo training dataset (2026-06-11)

## Deliverables (ready to train on)

| File | Records | What |
|---|---|---|
| `data/sft/cpp_mojo/train_translation_ep_v3.jsonl` | **43** | New behaviorally-verified EnergyPlus C++→Mojo pairs, Alpaca schema, same instruction/system as `train_translation.jsonl` — drop-in for LLaMA Factory |
| `data/sft/cpp_mojo/train_translation_ep_v3_nocomment.jsonl` | 43 | Same pairs, comment-stripped C++ input (second training view) |
| `data/night/ep_pairs_v3_final_manifest.jsonl` | 43 | Raw pairs with full verification metadata (samples, max_rel_err, coverage, provenance) — **latest-Mojo syntax** |

Both files are registered in `data/sft/cpp_mojo/dataset_info.json` as
`cpp_mojo_translation_ep_v3` and `cpp_mojo_translation_ep_v3_nocomment`.

Every pair passed the same gate as the existing dataset: compile both sides
standalone, run on ~125 sampled inputs, **rel-err ≤ 1e-9 agreement** and **full
computational branch coverage** of the C++ body. Worst max_rel_err across all
43: 7.9e-10. QA: zero schema problems, zero held-out leaks (all 17
`heldout_names.json` functions excluded).

## How the 43 were produced

Three stages, all gated by behavioral verification:

1. **Algorithmic sweep** (`build_cpp_mojo_dataset.py`, recursive over
   `src/EnergyPlus/**`): 154 pure-scalar candidates → 99 verified, of which
   ~26 were never in `train_translation.jsonl` (18 survived dedup).
2. **LLM-translate the transpiler's failures** (new
   `scripts/verify_llm_pairs.py` re-verifies through the same gate): 40
   candidates → 14 verified, incl. dependency-bundled pairs
   (`CalcASHRAETARPNatural`, `CalcEmmelVertical/Roof` bundling their verified
   callees) and `CalcWindSurfaceTheta` (faithfully reproduces the C++
   unqualified-`abs`-truncates-to-int quirk).
3. **New candidate class — reference out-params** (new
   `scripts/night_extract_outparam.py` + `scripts/night_verify_outparam.py`):
   `void f(Real64 x, Real64 &out)` ↔ Mojo `def f(x: Float64, mut out: Float64)`.
   16 candidates → **15 verified** (CLIPLINE, SUN3, CalcFangerPMV-adjacent
   film coeffs, Bessel-adjacent Material.cc indexers...). The harness
   initializes refs to sampled values on both sides and compares every output.

Provenance split of the 43: 18 algorithmic-transpiler outputs, 25
LLM-translated (all re-verified). 21 distinct EnergyPlus source files;
15 pairs exercise mut/out-param semantics — a shape absent from the
existing 1005-record training set.

## Dropped, with reasons (gate discipline, not laziness)

- **62 name-dups / 5 near-twins** of the existing training set, **17 held-out**.
- **6 libm-ULP divergences** (Beausoleil-Morrison ×4, AdjustCBF, pvstar):
  `pow`/`exp` differ between glibc and Mojo's runtime by ~2e-9 at
  physically-absurd sampled extremes (e.g. T=719 K). Not translation bugs;
  unverifiable to 1e-9 without bit-identical libm.
- **2 dead-defensive-code coverage failures** (CalcFangerPPD's PPD clamps,
  OutdoorDryBulbGrad's `Upper==Lower` branch): mathematically unreachable
  lines — the gate can never certify them.
- **1 whack-a-mole** (CalcIBesselFunc): each sampling fix exposed another
  uncovered error path; abandoned after 3 rounds.
- **19 agent-skipped**: zero-arg class methods reading object state
  (ResultsFramework accessors etc.) — not expressible as self-contained Mojo.
- **13 unresolved-callee skips**: call EnergyPlus functions with no verified
  translation yet (these become candidates as the verified pool grows).

## Domain-restricted sampling (4 pairs)

`calculateDayOfYear`, `isMinuteMultipleOfTimestep`, `GetPhiThetaIndices`,
`film` have C++ **undefined behavior** outside their natural domain
(`% 0`, `array[Month-1]` with Month=0, double→int overflow). They were
verified on domain-restricted samples (still full branch coverage); marked
`"note": "domain-restricted sampling"` in the manifest.

## Notes for the DiffusionGemma fine-tune (issue #59)

- Records use the standard Alpaca columns — Unsloth/LLaMA Factory both accept
  them directly; mix `cpp_mojo_translation_ep_v3` with the existing
  `cpp_mojo_translation` dataset.
- **Mojo follows the latest syntax** per Modular's official
  [`modular/skills`](https://github.com/modular/skills) `mojo-syntax` agent
  skill (cloned at `data/night/modular-skills/`): stdlib imports use the
  `std.` prefix (`from std.math import exp`), prelude functions
  (`pow`/`abs`/`min`/`max`) are used without imports, list literals (never the
  `List[T](...)` ctor), `mut` argument convention, `def` (not `fn`), no
  `alias`/`let`/`inout` anywhere. All 43 pairs were **re-verified through the
  behavioral gate after the syntax migration** (43/43 pass; `std.math` imports
  compile clean on Mojo 1.0.0b1, no deprecation warnings).
  NOTE: the existing 1005-record `train_translation.jsonl` still uses the old
  `from math import …` style — migrating it the same way (mechanical rewrite +
  re-verify of the C++ pairs via `scripts/verify_llm_pairs.py`) is a
  recommended follow-up so the model sees one consistent convention.
- Verification toolchain: Mojo 1.0.0b1 (energyplus-mojo pixi env, WSL
  `Ubuntu`, user `amd`), g++ 15.2, EnergyPlus source at `~/EnergyPlus`.

## Repo hygiene

- `scripts/build_cpp_mojo_dataset.py` is untouched (its `/home/bart` paths
  are overridden via monkey-patching from the night scripts; set
  `TRANSPILERS_EPMOJO` env var).
- New reusable scripts: `verify_llm_pairs.py`,
  `night_extract_outparam.py`, `night_verify_outparam.py`,
  `night_prep_llm.py`, `night_assemble.py`, `night_strip_variant.py`,
  `night_qa.py` (+ one-off `night_*` debug/rescue helpers).
- Intermediate artifacts: `data/night/` (Windows) and WSL `~/night/`.
- Nothing committed — working tree only.
