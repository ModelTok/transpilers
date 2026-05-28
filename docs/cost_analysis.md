# Cost Analysis: Most Cost-Effective Transpilation Mechanism

## Overview

This document analyzes the cost tradeoffs between different transpilation approaches for large-scale C++ to Python/Mojo migration, using a 1M LOC C++ repository as the reference workload.

---

## Reference Workload: 1M LOC C++ Repository

| Metric | Estimate |
|---|---|
| Lines of code | 1,000,000 |
| Average tokens per line (input) | 15 |
| Estimated input tokens | ~250M tokens |
| Estimated output tokens (translated code) | ~100M tokens |
| Unique functions | ~50,000 |
| Unique classes | ~5,000 |

---

## Cost Comparison Table

| Approach | Cost | Accuracy | Speed | Best For |
|---|---|---|---|---|
| GPT-4o API ($10/M input, $30/M output) | ~$5,500 total | Highest (frontier) | ~500 tokens/sec | Pilot, benchmarks, complex logic |
| Claude 3.5 Sonnet ($3/M input, $15/M output) | ~$2,250 total | Very high | ~600 tokens/sec | Balanced cost/quality |
| Gemini 1.5 Pro ($3.50/M input, $10.50/M output) | ~$1,925 total | High | ~800 tokens/sec | High-volume, long context |
| Fine-tuned 7B on RunPod A40 ($0.40/hr) | ~$40–80 total | Domain-high | ~1,500 tokens/sec | Production after training |
| Algorithmic (tree-sitter only) | ~$0 | Low–Medium | Instant | Simple syntax, boilerplate |
| Hybrid (algorithmic + LLM for gaps) | ~$500–1,000 | High | Fast | Best balance at scale |

### GPT-4o Cost Breakdown (1M LOC)

```
Input:  250M tokens × $10/M  = $2,500
Output: 100M tokens × $30/M  = $3,000
Total:                         $5,500
```

> Note: pricing as of mid-2025. Batch API discounts (50%) reduce this to ~$2,750.

### Fine-Tuned 7B on RunPod A40 Cost Breakdown

```
Training data prep:      $20   (GPT-4o on 1,000 pilot functions)
Fine-tuning run:         $15   (A40 × ~38 hrs for 10K examples, 3 epochs)
Inference (1M LOC):      $25   (A40 × ~60 hrs at 1,500 tokens/sec)
Total:                   ~$60
```

---

## Detailed Estimates

### Option A: GPT-4o API Only

- **Total cost**: ~$5,500 (standard) or ~$2,750 (Batch API)
- **Accuracy**: Highest — handles complex templates, SFINAE, macros
- **Latency**: Rate-limited; 1M LOC at 10K tokens/min = ~417 hours unless parallelized
- **Risk**: Cost spike if prompts are inefficient; no domain fine-tuning

### Option B: Fine-Tuned 7B (Qwen2.5-Coder-7B-Instruct) on RunPod

- **Training cost**: ~$15–30 (A40 at $0.40/hr, 10K examples × 3 epochs)
- **Inference cost**: ~$20–40 for 1M LOC (depends on throughput)
- **Total**: **$40–80** including pilot data generation
- **Accuracy**: High for domain-specific patterns; lower for novel constructs
- **Risk**: Requires quality training data; degrades on out-of-distribution code

### Option C: Hybrid Pipeline (Recommended for Production)

- **Algorithmic stage**: Handles ~60% of tokens (declarations, simple expressions) at $0
- **Fine-tuned 7B**: Handles ~30% of tokens (routine function bodies) at ~$0.01/function
- **Frontier model**: Handles ~10% of tokens (complex logic, templates) at full API cost
- **Total**: ~$200–400 for 1M LOC

---

## Decision Tree: When to Use Each Approach

```
Start
  │
  ├─► Is this a pilot / first 1,000 functions?
  │     └─► YES → Use GPT-4o API (quality benchmark, generate training data)
  │
  ├─► Do you have >5,000 labeled translation examples?
  │     └─► YES → Fine-tune 7B, run on RunPod for inference
  │
  ├─► Is the function purely syntactic (simple loops, assignments)?
  │     └─► YES → Use algorithmic (tree-sitter) transpiler — zero cost
  │
  ├─► Is the function domain-specific (EnergyPlus physics, numerical)?
  │     └─► YES → Fine-tuned 7B will outperform generic frontier models
  │
  ├─► Is correctness critical with no tolerance for errors?
  │     └─► YES → Use Claude / GPT-4o with formal verification in loop
  │
  └─► Default production path → Hybrid pipeline (algorithmic + fine-tuned 7B + frontier fallback)
```

---

## Phased Rollout Recommendation

### Phase 1: Pilot (0–1,000 functions) — Use GPT-4o

- Cost: ~$50–100
- Goal: Establish quality baseline, generate training data
- Output: Benchmark Pass@1 scores, 1,000 labeled pairs

### Phase 2: Training (1,000–10,000 examples)

- Augment with EnergyPlus functions and open-source C++ corpora
- Fine-tune Qwen2.5-Coder-7B-Instruct on RunPod: ~$30
- Validate against transpilation-bench

### Phase 3: Production (Full 1M LOC) — Hybrid Pipeline

- Route easy functions to fine-tuned 7B
- Route complex/novel functions to GPT-4o (expected: <10% of volume)
- Estimated total: ~$200–400

---

## Cost Sensitivity Analysis

| Variable | Impact |
|---|---|
| Prompt efficiency (tokens/function) | ±30% cost swing; use compressed prompts |
| Model output verbosity | Chain-of-thought adds 2–3× output tokens; use direct-answer prompts |
| Algorithmic coverage | Each 10% more algorithmic coverage saves ~$250 on 1M LOC |
| Fine-tune quality | Poor training data doubles frontier-model fallback rate |
| RunPod spot vs on-demand | Spot instances save ~40% but risk interruption |

---

## References

- [RunPod GPU Pricing](https://www.runpod.io/gpu-instance/pricing)
- [OpenAI API Pricing](https://openai.com/api/pricing)
- [Qwen2.5-Coder on HuggingFace](https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct)
- [transpilation-bench](https://github.com/Tokarzewski/transpilation-bench) — evaluation harness
