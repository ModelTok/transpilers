#!/bin/bash
# One-shot: install deps, train, tar the adapter for download. Run inside a
# RunPod pytorch pod (or any CUDA box). Pick the base via MODEL env.
set -e
pip install -q -r requirements.txt
: "${MODEL:=Qwen/Qwen2.5-Coder-1.5B-Instruct}"
echo ">>> training $MODEL"
MODEL="$MODEL" EPOCHS="${EPOCHS:-2}" TR_UP="${TR_UP:-4}" MAX_LEN="${MAX_LEN:-8192}" python train.py
tar czf adapter.tgz -C "$(dirname adapter)" adapter
echo ">>> done. download adapter.tgz, then locally: tar xzf adapter.tgz -C data/sft/cpp_mojo/ && rename to adapter_<tag>"
