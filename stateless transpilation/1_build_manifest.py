#!/usr/bin/env python3
"""Step 1 — build 1_manifest.json: every EnergyPlus oracle file to migrate.

Flat toolkit. Recursively scans the EnergyPlus C++ source (top level AND
subdirs: Coils, Plant, AirflowNetwork, InputProcessing, …) and emits one JSON
record per translation unit with oracle paths, size, stateful flag, tier,
target output paths, a `decision` (port|replace|stub), and status. Also lists
the bundled C++ libraries the engine depends on (ObjexxFCL, Btwxt, …) with a
decision each — a faithful port needs these too.

Usage:
  python3 1_build_manifest.py
  python3 1_build_manifest.py --oracle /path/to/EnergyPlus/src/EnergyPlus
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

BASE = Path(__file__).resolve().parent
DEFAULT_ORACLE = BASE.parent.parent / "EnergyPlus" / "src" / "EnergyPlus"

# Bundled libraries the engine depends on. Decisions:
#   native  — NOT needed as a port; handled by Python/Mojo native arrays per-file
#   reuse   — already done in the original repo (../energyplus-mojo); don't redo
#   port    — faithfully transcribe (a real algorithm we need and don't have)
#   replace — re-implement small (don't transcribe a huge lib)
#   stub    — defer / fake until needed
# Paths are searched under <repo>/third_party and <repo>/src.
DEPENDENCIES = [
    ("ObjexxFCL", "native", "Fortran 1-based array semantics — NO shim. The Py/Mojo ports use "
                            "numpy/native 0-based arrays; 1->0-based is handled per-file at transpile."),
    ("Btwxt", "reuse", "N-D table interpolation — already in ../energyplus-mojo/curves/."),
    ("Windows-CalcEngine", "port", "Detailed-window optical/thermal sub-engine; port or stub per need."),
    ("kiva", "reuse", "Ground FD solver — already stubbed at ../energyplus-mojo/foundation/kiva_stub.py."),
    ("penumbra", "replace", "GPU/OpenGL shading; replace with a CPU shading equivalent."),
]


def tier(name: str, stateful: bool) -> int:
    n = name.lower()
    if name.startswith("Data") or n in ("constant", "datastringglobals", "configuredfunctions"):
        return 0
    if not stateful or n in (
        "vectors", "surfaceoctree", "psychrometrics", "general", "curvemanager",
        "convectioncoefficients", "windowmanager", "tarcoggasses90", "fluidproperties",
    ):
        return 1
    if any(k in n for k in (
        "coil", "pump", "fan", "chiller", "boiler", "baseboard", "radiant", "tower",
        "tank", "generator", "pv", "photovolt", "battery", "heatpump", "heater",
    )):
        return 2
    if any(k in n for k in (
        "manager", "balance", "simulation", "hvac", "plant", "airloop", "zoneequip", "branch",
    )):
        return 3
    return 2


def _count(root: Path) -> tuple[int, int]:
    exts = ("*.cc", "*.cpp", "*.hh", "*.hpp", "*.h")
    files = [f for e in exts for f in root.rglob(e)] if root.is_dir() else []
    loc = sum(f.read_text(errors="ignore").count("\n") for f in files)
    return len(files), loc


def find_dependencies(repo: Path) -> list[dict]:
    deps = []
    for libname, decision, note in DEPENDENCIES:
        hits = []
        for base in (repo / "third_party", repo / "src", repo):
            if base.is_dir():
                # case-insensitive: dirs may be lowercase (e.g. btwxt, kiva)
                hits += [d for d in base.rglob("*")
                         if d.is_dir() and d.name.lower().startswith(libname.lower())]
        # shallowest match (the lib root, not a nested subdir)
        root = min(hits, key=lambda h: len(h.parts)) if hits else None
        files, loc = _count(root) if root else (0, 0)
        deps.append({"name": libname, "kind": "dependency", "decision": decision,
                     "path": str(root) if root else None, "files": files, "loc": loc,
                     "note": note, "status": "pending"})
    return deps


def fortran_records(src_root: Path, names_taken: set[str]) -> list[dict]:
    """Records for EnergyPlus-authored Fortran under src/ (NOT third_party eigen).

    Real physics (Slab/Basement/CalcSoilSurfTemp -> tier 1, port); version-
    migration tooling (Transition -> skip); other aux programs -> tier 2, port.
    """
    out: list[dict] = []
    if not src_root.is_dir():
        return out
    # Exclude the C++ engine subdir (src/EnergyPlus) — match the relative path,
    # not p.parts (the repo dir itself is named "EnergyPlus").
    fsrc = sorted(p for ext in ("*.f", "*.f90", "*.f95", "*.for")
                  for p in src_root.rglob(ext)
                  if p.relative_to(src_root).parts[0] != "EnergyPlus")
    for f in fsrc:
        parent = f.parent.name
        stem = f.stem
        name = f"{parent}_{stem}" if (stem in names_taken or f"F_{stem}" in names_taken) else f"F_{stem}"
        names_taken.add(name)
        pl = str(f).lower()
        decision = "port"  # include everything; tier orders priority, not exclusion
        if any(k in pl for k in ("slab", "basement", "calcsoilsurftemp")):
            t = 1  # ground/foundation physics
        elif "transition" in pl:
            t = 3  # IDF version-migration tooling — low priority but still ported
        else:
            t = 2  # other aux programs
        snake = re.sub(r"(?<!^)(?=[A-Z])", "_", name).lower()
        out.append({
            "name": name,
            "lang": "fortran",
            "subdir": parent,
            "cc_path": str(f),
            "hh_path": None,
            "loc": f.read_text(errors="ignore").count("\n"),
            "stateful": False,
            "tier": t,
            "decision": decision,
            "target_python": f"out/python/{name}.py",
            "target_mojo": f"out/mojo/{snake}.mojo",
            "status": "pending",
        })
    return out


def library_records(deps: list[dict], names_taken: set[str]) -> list[dict]:
    """One record per translation unit in each bundled library — included, not
    excluded. The library's decision (native/reuse/port/replace/stub) rides on
    every file so nothing is hidden; tier 8 keeps deps after the engine in order.
    """
    out: list[dict] = []
    exts = ("*.cc", "*.cpp", "*.f", "*.f90", "*.f95", "*.for")
    for d in deps:
        root = Path(d["path"]) if d.get("path") else None
        if not root or not root.is_dir():
            continue
        for f in sorted(p for e in exts for p in root.rglob(e)):
            stem = f.stem
            base = f"{d['name']}_{stem}"
            name = base
            i = 1
            while name in names_taken:
                name = f"{base}_{i}"; i += 1
            names_taken.add(name)
            lang = "fortran" if f.suffix.lower() in (".f", ".f90", ".f95", ".for") else "cpp"
            hh = f.with_suffix(".hh" if lang == "cpp" else "")
            snake = re.sub(r"(?<!^)(?=[A-Z])", "_", name).lower()
            out.append({
                "name": name, "lang": lang, "library": d["name"], "subdir": d["name"],
                "cc_path": str(f), "hh_path": str(hh) if (lang == "cpp" and hh.exists()) else None,
                "loc": f.read_text(errors="ignore").count("\n"), "stateful": False,
                "tier": 8, "decision": d["decision"],
                "target_python": f"out/python/{name}.py", "target_mojo": f"out/mojo/{snake}.mojo",
                "status": "pending",
            })
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--oracle", default=str(DEFAULT_ORACLE))
    ap.add_argument("--out", default=str(BASE / "1_manifest.json"))
    args = ap.parse_args()

    oracle = Path(args.oracle).resolve()
    if not oracle.is_dir():
        print(f"ERROR: oracle dir not found: {oracle}")
        return 1
    repo = oracle.parent.parent  # <repo>/src/EnergyPlus -> <repo>

    deps = find_dependencies(repo)

    # WHOLE-REPO scan — every translation unit becomes a record, nothing excluded.
    exts = ("*.cc", "*.cpp", "*.cxx", "*.f", "*.f90", "*.f95", "*.for")
    fortran_ext = {".f", ".f90", ".f95", ".for"}
    all_src = sorted(p for e in exts for p in repo.rglob(e))
    seen: set[str] = set()
    records = []
    for f in all_src:
        rel = f.relative_to(repo).as_posix()
        rl = rel.lower()
        lang = "fortran" if f.suffix.lower() in fortran_ext else "cpp"
        txt = f.read_text(errors="ignore")
        loc = txt.count("\n")
        stateful = "EnergyPlusData" in txt

        # decision + tier by location (8 = bundled EP libs, 9 = generic vendored).
        if rl.startswith("src/energyplus/"):
            decision, t, lib = "port", tier(f.stem, stateful), ""
        elif rl.startswith("src/"):
            decision, lib = "port", ""
            t = (1 if any(k in rl for k in ("slab", "basement", "calcsoilsurftemp"))
                 else 3 if "transition" in rl else 2)
        elif "objexxfcl" in rl:
            decision, t, lib = "native", 8, "ObjexxFCL"
        elif "/btwxt" in rl:
            decision, t, lib = "reuse", 8, "Btwxt"
        elif "/kiva" in rl and not any(k in rl for k in ("/boost", "/vendor", "/test")):
            decision, t, lib = "reuse", 8, "kiva"
        elif "windows-calcengine" in rl:
            decision, t, lib = "port", 8, "Windows-CalcEngine"
        elif "penumbra" in rl:
            decision, t, lib = "replace", 8, "penumbra"
        else:  # generic vendored deps: boost, gtest, eigen, sqlite, fmt, json, re2, zlib...
            decision, t, lib = "replace", 9, rel.split("/")[1] if "/" in rel[12:] else "third_party"

        # collision-safe name
        base = f.stem if f.stem not in seen else f"{f.parent.name}_{f.stem}"
        name, i = base, 1
        while name in seen:
            name, i = f"{base}_{i}", i + 1
        seen.add(name)
        hh = next((f.with_suffix(s) for s in (".hh", ".hpp", ".h") if f.with_suffix(s).exists()), None)
        snake = re.sub(r"(?<!^)(?=[A-Z])", "_", name).lower()
        records.append({
            "name": name, "lang": lang, "library": lib,
            "subdir": str(Path(rel).parent), "cc_path": str(f),
            "hh_path": str(hh) if (lang == "cpp" and hh) else None,
            "loc": loc, "stateful": stateful, "tier": t, "decision": decision,
            "target_python": f"out/python/{name}.py", "target_mojo": f"out/mojo/{snake}.mojo",
            "status": "pending",
        })

    records.sort(key=lambda r: (r["tier"], r["loc"]))
    from collections import Counter
    by_decision = Counter(r["decision"] for r in records)
    by_lang = Counter(r["lang"] for r in records)
    # Preserve transpilation progress across rebuilds: carry over status
    # (done/partial) from any existing manifest, keyed by file name.
    prev_path = Path(args.out)
    if prev_path.exists():
        try:
            prev = {r["name"]: r.get("status")
                    for r in json.loads(prev_path.read_text()).get("files", [])}
            carried = 0
            for r in records:
                st = prev.get(r["name"])
                if st in ("done", "partial"):
                    r["status"] = st
                    carried += 1
            print(f"  carried over status for {carried} files from existing manifest")
        except Exception as e:  # noqa: BLE001
            print(f"  WARN: could not carry over prior status: {e}")

    manifest = {
        "oracle_dir": str(oracle),
        "total_files": len(records),
        "total_loc": sum(r["loc"] for r in records),
        "by_lang": dict(by_lang),
        "by_decision": dict(by_decision),
        "tiers": {str(t): sum(1 for r in records if r["tier"] == t) for t in (0, 1, 2, 3, 8, 9)},
        "dependencies": deps,
        "files": records,
    }
    Path(args.out).write_text(json.dumps(manifest, indent=2))
    print(f"wrote {args.out}")
    print(f"  {manifest['total_files']} file records — NOTHING excluded "
          f"({by_lang.get('cpp', 0)} C++ + {by_lang.get('fortran', 0)} Fortran), "
          f"{manifest['total_loc']:,} LOC")
    print(f"  by decision: {dict(by_decision)}")
    print(f"  tiers (0-3 engine, 8 bundled libs): {manifest['tiers']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
