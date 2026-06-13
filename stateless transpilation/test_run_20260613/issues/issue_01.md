# Issue 01 — Chunked transpile (levels.object) for 80 large "no FILE block" failures

**Parent:** TEST RUN on ENERGYPLUS — stateless 100% LLM transpilation (mother issue)

## TL;DR
Re-run the 80 files that failed with `error: no FILE block` and are between 2K and 70K LOC by chunking them into top-level C++ objects (classes, functions, structs) and transpiling each object independently. The LLM still does all the work; we just feed it smaller prompts. Reuses `src/transpilers/levels.py`'s libclang-based splitter; no algorithmic typing.

## Scope
- 73 files 2K-10K LOC + 7 files >10K LOC = 80 files
- ~450,000 LOC of C++ source
- All in `tst/EnergyPlus/unit/` (huge .unit.cc files) and `third_party/ssc/tcs/` (csp_solver_*)

## Approach
1. Use `transpile-levels --level object --name None` on each failing file → list of C++ objects.
2. For each object: build a prompt (object source + minimal context), call LLM, extract `<<<FILE ...>>> ... <<<END>>>` block, write to the corresponding Mojo region.
3. Stitch the per-object Mojo outputs into a single file at the original target path.
4. Run `mojo build --emit llvm` as a smoke check; gate-keep the result on parse success.
5. Mark `decision = done` only when stitched file compiles.

## Files
- `src/transpilers/levels.py` — `extract_objects` already uses libclang; just needs the `levels.object` driver wired into a new sub-script.
- `src/transpilers/cli/main.py:transpile_cpp_to_mojo` — the underlying transpile function, callable per object.

## Acceptance
- 60+ of the 80 files now produce a parseable Mojo file (gate: `mojo build --emit llvm` returns 0).
- Token spend for this batch: ~$1.5–$70 (cheap–expensive) — see `02_token_accounting.json`.

## Out of scope
- The 2 1M-token SSC files (issue 02).
- The 330 small noFB files (covered by issue 06/07 / general retry).
- Mojo 1.0 package layout (issue 05).
