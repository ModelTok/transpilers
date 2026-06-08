# Running the transpiler model on a different GPU (e.g. AMD RX 7700 XT)

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
| `scripts/sft/` | train (`train_05b.py`), eval (`eval_diverse.py`, `eval_transbench.py`), migrate (`migrate_py_leaves.py`), verify gates (`diff_verify.py`, `py_verify.py`) |
| `benchmarks/transpilation-bench/` | the 40-task benchmark |

The base model is `Qwen/Qwen2.5-Coder-1.5B-Instruct` — pulled from HF automatically.

## Setup on the 7700 XT (gfx1101, RDNA3)

```bash
python3 -m venv ~/transpilers-venv && source ~/transpilers-venv/bin/activate
# 1) ROCm PyTorch for your GPU (RDNA3 supported natively in ROCm >= 6.2):
pip install --index-url https://download.pytorch.org/whl/rocm6.3 torch
# 2) the rest:
pip install -r requirements.txt
```

**GPU env var:** the iGPU this was built on (Radeon 890M = gfx1150) needed
`HSA_OVERRIDE_GFX_VERSION=11.0.0` to be recognized. The **7700 XT (gfx1101) is
natively supported**, so you likely need **no override**. If torch doesn't see the
GPU, try `HSA_OVERRIDE_GFX_VERSION=11.0.1`. Confirm with:
```bash
python -c "import torch; print(torch.cuda.is_available(), torch.cuda.get_device_name(0))"
```

## Run it

```bash
# Evaluate the model on the benchmark (Python->Mojo or C++->Mojo):
python scripts/sft/eval_transbench.py --adapter data/sft/cpp_mojo/adapter_15b_v2 --source python_reference

# Retrain the adapter (the 7700 XT is ~3-4x faster than the iGPU — ~1.5h not ~6h):
SMOKE_MODEL=Qwen/Qwen2.5-Coder-1.5B-Instruct TR_UP=3 AB_EPOCHS=2 \
  ADAPTER_DIR=data/sft/cpp_mojo/adapter_15b_v3 python scripts/sft/train_05b.py

# Run the model on energyplus-mojo leaf functions (needs the Mojo toolchain — see below):
python scripts/sft/migrate_py_leaves.py --adapter data/sft/cpp_mojo/adapter_15b_v2 --k 3
```

## The Mojo verify gate (optional, for `migrate_py_leaves.py` / `diff_verify`)

The differential-verify gate compiles the generated Mojo to confirm correctness. It
needs a **Mojo 1.0 toolchain**. In this setup that came from the sibling
`energyplus-mojo` repo's pixi env (`diff_verify.py` points `MOJO_BIN` at
`energyplus-mojo/.pixi/envs/default/bin/mojo`). To run the verify gate on the 7700 XT
box, either clone `energyplus-mojo` and run `pixi install`, or install Mojo standalone
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
