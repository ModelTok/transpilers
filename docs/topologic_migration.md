# Migrating github.com/wassimj/Topologic (issue #79)

Topologic is a real-world CAD/geometry-kernel C++ library built on
OpenCASCADE (OCCT). It's a useful, demanding stress test for the strict
engine: multi-file (`.h`/`.cpp` split), a large third-party dependency, and
real class hierarchies.

## What was blocking it, and what's fixed

1. **Multi-file projects weren't supported at all.** The frontend strips
   every `#include` by design (toolchain-free single-file model), so a
   `.cpp` whose class is declared in a separate `.h` failed immediately
   with "use of undeclared identifier". Fixed by
   `frontends/cpp/parser/includes.py::resolve_local_includes` — opt-in via
   `transpile --include-dir/-I` or `transpile-levels --inc`, transitively
   inlining local headers found on the search path (matching by
   findability, not `"..."` vs `<...>` spelling — Topologic itself uses
   `#include <Bitwise.h>` for its own sibling header).

2. **`_project_preamble()` was silently broken.** The extension point for
   injecting domain-specific declarations (`$TRANSPILERS_CPP_PREAMBLE[_FILE]`
   — originally added for EnergyPlus's `Real64`) appended its content
   *after* the user's source instead of before, so anything it declared
   could never actually be used by that code (C++ requires declare-before-
   use). Fixed by reordering; see `docs/occt_preamble.hpp` for a working
   example.

3. **`docs/occt_preamble.hpp`** — a minimal OCCT shim, usable via the fix
   above. Scope: Topologic's `Utilities.h` bundles its `TOPOLOGIC_API`
   export macro together with an unrelated `TopoDS_Shape`-typed helper, so
   *every* file that only wants the macro also inherits an OCCT dependency
   it doesn't otherwise touch. This shim declares just enough
   (`TopoDS_Shape`, `TopAbs_ShapeEnum`) to get past that specific coupling
   — it is not a real OCCT binding and won't get a file whose own logic
   calls deep into the OCCT API (`BRepBuilderAPI_*`, `Geom_*`, `gp_*`, ...)
   to a compiling target; that would need a real Mojo-side OCCT binding,
   which doesn't exist.

4. **Two general (non-Topologic-specific) bugs** these changes surfaced
   once parsing got far enough to reach emission and real compilation
   (validated against the actual Mojo 1.0.0b2 compiler):
   - An unqualified call to a sibling method (`square(x)` inside `cube()`,
     valid C++ via implicit member lookup, including for static methods)
     was emitted as a free function call instead of `self.square(x)` —
     every backend's methods live on a struct, not as free functions.
   - `operator()` (the functor call operator) was missing from the
     operator→dunder table, so it emitted the literal invalid identifier
     `operator()` instead of `__call__`.

5. **`dedupe_overloads` pass (issue #80).** Two C++ overloads differing
   only by signedness (`int` vs `unsigned int`) collapse to the same target
   scalar type, so both emitted a method with an *identical* signature in
   the same struct — a guaranteed duplicate-definition compile error in
   Mojo/Rust/Zig (found via `Bitwise::NOT(int)` / `Bitwise::NOT(unsigned
   int)`). Renamed deterministically after type inference; use
   `--fidelity idiomatic` when verifying such a file, since the rename is
   itself a (intentional) structural-fidelity divergence under the default
   `structural` gate.

6. A stray-comma bug in the Rust backend's struct emission for a class with
   *zero* fields (e.g. a static-method-only utility class like `Bitwise`
   itself) — `struct Empty {\n,\n}` is a syntax error, not just cosmetic.

## Honest current state

With every fix above, `TopologicCore/src/Bitwise.cpp` — a self-contained
utility class with no OCCT-typed *parameters* of its own — transpiles to
Mojo and compiles with the real compiler end-to-end
(`--fidelity idiomatic --verify`).

The rest of `TopologicCore` remains blocked, and will stay blocked without
substantially more investment: every non-trivial class's own logic (not
just an incidental macro-header dependency) constructs and manipulates real
OCCT geometry objects (`TopoDS_Vertex`, `Geom_Surface`, `BRepBuilderAPI_*`,
...) — 111 distinct OCCT headers across the corpus, ~400 uses of
`TopoDS_Shape` alone. Getting those files to a *compiling* Mojo output
would need a real OCCT binding for Mojo (which doesn't exist) or a
purpose-built, much larger opaque-type shim covering real method surfaces
for dozens of OCCT classes — a project on the scale of the engine itself,
not a bug-fixing pass. `transpilers.lift` (the never-refuse C++→Python
engine) already handles this gracefully today by degrading unresolvable
constructs to `# TODO[lift]` stubs, but only targets Python, not Mojo.
