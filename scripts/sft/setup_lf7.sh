#!/usr/bin/env bash
# setup_lf7.sh — create /root/venvs/lf7 with torch+rocm7.0 and training stack.
#
# SAFE: does NOT touch /root/venvs/lf (live inference + migrate_py_leaves job).
# GPU calls are intentionally omitted: GPU context is corrupted (SDMAQueue
# assertion). CPU-only import checks only. GPU testing deferred to post-WSL-restart.
#
# Usage (from WSL Ubuntu-24.04 as root):
#   bash /mnt/c/Github/transpilers/scripts/sft/setup_lf7.sh 2>&1 | tee /tmp/setup_lf7.log
set -euo pipefail

LF7="/root/venvs/lf7"
LF_SRC="/root/venvs/lf"
LF_FACTORY_SRC="/root/LLaMA-Factory"
ROCM7_INDEX="https://download.pytorch.org/whl/rocm7.0"
TORCH_VER="2.10.0+rocm7.0"
TORCHVISION_VER="0.25.0+rocm7.0"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

# ── 0. Safety guard: confirm lf venv is untouched ───────────────────────────
log "Guard: confirming lf venv is intact..."
test -f "$LF_SRC/bin/llamafactory-cli" || { echo "ERROR: lf venv missing"; exit 1; }
test -d "$LF_FACTORY_SRC" || { echo "ERROR: LLaMA-Factory source missing"; exit 1; }
log "lf venv OK: $($LF_SRC/bin/python -c 'import torch; print(torch.__version__)' 2>/dev/null || echo 'import deferred')"

# ── 1. Create fresh venv at /root/venvs/lf7 ──────────────────────────────────
log "Creating venv at $LF7 ..."
if [ -d "$LF7" ]; then
    log "  $LF7 already exists — removing and recreating."
    rm -rf "$LF7"
fi
python3 -m venv "$LF7"
source "$LF7/bin/activate"
log "Python: $(python --version)"
pip install --upgrade pip --quiet

# ── 2. Install torch+rocm7.0 and matching torchvision FIRST ─────────────────
# Do this first so LF's dep resolution sees them already installed.
log "Installing torch==$TORCH_VER and torchvision==$TORCHVISION_VER from $ROCM7_INDEX ..."
pip install \
    "torch==$TORCH_VER" \
    "torchvision==$TORCHVISION_VER" \
    --index-url "$ROCM7_INDEX"

log "torch installed: $(python -c 'import torch; print(torch.__version__)')"

python - <<'PY'
import torch
ver = torch.__version__
assert "rocm7" in ver, f"Expected rocm7.0 build, got: {ver}"
print(f"  [OK] torch={ver}")
PY

# ── 3. Install training stack matching lf venv versions ──────────────────────
log "Installing transformers==5.6.0, peft==0.18.1, accelerate==1.11.0 ..."
pip install \
    "transformers==5.6.0" \
    "peft==0.18.1" \
    "accelerate==1.11.0" \
    --quiet

# ── 4. Install LLaMA-Factory editable ────────────────────────────────────────
# torch is already pinned; LF will see torch>=2.x satisfied and not upgrade.
log "Installing LLaMA-Factory (editable) from $LF_FACTORY_SRC ..."
pip install -e "$LF_FACTORY_SRC" --quiet

# ── 5. Guard: re-confirm torch is still rocm7 after LF install ───────────────
log "Re-checking torch version post-LF install..."
TORCH_ACTUAL=$(python -c 'import torch; print(torch.__version__)')
log "torch: $TORCH_ACTUAL"
if echo "$TORCH_ACTUAL" | grep -q "rocm7"; then
    log "  [OK] rocm7 intact"
else
    log "  WARNING: LF overwrote torch with $TORCH_ACTUAL — force-reinstalling rocm7..."
    pip install \
        "torch==$TORCH_VER" \
        "torchvision==$TORCHVISION_VER" \
        --index-url "$ROCM7_INDEX" \
        --force-reinstall
    log "  torch after fix: $(python -c 'import torch; print(torch.__version__)')"
fi

# ── 6. Install numpy ──────────────────────────────────────────────────────────
log "Installing numpy ..."
pip install numpy --quiet

# ── 7. CPU-only import sanity (NO GPU ops) ───────────────────────────────────
log "=== CPU-ONLY IMPORT CHECKS (no GPU ops) ==="

python - <<'PY'
import torch
ver = torch.__version__
print(f"torch: {ver}")
assert "rocm7" in ver, f"Expected rocm7.0 build, got: {ver}"
print("  [OK] torch version is +rocm7.0")

import transformers
print(f"transformers: {transformers.__version__}")

import peft
print(f"peft: {peft.__version__}")

import accelerate
print(f"accelerate: {accelerate.__version__}")

import llamafactory
print(f"llamafactory: imported OK")

print("\n[ALL CPU IMPORTS PASSED]")
PY

# ── 8. llamafactory-cli sanity ────────────────────────────────────────────────
log "=== llamafactory-cli version ==="
"$LF7/bin/llamafactory-cli" version 2>&1 | head -5

# ── 9. Disk usage ─────────────────────────────────────────────────────────────
log "=== DISK USAGE ==="
du -sh "$LF7" 2>/dev/null || true

log "setup_lf7.sh complete. lf7 venv ready at $LF7"
log "GPU testing deferred — run after: wsl --shutdown (from Windows PowerShell)"
