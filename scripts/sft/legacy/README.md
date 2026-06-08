# Legacy trainers (deprecated)

These bespoke TRL trainers have been **superseded by LLaMA Factory**. They are kept
as a fallback (e.g. pure-CPU boxes with no ROCm/CUDA) and for git history.

| File | Was |
|---|---|
| `train_05b.py` | TRL `SFTTrainer` LoRA fine-tune (CPU-first, ROCm-iGPU optional). Produced the shipped `adapter_15b_v2` (r=16, alpha=32, dropout=0.05, all linear projections). |
| `smoke_train.py` | Tiny smoke trainer for wiring checks. |

## Use LLaMA Factory instead

Training now runs through LLaMA Factory, which reproduces the same LoRA hyperparameters.

```bash
# CLI (inside the Ubuntu-24.04 WSL ROCm distro, venv /root/venvs/lf):
llamafactory-cli train data/sft/cpp_mojo/sft.yaml

# GUI: open http://localhost:7860 (LLaMA Board) — see RUN.md for the walkthrough.
#   First-time dataset registration:  bash scripts/sft/register_datasets.sh
```

The datasets are registered in `data/sft/cpp_mojo/dataset_info.json`. The config is
`data/sft/cpp_mojo/sft.yaml`.

**Note:** only the *training* step moved to LLaMA Factory. The eval (`eval_transbench.py`,
`run_heldout_eval.py`), verify gates (`diff_verify.py`, `py_verify.py`), and dataset
builders in `scripts/sft/` are transpiler-specific and remain the canonical tools.
