# Related projects

## `Tokarzewski/energyplus-mojo`

A sister project: a reimplementation of NREL's EnergyPlus building-energy
simulator in Python + Mojo. It includes a specialized **C++ → Mojo**
transpiler (~2,900 LOC) at `scripts/_transpile_cpp_to_mojo/` targeting
kernel-style numerical code.

**Why it matters for this repo.** Two different design points coexist:

|             | `transpilers` (this repo)                                | `energyplus-mojo`'s transpiler                |
|-------------|----------------------------------------------------------|-----------------------------------------------|
| Scope       | Many-to-many — eleven source × seven target languages    | C++ → Mojo only                                |
| Architecture| HIR → MIR → LIR → target (multi-tier IR, source-agnostic) | Direct libclang AST → Mojo emission           |
| Type cover  | Subset, growing per corpus runs                          | Full C++ kernel surface (size_t, std::string, templates, refs, default args, raw strings) |
| LLM passes  | Type-hole inference + variable rename                    | LLM-authored emitter functions per node kind  |
| Target use  | Cross-language demos, corpus stress-testing              | Industrial C++ → Mojo for real EnergyPlus kernels |

**Knowledge ported here from the sister project:**
- Expanded `CPP_TYPE_ALIASES` in `src/transpilers/frontends/cpp/parser.py`
  with stdint variants, `size_t`/`ptrdiff_t`, full `std::string` /
  `string_view` family, and `char *` / `const char *` mappings — drawn
  from their `_BUILTIN_MAP` in `_transpile_cpp_to_mojo/types_render.py`.

**Not ported** (different architecture, would require major refactor):
- The whole `emit_exprs.py` / `emit_decls.py` / `emit_funcs.py` /
  `emit_stmts.py` directory — direct-emission style assumes no IR layer,
  conflicts with our HIR/MIR/LIR pipeline.
- The C++ operator-overloading → Mojo dunder map (`names.py`) — useful
  when we add C++ class operator-overload support; not yet needed.

**Where to go for richer C++ → Mojo coverage:** if you have a real
C++ codebase that needs production-quality Mojo output (templates,
operator overloads, `std::move`, references, ADL), the sister project's
emitter is the better fit. Our pipeline trades depth on any single pair
for breadth across the matrix.
