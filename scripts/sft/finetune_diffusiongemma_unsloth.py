#!/usr/bin/env python3
"""Fine-tune DiffusionGemma 26B for C++/Python -> Mojo transpilation with Unsloth.

Unsloth provides first-class support for DiffusionGemma fine-tuning, including:
- 2x faster training with 70% less VRAM (vs. standard HF PEFT)
- Proper diffusion-aware training loops
- 4-bit QLoRA support enabling the 26B model to train on 24 GB GPUs
- Seamless export to GGUF for inference with llama.cpp

Prerequisites:
    pip install unsloth huggingface_hub datasets

Usage:
    # Default: fine-tune on the cpp_mojo dataset
    python scripts/sft/finetune_diffusiongemma_unsloth.py

    # Custom config
    python scripts/sft/finetune_diffusiongemma_unsloth.py \\
        --model google/diffusion-gemma-26b-it \\
        --dataset data/sft/cpp_mojo/train_translation.jsonl \\
        --output-dir checkpoints/diffusiongemma-cpp-mojo \\
        --lr 1e-4 --epochs 2

    # Export to GGUF after training
    python scripts/sft/finetune_diffusiongemma_unsloth.py --export-gguf
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
SFT_DIR = REPO_ROOT / "data/sft/cpp_mojo"
DEFAULT_MODEL = "google/diffusion-gemma-26b-it"
DEFAULT_OUTPUT_DIR = REPO_ROOT / "checkpoints/diffusiongemma-cpp-mojo"
DEFAULT_DATASETS = [
    str(SFT_DIR / "mojo_acquisition.json"),
    str(SFT_DIR / "train_translation.jsonl"),
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Fine-tune DiffusionGemma for C++/Python -> Mojo transpilation",
    )
    parser.add_argument("--model", default=DEFAULT_MODEL, help="HF model ID")
    parser.add_argument("--dataset", nargs="+", default=DEFAULT_DATASETS, help="Dataset files")
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR, help="Output dir")
    parser.add_argument("--lr", type=float, default=1e-4, help="Learning rate")
    parser.add_argument("--epochs", type=float, default=2.0, help="Training epochs")
    parser.add_argument("--batch-size", type=int, default=2, help="Per-device batch size")
    parser.add_argument("--grad-accum-steps", type=int, default=4, help="Gradient accumulation steps")
    parser.add_argument("--max-seq-length", type=int, default=2048, help="Max sequence length")
    parser.add_argument("--lora-r", type=int, default=16, help="LoRA rank")
    parser.add_argument("--4bit", action="store_true", default=True, help="4-bit QLoRA")
    parser.add_argument("--export-gguf", action="store_true", help="Export to GGUF after training")
    parser.add_argument("--system-prompt", type=str, default="", help="System prompt file path")
    parser.add_argument("--no-train", action="store_true", help="Dry-run, skip training")
    return parser.parse_args()


def load_datasets(file_paths: list[str]) -> list[dict]:
    """Load and merge dataset files (JSON arrays or JSONL)."""
    examples: list[dict] = []
    for fp in file_paths:
        path = Path(fp)
        if not path.exists():
            print(f"WARNING: dataset {path} not found, skipping")
            continue
        raw = path.read_text().strip()
        if not raw:
            continue
        try:
            data = json.loads(raw)
            if isinstance(data, list):
                examples.extend(data)
            else:
                examples.append(data)
        except json.JSONDecodeError:
            for line in raw.splitlines():
                if line.strip():
                    examples.append(json.loads(line))
    return examples


def format_sft_example(ex: dict, system_prompt: str) -> dict:
    """Format an example for SFT using the Gemma 4 chat template."""
    instruction = ex.get("instruction", ex.get("prompt", ""))
    output = ex.get("output", ex.get("completion", ""))
    query = ex.get("input", ex.get("query", ""))
    parts: list[str] = []
    if system_prompt:
        parts.append(f"<|system|>\\n{system_prompt}\\n")
    if query:
        parts.append(f"<|user|>\\n{instruction}\\n{query}")
    else:
        parts.append(f"<|user|>\\n{instruction}")
    parts.append(f"<|assistant|>\\n{output}")
    return {"text": "\\n".join(parts)}


def main() -> None:
    args = parse_args()

    # Load system prompt
    system_prompt = ""
    if args.system_prompt:
        sp = Path(args.system_prompt)
        if sp.exists():
            system_prompt = sp.read_text().strip()
    else:
        default_sp = SFT_DIR / "system.txt"
        if default_sp.exists():
            system_prompt = default_sp.read_text().strip()

    # Load datasets
    print("Loading datasets...")
    raw_examples = load_datasets(args.dataset)
    print(f"  Loaded {len(raw_examples)} raw examples")
    examples = [format_sft_example(ex, system_prompt) for ex in raw_examples]
    print(f"  Formatted {len(examples)} SFT examples")

    if args.no_train:
        print("Dry-run: --no-train set, exiting.")
        return

    # Imports
    try:
        import torch
        from unsloth import FastLanguageModel, is_bfloat16_supported
        from datasets import Dataset
        from transformers import TrainingArguments
        from trl import SFTTrainer
    except ImportError as e:
        print(f"ERROR: {e}\\nInstall:\n  pip install unsloth huggingface_hub datasets trl transformers")
        sys.exit(1)

    # Load model
    print(f"\\nLoading DiffusionGemma model: {args.model}")
    model, tokenizer = FastLanguageModel.from_pretrained(
        model_name=args.model,
        max_seq_length=args.max_seq_length,
        dtype=None,
        load_in_4bit=args._4bit,
    )

    model = FastLanguageModel.get_peft_model(
        model,
        r=args.lora_r,
        target_modules=["q_proj", "k_proj", "v_proj", "o_proj",
                        "gate_proj", "up_proj", "down_proj"],
        lora_alpha=args.lora_r * 2,
        lora_dropout=0.05,
        bias="none",
        use_gradient_checkpointing="unsloth",
        random_state=42,
        use_rslora=False,
        loftq_config=None,
    )

    dataset = Dataset.from_list(examples)
    output_dir = args.output_dir
    output_dir.mkdir(parents=True, exist_ok=True)

    training_args = TrainingArguments(
        output_dir=str(output_dir),
        per_device_train_batch_size=args.batch_size,
        gradient_accumulation_steps=args.grad_accum_steps,
        num_train_epochs=args.epochs,
        learning_rate=args.lr,
        warmup_ratio=0.05,
        lr_scheduler_type="cosine",
        logging_steps=10,
        save_strategy="epoch",
        save_total_limit=2,
        bf16=is_bfloat16_supported(),
        fp16=not is_bfloat16_supported(),
        gradient_checkpointing=True,
        gradient_checkpointing_kwargs={"use_reentrant": False},
        optim="adamw_8bit",
        weight_decay=0.01,
        report_to="tensorboard",
        dataloader_num_workers=4,
    )

    trainer = SFTTrainer(
        model=model,
        args=training_args,
        train_dataset=dataset,
        tokenizer=tokenizer,
        dataset_text_field="text",
        max_seq_length=args.max_seq_length,
        packing=False,
    )

    print(f"\\nStarting training ({args.epochs} epochs, LR={args.lr})...")
    trainer.train()
    print(f"\\nTraining complete. Saving model to {output_dir}")

    model.save_pretrained(str(output_dir / "lora_adapter"))
    tokenizer.save_pretrained(str(output_dir / "lora_adapter"))
    print(f"  LoRA adapter saved to {output_dir / 'lora_adapter'}")

    merged_dir = output_dir / "merged"
    print(f"Saving merged model to {merged_dir} ...")
    model.save_pretrained_merged(str(merged_dir), tokenizer, save_method="merged_16bit")

    if args.export_gguf:
        print(f"\\nExporting to GGUF...")
        model.save_pretrained_gguf(
            str(output_dir / "gguf"),
            tokenizer,
            quantization_method="q4_k_m",
        )

    print("\\n=== Fine-tuning complete ===")
    print(f"  Model: {args.model}")
    print(f"  Output: {output_dir}")
    print(f"  LoRA adapter: {output_dir / 'lora_adapter'}")
    print("\\nTo run inference:")
    print(f"  python scripts/sft/infer_diffusiongemma.py --backend unsloth \\\\")
    print(f"      --model {output_dir / 'lora_adapter'}")


if __name__ == "__main__":
    main()
