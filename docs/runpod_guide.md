# RunPod Guide: Cost-Efficient Open-Weight LLM Inference

## Overview

RunPod provides on-demand GPU instances well-suited for hosting open-weight models during both fine-tuning and inference phases of the transpilation pipeline. This guide covers instance selection, vLLM server setup, and integration with the transpilers CLI.

---

## Recommended Instance

### RTX A40 48GB — Primary Choice

| Property | Value |
|---|---|
| GPU | NVIDIA RTX A40 |
| VRAM | 48 GB |
| Price (on-demand) | ~$0.39–0.44/hr |
| Price (spot/interruptible) | ~$0.20–0.28/hr |
| Model capacity | 13B at fp16, 30B at 4-bit, 7B at fp16 with headroom |
| Throughput (Qwen2.5-7B) | ~1,500–2,000 tokens/sec (vLLM with continuous batching) |

### Alternative Instances

| GPU | VRAM | Price/hr | Best for |
|---|---|---|---|
| RTX A40 48GB | 48 GB | $0.39 | 13B fp16, 30B 4-bit — recommended |
| RTX 4090 24GB | 24 GB | $0.44 | 7B fp16, 13B 4-bit |
| A100 SXM 80GB | 80 GB | $1.64 | 70B 4-bit, multi-model |
| 2× A40 | 96 GB | $0.78 | 34B fp16, 70B 4-bit |
| H100 SXM 80GB | 80 GB | $2.49 | Maximum throughput |

---

## Provider Comparison

| Provider | GPU | Price/hr | Strengths | Weaknesses |
|---|---|---|---|---|
| **RunPod** | A40 48GB | $0.39 | Easy UI, persistent storage, templates | Spot availability varies |
| **Lambda Labs** | A100 80GB | $1.10 | Stable, reserved instances | More expensive, less GPU variety |
| **vast.ai** | Various | $0.18–0.60 | Cheapest spot prices | Variable reliability, community hardware |
| **Paperspace** | A100 80GB | $1.32 | Good Jupyter integration | Expensive for production |
| **Local RTX 4090** | 24 GB | ~$0.05 (electricity) | Cheapest long-term, no latency | 24GB limit, not scalable |

**Recommendation**: Use RunPod for production inference (reliability + price). Use vast.ai for experimental/spot workloads. Use local 4090 for development iteration.

---

## Setup: vLLM OpenAI-Compatible Server

### Step 1: Create a RunPod instance

