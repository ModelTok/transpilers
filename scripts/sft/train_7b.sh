#!/usr/bin/env bash
# train_7b.sh — one-shot setup + two-phase LoRA finetune of Qwen2.5-Coder-7B
# for C++/Python -> Mojo (issue #41). The 7B sibling of cloud_train.sh.
#
# Run on a fresh Ubuntu + NVIDIA instance after rsync'ing the repo:
#   bash scripts/sft/train_7b.sh
#
# VRAM guidance:
#   * A100 40/80 GB or H100  -> bf16 LoRA (this script's default). Best quality.
#   * 24 GB (A10/L4/4090)    -> set QLORA=1 to use the 4-bit qwen7b_qlora.yaml
#                               (single-phase, cutoff 1024). bash QLORA=1 ... .
#   * <16 GB                 -> not enough for 7B; use the 3B recipe instead.
#
# Env overrides:
#   QLORA=1            use 4-bit QLoRA single-phase config instead of bf16 LoRA
#   SKIP_INSTALL=1     assume deps already present (re-runs / warm boxes)
#   CUDA_WHEEL=cu121   override the torch CUDA wheel index (default cu124)
#
# All output is tee'd to ./train_7b.log
set -euo pipefail

BUNDLE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG="$BUNDLE_ROOT/train_7b.log"
VENV="$BUNDLE_ROOT/.venv"
DATA="$BUNDLE_ROOT/data/sft/cpp_mojo"
OUT="$BUNDLE_ROOT/out"
QLORA="${QLORA:-0}"
SKIP_INSTALL="${SKIP_INSTALL:-0}"
CUDA_WHEEL="${CUDA_WHEEL:-cu124}"

exec > >(tee -a "$LOG") 2>&1
echo "========================================================"
echo "train_7b.sh  $(date -u '+%Y-%m-%dT%H:%M:%SZ')   QLORA=$QLORA"
echo "bundle root: $BUNDLE_ROOT"
echo "========================================================"

# ── 1. GPU sanity ────────────────────────────────────────────────────────────
echo ""; echo "--- GPU sanity (nvidia-smi) ---"
nvidia-smi --query-gpu=name,memory.total,driver_version,compute_cap \
           --format=csv,noheader || {
    echo "ERROR: nvidia-smi failed. Is this an NVIDIA GPU instance?" >&2; exit 1; }

VRAM_MB=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -1 | tr -d ' ')
if [ "$QLORA" != "1" ] && [ -n "$VRAM_MB" ] && [ "$VRAM_MB" -lt 38000 ] 2>/dev/null; then
    echo ""
    echo "WARNING: ${VRAM_MB} MB VRAM detected; bf16 LoRA on 7B wants ~40 GB+."
    echo "         Re-run with QLORA=1 for the 4-bit single-phase config, or use"
    echo "         a larger GPU. Continuing anyway (OOM is likely)."
fi

# ── 2. venv + deps ───────────────────────────────────────────────────────────
if [ ! -f "$VENV/bin/activate" ]; then python3 -m venv "$VENV"; fi
# shellcheck disable=SC1091
source "$VENV/bin/activate"
echo "Python: $(which python3)  $(python3 --version)"

if [ "$SKIP_INSTALL" != "1" ]; then
    echo ""; echo "--- Installing PyTorch ($CUDA_WHEEL) + LLaMA-Factory + ML deps ---"
    if ! python3 -c "import torch; assert torch.cuda.is_available()" 2>/dev/null; then
        pip install --quiet torch torchvision torchaudio \
            --index-url "https://download.pytorch.org/whl/$CUDA_WHEEL"
    fi
    if [ ! -f "$VENV/bin/llamafactory-cli" ]; then
        if [ -d "$BUNDLE_ROOT/LLaMA-Factory" ]; then
            pip install --quiet -e "$BUNDLE_ROOT/LLaMA-Factory[torch,metrics]"
        else
            pip install --quiet "llamafactory[torch,metrics]"
        fi
    fi
    pip install --quiet "transformers>=4.46.0" "peft>=0.14.0" "accelerate>=1.0.0" \
        datasets bitsandbytes tensorboard tqdm scipy
fi

