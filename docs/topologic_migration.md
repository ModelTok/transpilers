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

7. **The Mojo backend now auto-emits a minimal opaque placeholder struct**
   for any foreign type the parser resolved (e.g. via the OCCT preamble
   shim above) but the user's own code never declared — otherwise every
   reference to it in the *emitted* Mojo is "use of unknown declaration",
   even though libclang parsed it fine. Verified working for the realistic
   case of storing/passing an opaque value through without calling methods
   on it directly (a struct field of the foreign type, e.g.).

## Honest current state: 0/51 `TopologicCore` files transpile-and-compile

Every one of the 51 files in `TopologicCore/src/` still fails end-to-end
(`transpile ... --fidelity idiomatic --verify`), even with every fix above
and the OCCT shim. But *why* they fail changed meaningfully, and the
remaining wall is now precisely characterized rather than "everything dies
at parse":

- **~45 files**: still fail at `libclang parse errors` — they transitively
  pull in an OCCT header the shim doesn't cover (only `TopoDS_Shape` /
  `TopAbs_ShapeEnum` are declared; the corpus uses 111 distinct OCCT
  headers, ~400 uses of `TopoDS_Shape` alone).
- **`Bitwise.cpp`**: now parses *completely* (including `Utilities.h`'s
  `OcctShapeComparator`) and reaches real Mojo compilation, failing only on
  `rkOcctShape.TShape().operator->()` — the OCCT shim's `TopoDS_Shape` type
  resolves for parsing, but its placeholder struct has no `TShape()` method
  and `operator->()` has no Mojo/Python equivalent at all (there's no
  transparent-dereference operator to map it to). Getting *this* to compile
  needs per-method stubbing on every opaque OCCT type actually called into,
  not just the type names — a materially bigger, unbounded-looking task
  (every new file can call a new method on a new OCCT type) rather than a
  fixed one, so it's left as future work rather than chased further here.