1. Go to [runpod.io](https://www.runpod.io) → **Deploy**
2. Select **RTX A40 48GB** (or 2× A40 for larger models)
3. Choose template: **RunPod PyTorch 2.1** (or build custom from `vllm/vllm-openai` Docker image)
4. Set container disk: 50 GB (model weights + OS)
5. Set volume disk: 100 GB (for cached models and output)
6. Expose port **8000** (HTTP) in the network settings

### Step 2: Install vLLM (if not using the Docker image)

```bash
pip install vllm
```

### Step 3: Start the vLLM server

```bash
# Qwen2.5-Coder-7B-Instruct (fits A40 48GB at fp16, ~15 GB VRAM)
vllm serve Qwen/Qwen2.5-Coder-7B-Instruct \
    --port 8000 \
    --host 0.0.0.0 \
    --tensor-parallel-size 1 \
    --max-model-len 32768 \
    --dtype bfloat16 \
    --served-model-name qwen-coder-7b

# For fine-tuned LoRA adapter (merged weights)
vllm serve /workspace/checkpoints/qwen25-coder-7b-cpp-transpiler/final \
    --port 8000 \
    --host 0.0.0.0 \
    --dtype bfloat16

# For 13B model at fp16
vllm serve Qwen/Qwen2.5-Coder-14B-Instruct \
    --port 8000 \
    --tensor-parallel-size 1 \
    --dtype bfloat16

# For 32B model at 4-bit (requires ~35 GB VRAM)
vllm serve Qwen/Qwen2.5-Coder-32B-Instruct \
    --port 8000 \
    --quantization awq \
    --dtype auto
```

### Step 4: Verify the server is running

```bash
curl http://localhost:8000/v1/models
# Should return: {"object": "list", "data": [{"id": "qwen-coder-7b", ...}]}
```

---

## Connecting from the Transpilers CLI

### Environment variable setup

```bash
# In your local .envrc or shell profile
export VLLM_BASE_URL="https://<your-pod-id>-8000.proxy.runpod.net/v1"
export VLLM_API_KEY="none"  # vLLM doesn't require a key by default
export VLLM_MODEL="qwen-coder-7b"
```

### Usage in transpilers

```python
# The transpilers CLI reads VLLM_BASE_URL to route to RunPod
from openai import OpenAI
import os

client = OpenAI(
    base_url=os.environ["VLLM_BASE_URL"],
    api_key=os.environ.get("VLLM_API_KEY", "none"),
)

response = client.chat.completions.create(
    model=os.environ.get("VLLM_MODEL", "qwen-coder-7b"),
    messages=[
        {"role": "system", "content": "You are an expert C++ to Mojo transpiler."},
        {"role": "user", "content": f"Translate this C++ to Mojo:\n\n```cpp\n{cpp_code}\n```"},
    ],
    temperature=0.1,
    max_tokens=2048,
)
```

### CLI flag (when implemented)

```bash
# Use RunPod vLLM backend instead of OpenAI API
python -m transpilers translate src/file.cpp --backend runpod --model qwen-coder-7b

# Use OpenAI API (default)
python -m transpilers translate src/file.cpp --backend openai --model gpt-4o
```

---

## Cost Estimates

### 1M LOC C++ Repository

| Stage | Duration | Cost (A40 @ $0.39/hr) |
|---|---|---|
| Algorithmic transpilation (60% of code) | Negligible | $0 |
| Fine-tuned 7B inference (30% of code) | ~25 hrs | ~$10 |
| GPT-4o fallback (10% of code) | API call | ~$250 |
| **Total** | **~25 hrs GPU** | **~$260** |

### Pure vLLM inference (no API fallback)

```
1M LOC × 15 tokens/line = 15M output tokens
15M tokens ÷ 1,500 tokens/sec = 10,000 seconds ≈ 2.8 hrs
Cost: 2.8 × $0.39 = ~$1.10 per 1M LOC

At 350M total tokens (input + output): 
350M ÷ (1,500 × 3600) = 64.8 hrs
Cost: 64.8 × $0.39 = ~$25
```

### Fine-tuning run (A40)

```
Dataset: 10,000 examples × 3 epochs × 1,500 tokens avg = 45M tokens trained
A40 throughput for training: ~500 tokens/sec
Duration: 45M ÷ 500 = 25 hours
Cost: 25 × $0.39 = ~$10

Total for training + inference: ~$35–50
```

---

## RunPod Tips

### Persistent storage

- Attach a **Network Volume** (not container disk) so model weights survive pod restarts
- Cache HuggingFace models to `/workspace/models` on the volume

```bash
# In pod startup script
export HF_HOME=/workspace/models
export TRANSFORMERS_CACHE=/workspace/models
```

### Auto-shutdown on idle

```bash
# Add to pod startup to shut down if idle >30 minutes (saves cost)
# Install runpod CLI and use webhook-based monitoring
```

### Using spot instances

Spot instances cost 40–60% less but can be interrupted. For inference:
- Save progress to volume every N functions
- Resume from checkpoint on restart

```bash
# Spot instance: use --interruptible flag when creating via API
# UI: check "Spot" checkbox when deploying
```

---

## References

- [RunPod GPU Pricing](https://www.runpod.io/gpu-instance/pricing)
- [vLLM Documentation](https://docs.vllm.ai)
- [vLLM OpenAI-Compatible Server](https://docs.vllm.ai/en/latest/serving/openai_compatible_server.html)
- [Qwen2.5-Coder on HuggingFace](https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct)
