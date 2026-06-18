#!/bin/bash
# Debug each remaining reject; print compact failure signatures.
cd /mnt/c/Github/transpilers
export TRANSPILERS_EPMOJO=/home/amd/energyplus-mojo/.pixi/envs/default
for n in "$@"; do
  echo "##### $n"
  /home/amd/tn-venv/bin/python scripts/night_debug_verify.py /home/amd/night/llm_round2.jsonl "$n" 2>&1 \
    | grep -E '^(mojo_params|== |MISMATCH|no mismatches|.*error|mojo lines)' | head -12
done
