# Systematic LLM Comparison for C++ to Python and Mojo Translation

## Overview

This document provides a structured comparison of LLMs across the dimensions most relevant to the transpilation pipeline: accuracy, cost, speed, and context window. The goal is a recommendation matrix that guides model selection based on use case.

---

## Comparison Dimensions

| Dimension | Metric | Why It Matters |
|---|---|---|
| **Accuracy** | Pass@1 on transpilation-bench | Primary quality signal |
| **Cost** | $/1000 functions translated | Budget planning |
| **Speed** | tokens/sec (output) | Pipeline throughput |
| **Context window** | tokens | Handles large classes / files |
| **Type accuracy** | % correct types (Mojo) | Critical for compiled targets |
| **Multi-shot benefit** | Pass@1 improvement with 5 examples | Amortizable improvement |

---

## Model Comparison Table

| Model | Pass@1 (est.) | Cost/1K fns | Speed (tok/s) | Context | Type Acc (est.) | License |
|---|---|---|---|---|---|---|
| GPT-4o | ~70% | $8.00 | ~80 (API) | 128K | ~72% | Proprietary |
| Claude 3.5 Sonnet | ~72% | $2.40 | ~90 (API) | 200K | ~74% | Proprietary |
| Claude Opus 4.7 | ~78% | $18.00 | ~60 (API) | 200K | ~80% | Proprietary |
| Gemini 1.5 Pro | ~65% | $2.80 | ~100 (API) | 1M | ~67% | Proprietary |
| Gemini 2.0 Flash | ~58% | $0.28 | ~150 (API) | 1M | ~60% | Proprietary |
| Llama-3.1-70B | ~55% | $0.12 | ~400 (A40) | 128K | ~57% | Llama 3.1 Community |
| Qwen2.5-Coder-32B | ~68% | $0.06 | ~600 (A40) | 128K | ~70% | Apache-2.0 |
| Qwen2.5-Coder-7B | ~45% | $0.01 | ~1,800 (A40) | 128K | ~47% | Apache-2.0 |
| LLM Compiler 13B | ~52% | $0.02 | ~1,200 (A40) | 16K | ~65% | Llama 2 Community |
| StarCoder2-15B | ~48% | $0.03 | ~1,100 (A40) | 16K | ~50% | BigCode OpenRAIL-M |
| DeepSeek-Coder-33B | ~60% | $0.07 | ~650 (A40) | 16K | ~62% | DeepSeek License |

> Note: Pass@1 estimates are based on public benchmarks and extrapolated for C++ translation tasks. Fill in measured values after running `run_eval.py`.

> Cost per 1K functions assumes ~500 input tokens + ~300 output tokens per function.

---

## Per-Tier Analysis

### Tier 1: Frontier Models (Claude Opus 4.7, GPT-4o, Claude 3.5 Sonnet)

**Best at**:
- Complex template metaprogramming and SFINAE patterns
- Multi-step algorithmic logic requiring reasoning
- Novel constructs not seen in training data
- Explanation-enhanced translation (chain-of-thought improves accuracy)

**Where they struggle**:
- High-volume, repetitive boilerplate (expensive)
- Very large files exceeding effective context (>32K tokens practical limit)
- Domain-specific EnergyPlus patterns without examples

**Recommendation**: Use for <10% of code volume — complex logic, template-heavy headers, and architecture decisions.

### Tier 2: Large Open-Weight Models (Qwen2.5-Coder-32B, Llama-3.1-70B, DeepSeek-Coder-33B)

**Best at**:
- Standard algorithmic patterns (loops, conditionals, data structures)
- Self-hosted deployment for privacy-sensitive codebases
- High-volume translation at 100× lower cost than frontier

**Where they struggle**:
- Mojo-specific type system (fewer training examples)
- Very complex C++ metaprogramming
- Long-context files (practical limit ~8K tokens for quality)

**Recommendation**: Primary workhorse for 30–50% of translation volume. Run on RunPod A40.

### Tier 3: Small Specialized Models (LLM Compiler 13B, Qwen2.5-Coder-7B)

**Best at**:
- Token-level transpilation (keyword mapping, syntax transformation)
- IR-level translation (LLM Compiler excels here)
- High-throughput, low-latency batch processing
- Fine-tuning target — highest ROI after domain fine-tuning

**Where they struggle**:
- Multi-function reasoning
- Type inference without explicit annotations
- Novel control flow patterns

