# Issue 03 — Deterministic + 1-shot LLM repair for 10 "compile" failures

**Parent:** TEST RUN on ENERGYPLUS — stateless 100% LLM transpilation (mother issue)

## TL;DR
The 10 files where the LLM produced a valid `<<<FILE>>>` block but the resulting Mojo doesn't compile need a deterministic first pass (`mojo_repair.py` rules) followed by a 1-shot LLM fix-on-stderr. All 10 are small, so the retry should be cheap.

## Scope
10 files, 25K LOC total. From `ep_full_config.json`:
- 9 in `tst/EnergyPlus/unit/` (.unit.mojo files for AirTerminalSingleDuctMixer, CurveManager, EconomicTariff, HVACHXAssistedCoolingCoil, HeatBalanceManager, ResultsFramework, SQLite, VAVDefMinMaxFlow, WaterThermalTanks)
- 1 in `third_party/ssc/tcs/sam_mw_gen_Type260.mojo`

## Approach
1. For each file, run the existing `mojo_repair.py` rules (math imports, `.size()`→`len()`, `Self.T` qualification, `raises` keyword). The file may already be fixable at this stage.
2. If still failing, build a 1-shot prompt: `Fix this Mojo file. The Mojo compiler reported these errors:\n<stderr>\n\nHere is the file:\n<code>`. Send to cloud model. Cap at 2 retries per file.
3. Verify by re-running `mojo build --emit llvm`. Mark `decision = done` only on success.

## Files
- `scripts/sft/mojo_repair.py` — has 4 rules already. Extend with Mojo 1.0-specific ones (e.g. `from "X" import` → `from X import`, drop empty imports).
- `scripts/sft/diff_verify_ep.py:verify()` — the mojo_compile helper to reuse for the gate.

## Acceptance
- 7+ of the 10 files compile after the deterministic + 1-shot LLM pass.
- Cost: <$0.50 (cheap cloud model + small files).
