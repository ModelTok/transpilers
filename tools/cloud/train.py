#!/usr/bin/env python3
"""Portable LoRA fine-tune for C++->Mojo, for a cloud NVIDIA GPU (RunPod etc.).

Same recipe as the local iGPU run, but CUDA-native and self-contained: reads
./data/, writes ./adapter/. No ROCm/HSA env needed. Run with:
  MODEL=Qwen/Qwen2.5-Coder-1.5B-Instruct EPOCHS=2 TR_UP=4 python train.py
Then download ./adapter/ and eval locally (the Mojo verify-gate lives there).
"""
import json, os, random
os.environ.setdefault("TOKENIZERS_PARALLELISM", "false")
import torch
from datasets import Dataset
from transformers import AutoModelForCausalLM, AutoTokenizer
from peft import LoraConfig
from trl import SFTConfig, SFTTrainer

HERE = os.path.dirname(os.path.abspath(__file__))
MODEL = os.environ.get("MODEL", "Qwen/Qwen2.5-Coder-0.5B-Instruct")
TR_UP = int(os.environ.get("TR_UP", "4"))
ACQ_N = int(os.environ.get("ACQ_N", "300"))
EPOCHS = float(os.environ.get("EPOCHS", "2"))
MAX_LEN = int(os.environ.get("MAX_LEN", "8192"))
ADAPTER = os.environ.get("ADAPTER_DIR", os.path.join(HERE, "adapter"))
assert torch.cuda.is_available(), "no CUDA GPU visible"
rnd = random.Random(7)

msgs = []
tr = [json.loads(l) for l in open(f"{HERE}/data/train_translation.jsonl") if l.strip()]
for _ in range(TR_UP):
    for r in tr:
        msgs.append([{"role": "system", "content": r["system"]},
                     {"role": "user", "content": r["instruction"]},
                     {"role": "assistant", "content": r["output"]}])
acq = json.load(open(f"{HERE}/data/mojo_acquisition.json")); rnd.shuffle(acq)
for r in acq[:ACQ_N]:
    user = r["instruction"] + (("\n\n" + r["input"]) if r.get("input") else "")
    msgs.append([{"role": "user", "content": user}, {"role": "assistant", "content": r["output"]}])
rnd.shuffle(msgs)
print(f"GPU: {torch.cuda.get_device_name(0)} | examples: {len(msgs)} (translation x{TR_UP}={len(tr)*TR_UP}, acq={min(ACQ_N,len(acq))}) | base: {MODEL}")

ds = Dataset.from_list([{"messages": m} for m in msgs])
tok = AutoTokenizer.from_pretrained(MODEL)
model = AutoModelForCausalLM.from_pretrained(
    MODEL, dtype=torch.bfloat16,
    attn_implementation="flash_attention_2" if os.environ.get("FLASH") else "sdpa")
peft_cfg = LoraConfig(r=16, lora_alpha=32, lora_dropout=0.05, target_modules="all-linear", task_type="CAUSAL_LM")
args = SFTConfig(output_dir=ADAPTER, num_train_epochs=EPOCHS,
                 per_device_train_batch_size=int(os.environ.get("BS", "2")),
                 gradient_accumulation_steps=int(os.environ.get("GA", "4")),
                 learning_rate=1.5e-4, lr_scheduler_type="cosine", warmup_ratio=0.05,
                 logging_steps=10, save_strategy="epoch", max_length=MAX_LEN,
                 report_to="none", bf16=True, dataset_num_proc=2)
trainer = SFTTrainer(model=model, args=args, train_dataset=ds, peft_config=peft_cfg, processing_class=tok)
out = trainer.train(); trainer.save_model(ADAPTER)
print(f"DONE train_loss={out.training_loss:.4f}  adapter -> {ADAPTER}")
