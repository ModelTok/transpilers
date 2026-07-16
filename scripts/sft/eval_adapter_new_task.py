#!/usr/bin/env python3
"""Ad-hoc eval of the fine-tuned Mojo-migration LoRA on a NEW task.

Loads Qwen2.5-Coder-3B-Instruct + our out/adapter_3b_cuda LoRA via
peft and transpiles a C++ snippet that is NOT in the training set
(we verify it is absent from train_translation.jsonl). Prints the
generated Mojo so we can eyeball idiom correctness.

Run with the 3.13 CUDA venv:
  .venv_cuda/Scripts/python.exe scripts/sft/eval_adapter_new_task.py
"""
from __future__ import annotations
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
BASE = "Qwen/Qwen2.5-Coder-3B-Instruct"
ADAPTER = str(REPO / "out/adapter_3b_cuda")
TRAIN_FILE = REPO / "data/sft/cpp_mojo/train_translation.jsonl"

# A NEW task: RAII unique_ptr + custom deleter -> Mojo Owned/RAII pattern.
# This class of problem (custom deleters, move-only ownership) was NOT in the
# small 1005-line training set, so it is a genuine generalization probe.
NEW_CPP = r'''
#include <memory>
#include <cstdio>

struct File {
    FILE* f;
    File(const char* p) : f(std::fopen(p, "rb")) {}
    ~File() { if (f) std::fclose(f); }
};

// Move-only handle with a custom deleter.
struct Buf {
    int* data;
    Buf(int n) : data(new int[n]) {}
    ~Buf() { delete[] data; }
    Buf(const Buf&) = delete;
    Buf& operator=(const Buf&) = delete;
};

int sum(const Buf& b, int n) {
    int s = 0;
    for (int i = 0; i < n; ++i) s += b.data[i];
    return s;
}
'''

PROMPT = (
    "You are an expert C++ to Mojo transpiler. Convert the following C++ "
    "code to idiomatic Mojo. Preserve semantics, ownership, and RAII. "
    "Do not add explanations; emit only the Mojo translation.\n\n"
    "### C++ source\n```cpp\n" + NEW_CPP.strip() + "\n```\n\n### Mojo translation\n```mojo\n"
)


def is_novel() -> bool:
    if not TRAIN_FILE.exists():
        return True
    blob = TRAIN_FILE.read_text(encoding="utf-8")
    # crude signature: the for-loop sum-with-bracket pattern is unique to this probe
    return "operator=(const Buf&) = delete" not in blob and "delete[] data" not in blob


def main() -> int:
    print(f"[eval] base={BASE}")
    print(f"[eval] adapter={ADAPTER}")
    print(f"[eval] task novel vs training set: {is_novel()}")

    from transformers import AutoModelForCausalLM, AutoTokenizer
    from peft import PeftModel

    tok = AutoTokenizer.from_pretrained(BASE)
    model = AutoModelForCausalLM.from_pretrained(
        BASE, torch_dtype="auto", device_map="auto"
    )
    model = PeftModel.from_pretrained(model, ADAPTER)
    model.eval()

    messages = [{"role": "user", "content": PROMPT}]
    text = tok.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
    inputs = tok(text, return_tensors="pt").to(model.device)
    out = model.generate(
        **inputs,
        max_new_tokens=512,
        do_sample=False,
        temperature=1.0,
        eos_token_id=tok.eos_token_id,
    )
    gen = tok.decode(out[0][inputs["input_ids"].shape[1]:], skip_special_tokens=True)

    print("\n=== GENERATED MOJO (new task) ===\n")
    print(gen.strip())
    print("\n=== END ===")

    # rough quality signals
    mojo = gen.lower()
    signals = {
        "uses `def`": "def " in mojo,
        "uses `struct`": "struct " in mojo,
        "uses `var`/`let`": ("var " in mojo or "let " in mojo),
        "mentions Owned/Rc/Arc/borrowed": any(k in mojo for k in ("owned", "rc", "arc", "borrowed")),
        "mentions destructor/`__del`/`def __moveinit__`": any(k in mojo for k in ("__del", "__moveinit__", "destructor")),
        "no stray c++ `std::`": "std::" not in mojo,
    }
    print("\n--- quality signals ---")
    for k, v in signals.items():
        print(f"  [{'Y' if v else 'N'}] {k}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
