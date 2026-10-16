
set -euo pipefail

BUNDLE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG="$BUNDLE_ROOT/cloud_train.log"
VENV="$BUNDLE_ROOT/.venv"
DATA="$BUNDLE_ROOT/data/sft/cpp_mojo"
OUT="$BUNDLE_ROOT/out"

exec > >(tee -a "$LOG") 2>&1

echo "========================================================"
echo "cloud_train.sh  $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
echo "bundle root: $BUNDLE_ROOT"
echo "========================================================"

echo ""
echo "--- GPU sanity (nvidia-smi) ---"
nvidia-smi --query-gpu=name,memory.total,driver_version,compute_cap \
           --format=csv,noheader || {
    echo "ERROR: nvidia-smi failed. Is this an NVIDIA GPU instance?" >&2
    exit 1
}

echo ""
echo "--- Python venv ---"
if [ ! -f "$VENV/bin/activate" ]; then
    echo "Creating venv at $VENV"
    python3 -m venv "$VENV"
else
    echo "Venv already exists at $VENV — skipping creation"
fi
source "$VENV/bin/activate"
echo "Python: $(which python3)  $(python3 --version)"

echo ""
echo "--- Installing PyTorch (CUDA 12.4) + LLaMA-Factory + ML deps ---"
if ! python3 -c "import torch; assert torch.cuda.is_available()" 2>/dev/null; then
    echo "Installing PyTorch cu124..."
    pip install --quiet torch torchvision torchaudio \
        --index-url https://download.pytorch.org/whl/cu124
else
    echo "PyTorch with CUDA already installed — skipping torch install"
fi

if [ ! -f "$VENV/bin/llamafactory-cli" ]; then
    echo "Installing LLaMA-Factory..."
    if [ -d "$BUNDLE_ROOT/LLaMA-Factory" ]; then
        pip install --quiet -e "$BUNDLE_ROOT/LLaMA-Factory[torch,metrics]"
    else
        pip install --quiet "llamafactory[torch,metrics]"
    fi
else
    echo "llamafactory-cli already in venv — skipping"
fi

pip install --quiet \
    "transformers>=4.46.0" \
    "peft>=0.14.0" \
    "accelerate>=1.0.0" \
    datasets \
    bitsandbytes \
    tensorboard \
    tqdm \
    scipy

echo ""
echo "--- flash-attn ---"
COMPUTE_CAP=$(nvidia-smi --query-gpu=compute_cap --format=csv,noheader 2>/dev/null | head -1 | tr -d '.')
if [ -n "$COMPUTE_CAP" ] && [ "$COMPUTE_CAP" -ge 80 ] 2>/dev/null; then
    if python3 -c "import flash_attn" 2>/dev/null; then
        echo "flash-attn already installed — skipping"
    else
        echo "Ampere+ GPU detected (compute cap $COMPUTE_CAP), installing flash-attn..."
        pip install --quiet flash-attn --no-build-isolation
    fi
else
    echo "GPU compute cap < 8.0 or unknown ($COMPUTE_CAP) — skipping flash-attn."
    echo "  -> Edit the cloud yaml: change flash_attn: fa2  to  flash_attn: sdpa"
    sed -i 's/^flash_attn: fa2/flash_attn: sdpa/g' \
        "$DATA/sft_3b_phase1_cloud.yaml" \
        "$DATA/sft_3b_phase2_cloud.yaml"
    echo "  -> Patched cloud yamls: flash_attn set to sdpa"
fi

echo ""
echo "--- PyTorch CUDA check ---"
python3 - <<'PY'
import torch, sys
if not torch.cuda.is_available():
    print("ERROR: torch.cuda.is_available() == False", file=sys.stderr)
    sys.exit(1)
print(f"torch {torch.__version__}  CUDA {torch.version.cuda}")
print(f"GPU 0: {torch.cuda.get_device_name(0)}  ({torch.cuda.get_device_properties(0).total_memory // 1024**3} GB)")
PY