**Recommendation**: Use as the first-pass model in a hybrid pipeline. Route failures to Tier 2/1.

---

## Zero-Shot vs Multi-Shot Comparison

Providing examples in the prompt (few-shot / multi-shot) consistently improves accuracy:

| Condition | GPT-4o Pass@1 | Qwen2.5-7B Pass@1 | Cost Increase |
|---|---|---|---|
| Zero-shot | ~70% | ~45% | 1× |
| 1-shot (1 example) | ~74% | ~52% | 1.4× |
| 3-shot (3 examples) | ~77% | ~57% | 2.0× |
| 5-shot (5 examples) | ~79% | ~60% | 2.8× |
| 10-shot (10 examples) | ~80% | ~62% | 4.5× |

**Key insight**: Multi-shot provides diminishing returns after 5 examples, but the 3-shot setting gives the best accuracy/cost tradeoff for production.

**Domain-matched examples**: Providing EnergyPlus-specific examples (same problem domain as the function being translated) improves Pass@1 by an additional 5–8% vs generic examples.

---

## Recommendation Matrix by Use Case

| Use Case | Recommended Model | Reason |
|---|---|---|
| **Pilot / establish baseline** | GPT-4o or Claude 3.5 Sonnet | Best accuracy, generate gold standard |
| **High-accuracy, cost unconstrained** | Claude Opus 4.7 | Highest Pass@1, best on novel constructs |
| **Production at scale** | Hybrid: Qwen2.5-7B + Claude fallback | 90% cheap, 10% accurate |
| **Self-hosted, privacy-sensitive** | Qwen2.5-Coder-32B (A40) | Near-frontier quality, no data egress |
| **Maximum throughput** | Qwen2.5-Coder-7B (fine-tuned) | 1,800 tokens/sec, domain-optimized |
| **IR-grounded translation** | LLM Compiler 13B | Trained on LLVM IR, best type inference |
| **Cost-constrained pilot** | Gemini 2.0 Flash | 10× cheaper than GPT-4o, acceptable quality |
| **Research / experimentation** | StarCoder2-15B | Open weights, transparent training data |

---

## Model Selection Decision Tree

```
What matters most?
│
├─► Accuracy is critical (legal, safety-critical code)
│     └─► Claude Opus 4.7 → validate with formal verification
│
├─► Cost is critical (>100K functions to translate)
│     ├─► Can you fine-tune? → Qwen2.5-Coder-7B (fine-tuned)
│     └─► No fine-tuning → Gemini 2.0 Flash + Claude fallback for failures
│
├─► Speed is critical (<1hr for 10K functions)
│     └─► Qwen2.5-Coder-7B self-hosted (1,800 tokens/sec on A40)
│
├─► Large context needed (whole-file translation)
│     └─► Gemini 1.5 Pro (1M context) or Claude 3.5 Sonnet (200K)
│
├─► Privacy / no cloud egress
│     └─► Qwen2.5-Coder-32B on RunPod (Apache-2.0 license)
│
└─► Default production recommendation
      └─► Stage 1: Qwen2.5-7B (fast, cheap, handles 60%)
          Stage 2: Qwen2.5-32B (handles 30%)
          Stage 3: Claude 3.5 Sonnet (handles 10% complex cases)
```

---

## Context Window Considerations

| File type | Typical token count | Model needed |
|---|---|---|
| Single function (<50 lines) | ~500 tokens | Any model |
| Single class (~200 lines) | ~2,000 tokens | Any model |
| Large class + dependencies (~1,000 lines) | ~10,000 tokens | Needs 16K+ context |
| Full file with includes (~3,000 lines) | ~30,000 tokens | Needs 32K+ context |
| Module with multiple files | ~100,000 tokens | Gemini 1.5 Pro / Claude |

**Practical recommendation**: Split translation at the function level when possible. Only escalate to file-level context for functions with heavy cross-function dependencies.

---

## References

- [LMSYS Chatbot Arena Leaderboard](https://huggingface.co/spaces/lmsys/chatbot-arena-leaderboard)
- [EvalPlus Leaderboard](https://evalplus.github.io/leaderboard.html)
- [BigCode LLM Leaderboard](https://huggingface.co/spaces/bigcode/bigcode-models-leaderboard)
- [LLM Compiler paper](https://arxiv.org/abs/2407.02524)
- [Qwen2.5-Coder technical report](https://arxiv.org/abs/2409.12186)
- [transpilation-bench](https://github.com/Tokarzewski/transpilation-bench)
