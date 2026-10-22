set -euo pipefail

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
