# 0 — Inference: running the C++/Fortran→Mojo transpiler model

Everything needed to serve the fine-tuned transpiler model and point this
pipeline (`2_transpile.py --backend lmstudio`) at it.

---

## What the model is

- **Base:** `Qwen/Qwen2.5-Coder-1.5B-Instruct` (qwen2 arch, 1.54 B params, 28 layers, **32 768-token context**).
- **Fine-tune:** a LoRA adapter (`adapter_15b_v2`, rank 16, α 32, ~36 M trainable params) SFT-trained for C++→Mojo transpilation.
  - Canonical source: `/home/bart/Github/transpilers/data/sft/cpp_mojo/adapter_15b_v2`
  - Frozen-ruler accuracy (per the transpilers repo): scalar 88 %, diverse 72 %.

## Weights saved here (`model/`)

| File | Size | Use |
|------|------|-----|
| `model/adapter_15b_v2/` | ~85 MB | **Canonical fine-tune** (LoRA + tokenizer). Everything below is derived from this + the base model. |
| `model/transpiler-1.5B-Q4_K_M.gguf` | 0.99 GB | **Fast** inference (~68 tok/s single-stream on the 890M). Default. |
| `model/transpiler-1.5B-Q8_0.gguf` | 1.53 GB | **Higher-quality** drafts (~45 tok/s). Use if pass@k hit-rate matters more than speed. |

> The 3 GB `f16` GGUF and the merged HF model are intermediates — not saved here, regenerable in minutes (see "Rebuild from the adapter").

---

## Recommended: serve the GGUF over an OpenAI-compatible endpoint

`2_transpile.py` talks to OpenAI-compatible `/v1/chat/completions` endpoints and
round-robins across `--endpoints` (your machines). Two ways to expose one:

### Option A — llama.cpp `llama-server` (fastest, headless)

Built (Vulkan) at `~/Github/llama.cpp-diffusion/build/bin/`. On the **890M** box:

```bash
~/Github/llama.cpp-diffusion/build/bin/llama-server \
  -m "/home/bart/Github/EnergyPlus-Mojo/stateless transpilation/model/transpiler-1.5B-Q4_K_M.gguf" \
  -ngl 99 \                # full GPU offload (model is ~1 GB, fits the iGPU GTT easily)
  -c 32768 \               # context; raise --parallel slots share this pool
  --parallel 32 \          # 32 concurrent slots — throughput sweet spot (see benchmarks)
  --host 0.0.0.0 --port 1234
```

Then transpile against it:

```bash
python3 2_transpile.py --all --backend lmstudio \
  --endpoints http://localhost:1234/v1 \
  --model transpiler-1.5B-Q4 --per-endpoint 32
```

(`--model` string is cosmetic for llama-server — it serves whatever `-m` loaded.)

### Option B — LM Studio (GUI, if you prefer it)

LM Studio is installed as a Flatpak; server at `http://127.0.0.1:1234`.
1. Put the GGUF where LM Studio sees it (its models dir is
   `~/.var/app/ai.lmstudio.lm-studio/.lmstudio/models/<author>/<repo>/`), or
   import via the GUI.
2. Load it, enable **Serve on Local Network**, set parallelism.
3. Point `2_transpile.py --endpoints http://<host>:1234/v1`.

Driving LM Studio's CLI from a host shell (it lives in the flatpak):
```bash
APP=~/.var/app/ai.lmstudio.lm-studio
HOME=$APP $APP/.lmstudio/bin/lms ps        # HOME override needed to find the auth key
HOME=$APP $APP/.lmstudio/bin/lms load <model> --gpu max -c 32768 -y
```

### Multi-machine (round-robin across the 890M + the RX 7700 XT)

`2_transpile.py` is built for this — list every endpoint; the scheduler hands the
next free file to whichever machine is idle (faster boxes naturally do more):

```bash
python3 2_transpile.py --all --backend lmstudio \
  --endpoints http://localhost:1234/v1 http://<7700xt-ip>:1234/v1 \
  --model transpiler-1.5B-Q4 --per-endpoint 16
```

