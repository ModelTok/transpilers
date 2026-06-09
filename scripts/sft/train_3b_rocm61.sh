#!/usr/bin/env bash
# train_3b_rocm61.sh — two-phase LoRA training using the lf61 venv
# (torch 2.6.0+rocm6.1).
#
# Hypothesis: ROCm 6.1 ships an older libroctracer64.so that does NOT trigger
# the async HIP completion callback deadlock seen in 6.4 on gfx1101 RDNA3.
# (rocm7.0 was already ruled out: its wheel cannot detect the GPU on a 6.4
# driver system.)
#
# YAMLs are UNCHANGED from previous attempts — already hardened:
#   sft_3b_phase1.yaml / sft_3b_phase2.yaml set:
#     flash_attn: disabled
#     use_unsloth_gc: false   ← prevents non_blocking async HIP copy in backward
#     use_reentrant_gc: false
#     No quantization_bit / quantization_type (plain bf16 — bnb broken on rocm)
#
# VERDICT criterion (DO NOT call success until verified):
#   SUCCESS = step counter advances PAST 10 at <20s/step, GPU busy.
#   FAILURE = hung at step <=3, CPU at 2000-4000%, no step progress.
#
# Usage (from WSL Ubuntu-24.04 as root, lf61 venv already set up):
#   bash /mnt/c/Github/transpilers/scripts/sft/train_3b_rocm61.sh \
#       2>&1 | tee /mnt/c/Github/transpilers/train_3b_rocm61.log
set -euo pipefail

# ROCm experimental kernels + reduce VRAM fragmentation
export TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL=1
export PYTORCH_ALLOC_CONF=expandable_segments:True
# Keep roctracer quiet during backward — belt-and-suspenders
export HSA_ENABLE_INTERRUPT=0

REPO="/home/bart/Github/transpilers"
VENV="/root/venvs/lf61"
LF="$VENV/bin/llamafactory-cli"
CFG_P1="$REPO/data/sft/cpp_mojo/sft_3b_phase1.yaml"
CFG_P2="$REPO/data/sft/cpp_mojo/sft_3b_phase2.yaml"
ADAPTER_P1="$REPO/data/sft/cpp_mojo/adapter_3b_v1_phase1"
ADAPTER_P2="$REPO/data/sft/cpp_mojo/adapter_3b_v1"

source "$VENV/bin/activate"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

# ─── Sanity: confirm rocm6.1 torch ───────────────────────────────────────────
log "Venv: $VENV"
TORCH_VER=$(python3 -c 'import torch; print(torch.__version__)')
log "torch: $TORCH_VER"
if ! echo "$TORCH_VER" | grep -q "rocm6.1"; then
    echo "ERROR: Expected rocm6.1 torch, got $TORCH_VER. Wrong venv or overwritten?"
    exit 1
fi
log "  [OK] rocm6.1 confirmed"

# ─── 1. GPU probe ─────────────────────────────────────────────────────────────
log "--- GPU probe ---"
GPU_CHECK=$(timeout 15 python3 -c "
import torch, sys
avail = torch.cuda.is_available()
print(f'cuda available: {avail}')
if avail:
    print(f'device: {torch.cuda.get_device_name(0)}')
    mem = torch.cuda.mem_get_info()
    print(f'VRAM free/total: {mem[0]//1024**2} MB / {mem[1]//1024**2} MB')
else:
    print('No HIP GPUs available — STOP', file=sys.stderr)
    sys.exit(2)
" 2>&1) || GPU_EXIT=$?

echo "$GPU_CHECK"

if echo "$GPU_CHECK" | grep -q "No HIP GPUs available"; then
    log "STOP: GPU not detected by rocm6.1 torch — cloud is the answer."
    exit 2
fi

if ! echo "$GPU_CHECK" | grep -q "cuda available: True"; then
    log "STOP: GPU check failed or timed out."
    exit 2
fi
log "  [OK] GPU detected"

# ─── 2. Forward-only matmul sanity (no backward, just tests GPU is alive) ────
log "--- 2048x2048 matmul (forward) ---"
timeout 30 python3 -c "
import torch, time
a = torch.randn(2048, 2048, dtype=torch.bfloat16, device='cuda')
b = torch.randn(2048, 2048, dtype=torch.bfloat16, device='cuda')
torch.cuda.synchronize()
t0 = time.time()
c = a @ b
torch.cuda.synchronize()
print(f'matmul done in {time.time()-t0:.3f}s, result sum={c.sum().item():.2f}')
" 2>&1
log "  [OK] matmul passed"

# ─── 3. Phase 1: mojo_acquisition (2 epochs) ─────────────────────────────────
log "=== PHASE 1: mojo_acquisition (2 epochs, LR=1.5e-4) ==="
log "VERDICT: watching for step counter to advance past 10 at <20s/step ..."
T1_START=$(date +%s)
"$LF" train "$CFG_P1"
T1_END=$(date +%s)
T1_WALL=$(( T1_END - T1_START ))
log "Phase 1 done in ${T1_WALL}s ($(( T1_WALL/60 ))m $(( T1_WALL%60 ))s). Adapter: $ADAPTER_P1"

# ─── 4. Phase 2: cpp_mojo_translation (4 epochs, lower LR) ──────────────────
log "=== PHASE 2: cpp_mojo_translation (4 epochs, LR=5e-5) ==="
T2_START=$(date +%s)
"$LF" train "$CFG_P2"
T2_END=$(date +%s)
T2_WALL=$(( T2_END - T2_START ))
log "Phase 2 done in ${T2_WALL}s ($(( T2_WALL/60 ))m $(( T2_WALL%60 ))s). Adapter: $ADAPTER_P2"

TOTAL_WALL=$(( T1_WALL + T2_WALL ))
log "Total training wall-clock: ${TOTAL_WALL}s ($(( TOTAL_WALL/60 ))m)"

# ─── 5. Loss summary ─────────────────────────────────────────────────────────
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
