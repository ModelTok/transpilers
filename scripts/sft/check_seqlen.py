"""Check actual sequence lengths in the training datasets."""
import json
import os

DATASET_DIR = "/home/bart/Github/transpilers/data/sft/cpp_mojo"

for ds_name in ["mojo_acquisition", "cpp_mojo_translation"]:
    # Find the dataset file
    info_file = os.path.join(DATASET_DIR, "dataset_info.json")
    with open(info_file) as f:
        info = json.load(f)

    if ds_name not in info:
        print(f"{ds_name}: not in dataset_info.json")
        continue

    ds_info = info[ds_name]
    file_name = ds_info.get("file_name", "")
    file_path = os.path.join(DATASET_DIR, file_name)

    if not os.path.exists(file_path):
        print(f"{ds_name}: file not found at {file_path}")
        continue

    with open(file_path) as f:
        data = json.load(f)

    # Count total characters as proxy for token count (~4 chars/token)
    lengths = []
    for sample in data:
        total_chars = 0
        # Handle different formats
        if isinstance(sample, dict):
            for v in sample.values():
                if isinstance(v, str):
                    total_chars += len(v)
                elif isinstance(v, list):
                    for item in v:
                        if isinstance(item, dict):
                            for vv in item.values():
                                if isinstance(vv, str):
                                    total_chars += len(vv)
                        elif isinstance(item, str):
                            total_chars += len(item)
        approx_tokens = total_chars // 4
        lengths.append(approx_tokens)

    lengths.sort()
    n = len(lengths)
    print(f"\n{ds_name} ({n} samples):")
    print(f"  Approx token lengths (chars/4):")
    print(f"  min={lengths[0]}, p25={lengths[n//4]}, median={lengths[n//2]}, p75={lengths[3*n//4]}, p95={lengths[int(n*0.95)]}, max={lengths[-1]}")
    print(f"  Samples > 4096 tokens: {sum(1 for l in lengths if l > 4096)} ({100*sum(1 for l in lengths if l > 4096)/n:.1f}%)")
    print(f"  Samples > 2048 tokens: {sum(1 for l in lengths if l > 2048)} ({100*sum(1 for l in lengths if l > 2048)/n:.1f}%)")
