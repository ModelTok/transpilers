# AI Tools Evaluation: C++ to Python/Mojo Translation Benchmark

## Overview

This document defines the evaluation protocol for benchmarking AI models on C++ to Python and Mojo translation tasks using the transpilation-bench suite. Results tables are to be filled in after running the evaluation.

---

## Models Under Evaluation

### Frontier / Commercial APIs

| Model | Provider | Context | Pricing (input/output) | Notes |
|---|---|---|---|---|
| GPT-4o | OpenAI | 128K | $10/$30 per M tokens | Baseline frontier model |
| Claude Opus 4.7 | Anthropic | 200K | $15/$75 per M tokens | Strongest on complex reasoning |
| Claude 3.5 Sonnet | Anthropic | 200K | $3/$15 per M tokens | Best cost/quality ratio |
| Gemini 1.5 Pro | Google | 1M | $3.50/$10.50 per M tokens | Long context, good code |
| Gemini 2.0 Flash | Google | 1M | $0.075/$0.30 per M tokens | Fastest, cheapest frontier |

### Open-Weight Models (Self-Hosted)

| Model | Size | License | VRAM Required | Notes |
|---|---|---|---|---|
| Llama-3.1-70B-Instruct | 70B | Llama 3.1 Community | 35GB (4-bit) | Strong general coding |
| Qwen2.5-Coder-7B-Instruct | 7B | Apache-2.0 | 15GB (fp16) | Best 7B code model |
| Qwen2.5-Coder-32B-Instruct | 32B | Apache-2.0 | 35GB (4-bit) | Near-frontier quality |

### Specialized Code Models

| Model | Size | Specialization | Notes |
|---|---|---|---|
| LLM Compiler 13B | 13B | LLVM IR / compiler tasks | Meta, optimized for compilation |
| StarCoder2-15B | 15B | Code (600+ languages) | BigCode, strong on C++ |
| DeepSeek-Coder-33B-Instruct | 33B | Code generation | Strong on algorithmic tasks |

---

## Evaluation Protocol

### Benchmark Suite: transpilation-bench

