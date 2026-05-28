# IR Pair Pipeline: Building Training Data from C++ and Mojo LLVM IR

## Overview

The IR pair pipeline creates `(LLVM IR input, Mojo source output)` training pairs for fine-tuning the translation model. By grounding both sides in LLVM IR, we can verify semantic equivalence at the IR level — something impossible with source-to-source comparison alone.

**Expected yield from EnergyPlus**: ~5,000 verified pairs (filtering from ~50,000 functions by compilability and complexity).

See also: `docs/llvm_ir_pipeline.md` for background on LLVM IR grounding and `scripts/emit_llvm_ir.py` for the IR emission script.

---

## Step 1: C++ → LLVM IR via clang

```bash
clang -S -emit-llvm -O0 -std=c++17 -g \
    -I src/EnergyPlus/include \
    -o ir/HeatBalance.ll \
    src/EnergyPlus/HeatBalance.cpp
```

**Batch processing**:
```bash
python scripts/emit_llvm_ir.py src/EnergyPlus/ \
    --output ir/ \
    --std c++17 \
    --includes "src/EnergyPlus/include,third_party/include"
```

**Expected yield**: Of ~50,000 EnergyPlus functions, ~40,000 compile cleanly. Many are too complex (template-heavy) to translate reliably at this stage — filter to complexity < 20.

---

## Step 2: C++ → Mojo via Existing Transpiler

Use the current algorithmic + LLM pipeline to generate Mojo translations:

```bash
# Translate all extractable functions to Mojo
python -m transpilers translate src/EnergyPlus/ \
    --target mojo \
    --output mojo_generated/ \
    --model claude-3-5-sonnet  # or qwen2.5-7b for cost efficiency
```

**Expected yield**: Of 40,000 compilable functions, ~15,000 produce syntactically valid Mojo on first attempt. ~5,000–8,000 pass `mojo check` after automated repair.

---

## Step 3: Mojo → LLVM IR via mojo build

For each successfully generated Mojo file, emit LLVM IR:

```bash
mojo build --emit=llvm mojo_generated/HeatBalance.mojo -o ir_mojo/HeatBalance.ll
```

Or using MLIR (higher-level, retains more semantic information):

```bash
mojo build --emit=mlir mojo_generated/HeatBalance.mojo -o mlir_mojo/HeatBalance.mlir
```

**Expected yield**: Of ~6,000 valid Mojo files, ~5,500 compile to LLVM IR successfully.

---

## Step 4: Verify IR-Level Equivalence

Verify that the C++ IR and Mojo IR implement the same computation. We use three levels of verification, applied in order:

### Level 1: Signature matching (fast)
Compare function names, parameter types, and return types between C++ IR and Mojo IR.

```python
def check_signature_equivalence(cpp_ll: str, mojo_ll: str) -> bool:
    cpp_fn = extract_function_signature(cpp_ll)
    mojo_fn = extract_function_signature(mojo_ll)
    return types_compatible(cpp_fn, mojo_fn)
```

### Level 2: Algebraic equivalence on test inputs (moderate)
Run both functions on the same numerical inputs and compare outputs:

```python
def check_numerical_equivalence(
    cpp_fn_name: str,
    mojo_fn_name: str,
    test_inputs: list,
    tolerance: float = 1e-9,
) -> bool:
    cpp_outputs = run_cpp_function(cpp_fn_name, test_inputs)
    mojo_outputs = run_mojo_function(mojo_fn_name, test_inputs)
    return all(abs(a - b) < tolerance for a, b in zip(cpp_outputs, mojo_outputs))
```

### Level 3: IR structural comparison (slow, optional)
For numerical kernels, compare the LLVM IR instruction sequences using LLVM's `opt` tool:

```bash
# Canonicalize both IRs and diff
opt -O1 cpp_fn.ll -o cpp_opt.ll
opt -O1 mojo_fn.ll -o mojo_opt.ll
diff <(llvm-dis cpp_opt.ll) <(llvm-dis mojo_opt.ll)
```

---

## Step 5: Store in JSONL Format

Verified pairs are stored in JSONL for fine-tuning:

