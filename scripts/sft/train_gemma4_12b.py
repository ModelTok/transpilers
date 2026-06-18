#!/usr/bin/env python3
"""Fine-tune code model for C++/Python -> Mojo translation.

Default model: Qwen2.5-Coder-3B-Instruct (cached, fits 16GB iGPU in bf16).
Set MODEL env var for other models:
  MODEL=google/gemma-4-12b-it  python scripts/sft/train_gemma4_12b.py
  MODEL=Qwen/Qwen2.5-Coder-7B-Instruct  python scripts/sft/train_gemma4_12b.py

Requires ROCm PyTorch:
  pip install torch --index-url https://download.pytorch.org/whl/rocm6.3
"""
from __future__ import annotations

import json, os, random, sys
import bitsandbytes as bnb
from pathlib import Path

os.environ.setdefault("TOKENIZERS_PARALLELISM", "false")

import torch
from datasets import Dataset
from transformers import (
    AutoModelForCausalLM, AutoTokenizer, BitsAndBytesConfig,
)
from peft import LoraConfig, prepare_model_for_kbit_training

from trl import SFTConfig, SFTTrainer

REPO = Path(__file__).resolve().parents[2]
DATA_DIR = REPO / "data" / "sft" / "cpp_mojo"

# Model selection
MODEL_ID = os.environ.get("MODEL", "Qwen/Qwen2.5-Coder-3B-Instruct")
model_short = MODEL_ID.split("/")[-1].replace(".", "-")
OUTPUT_DIR = REPO / "saves" / model_short / "lora" / "cpp_mojo_v1"

# Config per model size
needs_quant = "12b" in MODEL_ID.lower() or "7b" in MODEL_ID.lower()
CUTOFF_LEN = 1024 if needs_quant else 1024

print(f"Model: {MODEL_ID}")
print(f"Output: {OUTPUT_DIR}")
print(f"4-bit QLoRA: {needs_quant}")

EPOCHS = 2.0; LR = 1.0e-4
PER_DEVICE_BS = 1; GRAD_ACCUM = 8; WARMUP_RATIO = 0.05
LORA_R = 16; LORA_ALPHA = 32; LORA_DROPOUT = 0.05

if not torch.cuda.is_available():
    print("ERROR: CUDA/ROCm not available"); sys.exit(1)
p = torch.cuda.get_device_properties(0)
print(f"GPU: {p.name}  VRAM: {p.total_memory/1e9:.1f}GB  ROCm: {torch.version.hip}")

# Load datasets
def load_mojo_acquisition(path: Path) -> list[dict]:
    data = json.loads(path.read_text(encoding="utf-8"))
    msgs = []
    for r in data:
        user = r["instruction"]
        if r.get("input"): user += "\n\n" + r["input"]
        msgs.append({"messages": [{"role": "user", "content": user}, {"role": "assistant", "content": r["output"]}]})
    return msgs

def load_translation(path: Path) -> list[dict]:
    msgs = []
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line: continue
            r = json.loads(line)
            system = r.get("system", "")
            instruction = r["instruction"]
            user_content = system + "\n\n" + instruction if system else instruction
            if r.get("input"): user_content += "\n\n" + r["input"]
            msgs.append({"messages": [{"role": "user", "content": user_content}, {"role": "assistant", "content": r["output"]}]})
    return msgs

print("Loading datasets...")
acq = load_mojo_acquisition(DATA_DIR / "mojo_acquisition.json")
tr = load_translation(DATA_DIR / "train_translation.jsonl")
rng = random.Random(42)
all_examples = acq + tr; rng.shuffle(all_examples)
print(f"  total: {len(all_examples)}")
dataset = Dataset.from_list(all_examples)

# Load model
kwargs = dict(
    device_map="auto",
    torch_dtype=torch.bfloat16,
    trust_remote_code=True,
    low_cpu_mem_usage=True,
)

if needs_quant:
    kwargs["quantization_config"] = BitsAndBytesConfig(
        load_in_4bit=True, bnb_4bit_quant_type="nf4",
        bnb_4bit_compute_dtype=torch.bfloat16, bnb_4bit_use_double_quant=True,
    )

print(f"Loading model: {MODEL_ID}")
model = AutoModelForCausalLM.from_pretrained(MODEL_ID, **kwargs)

if hasattr(model, "vision_tower"):
    print("Freezing vision tower...")
    for param in model.vision_tower.parameters():
        param.requires_grad = False
if hasattr(model, "multi_modal_projector"):
    print("Freezing multi-modal projector...")
    for param in model.multi_modal_projector.parameters():
        param.requires_grad = False

if needs_quant:
    model = prepare_model_for_kbit_training(model)

trainable = sum(p.numel() for p in model.parameters() if p.requires_grad)
print(f"Trainable params: {trainable:,}")

tokenizer = AutoTokenizer.from_pretrained(MODEL_ID, trust_remote_code=True)
if tokenizer.pad_token is None:
    tokenizer.pad_token = tokenizer.eos_token

lora_config = LoraConfig(
    r=LORA_R, lora_alpha=LORA_ALPHA, lora_dropout=LORA_DROPOUT,
    target_modules="all-linear", task_type="CAUSAL_LM",
)

args = SFTConfig(
    output_dir=str(OUTPUT_DIR),
    num_train_epochs=EPOCHS,
    per_device_train_batch_size=PER_DEVICE_BS,
    gradient_accumulation_steps=GRAD_ACCUM,
    gradient_checkpointing=True,
    learning_rate=LR,
    lr_scheduler_type="cosine",
    warmup_ratio=WARMUP_RATIO,
    bf16=True,
    logging_steps=5,
    save_strategy="epoch",
    save_total_limit=2,
    packing=False,
    report_to="tensorboard",
    optim="adamw_8bit",
    dataset_num_proc=1,
    dataloader_num_workers=0,
)

trainer = SFTTrainer(
    model=model, args=args, train_dataset=dataset,
    processing_class=tokenizer, peft_config=lora_config,
)

print("Starting training...")
trainer.train()
trainer.save_model(str(OUTPUT_DIR))
print(f"Done! Adapter saved to {OUTPUT_DIR}")
