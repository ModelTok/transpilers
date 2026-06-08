# Cloud training bundle (RunPod / any NVIDIA GPU)

Trains the C++->Mojo LoRA on a fast cloud GPU, ~10-30x the local iGPU.
Train on cloud -> download adapter -> EVAL LOCALLY (the Mojo verify-gate is local).

## Speed (LoRA, this dataset)
| GPU            | 0.5B (2ep) | 1.5B (2ep) | 7B (2ep) |
|----------------|-----------|-----------|----------|
| iGPU 890M      | ~2.6h     | ~6h       | infeasible |
| RTX 4090       | ~6-10 min | ~15-25 min| ~1-1.5h  |
| A100 80GB      | ~4-6 min  | ~10-15 min| ~30-45 min |

## Steps
1. RunPod -> Deploy a **PyTorch** pod (RTX 4090 is plenty for <=1.5B; A100 for 7B).
2. Upload this `cloud/` folder (or `git clone` your repo and `cd cloud`).
3. `MODEL=Qwen/Qwen2.5-Coder-1.5B-Instruct ./run.sh`
   (swap MODEL for -0.5B / -3B / -7B; set `FLASH=1` for flash-attention on Ampere+)
4. Download `adapter.tgz`.
5. Locally: `tar xzf adapter.tgz -C data/sft/cpp_mojo/` then
   `mv data/sft/cpp_mojo/adapter data/sft/cpp_mojo/adapter_<tag>` and run
   `eval_05b.py` / `eval_diverse.py` / `migrate.py` against it (Mojo toolchain is local).

## Notes
- Script is CUDA-native (bf16). No ROCm/HSA env needed.
- Same data + recipe as the local frozen-ruler runs, so results are comparable
  (eval on the local frozen_diverse held-out for an apples-to-apples number).
- The data/ here is the current frozen training pool; refresh it by re-copying
  data/sft/cpp_mojo/train_translation.jsonl + mojo_acquisition.json before upload.
