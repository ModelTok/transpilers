set -euo pipefail

VENV="/root/venvs/lf61"
LF_SRC="/root/LLaMA-Factory"
ROCM_IDX="https://download.pytorch.org/whl/rocm6.1"
TORCH_VER="torch==2.6.0+rocm6.1"
TORCHVISION_VER="torchvision==0.21.0+rocm6.1"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

log "=== setup_lf61: creating $VENV ==="

if [ -d "$VENV" ]; then
    log "Removing existing $VENV ..."
    rm -rf "$VENV"
fi

log "Creating venv with $(python3 --version) ..."
python3 -m venv "$VENV"
source "$VENV/bin/activate"
log "  pip: $(pip --version)"

pip install --quiet --upgrade pip wheel setuptools

log "Installing $TORCH_VER from ROCm 6.1 index ..."
pip install \
    "$TORCH_VER" \
    "$TORCHVISION_VER" \
    --index-url "$ROCM_IDX" \
    --extra-index-url https://pypi.org/simple \
    --no-cache-dir

log "Smoke-test: torch import ..."
python3 -c "import torch; print('torch:', torch.__version__); print('HIP available:', torch.cuda.is_available())"

log "Installing LLaMA-Factory from $LF_SRC (editable) ..."
pip install \
    -e "$LF_SRC" \
    --extra-index-url "$ROCM_IDX" \
    --no-cache-dir

log "Guard: verifying torch is still rocm6.1 ..."
INSTALLED_TORCH=$(python3 -c 'import torch; print(torch.__version__)')
if ! echo "$INSTALLED_TORCH" | grep -q "rocm6.1"; then
    echo "ABORT: torch was overwritten by LF install! Got: $INSTALLED_TORCH"
    echo "Expected: 2.6.0+rocm6.1"
    exit 1
fi
log "  [OK] torch: $INSTALLED_TORCH"

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
