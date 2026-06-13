# PROMPT 2 — Glue the transpiled files (dependency-ordered, oracle-verified)

Run AFTER per-file transpiles (Prompt 1) have produced `out/python/*.py` modules
with stubbed external dependencies. This integrates them into a runnable whole,
bottom-up, verifying each layer against the EnergyPlus oracle before building the
next. Do NOT rewrite the physics — only wire, type, and verify.

## Inputs
- `1_manifest.json` — which files are `✅`/`🟡`/`⬜`.
- `out/python/*.py` — each with a
  `# EXTERNAL DEPS (to wire in glue):` block listing stubbed symbols + C++ origin.
- Oracle C++ `../EnergyPlus/src/EnergyPlus/*.{cc,hh}` for `#include` edges and the
  real `EnergyPlusData` / `state.dataXXX` shapes.
- `scripts/oracle_compare.py` + `scripts/oracle_baselines/*_oracle.csv` for
  full-sim numeric parity (north star #366: within 1%).

## Step 1 — Build the dependency graph
- For every `✅`/`🟡` module, parse its `EXTERNAL DEPS` block and the oracle
  file's `#include "...hh"` edges. Build a directed graph module → deps.
- Topologically sort. Report cycles (EnergyPlus has some) and pick a cut point
  (usually a shared state struct) to break each.

## Step 2 — Stand up the shared state
- Create `out/python/_state.py`: the integration-time
  equivalent of `EnergyPlusData` — a container of the per-module data structs
  (`dataHeatBalance`, `dataSurfaces`, …) the modules expect. Start minimal; grow
  it as each tier is wired. This replaces the per-file stubs.

## Step 3 — Wire bottom-up, ONE tier at a time
Process tiers in order (0 data → 1 pure math → 2 components → 3 managers):
1. Replace each module's stubbed dependency Protocols/placeholders with imports
   of the real transpiled modules and fields on `_state`.
2. Resolve type mismatches faithfully — do not change a formula to make types
   fit; fix the type/wiring.
3. Keep every already-passing per-file test green (run them after each wiring).

## Step 4 — Oracle parity per tier (the gate)
- After wiring a tier, run the closest available oracle comparison
  (`scripts/oracle_compare.py` against the baselines, or a targeted driver that
  feeds a known IDF case through the integrated modules).
- Divergence > 1% → bisect to the responsible module, re-read its oracle `.cc`,
  and fix the WIRING or a transcription error (re-confirm with a standalone g++
  compile if numeric). Never paper over a divergence by tuning a coefficient.
- Only advance to the next tier when the current one matches the oracle.

## Step 5 — Integration ledger
- Maintain `docs/integration_status.md`: per tier, which modules are wired, which
  oracle case passes, and current max % divergence. Update it each tier.

## Constraints
- Glue only: no new physics, no re-derivation. If a module is wrong, the fix is
  in that module (re-port from oracle), not in the glue.
- Small PRs: one tier (or one strongly-connected component) per PR, each with its
  oracle-parity evidence. Branch `glue/tier-N` or `glue/<component>`.
- Stop at the first tier that cannot reach <1% oracle parity; report the blocking
  module(s) rather than forcing it.
