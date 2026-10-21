# NVIDIA training bundle

Trains the C++->Mojo LoRA on any NVIDIA GPU (a local card or a rented box).
Train -> take the adapter -> EVAL LOCALLY (the Mojo verify-gate is local).

## Speed (LoRA, this dataset)

Earlier estimates, not re-measured:

| GPU            | 0.5B (2ep) | 1.5B (2ep) | 7B (2ep) |
|----------------|-----------|-----------|----------|
| RTX 4090       | ~6-10 min | ~15-25 min| ~1-1.5h  |
| A100 80GB      | ~4-6 min  | ~10-15 min| ~30-45 min |

## Steps

1. Get a machine with an NVIDIA GPU and a CUDA build of PyTorch (RTX 4090 is plenty
   for <=1.5B; an A100-class card for 7B).
2. Copy this `cloud/` folder over (or `git clone` the repo and `cd tools/cloud`).
3. `MODEL=Qwen/Qwen2.5-Coder-1.5B-Instruct ./run.sh`
   (swap MODEL for -0.5B / -3B / -7B; set `FLASH=1` for flash-attention on Ampere+)
4. Collect `adapter.tgz`.
5. Locally: `tar xzf adapter.tgz -C data/sft/cpp_mojo/` then
   `mv data/sft/cpp_mojo/adapter data/sft/cpp_mojo/adapter_<tag>` and run
   `eval_05b.py` / `eval_diverse.py` / `migrate.py` against it (Mojo toolchain is local).

For the LLaMA-Factory two-phase recipe use `scripts/sft/train_3b_cuda_local.sh` (local
NVIDIA) or `scripts/sft/cloud_train.sh` (fresh NVIDIA box); see `scripts/sft/cloud_bundle.md`.

## Notes
- Script is CUDA-native (bf16).
- Same data + recipe as the local frozen-ruler runs, so results are comparable
  (eval on the local frozen_diverse held-out for an apples-to-apples number).
- The data/ here is the current frozen training pool; refresh it by re-copying
  data/sft/cpp_mojo/train_translation.jsonl + mojo_acquisition.json before upload.
