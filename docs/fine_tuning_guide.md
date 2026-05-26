# Fine-Tuning Guide: C++ to Python and Mojo Translation

## Overview

This guide covers fine-tuning Qwen2.5-Coder-7B-Instruct for domain-specific C++ → Python/Mojo translation. A fine-tuned 7B model on a single A40 GPU is expected to outperform GPT-4o on domain-specific EnergyPlus constructs at <2% of the API cost.

---

## Base Model Recommendation

**Qwen2.5-Coder-7B-Instruct** — `Qwen/Qwen2.5-Coder-7B-Instruct`

| Property | Value |
|---|---|
| License | Apache-2.0 (commercial use allowed) |
| Parameters | 7.6B |
| Context window | 128K tokens |
| Languages | 92 programming languages |
| Code performance | Top-tier among open 7B models (HumanEval 88.4%) |
| Fits on | Single A40 48GB (fp16) or RTX 4090 24GB (4-bit) |
| HuggingFace | [Qwen/Qwen2.5-Coder-7B-Instruct](https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct) |

**Why not a larger model?**

- 7B runs on a single A40 at full fp16 — no tensor parallelism needed
- Fine-tuned 7B on domain data typically beats a generic 70B on that domain
- Inference cost is 10× cheaper than 70B
- LoRA fine-tuning completes in <4 hours on A40

---

## Dataset Format (SFT)

Use supervised fine-tuning (SFT) with instruction format:

```json
{
  "prompt": "Translate the following C++ function to Mojo:\n\n```cpp\ndouble computeHeatTransfer(double area, double delta_t, double coeff) {\n    return area * delta_t * coeff;\n}\n```\n\nMojo translation:",
  "completion": "```mojo\nfn compute_heat_transfer(area: Float64, delta_t: Float64, coeff: Float64) -> Float64:\n    return area * delta_t * coeff\n```"
}
```

### JSONL format (one JSON object per line)

```jsonl
{"prompt": "Translate C++ to Python:\n\n```cpp\n...\n```\n\nPython:", "completion": "```python\n...\n```"}
{"prompt": "Translate C++ to Mojo:\n\n```cpp\n...\n```\n\nMojo:", "completion": "```mojo\n...\n```"}
```

### Multi-target training

Include all three targets in the dataset. Use the same C++ function with different prompt suffixes:

- `"Python translation:"` → Python output
- `"Mojo translation:"` → Mojo output
- `"Type-annotated Python translation:"` → Python with type hints

---

## Phase 1: Seed Dataset from transpilation-bench

