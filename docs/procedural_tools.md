# Procedural and Rule-Based Transpilation Tools: Evaluation

## Overview

This document evaluates existing procedural and rule-based tools for C++ to Python/Mojo transpilation. Most tools were not designed for this purpose, but several provide useful preprocessing, AST manipulation, or structural transformation capabilities.

---

## Tools Evaluated

### 1. CppCheck — Static Analysis

**Purpose**: Static analysis and code quality tool for C/C++  
**Website**: [cppcheck.sourceforge.io](https://cppcheck.sourceforge.io)  
**Role in pipeline**: Pre-processing only

CppCheck is not a transpiler, but it provides value in the pre-transpilation phase:

- **Dead code detection**: Identifies unreachable code before transpilation
- **Type checking**: Flags implicit conversions and undefined behavior
- **Function complexity**: Reports cyclomatic complexity — useful for routing complex functions to frontier LLMs
- **Unused variable elimination**: Reduces noise in generated output

```bash
# Run before transpilation to flag problematic functions
cppcheck --enable=all --xml src/EnergyPlus/ 2> analysis.xml

# Extract high-complexity functions for LLM routing
python scripts/parse_cppcheck.py analysis.xml --complexity-threshold 20
```

**Verdict**: Not directly useful for transpilation. Useful for pre-screening and quality gating.

---

### 2. Tree-sitter — AST Parsing (Already in Use)

**Purpose**: Incremental parsing library for 100+ languages  
**Website**: [tree-sitter.github.io](https://tree-sitter.github.io)  
**Role in pipeline**: Core component — powers the algorithmic transpiler frontend

Tree-sitter is already used in `frontends/` of this project. It provides:

- **Fast, error-tolerant parsing**: Handles partial or malformed C++ gracefully
- **Cross-language support**: Parse C++, Python, Mojo with the same API
- **Concrete Syntax Tree**: Full CST with node types and position information
- **Incremental re-parsing**: Efficient for large repositories (re-parses only changed subtrees)
- **Python bindings**: `tree-sitter` Python package for programmatic access

```python
from tree_sitter import Language, Parser

Language.build_library("build/my-languages.so", ["vendor/tree-sitter-cpp"])
CPP_LANGUAGE = Language("build/my-languages.so", "cpp")

parser = Parser()
parser.set_language(CPP_LANGUAGE)
tree = parser.parse(bytes(source_code, "utf8"))
```

**Current usage**: See `frontends/` directory for tree-sitter-based C++ parsing.

**Verdict**: Essential — already integrated. The algorithmic transpiler is built on top of this.

---

### 3. Comby — Structural Code Rewriting

**Purpose**: Language-aware structural search and replace  
**Website**: [comby.dev](https://comby.dev)  
**Role in pipeline**: Rule-based pattern transformation

Comby uses a template language to match and rewrite code patterns, respecting language structure (not just text):

```bash
# Install
bash <(curl -sL get.comby.dev)

# Rewrite C++ nullptr to Python None
comby 'nullptr' 'None' .cpp

# Transform C++ for loop to Python range
comby 'for (int :[var] = 0; :[var] < :[limit]; :[var]++) { :[body] }' \
      'for :[var] in range(:[limit]):\n    :[body]' \
      .cpp

# Apply a template file
comby -templates cpp-to-python-templates/ src/
```

**Strengths**:
- Language-aware (understands balanced brackets, strings, comments)
- Fast — processes large repos in seconds
- Good for mechanical transformations (syntax sugar, naming conventions)

**Limitations**:
- Cannot handle type inference
- Cannot reason about semantics (only syntax)
- Template maintenance burden grows with codebase complexity

**Verdict**: Useful for systematic mechanical rewrites (e.g., `std::cout` → `print`, `nullptr` → `None`). Can pre-process C++ before LLM translation to reduce token count and errors.

---

### 4. OpenRewrite — Automated Code Refactoring

**Purpose**: Semantic code refactoring framework  
**Website**: [docs.openrewrite.org](https://docs.openrewrite.org)  
**Role in pipeline**: Not applicable

OpenRewrite is designed for Java and Kotlin source trees with first-class support for build system integration (Maven, Gradle). C++ support is experimental and limited.

**Assessment for C++ → Python/Mojo**:
- No production C++ parser in OpenRewrite
- Java-centric data model does not map to C++ semantics
- Would require significant custom recipe development

**Verdict**: Not suitable for C++ transpilation. Skip. Relevant only if the project later targets Java → Python/Mojo.

---

### 5. Clang LibTooling — C++ AST Rewriting via Clang

**Purpose**: Clang's C++ library for building source-to-source transformations  
**Website**: [clang.llvm.org/docs/LibTooling.html](https://clang.llvm.org/docs/LibTooling.html)  
**Role in pipeline**: High-quality C++ preprocessing and AST extraction

Clang LibTooling provides access to the full Clang AST — the most accurate C++ parser available:

```cpp
// Example: Extract all function declarations with their types
class FunctionExtractor : public RecursiveASTVisitor<FunctionExtractor> {
public:
    bool VisitFunctionDecl(FunctionDecl *FD) {
        llvm::outs() << FD->getNameAsString() << " returns "
                     << FD->getReturnType().getAsString() << "\n";
        return true;
    }
};
```

**Python binding (libclang)**:

```python
import clang.cindex as ci

idx = ci.Index.create()
tu = idx.parse("src/HeatBalance.cpp", args=["-std=c++17"])

def visit(node, indent=0):
    if node.kind == ci.CursorKind.FUNCTION_DECL:
        print(f"{'  '*indent}fn {node.spelling}: {node.result_type.spelling}")
    for child in node.get_children():
        visit(child, indent+1)

visit(tu.cursor)
```

**Strengths**:
- Full template resolution — handles SFINAE, concepts, variadic templates
- Accurate type information for all expressions
- Can emit modified AST back to source
- Used in production at scale (LLVM, Chrome, etc.)

**Limitations**:
- Complex setup (requires LLVM build)
- Slow compilation for large projects
- C++ expertise required for custom tools

**Verdict**: High value for extracting type-accurate function signatures and pre-processing complex C++ before LLM translation. Recommend using `libclang` Python bindings to extract function metadata (name, parameter types, return type) and inject this as structured context into LLM prompts.

---

### 6. Emscripten — C++ to WebAssembly/JavaScript

**Purpose**: LLVM-based compiler targeting WebAssembly  
**Website**: [emscripten.org](https://emscripten.org)  
**Role in pipeline**: Reference architecture only

Emscripten demonstrates the LLVM IR approach for cross-language compilation:
1. C++ → LLVM IR (via Clang)
2. LLVM IR → WebAssembly/JS (via Emscripten backend)

This is analogous to our proposed pipeline:
1. C++ → LLVM IR (via Clang)
2. LLVM IR → Mojo (via fine-tuned LLM)

**Verdict**: Not directly useful for Python/Mojo output. Valuable as architectural inspiration for the IR-grounded pipeline (see `docs/llvm_ir_pipeline.md`).

---

### 7. Cython — Python↔C Bridge

**Purpose**: Superset of Python that compiles to C for performance  
**Website**: [cython.org](https://cython.org)  
**Role in pipeline**: Alternative output target (not transpilation)

Cython is a different direction than our goal — it takes Python (with optional C type annotations) and compiles it to C extension modules, rather than converting C++ to Python.

Potential use: If translated Python code needs C-level performance, Cython annotations could be added post-translation:

```python
# Generated Python
def compute_heat(area: float, delta_t: float) -> float:
    return area * delta_t * 0.5

# After Cython annotation (for performance-critical paths)
def compute_heat(double area, double delta_t):  # cython: language_level=3
    cdef double result = area * delta_t * 0.5
    return result
```

**Verdict**: Not useful for transpilation itself. Could be used as a performance optimization layer after generating Python output.

---

## Summary and Recommendation

| Tool | C++ Parsing | Type Accuracy | Setup Effort | Usefulness |
|---|---|---|---|---|
| CppCheck | Partial | Low | Low | Pre-processing only |
| Tree-sitter | Good | None (CST only) | Done | Core — already in use |
| Comby | Structural | None | Low | Mechanical rewrites |
| OpenRewrite | Poor (C++) | N/A | High | Skip |
| Clang LibTooling | Excellent | Full | High | High — type extraction |
| Emscripten | Via LLVM | Full (IR) | Medium | Architecture reference |
| Cython | N/A | N/A | Low | Post-processing only |

### Recommended Stack

**Primary (already in use)**:
- Tree-sitter — algorithmic transpilation of syntactically simple patterns

**Add for production quality**:
- Clang LibTooling (via `libclang` Python bindings) — extract precise type signatures to inject as context into LLM prompts
- Comby — pre-process mechanical C++ patterns (stdlib calls, keyword mapping) before LLM translation

**Pipeline integration**:
```
C++ source
    │
    ├─[Clang LibTooling]──→ Type signatures + function metadata
    │
    ├─[Tree-sitter]──→ Algorithmic transpilation (simple patterns)
    │
    ├─[Comby]──→ Mechanical rewrites (stdlib mapping, keyword replacement)
    │
    └─[LLM]──→ Complex logic translation (with type context injected)
```

---

## References

- [Tree-sitter GitHub](https://github.com/tree-sitter/tree-sitter)
- [libclang Python bindings](https://libclang.readthedocs.io)
- [Comby documentation](https://comby.dev/docs/overview)
- [Clang LibTooling tutorial](https://clang.llvm.org/docs/LibASTMatchersTutorial.html)
- [Emscripten LLVM IR approach](https://emscripten.org/docs/compiling/index.html)
