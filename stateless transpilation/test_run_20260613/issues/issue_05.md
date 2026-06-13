# Issue 05 — Mojo 1.0 package layout: re-layout so 2,400 .mojo files compile (the big one)

**Parent:** TEST RUN on ENERGYPLUS — stateless 100% LLM transpilation (mother issue)

## TL;DR
The 2,400 transpiled `.mojo` files compile at 0/50 because the LLM transpiler wrote them assuming Python-style `from X.Y.Z import` semantics. Mojo 1.0 uses a strict package system: each directory with `.mojo` files needs an `__init__.mojo`, the file's directory is the package root, and imports must use relative dots. This needs a one-shot tree rewrite (~2,400 files), not per-file edits.

## Scope
- 2,400 `.mojo` files in `/home/bart/Github/EnergyPlus-Mojo/`
- 181 directories need `__init__.mojo` (already done in v2 of auto_repair, then removed; needs to be done with correct placement)
- 9,511 `from "X/Y" import` already converted to `from X.Y import` (auto_repair v1); these are still wrong in Mojo 1.0 (no such module), need relative-dot form
- The C++ `#include` graph in `/home/bart/Github/EnergyPlus/src/EnergyPlus/**.hh` is the ground truth for who-uses-whom.

## Approach
1. **Build the include graph** from the C++ oracle: parse every `*.hh` and `*.cc` under `src/EnergyPlus/` for `#include "X.hh"` edges. (`src/transpilers/graph/code_graph.py` already does this for code_graph purposes; reuse it.)
2. **Build the file→C++-object graph** for each transpiled .mojo file. Each `from "X" import Y` (or the converted `from X.Y import Z`) maps to a specific C++ file. Group by which transpiled .mojo file came from which .cc source.
3. **Determine the package root**. The natural choice is `src/EnergyPlus/`. Subdirectories like `Coils/`, `Plant/`, `GroundTemperatureModeling/` are subpackages.
4. **Write `__init__.mojo` files** at:
   - `src/EnergyPlus/__init__.mojo` (top-level package)
   - `src/EnergyPlus/<SubPkg>/__init__.mojo` (subpackages) — but **only one level deep**, not in every dir.
5. **Rewrite every file's imports** to use relative paths:
   - Same dir: `from .X import Y` (sibling)
   - Parent dir: `from ..X import Y`
   - Cousin: `from ..SubPkg.X import Y`
6. **De-duplicate `struct EnergyPlusData`**: the LLM transpiler wrote a `struct EnergyPlusData: pass` in many files. Identify the canonical one (`src/EnergyPlus/Data/EnergyPlusData.mojo`) and remove the duplicates from the others.
7. **Strip C++ leftovers**: `namespace X { }`, `enum class X { }`, raw template syntax, `this->` (use `self.`).
8. **Verify** by running `mojo build --emit llvm` on each file, expecting the pass rate to go from 0/50 to 200+/2400.

## Acceptance
- 80%+ of the 2,400 .mojo files compile under `mojo build --emit llvm` after the re-layout.
- The structure follows Mojo 1.0's package conventions.
- The diff is large but reviewable: one new `__init__.mojo` per package dir, one rewritten import block per file, deletion of redundant struct forward-decls.

## Files
- New script: `tools/mojo1_relayout.py` (in this worktree) or `scripts/sft/mojo1_relayout.py`.
- Reuses: `src/transpilers/graph/code_graph.py` (include-graph parser), `src/transpilers/frontends/cpp/parser.py` (libclang).

## Risk
- The Trash version of `energyplus-mojo` has a different design (Python orchestrator + Mojo hot kernels) that doesn't suffer this. Consider a smaller-scope alternative: keep the C++ 1:1 ports where they compile, and replace the rest with thin Python wrappers that call the canonical Mojo implementations.

## Cost
- 0 LLM tokens — this is a structural rewrite, not a generation.
- ~1-2 days of dev + careful review.
