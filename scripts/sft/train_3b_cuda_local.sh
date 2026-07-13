#!/usr/bin/env bash
# train_3b_cuda_local.sh — two-phase LoRA fine-tune of Qwen2.5-Coder-3B-Instruct
# for C++/Python -> Mojo migration (issue #41/#57), running LOCALLY on an
# NVIDIA GPU via CUDA (not the ROCm/WSL path the other train_3b*.sh assume).
#
# Targeted at this box: NVIDIA GeForce RTX 5060 Ti (16 GB, Blackwell
# compute cap 12.0, driver 610.x, CUDA 12.8 runtime).
#
# Why a separate script from train_3b.sh / train_3b_rocm7.sh:
#   * those assume ROCm torch (rocm6.4/7.0) in /root/venvs/lf and the
#     RDNA3 roctracer deadlock workarounds (flash_attn: disabled,
#     use_unsloth_gc: false, TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL=1).
#   * this box is NVIDIA + Blackwell sm_120. flash-attn has NO prebuilt
#     wheel for sm_120, so we use PyTorch-native SDPA (flash_attn: sdpa)
#     — no source compile, no deadlock. torch is installed from the cu128
#     index (the wheel that matches the 610 driver here; cu124/cu121 would
#     mismatch the installed CUDA runtime).
#   * 16 GB VRAM fits 3B bf16 LoRA (~8 GB per the phase configs); no
#     QLoRA needed. (7B would need QLoRA — use train_7b.sh QLORA=1.)
#
# Usage (git-bash on Windows, RTX 5060 Ti):
#   bash scripts/sft/train_3b_cuda_local.sh 2>&1 | tee train_3b_cuda_local.log
#
# Env overrides:
#   SKIP_INSTALL=1   assume venv deps already present (re-runs / warm box)
#   CUDA_WHEEL=cu128  torch wheel index (default cu128; matches driver 610)
#
# Verification criterion: steps must advance past ~10 at sane it/s; the loss
# summary at the end should show a decreasing curve. Any hang at step <=3 or
# torch.cuda.is_available() == False => report (bad wheel / no GPU).
set -euo pipefail

# CRITICAL (git-bash / Windows): the hermes runtime exports PYTHONPATH
# pointing at ITS OWN venv's site-packages. A `python -m venv` here is
# fine, but bare `pip`/`python` afterwards resolve to that leaked venv and
# install/import into the WRONG place (and `activate` doesn't reliably
# prepend on PATH in this shell). Unset it so the local venv is self-
# contained, and drive every pip call with the venv's ABSOLUTE python.
unset PYTHONPATH || true

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG="$REPO/train_3b_cuda_local.log"
VENV="$REPO/.venv_cuda"
VENV_PY="$VENV/Scripts/python.exe"   # Windows venv (git-bash); fallback below
[ -x "$VENV_PY" ] || VENV_PY="$VENV/bin/python"
DATA="$REPO/data/sft/cpp_mojo"
OUT="$REPO/out"
CUDA_WHEEL="${CUDA_WHEEL:-cu128}"
SKIP_INSTALL="${SKIP_INSTALL:-0}"

CFG_P1="$DATA/sft_3b_cuda_local_phase1.yaml"
CFG_P2="$DATA/sft_3b_cuda_local_phase2.yaml"
ADAPTER_P1="$OUT/adapter_3b_cuda_phase1"
ADAPTER_P2="$OUT/adapter_3b_cuda"

# LLaMA-Factory's CLI is a NATIVE Windows exe (llamafactory-cli.exe), so it
# needs Windows-style paths (C:\...), NOT the MSYS /c/... form this bash
# script otherwise uses. Convert the paths that get written into the yamls
# (dataset_dir / output_dir / adapter_name_or_path) and the train arg.
REPO_W=$(cygpath -w "$REPO")
DATA_W=$(cygpath -w "$DATA")
OUT_W=$(cygpath -w "$OUT")
CFG_P1_W=$(cygpath -w "$CFG_P1")
CFG_P2_W=$(cygpath -w "$CFG_P2")
ADAPTER_P1_W=$(cygpath -w "$ADAPTER_P1")
ADAPTER_P2_W=$(cygpath -w "$ADAPTER_P2")

# Activate the venv in a cross-platform way. On Windows/git-bash `python -m
# venv` produces Scripts/activate (not bin/); on Linux it is bin/activate.
if [ -f "$VENV/Scripts/activate" ]; then
    ACTIVATE="$VENV/Scripts/activate"
elif [ -f "$VENV/bin/activate" ]; then
    ACTIVATE="$VENV/bin/activate"
else
    ACTIVATE=""
fi

exec > >(tee -a "$LOG") 2>&1
echo "========================================================"
echo "train_3b_cuda_local.sh  $(date -u '+%Y-%m-%dT%H:%M:%SZ')  CUDA_WHEEL=$CUDA_WHEEL"
echo "repo: $REPO"
echo "========================================================"

