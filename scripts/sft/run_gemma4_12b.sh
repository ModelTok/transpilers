#!/usr/bin/env bash
# Run Gemma 4 12B QLoRA fine-tune for C++/Python -> Mojo translation.
#
# Prerequisites: ROCm runtime + AMD GPU with amdgpu driver
#
# Usage:
#   bash scripts/sft/run_gemma4_12b.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

# ROCm in PATH
if [ -d /opt/rocm/bin ]; then
    export PATH=/opt/rocm/bin:/opt/rocm/llvm/bin:$PATH
fi

# Check deps
echo "=== GPU check ==="
python3 -c "import torch; p=torch.cuda.get_device_properties(0); print(f'GPU: {p.name}  VRAM: {p.total_memory/1e9:.1f}GB  ROCm: {torch.version.hip}')" 2>/dev/null || {
    echo "ERROR: ROCm PyTorch not found or GPU not available."
    echo "Install: pip install torch --index-url https://download.pytorch.org/whl/rocm6.3"
    exit 1
}

# Check deps
pip install transformers peft trl datasets accelerate bitsandbytes 2>&1 | tail -3

# Create output dir
mkdir -p saves/gemma-4-12b-it/lora

# Run training (direct or via LLaMA Factory)
if [ "${USE_LF:-false}" = "true" ] && command -v llamafactory-cli &>/dev/null; then
    bash scripts/sft/register_datasets.sh 2>/dev/null || true
    llamafactory-cli train data/sft/cpp_mojo/gemma4_12b_qlora.yaml
else
    python3 scripts/sft/train_gemma4_12b.py
fi

echo "=== Done ==="
ls -la saves/gemma-4-12b-it/lora/cpp_mojo_qlora_v1/
