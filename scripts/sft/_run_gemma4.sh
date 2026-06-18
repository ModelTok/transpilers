#!/usr/bin/env bash
export PATH=/opt/rocm/bin:/opt/rocm/llvm/bin:$PATH
exec /home/bart/.venvs/gemma4/bin/python /home/bart/.cline/worktrees/21960/transpilers/scripts/sft/train_gemma4_12b.py
