# Finetuning Qwen2.5-Coder-7B for C++/Python → Mojo (issue #41)

A complete, runnable LoRA finetune of **Qwen2.5-Coder-7B-Instruct** on the
repo's verified C++/Python→Mojo SFT corpus, ready to launch on a GPU box. This
is the 7B scale-up of the proven two-phase 3B recipe (`scripts/sft/cloud_train.sh`).

> This recipe was authored and validated for *launch-readiness* (configs parse,
> dataset registration matches `dataset_info.json`, launcher passes `bash -n`).
> The actual GPU run is not executed here — run it on the box per the steps below.

## TL;DR

```bash
# On a fresh Ubuntu + NVIDIA box, from the repo root:
bash scripts/sft/train_7b.sh                 # A100/H100: bf16 LoRA, two phases
bash QLORA=1 scripts/sft/train_7b.sh         # 24 GB card: 4-bit QLoRA, single phase
```

Final adapter lands in `out/adapter_7b/` (bf16) or
`saves/Qwen2.5-Coder-7B-Instruct/lora/` (QLoRA).

## Hardware

| GPU VRAM | Recipe | Config | Notes |
|----------|--------|--------|-------|
| 40–80 GB (A100/H100) | bf16 LoRA, 2-phase | `sft_7b_phase1_cloud.yaml` + `sft_7b_phase2_cloud.yaml` | best quality, cutoff 4096 |
| 24 GB (A10/L4/4090)  | 4-bit QLoRA, 1-phase | `qwen7b_qlora.yaml` (`QLORA=1`) | cutoff 1024 to fit activations |
| < 16 GB | — | — | too small for 7B; use the 3B recipe |

The launcher auto-detects VRAM and warns if bf16 won't fit, and patches
`flash_attn: fa2 → sdpa` automatically on pre-Ampere GPUs (compute cap < 8.0).

## What it trains on

Datasets are registered from `data/sft/cpp_mojo/dataset_info.json` (the launcher
merges them into LLaMA-Factory's `dataset_info.json` with absolute paths):

- **Phase 1 — `mojo_acquisition`** (`mojo_acquisition.json`, ~1163 samples):
  teach idiomatic Mojo. 2 epochs, LR 1.5e-4.
- **Phase 2 — `cpp_mojo_translation_v2`** (`train_translation_v2.jsonl`, ~1065
  verified pairs): specialize for translation, warm-started from the Phase 1
  adapter. 4 epochs, LR 5e-5 (lower, to avoid forgetting Mojo idioms).

Both use `template: qwen` and the columns
`prompt=instruction / query=input / response=output` (+`system` for Phase 2).

To also fold in the new #57 algorithm pairs, append the `data/sft/algorithms/`
JSONL files as additional datasets in `dataset_info.json` and add their names to
the `dataset:` list in the Phase 2 YAML.

## Hyperparameters

LoRA r=16, α=32, dropout=0.05, `lora_target: all`, bf16, cosine schedule,
warmup 5%, gradient checkpointing on (essential for 7B). Effective batch = 8
(`per_device=1 × grad_accum=8`); raise `per_device_train_batch_size` to 2–4 on
80 GB. These mirror the 3B configs that produced the live adapters.

## Files

| path | purpose |
|------|---------|
| `scripts/sft/train_7b.sh` | one-shot launcher: GPU check → deps → register → 2-phase train → eval hint |
| `data/sft/cpp_mojo/sft_7b_phase1_cloud.yaml` | Phase 1 (Mojo acquisition), bf16 LoRA |
| `data/sft/cpp_mojo/sft_7b_phase2_cloud.yaml` | Phase 2 (translation), warm-start |
| `data/sft/cpp_mojo/qwen7b_qlora.yaml` | 4-bit QLoRA fallback for 24 GB cards (pre-existing) |

## Manual run (without the launcher)

```bash
pip install "llamafactory[torch,metrics]" "transformers>=4.46" "peft>=0.14" accelerate datasets bitsandbytes
# register datasets (see the inline python in train_7b.sh), then:
llamafactory-cli train data/sft/cpp_mojo/sft_7b_phase1_cloud.yaml
llamafactory-cli train data/sft/cpp_mojo/sft_7b_phase2_cloud.yaml
```

## Evaluate

After training, score against the frozen benchmark:

```bash
python3 scripts/sft/eval_transbench.py --adapter out/adapter_7b
```

Compare the 7B `pass@1` to the 3B baseline to decide whether the scale-up earns
its cost (the north-star metric from #56).
