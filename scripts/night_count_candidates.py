#!/usr/bin/env python3
"""Count recursive extraction candidates (ETA estimate for the sweep)."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_cpp_mojo_dataset import extract_fns

fns = extract_fns(Path("/home/amd/EnergyPlus/src/EnergyPlus"), recursive=True)
print(len(fns))
from collections import Counter
top = Counter(f.source_file.split("/")[0] for f in fns)
for k, v in top.most_common(15):
    print(f"{v:4d}  {k}")
