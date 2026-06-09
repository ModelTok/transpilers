# Cloud training runbook — 3B (then 7B) LoRA for C++/Python→Mojo

**Why this exists:** local training on the RX 7700 XT (gfx1101 / RDNA3) is blocked by a
confirmed **PyTorch + ROCm backward-pass deadlock** — the autograd checkpoint backward
hangs in `pthread_cond_wait` (libhsa-runtime64 → libroctracer64) and NF4/bitsandbytes
reports `ROCM avail: False`. A `rocm7` retry is staged but may also fail. This runbook moves
training to a CUDA box (Option B, recommended) or a managed Replicate job (Option A), where
the AMD bug simply does not exist.

> **Status: STAGED, not executed.** Nothing here has been run. Pick an option, supply the
> "what you must provide" items, then execute top-to-bottom.

---

## What's already ready (no rebuild needed)

| Artifact | Path | Notes |
|---|---|---|
| Translation set | `data/sft/cpp_mojo/train_translation.jsonl` | 1005 verified C++/Python→Mojo pairs (Alpaca schema) |
| Mojo acquisition set | `data/sft/cpp_mojo/mojo_acquisition.json` | 1163 Mojo-target examples (teach target language) |
| Dataset registry | `data/sft/cpp_mojo/dataset_info.json` | maps `cpp_mojo_translation` + `mojo_acquisition` columns |
| Phase-1 config | `data/sft/cpp_mojo/sft_3b_phase1.yaml` | bf16 LoRA r16/a32, base `Qwen/Qwen2.5-Coder-3B-Instruct`, 2 epochs on `mojo_acquisition` |
| Phase-2 config | `data/sft/cpp_mojo/sft_3b_phase2.yaml` | warm-starts from phase-1 adapter, 4 epochs on `cpp_mojo_translation`, LR 5e-5 |
| Reference adapter | `data/sft/cpp_mojo/adapter_15b_v2/` | shipped 1.5B LoRA (~70 MB) — sanity baseline |
| Held-out metric | `data/sft/cpp_mojo/heldout_eval.jsonl` | 14 C++→Mojo pairs, **excluded from training** — the only number that matters |

**Two-phase recipe** (from `RUN.md` / dataset `README.md`): phase 1 teaches Mojo syntax,
phase 2 specializes on translation warm-started from the phase-1 adapter. Both configs are
already wired for this.

### One edit the configs need on cloud
The shipped configs hard-code WSL absolute paths (`/home/bart/Github/transpilers/...`) and the
ROCm deadlock workarounds. On a CUDA box, before running:

- Set `dataset_dir:` and `output_dir:` (and phase-2 `adapter_name_or_path:`) to the cloud
  paths where you rsync the data (e.g. `/workspace/transpilers/data/sft/cpp_mojo`).
- The ROCm-specific keys are harmless on CUDA but you may simplify:
  `flash_attn: disabled` → `flash_attn: fa2` (faster on Ampere+; optional),
  `use_unsloth_gc`/`use_reentrant_gc` can stay false. Keep `bf16: true`,
  `gradient_checkpointing: true`.

---

## Option A — Replicate (managed training job)

Best if you want zero box-babysitting and you're **already standing up Replicate for the
inference swarm** — the same trained model can do double duty: serve the swarm *and* be the
artifact you pull back here. Replicate runs training via a **Cog** package (a `cog.yaml` +
`predict.py`/`train.py`) and returns the trained weights as a downloadable artifact.

### A.1 Files to upload / bundle into the Cog
- `data/sft/cpp_mojo/train_translation.jsonl`
- `data/sft/cpp_mojo/mojo_acquisition.json`
- `data/sft/cpp_mojo/dataset_info.json`
- `data/sft/cpp_mojo/sft_3b_phase1.yaml`, `sft_3b_phase2.yaml` (with paths pointed at the
  in-container data dir)
