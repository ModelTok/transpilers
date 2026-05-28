# Multi-LLM Pipeline: Specialised Models per Translation Stage

## Overview

Rather than routing every function to a single expensive model, the multi-LLM pipeline decomposes translation into five stages and assigns the cheapest capable component to each stage. The goal is that >90% of work is handled by free or near-free steps, with frontier model calls reserved for the <10% that genuinely requires them.

---

## Pipeline Architecture

```
C++ function
     │
     ▼
┌─────────────┐
│  Stage 1    │  Tree-sitter parse → typed AST
│  PARSE      │  Algorithmic, free
└─────┬───────┘
      │
      ▼
┌─────────────┐
│  Stage 2    │  Walk AST → resolve types
│  TYPE       │  Algorithmic first; LLM for UnknownT holes
│  INFERENCE  │
└─────┬───────┘
      │
      ▼
┌─────────────┐
│  Stage 3    │  Map C++ stdlib → target stdlib
│  STDLIB     │  Lookup table (Zim RAG); LLM fallback
│  MAPPING    │
└─────┬───────┘
      │
      ▼
┌─────────────┐
│  Stage 4    │  Emit target code
│  EMIT       │  Small fine-tuned 7B for boilerplate
│             │  Large model for complex logic
└─────┬───────┘
      │
      ▼
┌─────────────┐
│  Stage 5    │  Compile / type-check generated code
│  REPAIR     │  Claude for error interpretation
│             │  Small model for code fixing
└─────┬───────┘
      │
      ▼
 Final output
```

---

## Stage 1: Parse — Tree-sitter (Free)

**Component**: Tree-sitter (already in `frontends/`)  
**Cost**: $0  
**Coverage**: 100% of input

Tree-sitter produces a Concrete Syntax Tree (CST) from C++ source. The algorithmic transpiler then converts the CST into a typed AST representation used by later stages.

```python
# frontends/cpp_frontend.py (existing)
def parse_cpp(source: str) -> ASTNode:
    tree = cpp_parser.parse(bytes(source, "utf8"))
    return build_ast(tree.root_node)
```

**Output**: Typed AST with `UnknownT` nodes where types cannot be resolved algorithmically.

---

## Stage 2: Type Inference — Algorithmic + Claude Fallback

**Primary**: Algorithmic type propagation (free)  
**Fallback**: Claude 3.5 Sonnet for `UnknownT` holes  
**Estimated coverage**: 70% algorithmic, 30% LLM

The type inference stage walks the AST and resolves types using rules:
- Literal expressions → primitive types
- Standard library types → known mappings
- Declared variables → propagate from declaration
- Template parameters → `UnknownT` (flagged for LLM)

```python
# pipeline/type_inference.py

def infer_types(ast: ASTNode, confidence_threshold: float = 0.8) -> ASTNode:
    """Resolve types algorithmically; flag low-confidence nodes for LLM."""
    resolver = AlgorithmicTypeResolver()
    ast = resolver.visit(ast)

    unknown_nodes = ast.find_all(lambda n: n.type == UnknownT or n.confidence < confidence_threshold)

    if unknown_nodes:
        context = extract_type_context(ast, unknown_nodes)
        resolved = claude_resolve_types(context, unknown_nodes)
        ast = ast.apply_resolutions(resolved)

    return ast

def claude_resolve_types(context: str, nodes: list[ASTNode]) -> dict[NodeId, Type]:
    """Ask Claude to resolve specific UnknownT holes in context."""
    prompt = f"""Given this C++ function context:

{context}

Resolve the types for these expressions (output as JSON):
{format_unknown_nodes(nodes)}

Respond with: {{"node_id": "resolved_type", ...}}"""

    response = claude.messages.create(
        model="claude-3-5-sonnet-20241022",
        max_tokens=512,
        messages=[{"role": "user", "content": prompt}],
    )
    return json.loads(response.content[0].text)
```

**Cost**: Only nodes with `UnknownT` or low confidence trigger API calls. Expected: ~$0.002/function average.

---

## Stage 3: Stdlib Mapping — Zim RAG + LLM Fallback

