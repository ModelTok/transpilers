#!/usr/bin/env python3
"""LOCAL SMOKE TEST of the C++->Mojo training loop (NOT real training).

Validates that our data + schema actually trains: loads train_translation.jsonl
(CodePivot schema), formats it as Qwen chat (system -> user -> assistant), and runs
a few LoRA SFT steps on a TINY model (Qwen2.5-0.5B — same template family as the
real 3B target; the 3B would OOM this 6GB-free box). Confirms loss computes/moves
and a LoRA adapter saves. Real training is LLaMA-Factory on GPU per sft.yaml.
"""
import json, os
os.environ["TOKENIZERS_PARALLELISM"] = "false"
import torch
from datasets import Dataset
from transformers import AutoModelForCausalLM, AutoTokenizer
from peft import LoraConfig
from trl import SFTConfig, SFTTrainer

MODEL = os.environ.get("SMOKE_MODEL", "Qwen/Qwen2.5-0.5B-Instruct")
DATA = "data/sft/cpp_mojo/train_translation.jsonl"
torch.set_num_threads(max(1, (os.cpu_count() or 4) - 1))

rows = []
for line in open(DATA):
    if not line.strip():
        continue
    r = json.loads(line)
    rows.append({"messages": [
        {"role": "system", "content": r["system"]},
        {"role": "user", "content": r["instruction"]},
        {"role": "assistant", "content": r["output"]},
    ]})
print(f"loaded {len(rows)} C++->Mojo training examples")
ds = Dataset.from_list(rows)

tok = AutoTokenizer.from_pretrained(MODEL)
# quick schema check: render one example through the chat template
sample = tok.apply_chat_template(rows[0]["messages"], tokenize=False)
print(f"chat-template render OK; example length = {len(tok(sample)['input_ids'])} tokens")

model = AutoModelForCausalLM.from_pretrained(MODEL, dtype=torch.float32)
peft_cfg = LoraConfig(r=8, lora_alpha=16, lora_dropout=0.0,
                      target_modules="all-linear", task_type="CAUSAL_LM")

args = SFTConfig(
    output_dir="/tmp/smoke_ckpt",
    max_steps=8,
    per_device_train_batch_size=1,
    gradient_accumulation_steps=2,
    learning_rate=2e-4,
    logging_steps=1,
    max_length=1280,
    warmup_steps=0,
    report_to="none",
    save_strategy="no",
    bf16=False, fp16=False,
    dataset_num_proc=1,
)
trainer = SFTTrainer(model=model, args=args, train_dataset=ds,
                     peft_config=peft_cfg, processing_class=tok)
print("=== training 8 steps (CPU, LoRA) ===")
out = trainer.train()
trainer.save_model("/tmp/smoke_ckpt")
loss = out.training_loss
adapter = os.path.exists("/tmp/smoke_ckpt/adapter_model.safetensors")
print(f"\nSMOKE RESULT: train_loss={loss:.4f}  adapter_saved={adapter}")
print("OK" if (loss == loss and adapter) else "FAILED")
