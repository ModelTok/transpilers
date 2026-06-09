# Cloud training bundle — 3B Mojo-transpiler LoRA

Drop-and-run bundle for a fresh Ubuntu + NVIDIA GPU instance.
Cross-reference: `docs/cloud_training.md` (full Option A/B runbook).

---

## What to rsync to the box

```
data/sft/cpp_mojo/
    train_translation_v2.jsonl      # 1065 pairs — phase 2 training set (v1 + 60 new Python leaves)
    train_translation.jsonl         # 1005 pairs — original, kept intact
    mojo_acquisition.json           # 1163 samples — phase 1 training set
    dataset_info.json               # LLaMA-Factory dataset registry (includes cpp_mojo_translation_v2)
    sft_3b_phase1_cloud.yaml        # phase 1 config (CUDA, flash_attn fa2, relative paths)
    sft_3b_phase2_cloud.yaml        # phase 2 config (warm-starts phase1, uses v2 dataset)
    system.txt                      # system prompt used in all Alpaca rows

scripts/sft/
    cloud_train.sh                  # one-shot setup + train script (run this on the box)
    eval_transbench.py              # optional: transbench pass@1 eval (needs benchmarks/ dir)
    run_heldout_eval.py             # optional: quick 14-pair held-out eval (no bench needed)

# Base model — auto-downloaded from HuggingFace during training (no token required):
#   Qwen/Qwen2.5-Coder-3B-Instruct  (~6 GB, public)
```

### Optional (for in-box eval)
```
benchmarks/transpilation-bench/     # rsync only if you want eval_transbench.py to run
```

---

## Exact rsync command (run locally before SSHing)

```bash
# On your LOCAL machine (Linux/macOS/WSL):
BOX_IP=<your-box-ip>   # e.g. 123.45.67.89
BOX_USER=root          # RunPod / Lambda default
REMOTE=/workspace/transpilers

rsync -avz --progress \
  --include='data/sft/cpp_mojo/train_translation_v2.jsonl' \
  --include='data/sft/cpp_mojo/train_translation.jsonl' \
  --include='data/sft/cpp_mojo/mojo_acquisition.json' \
  --include='data/sft/cpp_mojo/dataset_info.json' \
  --include='data/sft/cpp_mojo/sft_3b_phase1_cloud.yaml' \
  --include='data/sft/cpp_mojo/sft_3b_phase2_cloud.yaml' \
  --include='data/sft/cpp_mojo/system.txt' \
  --include='data/' \
  --include='data/sft/' \
  --include='data/sft/cpp_mojo/' \
  --include='scripts/' \
  --include='scripts/sft/' \
  --include='scripts/sft/cloud_train.sh' \
  --include='scripts/sft/eval_transbench.py' \
  --include='scripts/sft/run_heldout_eval.py' \
  --exclude='*' \
  /c/Github/transpilers/ \
  ${BOX_USER}@${BOX_IP}:${REMOTE}/
```

Or, simpler — rsync the whole repo minus large non-essentials:

```bash
rsync -avz --progress \
  --exclude='.git/' \
  --exclude='__pycache__/' \
  --exclude='*.pyc' \
  --exclude='adapter_*/' \
  --exclude='heldout_*.json' \
  --exclude='diverse_*.json' \
  /c/Github/transpilers/ \
  ${BOX_USER}@${BOX_IP}:${REMOTE}/
```

---

## One command once on the box

```bash
ssh ${BOX_USER}@${BOX_IP} "cd ${REMOTE} && bash scripts/sft/cloud_train.sh"
```

This is idempotent. Re-running skips already-installed deps and re-trains from scratch
(overwrite_output_dir: true in the yamls).

---

## What the script does

1. `nvidia-smi` sanity — confirms GPU is visible
2. Creates `.venv/` (Python venv) if not present
3. `pip install torch --index-url https://download.pytorch.org/whl/cu124` — CUDA 12.4 wheel
4. `pip install llamafactory[torch,metrics]` + transformers / peft / accelerate / bitsandbytes
5. `pip install flash-attn --no-build-isolation` — only if GPU compute cap ≥ 8.0 (Ampere+)
6. Registers `data/sft/cpp_mojo/dataset_info.json` entries into LLaMA-Factory's registry
7. `llamafactory-cli train data/sft/cpp_mojo/sft_3b_phase1_cloud.yaml` (~30–60 min)
8. `llamafactory-cli train data/sft/cpp_mojo/sft_3b_phase2_cloud.yaml` (~40–80 min)
9. Runs `eval_transbench.py` if `benchmarks/` dir is present
10. Prints rsync command to pull the adapter back