# ── 1. GPU sanity (local RTX 5060 Ti) ──────────────────────────────
echo ""; echo "--- GPU sanity (nvidia-smi) ---"
nvidia-smi --query-gpu=name,memory.total,driver_version,compute_cap \
          --format=csv,noheader || {
    echo "ERROR: nvidia-smi failed. Is an NVIDIA GPU present?" >&2; exit 1; }

# ── 2. venv + deps (CUDA / Blackwell) ─────────────────────────────
# Pin the venv to Python 3.13: dill (used by LLaMA-Factory's dataset cache)
# is incompatible with CPython 3.14's Pickler signature, so 3.14 breaks the
# cache save. 3.13 is the highest dill-compatible interpreter on this box.
PY313="${PY313:-/c/Users/model/AppData/Local/Programs/Python/Python313/python.exe}"
if [ ! -x "$VENV_PY" ]; then
    if [ -x "$PY313" ]; then
        "$PY313" -m venv "$VENV"
    else
        python3 -m venv "$VENV"
    fi
fi
echo "Python: $("$VENV_PY" --version)"

if [ "$SKIP_INSTALL" != "1" ]; then
    echo ""; echo "--- Installing PyTorch ($CUDA_WHEEL) + LLaMA-Factory + ML deps ---"
    if ! "$VENV_PY" -c "import torch; assert torch.cuda.is_available()" 2>/dev/null; then
        # Use the venv's ABSOLUTE python (never bare pip) so the hermes
        # runtime's PYTHONPATH leakage can't redirect installs elsewhere.
        "$VENV_PY" -m pip install --quiet torch torchvision torchaudio \
            --index-url "https://download.pytorch.org/whl/$CUDA_WHEEL"
    fi
    if [ ! -x "$VENV/Scripts/llamafactory-cli.exe" ] && [ ! -x "$VENV/bin/llamafactory-cli" ]; then
        if [ -d "$REPO/LLaMA-Factory" ]; then
            "$VENV_PY" -m pip install --quiet -e "$REPO/LLaMA-Factory[torch,metrics]"
        else
            # Pin transformers==4.53.2: llamafactory's dep tree can otherwise
            # resolve transformers 5.x, which conflicts with lemonade-sdk.
            "$VENV_PY" -m pip install --quiet "llamafactory[torch,metrics]" "transformers==4.53.2" \
                "peft==0.14.0" "accelerate>=1.0.0" \
                datasets bitsandbytes tensorboard tqdm scipy
        fi
    fi
fi

# ── 3. attention backend: native SDPA (Blackwell sm_120 has no
#       flash-attn prebuilt wheel). Do NOT pip-install flash-attn here. ─────
COMPUTE_CAP=$(nvidia-smi --query-gpu=compute_cap --format=csv,noheader 2>/dev/null | head -1 | tr -d '.')
echo ""; echo "--- compute cap: $COMPUTE_CAP (using PyTorch SDPA, not flash-attn) ---"

# ── 4. torch CUDA check ──────────────────────────────────────────────
echo ""; echo "--- PyTorch CUDA check ---"
"$VENV_PY" - <<'PY'
import torch, sys
if not torch.cuda.is_available():
    print("ERROR: torch.cuda.is_available() == False", file=sys.stderr); sys.exit(1)
print(f"torch {torch.__version__}  CUDA {torch.version.cuda}")
p = torch.cuda.get_device_properties(0)
print(f"GPU 0: {p.name}  ({p.total_memory // 1024**3} GB)")
x = torch.randn(2048, 2048, device="cuda", dtype=torch.bfloat16)
_ = torch.mm(x, x)
torch.cuda.synchronize()
print("GPU compute OK")
PY

# ── 5. generate the CUDA-local yamls (repo-relative paths, sdpa) ───────
mkdir -p "$DATA" "$OUT"
echo ""; echo "--- writing CUDA-local yamls (paths -> $REPO) ---"
cat > "$CFG_P1" <<YAML
### model
model_name_or_path: Qwen/Qwen2.5-Coder-3B-Instruct
trust_remote_code: true
# Plain bf16 LoRA (no QLoRA): 3B*bf16 ~6GB + LoRA ~120MB + optim ~240MB
# + activations(GC) ~1.5GB = ~8GB, fits the 16GB RTX 5060 Ti.

### attention (NVIDIA Blackwell sm_120 — native SDPA, NO flash-attn compile)
# flash-attn has no prebuilt wheel for sm_120; PyTorch SDPA is built-in.
flash_attn: sdpa
use_unsloth_gc: false
use_reentrant_gc: false

### method
stage: sft
do_train: true
finetuning_type: lora
lora_rank: 16
lora_alpha: 32
lora_dropout: 0.05
lora_target: all

### dataset
dataset_dir: ${DATA_W}
dataset: mojo_acquisition
template: qwen
cutoff_len: 4096
overwrite_cache: true
preprocessing_num_workers: 4

### output
output_dir: ${ADAPTER_P1_W}
logging_steps: 5
save_strategy: epoch
plot_loss: true
overwrite_output_dir: true
report_to: tensorboard