On the **7700 XT** box (12 GB GDDR6, ~3–4× this machine): serve the same GGUF via
Ollama / llama-server / LM Studio with the Vulkan backend (or ROCm with
`HSA_OVERRIDE_GFX_VERSION=11.0.0`, since it's gfx1101). Tailscale gives stable IPs
between machines.

---

## Reference: raw `transformers` + ROCm (no GGUF)

Slower (~13 tok/s, no batching wins) — only for debugging the un-quantized model.
Uses the transpilers repo's ROCm venv:

```bash
export HSA_OVERRIDE_GFX_VERSION=11.0.0     # 890M reports gfx1150; coerce to gfx1100
PY=~/rocm-venv/bin/python                  # torch 2.9.1+rocm6.3, transformers, peft
```
```python
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer
from peft import PeftModel
ADAPTER = ".../model/adapter_15b_v2"
tok  = AutoTokenizer.from_pretrained(ADAPTER)
base = AutoModelForCausalLM.from_pretrained("Qwen/Qwen2.5-Coder-1.5B-Instruct", dtype=torch.float16)
model = PeftModel.from_pretrained(base, ADAPTER).merge_and_unload().to("cuda").eval()
```

---

## Rebuild the GGUFs from the adapter (if weights are lost)

Requires: `~/rocm-venv` (torch+transformers+peft), `sentencepiece`+`protobuf` in
that venv (`uv pip install --python ~/rocm-venv/bin/python sentencepiece protobuf`),
and a llama.cpp checkout with `convert_hf_to_gguf.py` + `llama-quantize`
(`~/Github/llama.cpp-diffusion`).

```bash
# 1. merge LoRA into base -> HF dir
python - <<'PY'
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer
from peft import PeftModel
b = AutoModelForCausalLM.from_pretrained("Qwen/Qwen2.5-Coder-1.5B-Instruct", dtype=torch.float16)
m = PeftModel.from_pretrained(b, "model/adapter_15b_v2").merge_and_unload()
m.save_pretrained("/tmp/merged"); AutoTokenizer.from_pretrained("model/adapter_15b_v2").save_pretrained("/tmp/merged")
PY
# 2. HF -> f16 GGUF
cd ~/Github/llama.cpp-diffusion
PYTHONPATH=gguf-py ~/rocm-venv/bin/python convert_hf_to_gguf.py /tmp/merged --outfile /tmp/t-f16.gguf --outtype f16
# 3. quantize
build/bin/llama-quantize /tmp/t-f16.gguf model/transpiler-1.5B-Q4_K_M.gguf Q4_K_M
build/bin/llama-quantize /tmp/t-f16.gguf model/transpiler-1.5B-Q8_0.gguf  Q8_0
```

---

## Measured performance (890M iGPU, Vulkan, Q4, 2026-06-11)

Single-stream decode **68 tok/s**, prefill ~1600 tok/s, TTFT ~0.1 s.

**Batching scales throughput** (one model + `--parallel N` slots — NOT N copies):

| Parallel slots | Aggregate decode tok/s | per-request tok/s |
|----------------|------------------------|-------------------|
| 1 | 65 | 65 |
| 4 | 214 | 54 |
| 16 | 414 | 26 |
| **32** (knee) | **681** | 21 |
| 64 (peak) | 871 | 14 |
| 128 | 881 (plateau) | 7 |

- **For bulk transpilation set `--parallel 32`** on the 890M → ~681 tok/s aggregate (10× single-stream) with still-tolerable per-request latency. `--parallel 64` for pure overnight jobs (peak ~871 tok/s); beyond that is wasted.
- Prefill is compute-bound and constant ~1600 tok/s; its wall-time grows with batch, so very long prompts at high batch shift the bottleneck to prefill.
- The RX 7700 XT should move this whole curve up ~3–4×.

Q8 is ~35 % slower than Q4 at equal batch; pick it only if draft quality (pass@k
hit-rate) outweighs speed. The downstream verify gate (`3_verify.py`) catches any
quality regression either way.
```

---

## Local whole-file transpiler (iGPU, $0) — the workhorse

The 1.5B fine-tune above is for **function-level** work; on whole-file dual-port
it scored 7/64. For the batch pipeline use a general coder model:

- **Model:** `model/Qwen2.5-Coder-14B-Instruct-Q4_K_M.gguf` (8.4 GB, bartowski)
- **Server:** `llama-server` (Vulkan) on the AMD 890M, OpenAI API at :8080
- **Fit:** 9 GB weights + q8_0 KV @ 24K ctx — fully GPU-resident in 15.5 GB
- **Speed:** ~9.5 tok/s decode, ~72 tok/s prompt (single stream); server has
  4 slots so `--per-endpoint 3` raises aggregate throughput (bandwidth amortized).

Launch:
```bash
./run_local_server.sh                 # foreground
nohup ./run_local_server.sh > /tmp/llama-server.log 2>&1 &   # background
```

Run the batch against it:
```bash
python3 2_transpile.py --all --backend lmstudio \
  --endpoints http://127.0.0.1:8080/v1 --model qwen2.5-coder-14b \
  --per-endpoint 3 --max-chars 60000 --timeout 1800
```
No API key, no rate limits, no cold starts. Files whose prompt exceeds
`--max-chars` are skipped (send those to a cloud 131K endpoint). Status is
written back to `1_manifest.json` so reruns resume where they left off.
