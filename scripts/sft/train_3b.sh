set -euo pipefail

export TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL=1
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

log "Probing GPU availability..."
python3 - <<'PY'
import torch, time
assert torch.cuda.is_available(), "CUDA not available"
x = torch.randn(2048, 2048, device="cuda", dtype=torch.bfloat16)
y = torch.mm(x, x)
torch.cuda.synchronize()
free, total = torch.cuda.mem_get_info()
print(f"GPU OK: {torch.cuda.get_device_name(0)}, free={free/1e9:.1f}GB / total={total/1e9:.1f}GB")
PY

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
train = [e for e in entries if "loss" in e]
if train:
    first = train[0]
    last  = train[-1]
    print(f"  Steps: {len(train)}")
    print(f"  First loss: {first.get('loss','?'):.4f} (step {first.get('current_steps','?')})")
    print(f"  Final loss: {last.get('loss','?'):.4f}  (step {last.get('current_steps','?')})")
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