**Primary**: Lookup table from `stdlib_maps/` + Zim documentation RAG (free)  
**Fallback**: LLM for unmapped functions  
**Estimated coverage**: 80% lookup, 20% LLM

C++ standard library calls are mapped to Python/Mojo equivalents:

```python
# stdlib_maps/cpp_to_mojo.py (generated from Zim docs)
CPP_TO_MOJO = {
    "std::vector": "List",
    "std::map": "Dict",
    "std::string": "String",
    "std::abs": "abs",
    "std::sqrt": "math.sqrt",
    "std::min": "min",
    "std::max": "max",
    "std::sort": "sort",
    "std::accumulate": "reduce",
    # ... auto-generated from Zim RAG (issue #16, #22)
}
```

For unmapped functions, query the Zim documentation RAG:

```python
def resolve_stdlib(cpp_call: str, target: str) -> str | None:
    # 1. Check pre-built lookup table
    if cpp_call in CPP_TO_MOJO:
        return CPP_TO_MOJO[cpp_call]

    # 2. Query Zim RAG (D:/zim documentation)
    result = zim_rag.query(
        f"What is the {target} equivalent of C++ {cpp_call}?",
        sources=["mojo-stdlib", "python-stdlib", "cppreference"]
    )
    if result.confidence > 0.8:
        return result.mapping

    # 3. LLM fallback (small model sufficient for stdlib lookup)
    return llm_resolve_stdlib(cpp_call, target, context=result.context)
```

---

## Stage 4: Emit — Fine-Tuned 7B + Large Model Fallback

**Primary**: Qwen2.5-Coder-7B-Instruct (fine-tuned) on RunPod A40  
**Fallback**: Claude 3.5 Sonnet / GPT-4o for complex logic  
**Routing**: Confidence score from Stage 2/3 determines model tier

```python
# pipeline/emit.py

def emit(ast: ASTNode, target: str, context: TranslationContext) -> str:
    complexity = compute_complexity(ast)
    type_confidence = ast.average_type_confidence()

    if complexity < 10 and type_confidence > 0.9:
        # Simple function: fine-tuned 7B handles well
        return emit_with_model(ast, target, model="qwen2.5-coder-7b-finetuned")

    elif complexity < 30 and type_confidence > 0.7:
        # Moderate complexity: 32B open-weight model
        return emit_with_model(ast, target, model="qwen2.5-coder-32b")

    else:
        # High complexity: frontier model
        return emit_with_model(ast, target, model="claude-3-5-sonnet")

def emit_with_model(ast: ASTNode, target: str, model: str) -> str:
    prompt = build_emit_prompt(ast, target)
    return llm_call(model=model, prompt=prompt, temperature=0.1)
```

**Expected routing distribution**:
- Fine-tuned 7B: ~60% of functions (simple arithmetic, data structures)
- 32B open-weight: ~30% of functions (moderate complexity)
- Frontier model: ~10% of functions (templates, complex OOP, novel patterns)

---

## Stage 5: Repair — Claude + Small Model

**Primary**: Claude 3.5 Sonnet for error interpretation  
**Secondary**: Fine-tuned 7B for applying fixes  
**Trigger**: Compilation failure or type check failure

```python
# pipeline/repair.py

def repair(
    source_cpp: str,
    generated_code: str,
    error_message: str,
    target: str,
    max_attempts: int = 3,
) -> str | None:
    """Repair generated code using compile errors as feedback."""
    for attempt in range(max_attempts):
        # Claude interprets the error and produces a diff/fix instruction
        fix_instruction = claude_interpret_error(
            cpp_source=source_cpp,
            generated_code=generated_code,
            error=error_message,
            attempt=attempt,
        )

        if fix_instruction.is_simple_fix:
            # Small model applies the mechanical fix
            repaired = small_model_apply_fix(generated_code, fix_instruction)
        else:
            # Claude applies the fix directly (error is complex)
            repaired = fix_instruction.repaired_code

        # Validate the repair
        ok, new_error = compile_and_check(repaired, target)
        if ok:
            return repaired
        error_message = new_error

    return None  # Failed after max_attempts; flag for human review

def claude_interpret_error(cpp_source, generated_code, error, attempt):
    prompt = f"""A C++ to {target} translator generated this code:

```{target}
{generated_code}
```

The compiler/type-checker produced this error:
{error}

The original C++ source was:
{cpp_source}

Attempt {attempt+1}: Provide a minimal fix. Respond with JSON:
{{"simple_fix": true/false, "explanation": "...", "repaired_code": "..."}}"""

    response = claude.messages.create(...)
    return parse_fix_response(response)
```

