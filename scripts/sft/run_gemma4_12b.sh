set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

echo "=== GPU check ==="
python3 -c "import torch; p=torch.cuda.get_device_properties(0); print(f'GPU: {p.name}  VRAM: {p.total_memory/1e9:.1f}GB  CUDA: {torch.version.cuda}')" 2>/dev/null || {
    echo "ERROR: CUDA PyTorch not found or no NVIDIA GPU available."
    echo "Install: pip install torch --index-url https://download.pytorch.org/whl/cu128"
    exit 1
}

pip install transformers peft trl datasets accelerate bitsandbytes 2>&1 | tail -3

mkdir -p saves/gemma-4-12b-it/lora

if [ "${USE_LF:-false}" = "true" ] && command -v llamafactory-cli &>/dev/null; then
    bash scripts/sft/register_datasets.sh 2>/dev/null || true
    llamafactory-cli train data/sft/cpp_mojo/gemma4_12b_qlora.yaml
else
    python3 scripts/sft/train_gemma4_12b.py
fi

echo "=== Done ==="
ls -la saves/gemma-4-12b-it/lora/cpp_mojo_qlora_v1/
