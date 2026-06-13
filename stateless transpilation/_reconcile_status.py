#!/usr/bin/env python3
"""One-time: set status='done' for files that already have BOTH ports on disk.
Uses a generous union of naming schemes (manifest name, snake, target_* basename)
so we never re-transpile something that's actually present."""
import json, os, re
from pathlib import Path

BASE = Path(__file__).resolve().parent
MAN = BASE / "1_manifest.json"
m = json.loads(MAN.read_text())

py = set(os.listdir(BASE / "out/python")) if (BASE / "out/python").is_dir() else set()
mj = set(os.listdir(BASE / "out/mojo")) if (BASE / "out/mojo").is_dir() else set()

def snake(s): return re.sub(r"(?<!^)(?=[A-Z])", "_", s).lower()

def candidates(rec, ext, target_key):
    n = rec["name"]
    out = {f"{n}.{ext}", f"{snake(n)}.{ext}"}
    t = rec.get(target_key)
    if t: out.add(os.path.basename(t))
    return out

done = partial = 0
for rec in m["files"]:
    has_py = bool(candidates(rec, "py", "target_python") & py)
    has_mj = bool(candidates(rec, "mojo", "target_mojo") & mj)
    if has_py and has_mj:
        rec["status"] = "done"; done += 1
    elif has_py or has_mj:
        rec["status"] = "partial"; partial += 1
    else:
        if rec.get("status") in ("done", "partial"):  # stale -> reset
            rec["status"] = "pending"

MAN.write_text(json.dumps(m, indent=2))
print(f"reconciled: done={done} partial={partial} -> wrote {MAN.name}")