[transpilation-bench](https://github.com/Tokarzewski/transpilation-bench) provides 40 benchmark tasks × 3 target languages = **120 labeled examples**.

```bash
# Clone transpilation-bench
git clone https://github.com/Tokarzewski/transpilation-bench
cd transpilation-bench

# Inspect available tasks
ls tasks/
```

### Converting bench tasks to SFT format

```python
import json
from pathlib import Path

tasks_dir = Path("transpilation-bench/tasks")
examples = []

for task_dir in tasks_dir.iterdir():
    cpp_file = task_dir / "source.cpp"
    for target in ["python", "mojo"]:
        target_file = task_dir / f"target.{target}"
        if cpp_file.exists() and target_file.exists():
            examples.append({
                "prompt": f"Translate the following C++ function to {target.capitalize()}:\n\n"
                          f"```cpp\n{cpp_file.read_text()}\n```\n\n{target.capitalize()} translation:",
                "completion": f"```{target}\n{target_file.read_text()}\n```"
            })

with open("data/bench_examples.jsonl", "w") as f:
    for ex in examples:
        f.write(json.dumps(ex) + "\n")

print(f"Created {len(examples)} examples")
```

---

## Phase 2: Augment with EnergyPlus Functions

Goal: **10,000 examples** total for robust fine-tuning.

### Generation pipeline

1. Extract C++ functions from EnergyPlus source (use tree-sitter frontend)
2. Send to GPT-4o with structured prompt to generate Python + Mojo versions
3. Run unit tests / type checks to verify generated code
4. Filter to verified examples only

```bash
# Estimate: EnergyPlus has ~50,000 functions; target the 10K simplest
python scripts/extract_functions.py src/EnergyPlus/ --max-complexity 20 --output data/functions.jsonl

# Generate translations via GPT-4o (costs ~$50 for 10K functions)
python scripts/generate_translations.py data/functions.jsonl --model gpt-4o --output data/augmented.jsonl

# Verify: run mypy on Python, mojo check on Mojo
python scripts/verify_translations.py data/augmented.jsonl --output data/verified.jsonl
```

---

## Training Script (HuggingFace TRL + SFTTrainer)

```python
#!/usr/bin/env python3
"""Fine-tune Qwen2.5-Coder-7B-Instruct for C++ to Python/Mojo translation."""

from datasets import load_dataset
from peft import LoraConfig, get_peft_model
from transformers import AutoModelForCausalLM, AutoTokenizer, BitsAndBytesConfig
from trl import SFTConfig, SFTTrainer
import torch

# --- Configuration ---
MODEL_ID = "Qwen/Qwen2.5-Coder-7B-Instruct"
DATASET_PATH = "data/verified.jsonl"
OUTPUT_DIR = "checkpoints/qwen25-coder-7b-cpp-transpiler"

# --- LoRA Configuration ---
lora_config = LoraConfig(
    r=16,                    # Rank — higher = more capacity, more VRAM
    lora_alpha=32,           # Alpha = 2×r is a common heuristic
    target_modules=[
        "q_proj", "k_proj", "v_proj", "o_proj",
        "gate_proj", "up_proj", "down_proj",
    ],
    lora_dropout=0.05,
    bias="none",
    task_type="CAUSAL_LM",
)

# --- Quantization (for 24GB GPU; skip for A40 48GB) ---
bnb_config = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_quant_type="nf4",
    bnb_4bit_compute_dtype=torch.bfloat16,
)

# --- Load Model ---
model = AutoModelForCausalLM.from_pretrained(
    MODEL_ID,
    quantization_config=bnb_config,  # Remove for A40 fp16
    device_map="auto",
    torch_dtype=torch.bfloat16,
    trust_remote_code=True,
)
tokenizer = AutoTokenizer.from_pretrained(MODEL_ID, trust_remote_code=True)
tokenizer.pad_token = tokenizer.eos_token

model = get_peft_model(model, lora_config)
model.print_trainable_parameters()

# --- Dataset ---
dataset = load_dataset("json", data_files=DATASET_PATH, split="train")
dataset = dataset.train_test_split(test_size=0.05)

# --- Training Arguments ---
sft_config = SFTConfig(
    output_dir=OUTPUT_DIR,
    num_train_epochs=3,
    per_device_train_batch_size=4,
    gradient_accumulation_steps=4,      # effective batch = 16
    learning_rate=2e-4,
    lr_scheduler_type="cosine",
    warmup_ratio=0.05,
    bf16=True,
    logging_steps=10,
    save_strategy="epoch",
    evaluation_strategy="epoch",
    max_seq_length=4096,
    dataset_text_field=None,            # use prompt+completion format
    packing=False,
    report_to="tensorboard",
)

# --- Trainer ---
trainer = SFTTrainer(
    model=model,
    args=sft_config,
    train_dataset=dataset["train"],
    eval_dataset=dataset["test"],
    tokenizer=tokenizer,
    peft_config=lora_config,
    formatting_func=lambda x: x["prompt"] + x["completion"],
)

trainer.train()
trainer.save_model(OUTPUT_DIR + "/final")
```

---

## Hyperparameters

| Hyperparameter | Value | Notes |
|---|---|---|
| Learning rate | 2e-4 | Standard for LoRA SFT |
| Epochs | 3 | More risks overfitting on 10K examples |
| Batch size (per device) | 4 | A40 48GB: can go up to 8 |
| Gradient accumulation | 4 | Effective batch = 16 |
| LoRA rank (r) | 16 | Good balance; try 32 if underfitting |
| LoRA alpha | 32 | 2×r convention |
| Sequence length | 4096 | Most functions fit; increase for large classes |
| Scheduler | Cosine with warmup | 5% warmup steps |
| Optimizer | AdamW (default) | 8-bit AdamW to save VRAM |

---

## Evaluation: Run Against transpilation-bench

```bash
# Run eval after fine-tuning
python run_eval.py \
    --model checkpoints/qwen25-coder-7b-cpp-transpiler/final \
    --path direct \
    --bench transpilation-bench \
    --metric pass@1 codebleu

# Compare against GPT-4o baseline
python run_eval.py --model gpt-4o --path direct --bench transpilation-bench
```

---

## Expected Outcomes

| Model | Pass@1 (transpilation-bench) | Pass@1 (EnergyPlus domain) | Cost/1M LOC |
|---|---|---|---|
| GPT-4o (baseline) | ~70% | ~55% | ~$5,500 |
| Qwen2.5-Coder-7B (base, no fine-tune) | ~45% | ~30% | ~$40 |
| Qwen2.5-Coder-7B (fine-tuned, 10K) | ~68% | ~75% | ~$40 |
| Qwen2.5-Coder-7B (fine-tuned, 50K) | ~75% | ~82% | ~$40 |

**Key finding**: Fine-tuned 7B is expected to outperform GPT-4o on domain-specific EnergyPlus C++ constructs after 10K+ training examples, while costing 100× less at inference time.

---

## References

- [Qwen2.5-Coder Technical Report](https://arxiv.org/abs/2409.12186)
- [TRL SFTTrainer Documentation](https://huggingface.co/docs/trl/sft_trainer)
- [LoRA: Low-Rank Adaptation of Large Language Models](https://arxiv.org/abs/2106.09685)
- [transpilation-bench](https://github.com/Tokarzewski/transpilation-bench)