- **5 files** (`IntAttribute`, `DoubleAttribute`, `ListAttribute`,
  `Geometry`, `Surface`): now get past the OCCT wall entirely and hit a
  *different*, pre-existing, unrelated engine limitation —
  `class member TYPEDEF_DECL` (a nested type alias inside a class body,
  e.g. `typedef std::shared_ptr<IntAttribute> Ptr;`, isn't modeled).

None of this is specific to Topologic in the way it first looked: getting a
real-world OCCT-based C++ project to a *compiling* Mojo target output would
need a real OCCT binding for Mojo (which doesn't exist) or a purpose-built,
much larger opaque-type shim covering real method surfaces for dozens of
OCCT classes — a project on the scale of the engine itself, not a bug-
fixing pass. `transpilers.lift` (the never-refuse C++→Python engine)
already handles this gracefully today by degrading unresolvable constructs
to `# TODO[lift]` stubs, but only targets Python, not Mojo.

## What generalizes beyond Topologic

Everything in this session except the OCCT shim itself is a real, general
engine fix, each validated against the real Mojo 1.0.0b2 / rustc / zig /
gfortran compilers (now installed in dev/CI environments that have them) —
multi-file header resolution, the `_project_preamble()` ordering fix, the
sibling-method-call and copy-constructor bugs, `operator()`, the overload
dedup pass, the Rust empty-struct fix, and the foreign-struct placeholder
all apply to *any* C++ input, not just this corpus.

## Follow-up: a *real* binding for OCCT's `gp` package (issue #79 continued)

Point 3 above notes that `docs/occt_preamble.hpp` only stubs a couple of
opaque OCCT types to get *past* Topologic's coupling to them — it doesn't
attempt to transpile any real OCCT logic. As a narrower follow-on (per
explicit user direction: start with just `gp_Pnt`/`gp_Vec`/`gp_Dir` rather
than the whole inheritance-free `gp` package), this session went further:
`docs/occt_gp_preamble.hpp` targets actually transpiling `gp`'s own real
math logic to Mojo, since `gp` (unlike the rest of OCCT) has no
`Handle(T)`/`Standard_Transient` reference counting and no inheritance —
exactly the strict engine's current C++ subset.

**Current state: `gp_Pnt.cxx` (plus its real transitive `gp`-package
dependencies — gp_XYZ, gp_Vec, gp_Dir, gp_Ax1, gp_Ax2, gp_Trsf, gp_Mat, and
their 2D counterparts, all pulled in by `gp_Pnt.cxx`'s own real `#include`
list) now parses and converts to HIR with *zero* errors, and gets
substantially further into real Mojo compilation than before — but is not
yet a clean `--verify` pass.** Getting there surfaced eight distinct
general engine bugs, none Topologic- or OCCT-specific:

1. **A header-guard corruption bug in `preprocess.py`'s no-clang fallback**
   (`_strip_header_guard`): it tracked stack depth only for `#ifndef`
   opens, but popped on *any* `#endif` regardless of what opened it. A
   real `#ifdef`/`#endif` block nested inside an outer `#ifndef` guard (a
   platform-specific compiler-bug workaround, found in `gp_Mat.hxx`) wrongly
   consumed the outer guard's stack frame, stripping the *inner* `#endif`
   as if it were the guard's closer and leaving the *real* outer `#endif`
   behind as an orphan. libclang's own preprocessor then silently skipped
   every line between the still-open inner `#if` and the next `#endif` it
   could find — potentially thousands of lines, with zero diagnostics,
   silently discarding real class definitions. This took the most
   debugging effort in the session to isolate (compiler agreed the code
   parsed with no errors *and* produced no AST nodes for the missing
   classes — the two facts only made sense once the "silently-skipped
   inactive branch" explanation was found).
2. **`resolve_local_includes` couldn't represent circular textual
   includes** (`gp_Dir.hxx` forward-declares `gp_Ax2d` and only
   `#include`s it at the *bottom* of the file, after its own class body —
   `gp_Ax2d.hxx` does the mirror-image thing for `gp_Dir`). The original
   hoist-dependencies-before-dependents model can't hoist both before each
   other. Rewritten to expand each `#include` strictly in place (matching
   real preprocessor/header-guard semantics: a header's second inclusion
   anywhere is simply dropped) instead of pulling full dependency text to
   the front.
3. **`parse_cpp` relied on clang's default `-ferror-limit=20`**, so a
   large multi-file translation unit could blow past the limit before the
   macro-like-unknown-type retry loop ever saw every distinct macro name,
   or before `_check_diagnostics`'s final error report reflected more than
   an arbitrary prefix of the real problem set. Added `-ferror-limit=0`.
4. **`std::hash<T>`/`std::equal_to<T>` had no primary template
   declared** in the parser preamble, so the near-universal "make my type
   usable as an unordered_map/set key" idiom (`template<> struct
   hash<gp_Pnt> {...}`) failed to parse at all ("explicit specialization of
   undeclared template"). Added primary templates; the specialization
   itself is recognized (by its telltale bare-`TYPE_REF`-as-first-child
   shape, which no ordinary class produces) and skipped rather than
   transpiled — it's STL-interop plumbing for the type above it, not that
   type's own logic, and commonly uses constructs (`union`) outside the
   modeled subset anyway.
5. **`_convert_top_level` never checked `is_definition()` before
   converting a `CLASS_DECL`/`STRUCT_DECL`.** A forward declaration
   (`class gp_XYZ;`, used purely for by-reference/pointer parameters before
   the real definition) got converted into a second, *empty* `HirStruct`
   alongside the real one — every backend then emitted the struct twice, a
   hard "invalid redefinition" compile error, not just a fidelity
   divergence.
6. **The copy/move-constructor collapse fix from the Topologic session
   (`return v;` → plain `v`, not a fabricated `Vec(v, 0)`) only covered
   `_convert_call`'s call-expression path — `_convert_var_decl` (local
   variable declarations, `Vec aCopy = *this;`) has its own, separate
   struct-init detection with the identical bug.** Applied the same fix
   there.
7. **Several class-body/statement shapes had no handling at all**, each
   real and common in value-type-heavy C++, none OCCT-specific:
   `friend class X;` (a pure access-control declaration, safe to drop —
   adds no field/method), a templated *method* on an otherwise-concrete
   class (`template<class T> void GetMat4(T&)` — dropped, since the IR
   doesn't model templates and the struct's other concrete members are
   unaffected), a class-nested `enum class D {...}` (hoisted to the same
   module-level int constants a top-level enum already gets — references
   resolve by bare enumerator name regardless of nesting), an out-of-line
   *constructor* definition (`Class::Class(...) {...}`, previously only
   out-of-line *methods* were attached back to their struct), and a
   compound assignment on an implicitly-`this`-qualified field (`myA *=
   s;` inside a method — only plain `=` was special-cased for a
   `MEMBER_REF_EXPR` LHS, so `*=`/`+=`/etc on a bare field silently
   degraded to a dropped `pass # TODO[port]`).
8. **A `= default`ed special member (`Vec& operator=(const Vec&) =
   default;`) still reports `is_definition() == True` in libclang** despite
   having no explicit body — converting it produced a garbled, bodiless
   method instead of being skipped like any other declared-but-not-defined
   member.
9. **A CALL_EXPR shape unique to overloaded assignment operators**: when a
   field is assigned without explicit `this->` and its type has a
   user-defined (even `=default`ed) `operator=`, C++ desugars `vxdir =
   theV;` to `vxdir.operator=(theV)`, which libclang represents as a
   CALL_EXPR whose *first child is the field being assigned*, not an
   ordinary method receiver. The existing "MEMBER_REF_EXPR callee ⇒ method
   call" branch misread this as `self.vxdir(operator=, theV)` — calling
   the field itself with the operator-name decl-ref as a bogus argument.
   Fixed by recognizing `operator=`/the existing compound-assignment
   overload names up front and desugaring to a plain (or augmented)
   `HirFieldAssign`/`HirAssign`, mirroring the equivalent statement-level
   fix in point 7.
10. **A qualified cross-class static call (`Precision::Angular()`) was
    misdetected as an unqualified same-class self-call.** The Topologic
    session's fix for `square(x)` (implicit `this->` lookup inside another
    method of the same class) checked only whether the callee resolved to
    a `CXX_METHOD` cursor — true for *any* method call libclang can
    resolve, qualified or not. A real cross-class static call got rewritten
    to `self.Angular()`, silently invoking the wrong method (if one of that
    name even exists on self) instead of the real one — a correctness bug,
    not just a compile failure. Fixed by checking the callee's own tokens
    for a `::` (present for a qualified reference, absent for the
    unqualified case the original fix targeted).
11. **Two more operator/mutability bugs in `_method_name` and the Mojo
    backend**, both independent of the parser fixes above:
    `+`/`-` are ambiguous between unary and binary overloads (`operator-()`
    with no explicit params is negation; `operator-(other)` is
    subtraction) — both mapped to `__sub__`, producing a zero-argument
    `__sub__` every target's own arity check rejects. Fixed by checking
    parameter count. Separately, Mojo's `mut self` requirement was only
    detected via a small hardcoded STL-container method-name list; a
    method that mutates self *by calling another user-defined method that
    itself mutates self* (`Multiplied()` calling `self.Multiply(x)` —
    exactly the mutate-in-place/return-a-copy pairing OCCT's `gp_*` types
    use throughout for every arithmetic operation) was left as immutable
    `self`, which the real compiler rejects. Fixed with a module-wide,
    fixed-point closure over method names that mutate their receiver
    (conservative by design: it matches by bare method name, not
    per-struct, so at worst it marks an unrelated same-named method `mut`
    too — harmless, since Mojo permits that).
12. Two Mojo-only copy-insertion gaps, both the same underlying restriction
    (`return`/assign of a bare struct-typed reference needs `.copy()`) just
    missed for **fields** specifically: `return self.field` and `var x =
    self.field` weren't covered because `infer_types` never resolves a
    `MirFieldAccess`'s own type (no struct-field table available to it) —
    the existing check only looked at the pre-resolved `.ty`. Added a
    lowering-time struct-field-type lookup as a fallback, plus a
    `lower_field_assign` override in the Mojo backend (`self.other = ...`
    had no copy-insertion at all — the shared base implementation is
    correct for Rust/Zig, which don't need it, but Mojo does).

**What's left, characterized precisely rather than left as "still
fails":** the remaining `--verify` errors are no longer parser/HIR bugs —
they're two structural gaps of a different kind. First, OCCT declares many
methods in a header (`Standard_EXPORT double Angle(...) const;`) with the
real body living in a *separate* `.cxx` file (`gp_Dir.cxx`) that a
single-entry-point transpile of `gp_Pnt.cxx` never includes — calling into
one of these from an inline method that *is* transpiled correctly reports
"has no attribute". Solving this needs multiple `.cxx` files amalgamated
into one translation unit (the `gp` package as a whole, not one file at a
time), not another parser fix. Second, a qualified static call to a
preamble-stubbed foreign type's method (`Precision::Angular()`,
`gp::Resolution()`) now correctly avoids the wrong self-call rewrite (point
10) but falls through to an unresolved bare-name call instead — resolving
this needs either including that foreign type's real definition in the
output too, or dedicated handling for "call a stubbed type's static
method," neither of which exists yet.