---

## Pull the adapter back

```bash
rsync -avz ${BOX_USER}@${BOX_IP}:${REMOTE}/out/adapter_3b/ \
  /c/Github/transpilers/data/sft/cpp_mojo/adapter_3b_v1/
```

Then terminate the box immediately (billing stops on terminate, not stop, on RunPod/Vast).

---

## CUDA / PyTorch version chosen

| Component | Version | Why |
|---|---|---|
| CUDA wheel index | `cu124` (CUDA 12.4) | Current stable as of mid-2025; works on all NVIDIA GPUs from Ampere onward. Fall back to `cu121` if the instance template only ships CUDA 12.1. |
| PyTorch | latest from the cu124 index (2.5.x) | Installed from `download.pytorch.org/whl/cu124`. |
| flash-attn | latest | Installed only on Ampere+ (compute cap ≥ 8.0). The script auto-patches the yaml to `flash_attn: sdpa` on older GPUs. |
| transformers | ≥ 4.46.0 | Required for Qwen2.5 chat template |
| peft | ≥ 0.14.0 | LoRA target: all support |

---

## Estimated cost and time

| GPU | VRAM | Est. time (2-phase) | Est. cost |
|---|---|---|---|
| A10 (24 GB) | 24 GB | ~1.5 hr | ~$0.75–1.20 (RunPod/Vast ~$0.5–0.8/hr) |
| L4 (24 GB) | 24 GB | ~1.5 hr | ~$0.75–1.20 |
| A100 40 GB | 40 GB | ~1 hr | ~$1.40–2.00 (~$1.4/hr) |
| A100 80 GB | 80 GB | ~1 hr | ~$2.00–3.00 (~$2/hr) |

**Rule of thumb: ~$2–4 for the full 3B two-phase run on an A10/A100.**
Add ~5 min for dep installation on first run. Subsequent runs skip installed deps.

---

## 7B scaling note

To scale to the 7B model on the same scripts:

**GPU requirements:**
- Full bf16 LoRA: 48–80 GB VRAM (A100 80GB / H100)
- QLoRA 4-bit (recommended for 24 GB): A10 24 GB or A100 40 GB

**Config changes** (copy the cloud yamls, change these keys):

```yaml
# In both sft_3b_phase1_cloud.yaml and sft_3b_phase2_cloud.yaml:
model_name_or_path: Qwen/Qwen2.5-Coder-7B-Instruct

# For QLoRA on 24 GB (A10/L4):
quantization_bit: 4
quantization_type: bitsandbytes   # NF4 — works on CUDA; the AMD hang does NOT apply here

# Optionally reduce batch size if OOM:
per_device_train_batch_size: 1
gradient_accumulation_steps: 8
```

A reference config already exists at `data/sft/cpp_mojo/qwen7b_qlora.yaml` — use it as
the starting point and apply the cloud path + flash_attn fixes from the 3B cloud yamls.

**Cost / time:** 7B QLoRA on A10 ≈ 2–3 hr per phase (~$2–4 total on A10).
Full bf16 LoRA on A100 80 GB ≈ 1.5–2 hr per phase (~$6–8 total).

---

## Drift check vs docs/cloud_training.md

`docs/cloud_training.md` (Option B, §B.2) still references the old WSL paths
(`/home/bart/Github/transpilers/...`) and recommends running `sed -i` to repoint them.
The cloud yamls in this bundle make that manual step unnecessary — paths are already
relative (`./data/sft/cpp_mojo`, `./out/adapter_3b`).

The existing doc also suggests `cu121`; this bundle uses `cu124` (current stable, 2025).
Both work; `cu124` is preferred for A100 80GB / H100 to get full BF16 throughput.

`docs/cloud_training.md` mentions the held-out eval as
`uv run python scripts/sft/run_heldout_eval.py --tag ft` — still valid after pulling
the adapter back locally. `cloud_train.sh` runs `eval_transbench.py` in-box if the
bench dir is present (more comprehensive than heldout_eval for a cloud run).
