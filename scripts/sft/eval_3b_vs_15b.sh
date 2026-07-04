#!/usr/bin/env bash
# eval_3b_vs_15b.sh — compare 3B adapter vs 1.5B baseline on transpilation-bench.
#
# Runs eval_transbench.py for both adapters (pass@1, cpp_source) and prints a
# side-by-side summary. Run this after train_3b.sh completes.
#
# Usage (from WSL Ubuntu-24.04 as root):
#   bash scripts/sft/eval_3b_vs_15b.sh 2>&1 | tee eval_3b_vs_15b.log
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VENV="/root/venvs/lf"
SCRIPT="$REPO/scripts/sft/eval_transbench.py"
ADAPTER_15B="$REPO/data/sft/cpp_mojo/adapter_15b_v2"
ADAPTER_3B="$REPO/data/sft/cpp_mojo/adapter_3b_v1"

source "$VENV/bin/activate"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

# ─── Eval 1.5B baseline ───────────────────────────────────────────────────────
log "=== Evaluating 1.5B baseline (adapter_15b_v2) ==="
T_START=$(date +%s)

python3 - <<'PY'
import torch
torch.cuda.reset_peak_memory_stats()
PY

python3 "$SCRIPT" \
    --model  Qwen/Qwen2.5-Coder-1.5B-Instruct \
    --adapter "$ADAPTER_15B" \
    --source  cpp_source \
    --k 1 \
    2>&1 | tee /tmp/eval_15b.log

T1_WALL=$(( $(date +%s) - T_START ))

python3 - <<'PY'
import torch
peak = torch.cuda.max_memory_allocated() / 1e9
print(f"1.5B eval peak VRAM: {peak:.2f} GB")
PY

PASS_15B=$(grep -oP '(?<=pass@1: )\d+\.\d+(?=%)' /tmp/eval_15b.log || echo "?")
log "1.5B done in ${T1_WALL}s — pass@1 = ${PASS_15B}%"

# ─── Eval 3B new adapter ──────────────────────────────────────────────────────
log "=== Evaluating 3B new adapter (adapter_3b_v1) ==="
T_START=$(date +%s)

python3 - <<'PY'
import torch
torch.cuda.reset_peak_memory_stats()
PY

python3 "$SCRIPT" \
    --model  Qwen/Qwen2.5-Coder-3B-Instruct \
    --adapter "$ADAPTER_3B" \
    --source  cpp_source \
    --k 1 \
    2>&1 | tee /tmp/eval_3b.log

T2_WALL=$(( $(date +%s) - T_START ))

python3 - <<'PY'
import torch
peak = torch.cuda.max_memory_allocated() / 1e9
print(f"3B eval peak VRAM: {peak:.2f} GB")
PY

PASS_3B=$(grep -oP '(?<=pass@1: )\d+\.\d+(?=%)' /tmp/eval_3b.log || echo "?")
log "3B done in ${T2_WALL}s — pass@1 = ${PASS_3B}%"

# ─── Side-by-side summary ─────────────────────────────────────────────────────
echo ""
echo "====================================================="
echo "  TRANSPILATION-BENCH RESULTS (cpp_source -> Mojo)"
echo "====================================================="
echo ""
echo "  Model       Adapter           pass@1   eval time"
echo "  ----------  ----------------  -------  ---------"
printf "  Qwen 1.5B   adapter_15b_v2   %7s  %ds\n"   "${PASS_15B}%" "$T1_WALL"
printf "  Qwen 3B     adapter_3b_v1    %7s  %ds\n"   "${PASS_3B}%"  "$T2_WALL"
echo ""
echo "Tier breakdown (1.5B):"
grep "Tier" /tmp/eval_15b.log || true
echo ""
echo "Tier breakdown (3B):"
grep "Tier" /tmp/eval_3b.log || true
echo "====================================================="
