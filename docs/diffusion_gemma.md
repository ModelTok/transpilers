# DiffusionGemma: Inference & Fine-Tuning Guide

## Overview

[DiffusionGemma](https://blog.google/innovation-and-ai/technology/developers-tools/diffusion-gemma-faster-text-generation/) (`google/diffusion-gemma-26b-it`) is Google DeepMind's open experimental text-diffusion model, released under Apache 2.0. Unlike standard autoregressive LLMs that generate one token at a time, DiffusionGemma generates **256-token blocks (canvases) in parallel** and iteratively denoises them using an entropy-bounded sampler. This achieves up to **4x faster inference** on dedicated GPUs.

| Property | Value |
|----------|-------|
| Parameters | 26B total (MoE), 3.8B active |
| License | Apache 2.0 |
| Context | 256K tokens |
| Architecture | Gemma 4 MoE + diffusion head |
| Canvas size | 256 tokens |
| Inference speed | 1000+ tok/s (H100), 700+ tok/s (RTX 5090) |
| Min VRAM (4-bit) | 18 GB |

### How text diffusion works

1. **Canvas initialization** — The model starts with a canvas of random placeholder tokens
2. **Iterative refinement** — Multiple denoising passes lock in confident tokens and re-noise uncertain ones
3. **Bi-directional attention** — Every token attends to all others in the canvas
4. **Convergence** — The text block is complete when all tokens meet the entropy confidence threshold

**Key difference:** A standard LLM acts like a typewriter (one token at a time, GPU underutilized). DiffusionGemma acts like a printing press (256 tokens per forward pass, fully utilizing compute).

---

## Quick Start

### Prerequisites

```bash
# For llama.cpp backend (recommended for local inference):
git clone https://github.com/ggml-org/llama.cpp
cd llama.cpp
gh pr checkout 24423
cmake -B build -DGGML_CUDA=ON
cmake --build build -j --config Release --target llama-diffusion-cli
cd ..

# Install Python dependencies:
pip install huggingface_hub hf_transfer
```

### Download and run (llama.cpp)

```bash
# Download Q4_K_M GGUF (18 GB VRAM required)
python scripts/sft/infer_diffusiongemma.py --download-gguf Q4_K_M

# Single prompt
python scripts/sft/infer_diffusiongemma.py \
    --prompt "Translate C++ to Mojo:" \
    --thinking

# Interactive mode
python scripts/sft/infer_diffusiongemma.py --interactive --thinking
```

### Run with vLLM (cloud/server)

```bash
# Start vLLM server:
vllm serve google/diffusion-gemma-26b-it \
    --max-model-len 4096 \
    --gpu-memory-utilization 0.95 \
    --dtype bfloat16 \
    --port 8000

# Then from another terminal:
export DIFFUSION_VLLM_BASE_URL=http://localhost:8000/v1
python scripts/sft/infer_diffusiongemma.py \
    --backend vllm \
    --prompt "Translate C++ to Mojo:"
```

### Programmatic usage

```python
from transpilers.llm.diffusion import (
    DiffusionGemmaClient,
    DiffusionGenerationConfig,
    DiffusionSamplerConfig,
)

sampler = DiffusionSamplerConfig(
    temperature_start=0.8,
    temperature_end=0.4,
    entropy_bound=0.1,
    max_steps=48,
)
config = DiffusionGenerationConfig(
    max_new_tokens=1024,
    sampler=sampler,
    thinking=False,
    system_prompt="You are a code transpiler.",
)
client = DiffusionGemmaClient(
    backend="llamacpp",
    model="path/to/model.gguf",
    config=config,
)
response = client.generate("Translate C++ to Mojo:")
print(response)
```

---

## Diffusion Sampler Parameters

DiffusionGemma uses an **entropy-bounded denoising (EB) sampler** — NOT standard temperature/top-p/top-k.

| Parameter | Default | Description |
|-----------|---------|-------------|
| `temperature_start` | 0.8 | Initial denoising temperature (linearly decayed) |
| `temperature_end` | 0.4 | Final denoising temperature |
| `entropy_bound` | 0.1 | Mutual-information bound for token selection |
| `confidence` | 0.005 | Adaptive-stopping entropy threshold |
| `max_steps` | 48 | Maximum denoising steps |
| `adaptive_stopping` | True | Stop early when all tokens are confident |

**Recommended settings by use case:**

| Use Case | T_start | T_end | Steps | Entropy |
|----------|---------|-------|-------|---------|
| Default (balanced) | 0.8 | 0.4 | 48 | 0.1 |
| Speed-optimized | 0.9 | 0.5 | 24 | 0.15 |
| Quality-optimized | 0.7 | 0.3 | 64 | 0.05 |
| Code generation | 0.8 | 0.4 | 48 | 0.1 |
| Creative writing | 0.9 | 0.5 | 56 | 0.15 |

---

## Fine-Tuning

### Option 1: Unsloth (recommended)

Unsloth provides first-class DiffusionGemma support with 2x faster training and 70% less VRAM.

```bash
python scripts/sft/finetune_diffusiongemma_unsloth.py \
    --model google/diffusion-gemma-26b-it \
    --dataset data/sft/cpp_mojo/train_translation.jsonl \
    --dataset data/sft/cpp_mojo/mojo_acquisition.json \
    --output-dir checkpoints/diffusiongemma-cpp-mojo \
    --lr 1e-4 \
    --epochs 2 \
    --max-seq-length 2048 \
    --export-gguf
```

The script:
1. Loads DiffusionGemma with 4-bit QLoRA
2. Applies LoRA adapters (r=16, alpha=32, target=all linear layers)
3. Trains on the C++/Python -> Mojo SFT dataset
4. Saves the LoRA adapter, merged model, and optional GGUF export

**After fine-tuning, evaluate:**

```bash
# With Unsloth (for adapter evaluation)
python scripts/sft/infer_diffusiongemma.py \
    --backend unsloth \
    --model checkpoints/diffusiongemma-cpp-mojo/lora_adapter \
    --prompt "Translate C++ to Mojo:"

# With llama.cpp (for GGUF evaluation)
python scripts/sft/infer_diffusiongemma.py \
    --backend llamacpp \
    --model checkpoints/diffusiongemma-cpp-mojo/gguf/*.gguf \
    --prompt "..."
```

### Option 2: LLaMA Factory

Use `data/sft/cpp_mojo/diffusiongemma_qlora.yaml`:

```bash
llamafactory-cli train data/sft/cpp_mojo/diffusiongemma_qlora.yaml
```

**Caveat:** LLaMA Factory's SFT trainer uses standard teacher-forcing. This works for training, but inference MUST use a diffusion-aware runtime.

---

## Hardware requirements

| Quantization | Min VRAM | Recommended GPU |
|--------------|----------|-----------------|
| Q4_K_M (4-bit) | 18 GB | RTX 4090 24GB, RTX 5090 32GB, A40 48GB |
| Q5_K_M (5-bit) | 20 GB | RTX 5090 32GB, A40 48GB |
| Q8_0 (8-bit) | 28 GB | A40 48GB, L40S 48GB, A100 80GB |
| BF16/FP16 | 52 GB | A100 80GB, H100 80GB |

## Known Limitations

1. **Diffusion-aware runtime required** — Cannot use standard HF Transformers pipeline or standard llama.cpp
2. **Output quality vs. Gemma 4** — DiffusionGemma prioritizes speed; standard Gemma 4 is better for max quality
3. **Throughput advantage is local-only** — Speedup is strongest at low batch sizes on single accelerator
4. **Unified memory architectures** — Apple Silicon may not see the same speedup as discrete GPUs
5. **No standard greedy decoding** — DiffusionGemma always uses stochastic denoising

---

## References

- [Google Blog: Introducing DiffusionGemma](https://blog.google/innovation-and-ai/technology/developers-tools/diffusion-gemma-faster-text-generation/)
- [Unsloth: DiffusionGemma Guide](https://unsloth.ai/docs/models/diffusiongemma)
- [HuggingFace: diffusion-gemma-26b-it](https://huggingface.co/google/diffusion-gemma-26b-it)
- [llama.cpp Diffusion PR #24423](https://github.com/ggml-org/llama.cpp/pull/24423)
- [Unsloth Studio](https://unsloth.ai/)
