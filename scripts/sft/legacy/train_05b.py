#!/usr/bin/env python3
"""Real (bounded) LoRA fine-tune of Qwen2.5-0.5B for C++->Mojo, on CPU.

Translation pairs (the task, upweighted) + a Mojo-acquisition sample (so the 0.5B
learns the target language). CPU-only (~27s/step) so it's bounded by AB_EPOCHS /
the acquisition sample size — a multi-hour background run. Saves a LoRA adapter to
data/sft/cpp_mojo/adapter_05b/ for eval_05b.py --adapter.
"""
import json, os, random
os.environ["TOKENIZERS_PARALLELISM"] = "false"
# This AMD Strix Halo is memory-bandwidth-bound; cap to PHYSICAL cores (12) with
# a single OMP pool to avoid SMT oversubscription + bandwidth contention (faster
# than using all 24 logical CPUs). Must be set BEFORE torch imports. Override
# with THREADS=N.
_THREADS = int(os.environ.get("THREADS", "12"))
os.environ["OMP_NUM_THREADS"] = str(_THREADS)
os.environ["MKL_NUM_THREADS"] = str(_THREADS)
import torch
_GPU = torch.cuda.is_available()   # ROCm iGPU presents as cuda (run with HSA_OVERRIDE_GFX_VERSION=11.0.0)
from datasets import Dataset
from transformers import AutoModelForCausalLM, AutoTokenizer
from peft import LoraConfig
from trl import SFTConfig, SFTTrainer

REPO = "/home/bart/Github/transpilers"
MODEL = os.environ.get("SMOKE_MODEL", "Qwen/Qwen2.5-0.5B-Instruct")
TRANSLATE_UPWEIGHT = int(os.environ.get("TR_UP", "4"))
ACQ_SAMPLE = int(os.environ.get("ACQ_N", "300"))
EPOCHS = float(os.environ.get("AB_EPOCHS", "2"))
ADAPTER = os.environ.get("ADAPTER_DIR", "/home/bart/Github/transpilers/data/sft/cpp_mojo/adapter_05b")
torch.set_num_threads(_THREADS)
rnd = random.Random(7)

msgs = []
# translation (system,user,assistant), upweighted
tr = [json.loads(l) for l in open(f"{REPO}/data/sft/cpp_mojo/train_translation.jsonl") if l.strip()]
for _ in range(TRANSLATE_UPWEIGHT):
    for r in tr:
        msgs.append([{"role": "system", "content": r["system"]},
                     {"role": "user", "content": r["instruction"]},
                     {"role": "assistant", "content": r["output"]}])
# acquisition sample (no system; teach Mojo)
acq = json.load(open(f"{REPO}/data/sft/cpp_mojo/mojo_acquisition.json"))
rnd.shuffle(acq)
for r in acq[:ACQ_SAMPLE]:
    user = r["instruction"] + (("\n\n" + r["input"]) if r.get("input") else "")
    msgs.append([{"role": "user", "content": user},
                 {"role": "assistant", "content": r["output"]}])
rnd.shuffle(msgs)
print(f"training examples: {len(msgs)} (translation x{TRANSLATE_UPWEIGHT}={len(tr)*TRANSLATE_UPWEIGHT}, acquisition={min(ACQ_SAMPLE,len(acq))})")

ds = Dataset.from_list([{"messages": m} for m in msgs])
tok = AutoTokenizer.from_pretrained(MODEL)
model = AutoModelForCausalLM.from_pretrained(MODEL, dtype=(torch.bfloat16 if _GPU else torch.float32))
print(f"device: {'GPU ('+torch.cuda.get_device_name(0)+', bf16)' if _GPU else 'CPU (fp32, '+str(_THREADS)+' threads)'}")
peft_cfg = LoraConfig(r=16, lora_alpha=32, lora_dropout=0.05,
                      target_modules="all-linear", task_type="CAUSAL_LM")
_MAX_STEPS = int(os.environ.get("MAX_STEPS", "0"))   # >0 caps steps (for a quick GPU timing probe)
_MAX_LEN = int(os.environ.get("MAX_LEN", "4096"))    # truncation ceiling; our seqs ~2k so ≥4k = no truncation
args = SFTConfig(
    output_dir=ADAPTER,
    num_train_epochs=EPOCHS, max_steps=(_MAX_STEPS if _MAX_STEPS else -1),
    per_device_train_batch_size=1, gradient_accumulation_steps=4,
    learning_rate=1.5e-4, lr_scheduler_type="cosine", warmup_ratio=0.05,
    logging_steps=5, save_strategy=("no" if _MAX_STEPS else "epoch"), max_length=_MAX_LEN,
    report_to="none", bf16=_GPU, fp16=False, dataset_num_proc=1,
)
trainer = SFTTrainer(model=model, args=args, train_dataset=ds,
                     peft_config=peft_cfg, processing_class=tok)
print("=== training (CPU LoRA) ===")
out = trainer.train()
trainer.save_model(ADAPTER)
print(f"\nDONE train_loss={out.training_loss:.4f}  adapter -> "+ADAPTER+"")