echo ""
echo "--- Registering datasets into LLaMA-Factory ---"
LF_DATA=$(python3 -c "
import importlib.util, pathlib
spec = importlib.util.find_spec('llamafactory')
if spec and spec.origin:
    p = pathlib.Path(spec.origin).parent.parent / 'data' / 'dataset_info.json'
    print(p)
" 2>/dev/null || echo "")

if [ -n "$LF_DATA" ] && [ -f "$LF_DATA" ]; then
    echo "Found LF dataset_info.json at: $LF_DATA"
    python3 - "$DATA/dataset_info.json" "$DATA" "$LF_DATA" <<'PY'
import json, os, sys

src_info, data_dir, lf_info = sys.argv[1], sys.argv[2], sys.argv[3]
with open(src_info, encoding="utf-8") as f:
    repo_entries = json.load(f)
with open(lf_info, encoding="utf-8") as f:
    lf = json.load(f)

added, updated = [], []
for name, spec in repo_entries.items():
    spec = dict(spec)
    fn = spec.get("file_name", "")
    if not os.path.isabs(fn):
        spec["file_name"] = os.path.join(data_dir, fn)
    (updated if name in lf else added).append(name)
    lf[name] = spec

with open(lf_info, "w", encoding="utf-8") as f:
    json.dump(lf, f, indent=2)
    f.write("\n")

print(f"Registered {len(added)} new + {len(updated)} updated datasets into {lf_info}")
for n in list(added) + list(updated):
    print(f"  {n} -> {lf[n]['file_name']}")
PY
else
    echo "Could not locate LLaMA-Factory data dir automatically."
    echo "Datasets will be found via dataset_dir in the yaml configs (no merge needed)."
fi

mkdir -p "$OUT/adapter_3b_phase1" "$OUT/adapter_3b"

echo ""
echo "========================================================"
echo "Phase 1: Mojo acquisition  $(date -u '+%H:%M:%SZ')"
echo "========================================================"
cd "$BUNDLE_ROOT"
llamafactory-cli train data/sft/cpp_mojo/sft_3b_phase1_cloud.yaml
echo "Phase 1 complete  $(date -u '+%H:%M:%SZ')"

echo ""
echo "========================================================"
echo "Phase 2: C++/Python→Mojo translation  $(date -u '+%H:%M:%SZ')"
echo "========================================================"
llamafactory-cli train data/sft/cpp_mojo/sft_3b_phase2_cloud.yaml
echo "Phase 2 complete  $(date -u '+%H:%M:%SZ')"

BENCH_DIR="$BUNDLE_ROOT/benchmarks/transpilation-bench/benchmarks/tasks"
EVAL_SCRIPT="$BUNDLE_ROOT/scripts/sft/eval_transbench.py"

if [ -d "$BENCH_DIR" ] && [ -f "$EVAL_SCRIPT" ]; then
    echo ""
    echo "========================================================"
    echo "Optional: eval_transbench.py  $(date -u '+%H:%M:%SZ')"
    echo "========================================================"
    python3 "$EVAL_SCRIPT" \
        --model_path "$OUT/adapter_3b" \
        --base_model Qwen/Qwen2.5-Coder-3B-Instruct \
        --tag cloud_3b \
        2>&1 | tee "$BUNDLE_ROOT/eval_transbench_cloud.log" || \
        echo "eval_transbench.py exited non-zero — check eval_transbench_cloud.log"
else
    echo ""
    echo "Bench dir not found ($BENCH_DIR) — skipping eval_transbench."
    echo "To evaluate: rsync the benchmarks/ dir to the box and re-run, or"
    echo "  run python3 scripts/sft/run_heldout_eval.py after pulling the adapter back."
fi

echo ""
echo "========================================================"
echo "DONE  $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
echo "Adapter saved to: $OUT/adapter_3b/"
echo "Full log: $LOG"
echo ""
echo "Next steps:"
echo "  1. rsync -avz root@<BOX_IP>:$(basename $BUNDLE_ROOT)/out/adapter_3b/ \\"
echo "       /c/Github/transpilers/data/sft/cpp_mojo/adapter_3b_v1/"
echo "  2. TERMINATE the box (billing stops on terminate, not stop)."
echo "========================================================"