---

## Cost Flow Analysis

For 10,000 functions (representative batch):

| Stage | Model | % Handled | Cost |
|---|---|---|---|
| Parse | Tree-sitter | 100% | $0 |
| Type inference (algorithmic) | None | 70% | $0 |
| Type inference (LLM) | Claude 3.5 Sonnet | 30% | ~$3 |
| Stdlib mapping (lookup) | Zim RAG | 80% | $0 |
| Stdlib mapping (LLM) | Qwen2.5-7B | 20% | ~$0.20 |
| Emit (fine-tuned 7B) | Qwen2.5-7B (A40) | 60% | ~$1.50 |
| Emit (32B) | Qwen2.5-32B (A40) | 30% | ~$0.90 |
| Emit (frontier) | Claude 3.5 Sonnet | 10% | ~$3.00 |
| Repair | Claude + 7B | ~15% of outputs | ~$2.00 |
| **Total** | | | **~$10.60** |

At $10.60 per 10,000 functions = **~$0.001/function** average cost.

Compared to GPT-4o only: ~$8.00 per 10,000 functions (8× more expensive).

---

## Implementation: pipeline.py Routing Function

```python
# pipeline/pipeline.py

from dataclasses import dataclass
from enum import Enum

class ModelTier(Enum):
    SMALL = "qwen2.5-coder-7b-finetuned"
    MEDIUM = "qwen2.5-coder-32b"
    FRONTIER = "claude-3-5-sonnet-20241022"

@dataclass
class TranslationResult:
    code: str
    model_used: ModelTier
    confidence: float
    stages: dict[str, float]  # stage -> confidence
    repaired: bool = False

def translate(
    cpp_source: str,
    target: str = "mojo",
    max_cost: float | None = None,
) -> TranslationResult:
    """Main pipeline entry point."""

    # Stage 1: Parse
    ast = parse_cpp(cpp_source)

    # Stage 2: Type inference
    ast = infer_types(ast)

    # Stage 3: Stdlib mapping
    ast = map_stdlib(ast, target)

    # Stage 4: Emit (model tier by confidence)
    tier = route_to_tier(ast, max_cost)
    code = emit(ast, target, model=tier.value)

    # Stage 5: Repair (if compilation fails)
    ok, error = compile_and_check(code, target)
    if not ok:
        code = repair(cpp_source, code, error, target)

    return TranslationResult(
        code=code,
        model_used=tier,
        confidence=ast.average_type_confidence(),
        stages={...},
    )

def route_to_tier(ast: ASTNode, max_cost: float | None) -> ModelTier:
    """Route to model tier based on complexity and cost constraints."""
    complexity = compute_complexity(ast)
    type_confidence = ast.average_type_confidence()
    has_templates = ast.contains_templates()

    if max_cost and max_cost < 0.001:
        return ModelTier.SMALL

    if has_templates or complexity > 30 or type_confidence < 0.6:
        return ModelTier.FRONTIER

    if complexity > 10 or type_confidence < 0.8:
        return ModelTier.MEDIUM

    return ModelTier.SMALL
```

---

## References

- [docs/cost_analysis.md](cost_analysis.md) — cost breakdown per approach
- [docs/fine_tuning_guide.md](fine_tuning_guide.md) — fine-tuning the 7B model
- [docs/runpod_guide.md](runpod_guide.md) — hosting on RunPod A40
- [docs/llvm_ir_pipeline.md](llvm_ir_pipeline.md) — LLVM IR grounding
- [docs/llm_comparison.md](llm_comparison.md) — model comparison details
