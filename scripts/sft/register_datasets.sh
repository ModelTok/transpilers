#!/usr/bin/env bash
# Register this repo's SFT datasets into LLaMA Factory so they appear in the
# LLaMA Board GUI dropdown (and `llamafactory-cli train`) by default.
#
# Idempotent: reads data/sft/cpp_mojo/dataset_info.json (relative file_names),
# rewrites each file_name to its absolute path, and merges the entries into
# LLaMA Factory's data/dataset_info.json without disturbing the built-ins.
# Re-run after upgrading / reinstalling LLaMA Factory.
#
# Usage (inside the Ubuntu-24.04 WSL distro):
#   bash scripts/sft/register_datasets.sh
# Override the LLaMA Factory registry location if needed:
#   LF_DATASET_INFO=/path/to/LLaMA-Factory/data/dataset_info.json bash scripts/sft/register_datasets.sh
set -euo pipefail

# Resolve repo paths from this script's location (…/scripts/sft/register_datasets.sh).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DATA_DIR="$REPO_ROOT/data/sft/cpp_mojo"
SRC_INFO="$DATA_DIR/dataset_info.json"
LF_INFO="${LF_DATASET_INFO:-/root/LLaMA-Factory/data/dataset_info.json}"

[ -f "$SRC_INFO" ] || { echo "ERROR: $SRC_INFO not found" >&2; exit 1; }
[ -f "$LF_INFO" ]  || { echo "ERROR: LLaMA Factory registry $LF_INFO not found (set LF_DATASET_INFO)" >&2; exit 1; }

python3 - "$SRC_INFO" "$DATA_DIR" "$LF_INFO" <<'PY'
import json, os, sys

src_info, data_dir, lf_info = sys.argv[1], sys.argv[2], sys.argv[3]

with open(src_info, encoding="utf-8") as f:
    repo_entries = json.load(f)
with open(lf_info, encoding="utf-8") as f:
    lf = json.load(f)

added, updated = [], []
for name, spec in repo_entries.items():
    spec = dict(spec)
    fn = spec.get("file_name", "")
    # Rewrite relative file_name -> absolute path so it resolves regardless of
    # the GUI's "Data dir" field (LF does os.path.join(dataset_dir, file_name),
    # and join() with an absolute path returns the absolute path).
    if not os.path.isabs(fn):
        spec["file_name"] = os.path.join(data_dir, fn)
    (updated if name in lf else added).append(name)
    lf[name] = spec

with open(lf_info, "w", encoding="utf-8") as f:
    json.dump(lf, f, indent=2)
    f.write("\n")

print(f"registered into {lf_info}")
print(f"  added:   {added or '(none)'}")
print(f"  updated: {updated or '(none)'}")
for name in repo_entries:
    print(f"  - {name} -> {lf[name]['file_name']}")
PY

echo "OK: datasets registered. Refresh the LLaMA Board page (or reopen the Train tab) to see them."
