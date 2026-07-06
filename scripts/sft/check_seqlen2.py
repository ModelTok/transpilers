"""
More careful sequence length analysis using the actual tokenizer.
Checks if any sequences near cutoff_len=4096 could cause VRAM issues.
"""
import json
import os
import sys

sys.path.insert(0, '/root/venvs/lf/lib/python3.12/site-packages')

from transformers import AutoTokenizer

DATASET_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
    "data", "sft", "cpp_mojo",
)  # scripts/sft/<this file> -> repo root
TOKENIZER = "Qwen/Qwen2.5-Coder-3B-Instruct"

print(f"Loading tokenizer {TOKENIZER}...")
tok = AutoTokenizer.from_pretrained(TOKENIZER, trust_remote_code=True)

info_file = os.path.join(DATASET_DIR, "dataset_info.json")
with open(info_file) as f:
    info = json.load(f)

for ds_name in ["mojo_acquisition"]:
    if ds_name not in info:
        print(f"{ds_name}: not found")
        continue

    ds_info = info[ds_name]
    file_name = ds_info.get("file_name", "")
    file_path = os.path.join(DATASET_DIR, file_name)

    with open(file_path) as f:
        try:
            data = json.load(f)
        except:
            # Try JSONL
            f.seek(0)
            data = [json.loads(l) for l in f if l.strip()]

    print(f"\n{ds_name} ({len(data)} samples), file: {file_name}")
    print(f"Sample[0] keys: {list(data[0].keys()) if data else '?'}")
    if data:
        print(f"Sample[0]: {str(data[0])[:200]}")

    # Tokenize and measure
    lengths = []
    for i, sample in enumerate(data[:50]):  # Check first 50
        # Build text similar to how LF does it
        text = ""
        for v in sample.values():
            if isinstance(v, str):
                text += v + " "
            elif isinstance(v, list):
                for item in v:
                    if isinstance(item, dict):
                        for vv in item.values():
                            if isinstance(vv, str):
                                text += vv + " "

        n_toks = len(tok.encode(text))
        lengths.append((i, n_toks))
        if n_toks > 2048:
            print(f"  LONG: sample {i} = {n_toks} tokens")

    lengths.sort(key=lambda x: -x[1])
    print(f"Top 10 longest (first 50 samples):")
    for idx, n in lengths[:10]:
        print(f"  sample[{idx:4d}]: {n} tokens")
