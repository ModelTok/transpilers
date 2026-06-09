# Cloud training bundle (RunPod / any NVIDIA GPU)

Trains the C++->Mojo LoRA on a fast cloud GPU, ~10-30x the local iGPU.
Train on cloud -> download adapter -> EVAL LOCALLY (the Mojo verify-gate is local).

## Speed (LoRA, this dataset)
| GPU            | 0.5B (2ep) | 1.5B (2ep) | 7B (2ep) |
|----------------|-----------|-----------|----------|
| iGPU 890M      | ~2.6h     | ~6h       | infeasible |
| RTX 4090       | ~6-10 min | ~15-25 min| ~1-1.5h  |
| A100 80GB      | ~4-6 min  | ~10-15 min| ~30-45 min |

## Automated (RunPod API) — one command

`runpod_train.py` does the whole loop for you: provision a pod by GPU type ->
push this bundle -> run training with live logs -> download `adapter.tgz` ->
**auto-terminate the pod** (guaranteed via `finally`, even on crash or Ctrl-C, so
a failed run never leaves a GPU billing). It drives `train.py` / `run.sh`
unchanged.

Prereqs:
1. `export RUNPOD_API_KEY=...` (get it from RunPod console -> Settings -> API Keys).
2. Register your SSH **public** key in RunPod account settings (Settings -> SSH Keys).
   Default private key: `~/.ssh/id_ed25519` (override with `--ssh-key`).
3. `pip install -r orchestrator-requirements.txt` (local; separate from the pod-side `requirements.txt`).

Usage:
```
# free preview: validate key, resolve GPU id, print the pod spec, create nothing
python runpod_train.py --gpu 4090 --dry-run

# cheapest real end-to-end smoke (~minutes, ~$0.10), auto-terminates
python runpod_train.py --model Qwen/Qwen2.5-Coder-0.5B-Instruct --gpu 4090 \
    --epochs 1 --tr-up 1 --acq-n 20

# a real run: 7B in full bf16 on an A40, extract the adapter locally when done
python runpod_train.py --model Qwen/Qwen2.5-Coder-7B-Instruct --gpu a40 --epochs 1 --extract
```

| `--gpu` | RunPod gpu_type_id |
|---------|--------------------|
| `4090`  | NVIDIA GeForce RTX 4090 |
| `a40`   | NVIDIA A40 |
| `a6000` | NVIDIA RTX A6000 |
| `a100`  | NVIDIA A100 80GB PCIe |
| `l40s`  | NVIDIA L40S |

IDs and image tags drift over time — use `--gpu-id "<raw id>"` and `--image "<tag>"`
to override. Training knobs (`--epochs --tr-up --acq-n --max-len --bs --ga --flash`)
are forwarded as env to `run.sh`; anything you omit falls back to `train.py`'s
defaults. The adapter lands in `tools/cloud/out/<model-tag>-<ts>/adapter.tgz`
(add `--extract` to also untar it into `data/sft/cpp_mojo/adapter_<tag>`).
`--keep-alive` skips teardown — then **you** must terminate the pod manually.

## Manual steps
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