# ── 3. flash-attn (Ampere+) or fall back to sdpa in the yamls ─────────────────
echo ""; echo "--- flash-attn ---"
COMPUTE_CAP=$(nvidia-smi --query-gpu=compute_cap --format=csv,noheader 2>/dev/null | head -1 | tr -d '.')
if [ -n "$COMPUTE_CAP" ] && [ "$COMPUTE_CAP" -ge 80 ] 2>/dev/null; then
    python3 -c "import flash_attn" 2>/dev/null \
        || pip install --quiet flash-attn --no-build-isolation || true
else
    echo "compute cap < 8.0 ($COMPUTE_CAP) — patching yamls to flash_attn: sdpa"
    sed -i 's/^flash_attn: fa2/flash_attn: sdpa/g' \
        "$DATA/sft_7b_phase1_cloud.yaml" "$DATA/sft_7b_phase2_cloud.yaml" || true
fi

# ── 4. torch CUDA check ──────────────────────────────────────────────────────
echo ""; echo "--- PyTorch CUDA check ---"
python3 - <<'PY'
import torch, sys
if not torch.cuda.is_available():
    print("ERROR: torch.cuda.is_available() == False", file=sys.stderr); sys.exit(1)
print(f"torch {torch.__version__}  CUDA {torch.version.cuda}")
p = torch.cuda.get_device_properties(0)
print(f"GPU 0: {p.name}  ({p.total_memory // 1024**3} GB)")
PY

# ── 5. Register datasets into LLaMA-Factory (reuse repo dataset_info.json) ─────
echo ""; echo "--- Registering datasets ---"
LF_DATA=$(python3 -c "
import importlib.util, pathlib
spec = importlib.util.find_spec('llamafactory')
print(pathlib.Path(spec.origin).parent.parent / 'data' / 'dataset_info.json') if spec and spec.origin else print('')
" 2>/dev/null || echo "")
if [ -n "$LF_DATA" ] && [ -f "$LF_DATA" ]; then
    python3 - "$DATA/dataset_info.json" "$DATA" "$LF_DATA" <<'PY'
import json, os, sys
src_info, data_dir, lf_info = sys.argv[1:4]
repo = json.load(open(src_info, encoding="utf-8"))
lf = json.load(open(lf_info, encoding="utf-8"))
for name, spec in repo.items():
    spec = dict(spec)
    fn = spec.get("file_name", "")
    if not os.path.isabs(fn):
        spec["file_name"] = os.path.join(data_dir, fn)
    lf[name] = spec
json.dump(lf, open(lf_info, "w", encoding="utf-8"), indent=2)
print(f"Registered {len(repo)} datasets into {lf_info}")
PY
else
    echo "LF data dir not found; relying on dataset_dir in the yamls."
fi

cd "$BUNDLE_ROOT"

# ── 6. Train ─────────────────────────────────────────────────────────────────
if [ "$QLORA" = "1" ]; then
    echo ""; echo "=== QLoRA (4-bit, single-phase) ==="
    llamafactory-cli train "$DATA/qwen7b_qlora.yaml"
    echo "QLoRA training complete. Adapter under saves/Qwen2.5-Coder-7B-Instruct/lora/"
else
    mkdir -p "$OUT/adapter_7b_phase1" "$OUT/adapter_7b"
    echo ""; echo "=== Phase 1: Mojo acquisition  $(date -u '+%H:%M:%SZ') ==="
    llamafactory-cli train "$DATA/sft_7b_phase1_cloud.yaml"
    echo "=== Phase 2: C++/Python->Mojo  $(date -u '+%H:%M:%SZ') ==="
    llamafactory-cli train "$DATA/sft_7b_phase2_cloud.yaml"
    echo "Done. Final adapter: $OUT/adapter_7b"
fi

# ── 7. Optional eval ─────────────────────────────────────────────────────────
BENCH="$BUNDLE_ROOT/benchmarks/transpilation-bench/benchmarks/tasks"
EVAL="$BUNDLE_ROOT/scripts/sft/eval_transbench.py"
if [ -d "$BENCH" ] && [ -f "$EVAL" ]; then
    echo ""; echo "--- benchmark dir present; run eval manually, e.g. ---"
    echo "  python3 scripts/sft/eval_transbench.py --adapter $OUT/adapter_7b"
fi
echo ""; echo "train_7b.sh finished  $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