- `data/sft/cpp_mojo/system.txt`

### A.2 Cog package shape
Create `cog.yaml` + a `train.py` that shells out to LLaMA-Factory:

```yaml
# cog.yaml
build:
  gpu: true
  cuda: "12.1"
  python_version: "3.11"
  python_packages:
    - "torch==2.4.0"            # CUDA wheel (Replicate provides the CUDA base image)
    - "llamafactory"           # or: git+https://github.com/hiyouga/LLaMA-Factory.git
    - "transformers"
    - "peft"
    - "accelerate"
    - "datasets"
    - "bitsandbytes"           # only needed for the 7B QLoRA pass
train: "train.py:train"
```

```python
# train.py  (Cog training entrypoint — sketch)
from cog import BaseModel, Input, Path
import subprocess, shutil, os

class TrainingOutput(BaseModel):
    weights: Path

def train(
    phase: str = Input(default="both", choices=["phase1", "phase2", "both"]),
) -> TrainingOutput:
    data = "/src/data/sft/cpp_mojo"
    if phase in ("phase1", "both"):
        subprocess.run(["llamafactory-cli", "train",
                        f"{data}/sft_3b_phase1.yaml"], check=True)
    if phase in ("phase2", "both"):
        subprocess.run(["llamafactory-cli", "train",
                        f"{data}/sft_3b_phase2.yaml"], check=True)
    # zip the final adapter (phase-2 output_dir) and return it
    out = "/tmp/adapter_3b_v1"
    shutil.make_archive(out, "zip", f"{data}/adapter_3b_v1")
    return TrainingOutput(weights=Path(out + ".zip"))
```

### A.3 Run it
```bash
# from a machine with the Cog CLI + your Replicate token
export REPLICATE_API_TOKEN=...                 # you provide this
cog login
cog push r8.im/<your-username>/cpp-mojo-trainer    # builds + pushes the image

# kick a training run (CLI or the Python client)
replicate train <your-username>/cpp-mojo-trainer \
  --destination <your-username>/cpp-mojo-3b \
  -i phase=both
```

### A.4 Pull the adapter back
```bash
# the run's output `weights` is a downloadable URL; grab it and unzip into the repo
curl -L -o adapter_3b_v1.zip "<output-url-from-the-run>"
unzip adapter_3b_v1.zip -d data/sft/cpp_mojo/adapter_3b_v1
```

### A.5 Cost ballpark (Replicate)
Replicate bills per-second of GPU time. A **3B LoRA** two-phase run is ~1–2 GPU-hours.
- Nvidia A40 (48 GB): ~$0.05–0.10 / min → **~$3–10** for the full run.
- Nvidia A100 (80 GB): ~$0.14 / min → **~$10–18**.
Add a few minutes of build time on the first `cog push`. Idle = $0 (jobs are ephemeral).
**Double-duty note:** if the swarm already runs an inference deployment on Replicate, the
trained adapter you push here is the same artifact that deployment serves — one image, two jobs.

---

## Option B — Raw cloud GPU (RunPod / Lambda / Vast) — RECOMMENDED

Rent a single **NVIDIA** box (A10 / L4 / A100). CUDA sidesteps the entire ROCm RDNA3
backward-pass bug. This is the simplest path: SSH in, install, rsync, run, download.

### B.1 Pick a box
- **3B LoRA (bf16):** A10 (24 GB) or L4 (24 GB) is plenty. ~$0.5–0.8/hr (RunPod/Vast).
- **7B QLoRA (4-bit):** A100 40 GB or A10 24 GB with QLoRA. ~$1–2/hr.
Choose a PyTorch/CUDA template (e.g. RunPod "PyTorch 2.4 / CUDA 12.1") so torch is preinstalled.