### train
per_device_train_batch_size: 1
gradient_accumulation_steps: 8
gradient_checkpointing: true
learning_rate: 1.5e-4
num_train_epochs: 2.0
lr_scheduler_type: cosine
warmup_ratio: 0.05
bf16: true
YAML

cat > "$CFG_P2" <<YAML
### model
model_name_or_path: Qwen/Qwen2.5-Coder-3B-Instruct
trust_remote_code: true
# Warm-start from Phase 1 adapter (teaches Mojo idioms first).
adapter_name_or_path: ${ADAPTER_P1_W}
# Plain bf16 LoRA, fits 16GB.

### attention (NVIDIA Blackwell sm_120 — native SDPA)
flash_attn: sdpa
use_unsloth_gc: false
use_reentrant_gc: false

### method
stage: sft
do_train: true
finetuning_type: lora
lora_rank: 16
lora_alpha: 32
lora_dropout: 0.05
lora_target: all

### dataset
dataset_dir: ${DATA_W}
dataset: cpp_mojo_translation
template: qwen
cutoff_len: 4096
overwrite_cache: true
preprocessing_num_workers: 4

### output
output_dir: ${ADAPTER_P2_W}
logging_steps: 5
save_strategy: epoch
plot_loss: true
overwrite_output_dir: true
report_to: tensorboard

### train
per_device_train_batch_size: 1
gradient_accumulation_steps: 8
gradient_checkpointing: true
learning_rate: 5e-5
num_train_epochs: 4.0
lr_scheduler_type: cosine
warmup_ratio: 0.05
bf16: true
YAML
echo "wrote $CFG_P1 and $CFG_P2"

# ── 6. Train (two-phase) ───────────────────────────────────────────────────
LF="$VENV/Scripts/llamafactory-cli.exe"
[ -x "$LF" ] || LF="$VENV/bin/llamafactory-cli"
log() { echo "[$(date '+%H:%M:%S')] $*"; }

log "=== PHASE 1: mojo_acquisition (2 epochs, LR=1.5e-4) ==="
T1_START=$(date +%s)
"$VENV_PY" -c "import torch; torch.cuda.reset_peak_memory_stats()"
"$LF" train "$CFG_P1_W"
T1_END=$(date +%s)
T1_WALL=$(( T1_END - T1_START ))
"$VENV_PY" - <<'PY'
import torch
peak = torch.cuda.max_memory_allocated() / 1e9
print(f"Phase 1 peak VRAM allocated: {peak:.2f} GB")
PY
log "Phase 1 done in ${T1_WALL}s ($(( T1_WALL/60 ))m $(( T1_WALL%60 ))s). Adapter: $ADAPTER_P1"

log "=== PHASE 2: cpp_mojo_translation (4 epochs, LR=5e-5) ==="
T2_START=$(date +%s)
"$VENV_PY" -c "import torch; torch.cuda.reset_peak_memory_stats()"
"$LF" train "$CFG_P2_W"
T2_END=$(date +%s)
T2_WALL=$(( T2_END - T2_START ))
"$VENV_PY" - <<'PY'
import torch
peak = torch.cuda.max_memory_allocated() / 1e9
print(f"Phase 2 peak VRAM allocated: {peak:.2f} GB")
PY
log "Phase 2 done in ${T2_WALL}s ($(( T2_WALL/60 ))m $(( T2_WALL%60 ))s). Adapter: $ADAPTER_P2"

TOTAL_WALL=$(( T1_WALL + T2_WALL ))
log "Total training wall-clock: ${TOTAL_WALL}s ($(( TOTAL_WALL/60 ))m)"

# ── 7. Loss summary ───────────────────────────────────────────────────
log "=== LOSS SUMMARY ==="
# Use Windows-native adapter paths (the llamafactory-cli.exe is a native
# Windows exe and wrote the trainer_log.jsonl under the Windows path).
for dir in "$ADAPTER_P1_W" "$ADAPTER_P2_W"; do
    logfile="$dir/trainer_log.jsonl"
    label=$(basename "$dir")
    if [ -f "$logfile" ]; then
        echo "--- $label ---"
        "$VENV_PY" - "$logfile" <<'PY'
import json, sys
entries = [json.loads(l) for l in open(sys.argv[1]) if l.strip()]
train = [e for e in entries if "loss" in e]
if train:
    first, last = train[0], train[-1]
    print(f"  Steps: {len(train)}")
    print(f"  First loss: {first.get('loss','?'):.4f} (step {first.get('current_steps','?')})")
    print(f"  Final loss: {last.get('loss','?'):.4f}  (step {last.get('current_steps','?')})")
    step = max(1, len(train)//10)
    print("  Curve:", " ".join(f"{e['loss']:.3f}" for e in train[::step]))
else:
    print("  (no loss entries found)")
PY
    else
        echo "  $logfile not found"
    fi
done

log "Training complete. Final adapter at: $ADAPTER_P2"