- Repository: [github.com/Tokarzewski/transpilation-bench](https://github.com/Tokarzewski/transpilation-bench)
- Tasks: 40 C++ functions (selected for coverage of EnergyPlus-relevant patterns)
- Targets: Python 3.11+, Mojo 0.7+
- Total test cases: 40 × 2 targets = 80 translation tasks

### Task categories (40 functions)

| Category | Count | Examples |
|---|---|---|
| Pure arithmetic | 8 | Heat transfer formulae, unit conversions |
| Array/loop patterns | 8 | Summation, rolling average, min/max |
| String processing | 4 | Parsing, formatting |
| Data structure ops | 6 | Stack, queue, sorted insert |
| Numerical algorithms | 8 | Newton's method, integration, interpolation |
| OOP patterns | 4 | Inheritance, virtual dispatch |
| Template/generic | 2 | Type-parametric algorithms |

### Metrics

**Pass@1** — Primary metric
- Generate 1 translation per function
- Run against provided unit tests
- Pass@1 = fraction of functions where generated code passes all tests

**CodeBLEU** — Secondary metric
- Measures syntactic and semantic similarity to reference translations
- Range: 0–1, higher is better
- Components: n-gram match, weighted n-gram match, syntax match, dataflow match

**Type accuracy** — Mojo-specific
- Fraction of return types and parameter types correctly inferred
- Evaluated by running `mojo check` on generated code

---

## How to Run Evaluations

### Prerequisites

```bash
# Clone transpilation-bench
git clone https://github.com/Tokarzewski/transpilation-bench
pip install transpilation-bench

# Set API keys
export OPENAI_API_KEY="..."
export ANTHROPIC_API_KEY="..."
export GOOGLE_API_KEY="..."

# For self-hosted models, start vLLM server first (see docs/runpod_guide.md)
export VLLM_BASE_URL="http://localhost:8000/v1"
```

### Run evaluation per model

```bash
# GPT-4o (direct path: no intermediate representation)
python run_eval.py --model gpt-4o --path direct --target python
python run_eval.py --model gpt-4o --path direct --target mojo

# Claude Opus 4.7
python run_eval.py --model claude-opus-4-7 --path direct --target python

# Gemini 1.5 Pro
python run_eval.py --model gemini-1.5-pro --path direct --target python

# Self-hosted via vLLM
python run_eval.py --model qwen2.5-coder-7b --path direct --backend vllm --target python

# All models at once
python run_eval.py --all --path direct --output results/eval_$(date +%Y%m%d).json
```

### Translation paths to test

```bash
# Direct: C++ → target
python run_eval.py --model gpt-4o --path direct

# Hybrid: tree-sitter parse → LLM for gaps
python run_eval.py --model gpt-4o --path hybrid

# IR-grounded: C++ → LLVM IR → target (requires clang)
python run_eval.py --model gpt-4o --path ir_grounded

# Multi-shot (5 examples in prompt)
python run_eval.py --model gpt-4o --path direct --shots 5
```

---

## Expected Results Table (to be filled in after running)

### C++ → Python: Pass@1

| Model | Pass@1 | CodeBLEU | Cost/run | Notes |
|---|---|---|---|---|
| GPT-4o | TBD | TBD | ~$0.80 | |
| Claude Opus 4.7 | TBD | TBD | ~$2.20 | |
| Claude 3.5 Sonnet | TBD | TBD | ~$0.50 | |
| Gemini 1.5 Pro | TBD | TBD | ~$0.40 | |
| Llama-3.1-70B | TBD | TBD | ~$0.02 | Self-hosted |
| Qwen2.5-Coder-7B | TBD | TBD | ~$0.002 | Self-hosted |
| Qwen2.5-Coder-32B | TBD | TBD | ~$0.008 | Self-hosted |
| LLM Compiler 13B | TBD | TBD | ~$0.004 | Self-hosted |
| StarCoder2-15B | TBD | TBD | ~$0.005 | Self-hosted |
| DeepSeek-Coder-33B | TBD | TBD | ~$0.009 | Self-hosted |

### C++ → Mojo: Pass@1

| Model | Pass@1 | Type Accuracy | CodeBLEU | Cost/run |
|---|---|---|---|---|
| GPT-4o | TBD | TBD | TBD | ~$0.80 |
| Claude Opus 4.7 | TBD | TBD | TBD | ~$2.20 |
| Claude 3.5 Sonnet | TBD | TBD | TBD | ~$0.50 |
| Gemini 1.5 Pro | TBD | TBD | TBD | ~$0.40 |
| Qwen2.5-Coder-7B | TBD | TBD | TBD | ~$0.002 |
| LLM Compiler 13B | TBD | TBD | TBD | ~$0.004 |

---

## Cost Estimate Per Model Per Run

A "run" = 40 tasks × 2 targets = 80 translations.

Estimated tokens per task: ~500 input, ~300 output.

| Model | Total tokens/run | Cost/run |
|---|---|---|
| GPT-4o | 64K tokens | ~$0.80 |
| Claude Opus 4.7 | 64K tokens | ~$2.20 |
| Claude 3.5 Sonnet | 64K tokens | ~$0.50 |
| Gemini 1.5 Pro | 64K tokens | ~$0.40 |
| Gemini 2.0 Flash | 64K tokens | ~$0.05 |
| Self-hosted 7B | 64K tokens | ~$0.002 (A40 compute) |
| Self-hosted 70B | 64K tokens | ~$0.015 (A40 compute) |

**Total cost to evaluate all models once**: ~$4–5 (API) + ~$0.05 (self-hosted compute)

---

## Hypotheses to Validate

1. Claude Opus 4.7 will outperform GPT-4o on Mojo translation (stronger reasoning, better instruction following)
2. LLM Compiler 13B will outperform Llama-3.1-70B on IR-level patterns despite being 5× smaller
3. Multi-shot prompting (+5 examples) will improve Pass@1 by 10–15% across all models
4. IR-grounded path will improve type accuracy by 20–30% on Mojo targets vs direct translation

---

## References

- [transpilation-bench](https://github.com/Tokarzewski/transpilation-bench)
- [CodeBLEU metric](https://arxiv.org/abs/2009.10297)
- [LLM Compiler paper](https://arxiv.org/abs/2407.02524)
- [Qwen2.5-Coder technical report](https://arxiv.org/abs/2409.12186)
- [StarCoder2 paper](https://arxiv.org/abs/2402.19173)