### B.2 Command sequence (run on the box)
```bash
# --- 0. (on the box) sanity: confirm CUDA torch sees the GPU ---
python -c "import torch; print(torch.cuda.is_available(), torch.cuda.get_device_name(0))"

# --- 1. deps (skip torch if the template already ships a CUDA build) ---
pip install --index-url https://download.pytorch.org/whl/cu121 torch   # CUDA wheel, NOT rocm
pip install "llamafactory[torch,metrics]"     # or: git clone hiyouga/LLaMA-Factory && pip install -e .
pip install transformers peft accelerate datasets bitsandbytes

# --- 2. from your LOCAL machine: push the dataset + configs to the box ---
#     (run THIS block locally, not on the box)
rsync -avz --progress \
  /c/Github/transpilers/data/sft/cpp_mojo/ \
  root@<BOX_IP>:/workspace/transpilers/data/sft/cpp_mojo/
#   (Windows: use `wsl rsync ...`, scp -r, or `runpodctl send`.)

# --- 3. (on the box) point the configs at the box paths ---
cd /workspace/transpilers/data/sft/cpp_mojo
sed -i 's#/home/bart/Github/transpilers#/workspace/transpilers#g' sft_3b_phase1.yaml sft_3b_phase2.yaml

# --- 4. (on the box) train: phase 1 (Mojo acquisition) then phase 2 (translation) ---
llamafactory-cli train sft_3b_phase1.yaml      # -> adapter_3b_v1_phase1/   (~30–60 min)
llamafactory-cli train sft_3b_phase2.yaml      # warm-starts phase1 -> adapter_3b_v1/  (~30–60 min)

# --- 5. (on the box) quick sanity on the held-out metric BEFORE you tear down ---
#     serve the adapter + run the only number that matters (C++->Mojo pass@1):
#     uv run python scripts/sft/run_heldout_eval.py --tag ft
```

### B.3 Download the adapter back
```bash
# from your LOCAL machine
rsync -avz root@<BOX_IP>:/workspace/transpilers/data/sft/cpp_mojo/adapter_3b_v1/ \
  /c/Github/transpilers/data/sft/cpp_mojo/adapter_3b_v1/
# then TERMINATE the box (billing stops only on terminate, not stop, on most providers).
```

### B.4 Scaling to 7B
Swap the base model and switch to QLoRA to fit/accelerate:
- `model_name_or_path: Qwen/Qwen2.5-Coder-7B-Instruct`
- add `quantization_bit: 4` + `quantization_type: bitsandbytes` (works on CUDA — the AMD
  NF4 hang does not apply here)
- A100 40 GB recommended; ~1–2 hr for the two-phase run. Reference `qwen7b_qlora.yaml` in the
  dataset dir for the QLoRA knobs.

---

## What you (the user) must provide

1. **Choice of option:** A (Replicate, managed) or B (raw NVIDIA box) — **B is recommended**.
2. **Credentials:**
   - Option A: a `REPLICATE_API_TOKEN` and a Replicate account/destination model name.
   - Option B: a RunPod / Lambda / Vast account + SSH key, and the box's IP after you rent it.
   - Either: a **HuggingFace token** if the Qwen base ever gates (it currently doesn't).
3. **Budget sign-off:** ~$3–18 (Replicate) or ~$1–2/hr × ~1–2 hr (raw GPU) for the 3B run;
   roughly 2× for the 7B QLoRA pass.
4. **Target:** 3B first (configs are ready), then 7B (swap base + QLoRA per §B.4).

## Recommendation

**Go with Option B (raw NVIDIA cloud GPU).** It's the simplest and cheapest path: CUDA
sidesteps the entire ROCm RDNA3 deadlock that blocks local training, the existing
`sft_3b_phase1/phase2.yaml` configs run almost unchanged (just repoint paths), and the whole
two-phase 3B run is **~$1–2/hr for ~1–2 hr (≈$2–4 total)**. Use Option A (Replicate) only if
you're already deploying the inference swarm there and want the trained model to do
double duty as a managed, redeployable artifact.
```
