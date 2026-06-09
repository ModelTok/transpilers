#!/usr/bin/env bash
# train_3b_rocm7.sh — two-phase LoRA training using the lf7 venv (torch 2.10.0+rocm7.0).
#
# ROCm7 venv: /root/venvs/lf7 (torch 2.10.0+rocm7.0, newer roctracer bundled).
# Hypothesis: rocm7.0 ships a fixed libroctracer64.so that no longer deadlocks
# libhsa-runtime64.so → libroctracer64.so in the autograd backward pass on gfx1101.
#
# YAMLs are UNCHANGED from train_3b.sh:
#   sft_3b_phase1.yaml / sft_3b_phase2.yaml already set:
#     flash_attn: disabled, use_unsloth_gc: false, use_reentrant_gc: false
#
# DO NOT RUN until after: wsl --shutdown (from Windows PowerShell)
# GPU context is corrupted (SDMAQueue assertion) — requires WSL restart first.
#
# Verification criterion: steps must advance past ~10 at sane it/s (>0.05 it/s).
# Any hang at step <=3 = roctracer bug still present; report exact stack.
#
# Usage (from WSL Ubuntu-24.04 as root, after WSL restart):
#   bash /mnt/c/Github/transpilers/scripts/sft/train_3b_rocm7.sh 2>&1 | tee /mnt/c/Github/transpilers/train_3b_rocm7.log
set -euo pipefail

# ROCm attention fix: enable experimental AoTriton kernels + force eager attention
# via YAML (flash_attn: disabled).
export TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL=1
# Reduce VRAM fragmentation from repeated alloc/free cycles.
export PYTORCH_ALLOC_CONF=expandable_segments:True

REPO="/home/bart/Github/transpilers"
VENV="/root/venvs/lf7"
LF="$VENV/bin/llamafactory-cli"
CFG_P1="$REPO/data/sft/cpp_mojo/sft_3b_phase1.yaml"
CFG_P2="$REPO/data/sft/cpp_mojo/sft_3b_phase2.yaml"
ADAPTER_P1="$REPO/data/sft/cpp_mojo/adapter_3b_v1_phase1"
ADAPTER_P2="$REPO/data/sft/cpp_mojo/adapter_3b_v1"

source "$VENV/bin/activate"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

# ─── Sanity: confirm rocm7 torch and NOT lf (rocm6.4) venv ──────────────────
log "Venv: $VENV"
TORCH_VER=$(python -c 'import torch; print(torch.__version__)')
log "torch: $TORCH_VER"
if ! echo "$TORCH_VER" | grep -q "rocm7"; then
    echo "ERROR: Expected rocm7.0 torch, got $TORCH_VER. Wrong venv activated?"
    exit 1
fi
log "  [OK] rocm7 confirmed"

# ─── 1. GPU probe (CPU-path only — GPU may need WSL restart) ─────────────────
log "Checking torch.cuda.is_available() with 10s timeout ..."
timeout 10 python3 -c "
import torch
avail = torch.cuda.is_available()
print(f'cuda available: {avail}')
if avail:
    print(f'device: {torch.cuda.get_device_name(0)}')
" 2>&1 || log "  cuda check timed out or failed — continuing (GPU test deferred)"

# ─── 2. Phase 1: mojo_acquisition (2 epochs) ─────────────────────────────────
log "=== PHASE 1: mojo_acquisition (2 epochs, LR=1.5e-4) ==="
T1_START=$(date +%s)
"$LF" train "$CFG_P1"
T1_END=$(date +%s)
T1_WALL=$(( T1_END - T1_START ))
log "Phase 1 done in ${T1_WALL}s ($(( T1_WALL/60 ))m $(( T1_WALL%60 ))s). Adapter: $ADAPTER_P1"

# ─── 3. Phase 2: cpp_mojo_translation (4 epochs, lower LR) ──────────────────
log "=== PHASE 2: cpp_mojo_translation (4 epochs, LR=5e-5) ==="
T2_START=$(date +%s)
"$LF" train "$CFG_P2"
T2_END=$(date +%s)
T2_WALL=$(( T2_END - T2_START ))
log "Phase 2 done in ${T2_WALL}s ($(( T2_WALL/60 ))m $(( T2_WALL%60 ))s). Adapter: $ADAPTER_P2"

TOTAL_WALL=$(( T1_WALL + T2_WALL ))
log "Total training wall-clock: ${TOTAL_WALL}s ($(( TOTAL_WALL/60 ))m)"

# ─── 4. Loss summary ─────────────────────────────────────────────────────────
log "=== LOSS SUMMARY ==="
for dir in "$ADAPTER_P1" "$ADAPTER_P2"; do
    logfile="$dir/trainer_log.jsonl"
    label=$(basename "$dir")
    if [ -f "$logfile" ]; then
        echo "--- $label ---"
        python3 - "$logfile" <<'PY'
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
