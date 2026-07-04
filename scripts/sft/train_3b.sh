#!/usr/bin/env bash
# train_3b.sh — two-phase LoRA training for Qwen2.5-Coder-3B-Instruct.
#
# Runs Phase 1 (mojo_acquisition, 2 epochs) and Phase 2
# (cpp_mojo_translation, 4 epochs).  Captures loss logs, wall-clock, and
# peak VRAM for each phase.
#
# ROCm fix: sets TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL=1 and both YAMLs
# set flash_attn: disabled + gradient_checkpointing: false to bypass the
# experimental SDPA backward pass that hangs on RDNA3 (gfx1101).
#
# Usage (from WSL Ubuntu-24.04 as root, inside the transpilers repo):
#   bash scripts/sft/train_3b.sh 2>&1 | tee train_3b.log
#
# Output adapter: data/sft/cpp_mojo/adapter_3b_v1/
# Intermediate:   data/sft/cpp_mojo/adapter_3b_v1_phase1/
set -euo pipefail

# ROCm attention fix: enable experimental AoTriton kernels AND force eager attention
# via YAML (flash_attn: disabled).  Without this the SDPA backward pass hangs on
# RDNA3 (gfx1101) — the GPU sits at 0% util stuck at step 1.
export TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL=1
# Reduce VRAM fragmentation from repeated alloc/free cycles.
export PYTORCH_ALLOC_CONF=expandable_segments:True

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VENV="/root/venvs/lf"
LF="$VENV/bin/llamafactory-cli"
MIGRATE_LOG="/mnt/c/Github/transpilers/.migrate_leaves.log"
CFG_P1="$REPO/data/sft/cpp_mojo/sft_3b_phase1.yaml"
CFG_P2="$REPO/data/sft/cpp_mojo/sft_3b_phase2.yaml"
ADAPTER_P1="$REPO/data/sft/cpp_mojo/adapter_3b_v1_phase1"
ADAPTER_P2="$REPO/data/sft/cpp_mojo/adapter_3b_v1"
ADAPTER_15B="$REPO/data/sft/cpp_mojo/adapter_15b_v2"

source "$VENV/bin/activate"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

# ─── 1. Confirm GPU is free (quick VRAM probe via torch) ─────────────────────
# (migrate_py_leaves inference job already finished; GPU confirmed free.)
log "Probing GPU availability..."
python3 - <<'PY'
import torch, time
assert torch.cuda.is_available(), "CUDA not available"
# Quick matmul confirms the GPU is accessible
x = torch.randn(2048, 2048, device="cuda", dtype=torch.bfloat16)
y = torch.mm(x, x)
torch.cuda.synchronize()
free, total = torch.cuda.mem_get_info()
print(f"GPU OK: {torch.cuda.get_device_name(0)}, free={free/1e9:.1f}GB / total={total/1e9:.1f}GB")
PY

# ─── 2. Phase 1: mojo_acquisition (2 epochs) ──────────────────────────────────
log "=== PHASE 1: mojo_acquisition (2 epochs, LR=1.5e-4) ==="
T1_START=$(date +%s)

python3 - <<'PY'
import torch
torch.cuda.reset_peak_memory_stats()
print("Peak VRAM reset.")
PY

"$LF" train "$CFG_P1"

T1_END=$(date +%s)
T1_WALL=$(( T1_END - T1_START ))

python3 - <<'PY'
import torch
peak = torch.cuda.max_memory_allocated() / 1e9
reserved = torch.cuda.max_memory_reserved() / 1e9
print(f"Phase 1 peak VRAM allocated: {peak:.2f} GB, reserved: {reserved:.2f} GB")
PY

log "Phase 1 done in ${T1_WALL}s ($(( T1_WALL/60 ))m $(( T1_WALL%60 ))s). Adapter: $ADAPTER_P1"

# ─── 3. Phase 2: cpp_mojo_translation (4 epochs, lower LR) ───────────────────
log "=== PHASE 2: cpp_mojo_translation (4 epochs, LR=5e-5) ==="
T2_START=$(date +%s)

python3 - <<'PY'
import torch
torch.cuda.reset_peak_memory_stats()
print("Peak VRAM reset.")
PY

"$LF" train "$CFG_P2"

T2_END=$(date +%s)
T2_WALL=$(( T2_END - T2_START ))

python3 - <<'PY'
import torch
peak = torch.cuda.max_memory_allocated() / 1e9
reserved = torch.cuda.max_memory_reserved() / 1e9
print(f"Phase 2 peak VRAM allocated: {peak:.2f} GB, reserved: {reserved:.2f} GB")
PY

log "Phase 2 done in ${T2_WALL}s ($(( T2_WALL/60 ))m $(( T2_WALL%60 ))s). Adapter: $ADAPTER_P2"

TOTAL_WALL=$(( T1_WALL + T2_WALL ))
log "Total training wall-clock: ${TOTAL_WALL}s ($(( TOTAL_WALL/60 ))m)"

# ─── 4. Print loss summaries from trainer_log.jsonl ──────────────────────────
log "=== LOSS SUMMARY ==="
for phase in phase1 ""; do
    dir="$REPO/data/sft/cpp_mojo/adapter_3b_v1${phase:+_$phase}"
    logfile="$dir/trainer_log.jsonl"
    if [ -f "$logfile" ]; then
        label="${phase:-phase2 (final)}"
        echo "--- Phase $label ---"
        python3 - "$logfile" <<'PY'
import json, sys
entries = [json.loads(l) for l in open(sys.argv[1]) if l.strip()]
# Filter to training loss entries (have 'loss' key)
train = [e for e in entries if "loss" in e]
if train:
    first = train[0]
    last  = train[-1]
    print(f"  Steps: {len(train)}")
    print(f"  First loss: {first.get('loss','?'):.4f} (step {first.get('current_steps','?')})")
    print(f"  Final loss: {last.get('loss','?'):.4f}  (step {last.get('current_steps','?')})")
    # Show every ~10% of training
    step = max(1, len(train)//10)
    print("  Curve (every ~10%):", " ".join(f"{e['loss']:.3f}" for e in train[::step]))
else:
    print("  (no loss entries found)")
PY
    else
        echo "  $dir/trainer_log.jsonl not found"
    fi
done

log "Training complete. Final adapter at: $ADAPTER_P2"
log ""
log "Next step: run eval_transbench.py on both adapters (see train_3b_eval.sh)"
