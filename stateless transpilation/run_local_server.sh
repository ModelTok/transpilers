#!/usr/bin/env bash
# Local OpenAI-compatible inference server on the AMD 890M iGPU (Vulkan).
# Serves Qwen2.5-Coder-14B-Instruct (Q4_K_M) for the transpiler pipeline.
#
#   ./run_local_server.sh            # foreground
#   nohup ./run_local_server.sh &    # background (log -> /tmp/llama-server.log)
#
# Then point 2_transpile.py at it:
#   python3 2_transpile.py --files <names> --backend lmstudio \
#     --endpoints http://127.0.0.1:8080/v1 --model qwen2.5-coder-14b \
#     --per-endpoint 1 --max-chars 60000 --timeout 1800
set -euo pipefail

BIN=/home/bart/Github/llama.cpp-diffusion/build/bin/llama-server
MODEL="$(dirname "$0")/model/Qwen2.5-Coder-14B-Instruct-Q4_K_M.gguf"

# iGPU memory budget ~15.5 GB. 14B Q4 weights ~9 GB; q8_0 KV cache keeps 24K
# context at ~2.3 GB so the whole thing stays GPU-resident (no host spill).
exec "$BIN" \
  -m "$MODEL" \
  --alias qwen2.5-coder-14b \
  -ngl 99 \
  -c 24576 \
  --cache-type-k q8_0 --cache-type-v q8_0 \
  -fa on \
  --host 127.0.0.1 --port 8080
