#!/usr/bin/env bash
# setup_lf61.sh — Create /root/venvs/lf61 with torch 2.6.0+rocm6.1 and a
# compatible LLaMA-Factory training stack.
#
# Strategy:
#   1. Create fresh venv (Python 3.12)
#   2. Install torch 2.6.0+rocm6.1 + matching torchvision 0.21.0 FIRST
#   3. Install LLaMA-Factory editable from /root/LLaMA-Factory
#      (pyproject.toml requires torch>=2.4.0 — 2.6.0 satisfies; transformers
#       >=4.55.0,<=5.6.0; peft >=0.18.0,<=0.18.1; accelerate >=1.3.0,<=1.11.0)
#   4. Guard: re-verify torch is still 2.6.0+rocm6.1 (LF must not have pulled
#      a cuda/cpu wheel)
#
# Usage (as root in WSL Ubuntu-24.04):
#   bash /mnt/c/Github/transpilers/scripts/sft/setup_lf61.sh 2>&1 | tee /mnt/c/Github/transpilers/setup_lf61.log
set -euo pipefail

VENV="/root/venvs/lf61"
LF_SRC="/root/LLaMA-Factory"
ROCM_IDX="https://download.pytorch.org/whl/rocm6.1"
TORCH_VER="torch==2.6.0+rocm6.1"
TORCHVISION_VER="torchvision==0.21.0+rocm6.1"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

log "=== setup_lf61: creating $VENV ==="

# ─── 0. Remove any prior attempt ─────────────────────────────────────────────
if [ -d "$VENV" ]; then
    log "Removing existing $VENV ..."
    rm -rf "$VENV"
fi

# ─── 1. Create venv ───────────────────────────────────────────────────────────
log "Creating venv with $(python3 --version) ..."
python3 -m venv "$VENV"
source "$VENV/bin/activate"
log "  pip: $(pip --version)"

# ─── 2. Upgrade pip/wheel ─────────────────────────────────────────────────────
pip install --quiet --upgrade pip wheel setuptools

# ─── 3. Install torch 2.6.0+rocm6.1 (MUST come before LF to lock the version) ─
log "Installing $TORCH_VER from ROCm 6.1 index ..."
pip install \
    "$TORCH_VER" \
    "$TORCHVISION_VER" \
    --index-url "$ROCM_IDX" \
    --extra-index-url https://pypi.org/simple \
    --no-cache-dir

# Quick import smoke-test before the long LF install
log "Smoke-test: torch import ..."
python3 -c "import torch; print('torch:', torch.__version__); print('HIP available:', torch.cuda.is_available())"

# ─── 4. Install LLaMA-Factory (editable) ─────────────────────────────────────
# torch is already pinned in site-packages; pip will see it satisfies >=2.4.0
# and skip re-downloading a different torch.
# We explicitly pass --extra-index-url for PyPI so non-torch deps resolve.
log "Installing LLaMA-Factory from $LF_SRC (editable) ..."
pip install \
    -e "$LF_SRC" \
    --extra-index-url "$ROCM_IDX" \
    --no-cache-dir

# ─── 5. Guard: verify torch version was not overwritten ───────────────────────
log "Guard: verifying torch is still rocm6.1 ..."
INSTALLED_TORCH=$(python3 -c 'import torch; print(torch.__version__)')
if ! echo "$INSTALLED_TORCH" | grep -q "rocm6.1"; then
    echo "ABORT: torch was overwritten by LF install! Got: $INSTALLED_TORCH"
    echo "Expected: 2.6.0+rocm6.1"
    exit 1
fi
log "  [OK] torch: $INSTALLED_TORCH"

# ─── 6. Report installed stack ───────────────────────────────────────────────
log "=== Installed stack ==="
python3 -c "
import torch, transformers, peft, accelerate
try:
    import trl; trl_v = trl.__version__
except Exception: trl_v = 'N/A'
try:
    import llamafactory; lf_v = llamafactory.__version__
except Exception: lf_v = 'N/A'
print(f'  torch:        {torch.__version__}')
print(f'  transformers: {transformers.__version__}')
print(f'  peft:         {peft.__version__}')
print(f'  accelerate:   {accelerate.__version__}')
print(f'  trl:          {trl_v}')
print(f'  llamafactory: {lf_v}')
print(f'  cuda/HIP:     {torch.cuda.is_available()}')
"

log "llamafactory-cli: $VENV/bin/llamafactory-cli"
log "=== setup_lf61 DONE ==="
