# Plan: Custom RunPod fine-tuning orchestrator (local Python CLI)

> Design doc for an automated RunPod training loop built on top of this `tools/cloud/` bundle.
> **Implemented** as `runpod_train.py` (+ `orchestrator-requirements.txt`, README section, `just
> cloud-train` recipe). Live RunPod end-to-end smoke (verification step 2) still pending — it needs
> a real `RUNPOD_API_KEY` and creates a billable pod, so run it manually.

## Context

This repo fine-tunes C++/Python→Mojo LoRA adapters. The local box (RX 7700 XT, 12 GB, ROCm/WSL)
can't fit 7B/12B without flaky QLoRA, so larger runs belong on cloud NVIDIA GPUs. This bundle
already has a **manual** cloud path:
- `train.py` — self-contained CUDA TRL `SFTTrainer` LoRA recipe (reads `./data/`, writes `./adapter/`;
  env-tuned via `MODEL/EPOCHS/TR_UP/ACQ_N/MAX_LEN/BS/GA/FLASH`; r=16/α=32/dropout=0.05/all-linear).
- `run.sh` — one-shot: `pip install -r requirements.txt` → `python train.py` → `tar adapter.tgz`.
- `data/` — frozen pool already present (`train_translation.jsonl`, `mojo_acquisition.json`).

Today this requires clicking through the RunPod UI, uploading, SSHing, and downloading by hand.

**Goal:** a **local Python CLI** that fully automates the loop via the RunPod API — provision a pod
by GPU type → push the bundle → run training (live logs) → download the adapter → **auto-terminate
the pod** — driving the *existing* `train.py`/`run.sh` unchanged. One command, no UI clicking, with
guaranteed teardown so a crash never leaves a GPU billing.

**Decisions locked in:** Full RunPod API automation · drive the existing custom `train.py` · local
Python CLI.

## Design

### New: `tools/cloud/runpod_train.py` — the orchestrator
Pure-local CLI (argparse). Reuses the bundle as-is; adds only provisioning + transport + lifecycle.

- **Auth:** reads `RUNPOD_API_KEY` (env); clear error if missing.
- **Args:** `--model` (default Qwen/Qwen2.5-Coder-1.5B-Instruct), `--gpu` (friendly: `4090|a40|a6000|a100|l40s`,
  mapped to RunPod `gpu_type_id`; `--gpu-id` raw override since IDs drift), `--epochs --tr-up --acq-n
  --max-len --bs --ga --flash` (forwarded as env to `run.sh`), `--cloud {secure,community}`, `--disk`
  (container GB, default 50), `--image` (default a `runpod/pytorch:*cuda12*` tag, overridable),
  `--ssh-key` (default `~/.ssh/id_ed25519`), `--keep-alive` (skip teardown), `--extract` (auto-untar
  into `data/sft/cpp_mojo/adapter_<tag>`), `--dry-run`.
- **Flow (wrapped in try/finally for guaranteed teardown):**
  1. `runpod.api_key=…`; `runpod.create_pod(image_name, gpu_type_id, gpu_count=1, container_disk_in_gb,
     ports="22/tcp", cloud_type, support_public_ip=True, start_ssh=True)`.
  2. Poll `runpod.get_pod(id)` until `RUNNING` and the SSH mapping (public ip:port for private 22)
     appears in `runtime.ports`; timeout + retry.
  3. **paramiko** SSH connect with the key; **scp** the whole `tools/cloud/` dir → `/workspace/cloud`.
  4. Exec `cd /workspace/cloud && MODEL=… EPOCHS=… … bash run.sh`, **streaming** stdout/stderr live to
     the local console; capture exit status.
  5. On success scp `/workspace/cloud/adapter.tgz` → `tools/cloud/out/<model-tag>-<ts>/adapter.tgz`
     (and untar to `data/sft/cpp_mojo/adapter_<tag>` if `--extract`).
  6. **finally:** unless `--keep-alive`, `runpod.terminate_pod(id)` and print a cost-safety
     confirmation — runs on success, failure, AND Ctrl-C.
- **GPU map** (friendly→id, e.g. `4090→"NVIDIA GeForce RTX 4090"`, `a40→"NVIDIA A40"`,
  `a100→"NVIDIA A100 80GB PCIe"`); `--gpu-id` bypasses the map.

### New: `tools/cloud/orchestrator-requirements.txt`
Local-only deps for the orchestrator: `runpod`, `paramiko`, `scp`. (Kept separate from the pod-side
`requirements.txt`, which stays the training deps installed *on the pod*.) All pure-python /
cross-platform → runs from Windows or WSL.

### Edit: `tools/cloud/README.md`
Add an **"Automated (RunPod API)"** section: prereqs (`RUNPOD_API_KEY`, add your SSH **public** key in
RunPod account settings, `pip install -r orchestrator-requirements.txt`), the one-command usage, the
GPU table, and the teardown-safety / `--keep-alive` note. Keep the existing manual steps below it.

### Optional (nicety): `justfile` recipe
A thin `cloud-train model="…" gpu="4090"` wrapper over the Python CLI, matching the repo's existing
`just` style. Non-core; include only if trivial.

## Files
- NEW `tools/cloud/runpod_train.py` (the orchestrator — the bulk of the work)
- NEW `tools/cloud/orchestrator-requirements.txt`
- EDIT `tools/cloud/README.md`
- REUSED UNCHANGED: `tools/cloud/train.py`, `tools/cloud/run.sh`, `tools/cloud/data/*`
- (optional) EDIT `justfile`

## Prerequisites the user provides
- `RUNPOD_API_KEY` in env.
- An SSH keypair whose **public** key is registered in RunPod account settings (for full SSH).
- `pip install -r tools/cloud/orchestrator-requirements.txt` locally.

## Verification
1. **`--dry-run`:** validates the API key, resolves the GPU id, prints the pod spec — no pod created (free).
2. **Live smoke (cheapest end-to-end):** `python tools/cloud/runpod_train.py --model
   Qwen/Qwen2.5-Coder-0.5B-Instruct --gpu 4090 --epochs 1 --tr-up 1 --acq-n 20` → provisions a 4090,
   runs a tiny train (~minutes, ~$0.10), downloads `adapter.tgz` locally, then auto-terminates.
   Confirm: adapter.tgz present locally; `get_pod` shows terminated (and RunPod console is clear).
3. **Cost-safety:** Ctrl-C mid-run → confirm the `finally` block terminates the pod (no orphaned GPU).
4. Then a real run: `--model Qwen/Qwen2.5-Coder-7B-Instruct --gpu a40 --epochs 1` (7B in full bf16 on
   48 GB — the run that OOM'd locally).

## Notes / risks
- **Real spend:** every non-dry-run creates a billable pod. Teardown is guaranteed via `finally`; the
  smoke test uses the smallest viable config.
- RunPod GPU-type IDs and image tags drift over time → `--gpu-id` and `--image` overrides included.
- SSH readiness lags pod `RUNNING`; the poll handles it with a timeout.
- Eval/verify stay local (the Mojo verify-gate is local), matching this bundle's existing
  "train on cloud → eval locally" model.