```jsonl
{"llvm_ir": "define double @computeHeatTransfer(double %area, double %dt, double %coeff) {\nentry:\n  %mul = fmul double %area, %dt\n  %mul1 = fmul double %mul, %coeff\n  ret double %mul1\n}\n", "mojo_source": "fn compute_heat_transfer(area: Float64, dt: Float64, coeff: Float64) -> Float64:\n    return area * dt * coeff\n", "cpp_source": "double computeHeatTransfer(double area, double dt, double coeff) { return area * dt * coeff; }", "verified": true, "verification_level": 2, "complexity": 3, "source_file": "src/EnergyPlus/HeatBalance.cpp"}
```

### Schema

```json
{
  "llvm_ir": "string — LLVM IR of the C++ function",
  "mojo_source": "string — verified Mojo translation",
  "cpp_source": "string — original C++ source (optional, for reference)",
  "verified": "bool — passed equivalence check",
  "verification_level": "int — 1 (signature), 2 (numerical), 3 (structural)",
  "complexity": "int — cyclomatic complexity of original function",
  "source_file": "string — original .cpp file path",
  "metadata": {
    "return_type": "string",
    "param_count": "int",
    "has_loops": "bool",
    "has_recursion": "bool"
  }
}
```

---

## Expected Yield from EnergyPlus

| Stage | Count | Notes |
|---|---|---|
| Total functions in EnergyPlus | ~50,000 | Estimated from source analysis |
| Compile to LLVM IR cleanly | ~40,000 | ~80% compile; rest need missing headers |
| Complexity filter (< 20) | ~25,000 | Removes template-heavy and huge functions |
| Successful Mojo translation | ~8,000 | ~32% of filtered set pass `mojo check` |
| Pass signature equivalence (L1) | ~7,000 | Type-compatible signatures |
| Pass numerical equivalence (L2) | ~5,500 | Correct outputs on test inputs |
| Pass structural check (L3, optional) | ~4,000 | Structurally equivalent IR |
| **Final verified pairs** | **~5,000** | Conservative estimate |

With augmentation from other C++ sources (open-source numerical libraries), the target of 10,000 pairs is achievable.

---

## Script Usage

See `scripts/build_ir_pairs.py` for the full implementation:

```bash
# Process EnergyPlus source directory
python scripts/build_ir_pairs.py \
    src/EnergyPlus/ \
    --ir-output ir/ \
    --mojo-output mojo_generated/ \
    --pairs-output data/ir_pairs.jsonl \
    --model claude-3-5-sonnet \
    --verify-level 2 \
    --max-complexity 20

# Process with cost budget
python scripts/build_ir_pairs.py \
    src/EnergyPlus/ \
    --pairs-output data/ir_pairs.jsonl \
    --max-cost 50.00  # Stop when $50 of LLM API spent

# Resume interrupted run
python scripts/build_ir_pairs.py \
    src/EnergyPlus/ \
    --pairs-output data/ir_pairs.jsonl \
    --resume  # Skip already-processed files
```

---

## Training Usage

The resulting JSONL file can be used directly with SFTTrainer:

```python
# Option A: Train on IR → Mojo (better type accuracy)
dataset = load_dataset("json", data_files="data/ir_pairs.jsonl")
dataset = dataset.map(lambda x: {
    "prompt": f"Translate this LLVM IR to Mojo:\n\n```llvm\n{x['llvm_ir']}\n```\n\nMojo:",
    "completion": f"```mojo\n{x['mojo_source']}\n```"
})

# Option B: Train on C++ → Mojo (with IR as additional context)
dataset = dataset.map(lambda x: {
    "prompt": f"Translate this C++ function to Mojo.\n\nC++ source:\n```cpp\n{x['cpp_source']}\n```\n\nLLVM IR (for type reference):\n```llvm\n{x['llvm_ir'][:500]}\n```\n\nMojo:",
    "completion": f"```mojo\n{x['mojo_source']}\n```"
})
```

---

## References

- [docs/llvm_ir_pipeline.md](llvm_ir_pipeline.md) — LLVM IR emission and background
- [docs/fine_tuning_guide.md](fine_tuning_guide.md) — training on these pairs
- [scripts/emit_llvm_ir.py](../scripts/emit_llvm_ir.py) — batch IR emission
- [scripts/build_ir_pairs.py](../scripts/build_ir_pairs.py) — full pair pipeline
- arXiv:2207.03578 — "LLVM IR as Universal Intermediate for Code Translation"
