# TRANSPILE PROMPT (one-shot, stateless — used by 2_transpile.py)

Single completion per file. No tools, no git, no tests, no self-verification —
this model does ONE job: produce TWO faithful ports of the file. A different
model reviews them (4_review.py); a deterministic pass checks they
import/compile. Placeholders `{FILE}`, `{LANG}`, `{CC}`, `{HH}` are filled by
the driver. `{LANG}` is `cpp` or `fortran`.

---

You convert one EnergyPlus {LANG} translation unit into TWO complete, parallel
ports of the SAME file:
  1. a full Python port, and
  2. a full Mojo port.

Both must port EVERY function, subroutine, class, struct, enum, type, COMMON
block, and constant in the file — complete 1:1 translations, not subsets. The
Mojo port is NOT just hot-path kernels; it is the entire file rewritten in Mojo.
Output ONLY the two file blocks in the exact marker format below. Do not explain.
Do not write tests. Do not use tools.

## Source ({LANG}): {FILE}

```
{HH}
{CC}
```

## Rules — faithfulness (applies to BOTH ports)
- Port EVERY symbol: same formulas, coefficient values, branch structure,
  evaluation/Horner order. No inventing, approximating, or "improving".
- Look-alike sub-expressions across sibling routines are often NOT identical —
  transcribe each verbatim.
- Reproduce upstream quirks (off-by-one, odd guards) even if they look buggy.
- The Python and Mojo ports must be behaviorally identical to each other and to
  the source (same numeric results).
- Reserved-word collisions: if a source identifier (function, method, variable,
  field, enum) is a keyword in the target language, append a single underscore
  (`lambda` -> `lambda_`, `global` -> `global_`, `def` -> `def_`) and use that
  renamed form CONSISTENTLY at every site in that port. Python keywords include
  `lambda def class global from import return None True False async await`; Mojo
  keywords include `fn struct trait var let ref owned`. This is the ONE allowed
  rename — behavior is unchanged; do not rename anything else.

### If C++
- Array indexing base: ObjexxFCL `()` is 1-based, `[]` is 0-based — EnergyPlus
  mixes them per function. Translate to 0-based Python/Mojo correctly.
- Preserve `std::fmod` sign, round-half-away (`nint`), magic fallback values,
  range guards/clamps.

### If Fortran
- Fortran arrays are 1-based and column-major; DO loops are inclusive of the
  upper bound. Translate indices to 0-based Python/Mojo without changing which
  element is read. Preserve `MOD`/`SIGN`/`NINT`/`AINT` semantics exactly.
- `IMPLICIT` typing: infer the real type of every implicitly-typed variable.
- `COMMON`/`MODULE` shared state and `SAVE` variables become explicit parameters
  or a passed state object — never a global (see isolation). Translate `GOTO`
  faithfully into structured control flow with identical behavior. Handle
  fixed-form continuation and `DATA` initializers.

## Rules — isolation (applies to BOTH ports)
- Do NOT import other transpiled modules. For any cross-module symbol, shared
  state (`EnergyPlusData`/`state.dataXXX`, Fortran COMMON/MODULE), take it as an
  explicit typed parameter (Python: a `Protocol`/dataclass; Mojo: a
  struct/trait), never a global. List every such stub in a top-of-file
  `# EXTERNAL DEPS (to wire in glue):` block (same list in both files), with its
  source origin.

## Rules — Mojo specifics
- Idiomatic Mojo: `struct` for structs/derived types, `fn`/`def`, `@export` only
  where a C-ABI entry is genuinely needed. Faithful, complete — the whole file.
- `InlineArray[T, N](fill=...)` is the only valid array literal init; use an
  if-chain helper for constant tables. Factor long iterative loops into
  `@always_inline` helpers. Import math as `from math import ...`.

## Output format (emit BOTH blocks, complete)
<<<FILE out/python/{FILE}.py>>>
...full faithful Python port of the ENTIRE file...
<<<END>>>
<<<FILE out/mojo/{snake_file}.mojo>>>
...full faithful Mojo port of the ENTIRE file...
<<<END>>>
