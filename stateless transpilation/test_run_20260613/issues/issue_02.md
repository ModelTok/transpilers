# Issue 02 — Context-compression or long-ctx endpoint for 2 1M-token SSC files

**Parent:** TEST RUN on ENERGYPLUS — stateless 100% LLM transpilation (mother issue)

## TL;DR
The 2 files that hit `This endpoint's maximum context length is 1048576 tokens` need a path that doesn't try to fit the whole file in context. Two options: (a) chunked transpile (already covered by issue 01), or (b) a long-ctx cloud endpoint that can handle the full file. Pick the cheaper one and finish them. (c) recommended: skip transpilation entirely and replace with a working `coolprop` shim.

## Scope
- `/home/bart/Github/EnergyPlus/third_party/ssc/shared/water_properties.cpp` (79,542 LOC, 1.19M-tok prompt)
- `/home/bart/Github/EnergyPlus/third_party/ssc/shared/CO2_properties.cpp` (70,073 LOC, 1.08M-tok prompt)
- Both are in `third_party/ssc/shared/` and are pure data tables (R245fa, R744 etc.) — likely long but uniform.

## Approach
1. **(a)** Long-ctx endpoint (Gemini-1.5-pro or claude-3.5-sonnet-200k).
2. **(b)** Chunked transpile (issue 01 with object-level splitting — likely ~30-50 functions per file).
3. **(c) Recommended**: `decision: replace` — these are pure data tables; the C++ `Water::xxx` and `CO2::xxx` functions look up values from multi-dimensional tables. A pure-Python implementation using `coolprop` or `pyXSteam` is both smaller and more accurate. The `1_manifest.json` already classifies `ssc/shared` as `decision: replace` — execute that.

## Acceptance
- Either: both files transpiled and Mojo-compilable, **or** (recommended): their `decision` flipped to `replace` and replaced with a working `coolprop` shim.

## Cost
- (a) Gemini-1.5-pro @ ~$1.25/M in, $5/M out for 2.4M total tokens: ~$10
- (b) Cheap dsv4: $2 (split into 50 objects)
- (c) No LLM cost; ~1 day of dev on the coolprop shim.
