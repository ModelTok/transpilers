#!/usr/bin/env python3
"""Classify each upstream C++ module as kernel (numeric -> Mojo) vs application
(I/O / control -> Python), using the heuristic classifier from the `transpilers`
repo, and write a JSON sidecar that `migraph migration` overlays on the graph.

  python -m migraph classify [--cpp-src DIR] [--transpilers DIR] [--out JSON]

Defaults:
  --cpp-src     $ENERGYPLUS_SRC, then ../EnergyPlus/src/EnergyPlus
  --transpilers /home/db/transpilers  (or $TRANSPILERS_HOME)
  --out         ./.migration_progress/kernel_class.json

Output JSON: { "<module-basename>": {kind, kscore, conf, reasons:[...]}, ... }
  kind   = kernel | application | mixed | unknown
  kscore = kernel_score / (kernel_score + app_score)   (0..1; higher = more numeric)
"""
import os, re, sys, json, argparse, collections
from pathlib import Path

def _resolve_cpp(explicit):
    cands = []
    if explicit: cands.append(Path(explicit))
    if os.environ.get("ENERGYPLUS_SRC"): cands.append(Path(os.environ["ENERGYPLUS_SRC"]))
    cands += [Path.cwd().parent / "EnergyPlus" / "src" / "EnergyPlus",
              Path("/home/db/EnergyPlus/src/EnergyPlus")]
    return next((c for c in cands if c.is_dir()), None)

ap = argparse.ArgumentParser(prog="migraph classify")
ap.add_argument("--cpp-src", dest="cpp_src")
ap.add_argument("--transpilers", default=os.environ.get("TRANSPILERS_HOME", "/home/db/transpilers"))
ap.add_argument("--out")
args = ap.parse_args()

CPP = _resolve_cpp(args.cpp_src)
if CPP is None:
    print("classify: C++ source not found (set --cpp-src or $ENERGYPLUS_SRC).", file=sys.stderr)
    sys.exit(1)

# import the transpilers kernel classifier (pure stdlib; just needs it on path)
tp = Path(args.transpilers) / "src"
if not (tp / "transpilers" / "pipeline" / "kernel_classifier.py").is_file():
    print(f"classify: transpilers classifier not found under {tp} "
          f"(set --transpilers / $TRANSPILERS_HOME).", file=sys.stderr)
    sys.exit(1)
sys.path.insert(0, str(tp))
from transpilers.pipeline.kernel_classifier import KernelClassifier  # noqa: E402

def stem(rel):
    rel = rel[len("EnergyPlus/"):] if rel.startswith("EnergyPlus/") else rel
    return re.sub(r"\.(cc|hh|h)$", "", rel)

# concatenate each module's .cc/.hh source under one basename
src_by_mod = collections.defaultdict(list)
parent = CPP.parent
for root, _, files in os.walk(CPP):
    for f in files:
        if f.endswith((".cc", ".hh", ".h")):
            p = Path(root) / f
            mid = stem(os.path.relpath(p, parent)).split("/")[-1]   # basename matches graph labels
            src_by_mod[mid].append(p.read_text(encoding="utf-8", errors="ignore"))

clf = KernelClassifier()
out = {}
counts = collections.Counter()
for mid, chunks in src_by_mod.items():
    r = clf.classify("\n".join(chunks))
    total = r.kernel_score + r.app_score
    kscore = round(r.kernel_score / total, 3) if total > 1e-9 else 0.0
    out[mid] = {"kind": r.kind.value, "kscore": kscore, "conf": r.confidence,
                "reasons": r.reasons[:6]}
    counts[r.kind.value] += 1

dest = Path(args.out) if args.out else (Path.cwd() / ".migration_progress" / "kernel_class.json")
dest.parent.mkdir(parents=True, exist_ok=True)
dest.write_text(json.dumps(out, indent=0, sort_keys=True))
print(f"classified {len(out)} modules -> {dest}", file=sys.stderr)
print("by kind:", dict(counts), file=sys.stderr)
