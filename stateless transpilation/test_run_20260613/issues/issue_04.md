# Issue 04 — Retry with backoff + model failover for 4 EOF/validate LLM errors

**Parent:** TEST RUN on ENERGYPLUS — stateless 100% LLM transpilation (mother issue)

## TL;DR
The 4 "Response validation failed: EOF while parsing" errors are transient — the LLM's response was cut off or malformed. Re-run with exponential backoff (already partially in `2_transpile.py:_transient` + `OPENROUTER_RETRIES=4`) and a model failover (cheapest first, escalate to mid-tier on retry).

## Scope
4 files (~8K LOC):
- `third_party/ssc/tcs/csp_solver_mspt_receiver.cpp` (4,138 LOC)
- `third_party/ssc/tcs/thermocline_tes.cpp` (810 LOC)
- `tst/EnergyPlus/unit/RefrigeratedCase.unit.cc` (2,789 LOC)
- `tst/EnergyPlus/unit/ZoneHVACEvaporativeCooler.unit.cc` (636 LOC)

## Approach
1. Bump `OPENROUTER_RETRIES` to 6 (currently 4) for these specific files.
2. Model failover chain: deepseek-v4-flash → claude-3.5-haiku → claude-3.5-sonnet.
3. The first 2 retries use the same model with temperature 0.0; the 3rd-4th use temperature 0.3 to escape the failure mode; the 5th-6th use the next model in the chain.
4. The existing `_transient` detection (matches 429/5xx/rate-limit/timeout) doesn't match EOF/validate. Add a new pattern: `EOF while parsing` and `Response validation failed`.

## Files
- `stateless transpilation/2_transpile.py:_transient` — extend the regex list.
- `stateless transpilation/2_transpile.py:call_openrouter` — add a model chain via a new `--model-chain` arg.

## Acceptance
- 3+ of the 4 files transpile successfully within 6 retries.
- Cost: <$0.20 (tiny files, mostly retries at the cheap tier).
