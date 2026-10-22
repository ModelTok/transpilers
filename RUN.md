# Running the transpiler model on an NVIDIA GPU

Everything needed to run, retrain, and evaluate the C++/Python → Mojo model is in
this repo. The only thing **not** committed is the stock base model (auto-downloaded
from HuggingFace on first run) and the throwaway training checkpoints.

## What's in the repo

| Path | What |
|---|---|
| `data/sft/cpp_mojo/adapter_15b_v2/` | **the model** — LoRA adapter (~70 MB), bilingual no-think (Py→Mojo 70%, C++ 72%) |
| `data/sft/cpp_mojo/adapter_15b/`, `adapter_05b/` | earlier adapters |
| `data/sft/cpp_mojo/train_translation.jsonl` | the training set (C++ + Python → Mojo, code-only) |
| `data/sft/cpp_mojo/system.txt` | the lean system prompt |
| `data/sft/diverse/verified.jsonl`, `py_verified.jsonl` | verified translation pairs |
| `data/sft/cpp_mojo/sft.yaml` + `dataset_info.json` | **LLaMA Factory training config + dataset registry** (the training path) |
| `scripts/sft/` | eval (`eval_diverse.py`, `eval_transbench.py`), migrate (`migrate_py_leaves.py`), verify gates (`diff_verify.py`, `py_verify.py`); `register_datasets.sh`; legacy TRL trainers under `legacy/` |
| `benchmarks/transpilation-bench/` | the 40-task benchmark |

The base model is `Qwen/Qwen2.5-Coder-1.5B-Instruct` — pulled from HF automatically.

## Setup on an NVIDIA GPU

```bash
python3 -m venv ~/transpilers-venv && source ~/transpilers-venv/bin/activate
# 1) CUDA PyTorch matching your driver. cu128 is for RTX 50-series (Blackwell, sm_120);
#    older cards can use cu124 / cu121. Pick the index that matches your driver.
pip install --index-url https://download.pytorch.org/whl/cu128 torch
# 2) the rest:
pip install -r requirements.txt
```

Confirm torch sees the GPU:
```bash
python -c "import torch; print(torch.cuda.is_available(), torch.cuda.get_device_name(0))"
```

For a one-command local two-phase 3B run on NVIDIA (includes the CUDA wheel install and
uses PyTorch SDPA, since flash-attn has no prebuilt wheel for sm_120), see
`scripts/sft/train_3b_cuda_local.sh`.

## Retrain the adapter — LLaMA Factory (GUI or CLI)

Training runs through **LLaMA Factory** on the NVIDIA GPU. It reproduces the shipped
`adapter_15b_v2` LoRA (base Qwen2.5-Coder-1.5B-Instruct, r=16, alpha=32, dropout=0.05,
all linear projections). Config: `data/sft/cpp_mojo/sft.yaml`; datasets registered in
`data/sft/cpp_mojo/dataset_info.json`.

```bash
# One-time: make the datasets visible to LLaMA Factory / the GUI.
bash scripts/sft/register_datasets.sh

# CLI retrain:
llamafactory-cli train data/sft/cpp_mojo/sft.yaml
```

### GUI (LLaMA Board)

```bash
# Launch the GUI with datasets pre-registered, then open http://localhost:7860
wsl -d Ubuntu-24.04 -u root -- bash /mnt/c/Users/<you>/wsl-setup/08-train-gui.sh
```
In the **Train** tab: Model = `Qwen2.5-Coder-1.5B-Instruct` · Finetuning = `lora`
(rank 16) · Template = `qwen` · Dataset = `mojo_acquisition` + `cpp_mojo_translation`
· LR `1.5e-4` · Epochs `2` → **Start**. Watch the loss curve live; the adapter lands
in the chosen Output dir.

**Two-phase (recommended if translation under-fits):** acquisition (1163) dwarfs
translation (1005), so the task signal can dilute. Phase 1: train `mojo_acquisition`
only (1–2 epochs) → checkpoint. Phase 2: load that adapter and train
`cpp_mojo_translation` (3–5 epochs, lower LR). This replaces the old script's ×4
translation upweight.

## Run it (eval / migrate)

```bash
# Evaluate the model on the benchmark (Python->Mojo or C++->Mojo):
python scripts/sft/eval_transbench.py --adapter data/sft/cpp_mojo/adapter_15b_v2 --source python_reference

# Run the model on energyplus-mojo leaf functions (needs the Mojo toolchain — see below):
python scripts/sft/migrate_py_leaves.py --adapter data/sft/cpp_mojo/adapter_15b_v2 --k 3
```

## The Mojo verify gate (optional, for `migrate_py_leaves.py` / `diff_verify`)

The differential-verify gate compiles the generated Mojo to confirm correctness. It
needs a **Mojo 1.0 toolchain**. In this setup that came from the sibling
`energyplus-mojo` repo's pixi env (`diff_verify.py` points `MOJO_BIN` at
`energyplus-mojo/.pixi/envs/default/bin/mojo`). To run the verify gate on a new
machine, either clone `energyplus-mojo` and run `pixi install`, or install Mojo standalone
and set `MOJO_BIN`/`MODULAR_HOME` accordingly. **Pure model inference + eval against
the benchmark's expected outputs does not need Mojo** — only the live compile-verify of
generated code does.

## Merge the adapter into a standalone model (portable, no PEFT at inference)

```python
from transformers import AutoModelForCausalLM
from peft import PeftModel
b = AutoModelForCausalLM.from_pretrained("Qwen/Qwen2.5-Coder-1.5B-Instruct")
m = PeftModel.from_pretrained(b, "data/sft/cpp_mojo/adapter_15b_v2").merge_and_unload()
m.save_pretrained("merged-coder-1.5b-mojo")   # a normal HF model you can quantize / convert to GGUF
```
