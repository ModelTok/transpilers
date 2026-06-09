#!/usr/bin/env python3
"""One-shot: rank PARTIAL ('amber') modules from migraph's embedded graph data.

Reads the node data baked into migration_graph.html (status, inbound-#include
count `indeg`, loc, target file `tgt`/`ker`), keeps the PARTIAL modules, ranks
them by inbound #includes (leverage proxy) with LOC as tiebreak, and emits
swarm_worklist.{md,json}. Pure stdlib, no model/torch/installs.
"""
import json, re, sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
HTML = HERE / "migration_graph.html"
MAP = Path("C:/Github/energyplus-mojo/.migration_progress/MIGRATION_MAP.md")
CPP = Path("C:/Github/EnergyPlus/src/EnergyPlus")
TOPN = 30

# ---- pull the embedded JSON: `const DATA={...};` (greedy to the closing `;`) ----
txt = HTML.read_text(encoding="utf-8", errors="ignore")
m = re.search(r"const DATA=(\{.*?\});", txt, re.S)
if not m:
    sys.exit("could not find embedded DATA in migration_graph.html")
data = json.loads(m.group(1))
nodes = data["nodes"]

# ---- map note column (cells[4]) per module from MIGRATION_MAP.md ----
notes = {}
for ln in MAP.read_text(encoding="utf-8", errors="ignore").splitlines():
    if not ln.strip().startswith("|"):
        continue
    cells = [c.strip() for c in ln.strip().strip("|").split("|")]
    mm = re.search(r"`([^`]+)\.(?:cc|hh|h)`", cells[0]) if cells else None
    if not mm:
        continue
    key = mm.group(1).split("/")[-1]
    note = cells[4] if len(cells) > 4 else ""
    notes.setdefault(key, note)

# ---- locate the actual cpp path for a module id ----
def cpp_path(mid: str) -> str:
    for ext in (".cc", ".hh", ".h"):
        p = CPP / (mid + ext)
        if p.is_file():
            return f"src/EnergyPlus/{mid}{ext}"
    # try basename across tree
    base = mid.split("/")[-1]
    for ext in (".cc", ".hh", ".h"):
        hits = list(CPP.rglob(base + ext))
        if hits:
            return "src/EnergyPlus/" + str(hits[0].relative_to(CPP)).replace("\\", "/")
    return ""

partial = [n for n in nodes if n.get("status") == "PARTIAL"]

# Modules energyplus-mojo replaces architecturally (global data-structs, the
# IDD input processor, generic plumbing/node-connection helpers) rather than
# 1:1-porting their physics. They top the raw inbound-#include count because
# everything includes them, but they are NOT amber->green *physics* swarm work.
# Flag (don't drop) them so the runner can skip or deprioritise.
INFRA = {
    "InputProcessor", "DataEnvironment", "DataHVACGlobals", "General",
    "DataHeatBalance", "NodeInputManager", "BranchNodeConnections",
    "PlantUtilities", "DataZoneEquipment", "DataSurfaces", "GeneralRoutines",
    "DataZoneEnergyDemands", "OutAirNodeManager", "Autosizing/Base",
    "BranchInputManager",
}
def is_infra(mid: str) -> bool:
    return mid in INFRA or mid.split("/")[-1] in {i.split("/")[-1] for i in INFRA}

# rank: inbound #includes desc, then LOC desc, then name
partial.sort(key=lambda n: (-n.get("indeg", 0), -n.get("loc", 0), n["id"]))
top = partial[:TOPN]

rows = []
for rank, n in enumerate(top, 1):
    mid = n["id"]
    base = mid.split("/")[-1]
    tgt = n.get("tgt", "").strip()
    ker = n.get("ker", "").strip()
    if ker and ker not in ("—", "—", ""):
        tgt_full = f"{tgt} (+kernels: {ker})" if tgt else f"(kernels: {ker})"
    else:
        tgt_full = tgt or "—"
    rows.append({
        "rank": rank,
        "module": base,
        "status": "PARTIAL",
        "inbound_includes": n.get("indeg", 0),
        "loc": n.get("loc", 0),
        "cpp_path": cpp_path(mid),
        "target_py": tgt or "",
        "kernels": ker if ker not in ("—", "—") else "",
        "infra_replaced": is_infra(mid),
        "note": notes.get(base, "").strip(),
        "_tgt_full": tgt_full,
    })

# physics-only secondary view: drop the architecturally-replaced infra rows and
# re-rank the real component/physics modules (still by inbound includes, LOC tie)
physics = [n for n in partial if not is_infra(n["id"])]
physics.sort(key=lambda n: (-n.get("indeg", 0), -n.get("loc", 0), n["id"]))

# ---- JSON artifact (machine-readable for the swarm runner) ----
json_out = [
    {
        "module": r["module"],
        "status": r["status"],
        "inbound_includes": r["inbound_includes"],
        "loc": r["loc"],
        "cpp_path": r["cpp_path"],
        "target_py": r["target_py"],
        "infra_replaced": r["infra_replaced"],
    }
    for r in rows
]
physics_out = []
for n in physics[:TOPN]:
    base = n["id"].split("/")[-1]
    physics_out.append({
        "module": base,
        "status": "PARTIAL",
        "inbound_includes": n.get("indeg", 0),
        "loc": n.get("loc", 0),
        "cpp_path": cpp_path(n["id"]),
        "target_py": n.get("tgt", "").strip(),
        "infra_replaced": False,
    })

(HERE / "swarm_worklist.json").write_text(
    json.dumps({"ranking_method": "inbound #include count (leverage proxy), "
                                  "LOC tiebreak; infra_replaced rows are "
                                  "architecturally replaced, not physics ports",
                "by_inbound_includes": json_out,
                "physics_priority": physics_out}, indent=2) + "\n",
    encoding="utf-8")

# ---- Markdown artifact ----
def esc(s: str) -> str:
    return (s or "").replace("|", "\\|").replace("\n", " ").strip()

n_partial = len(partial)
lines = []
lines.append("# Swarm worklist — amber→green priority queue")
lines.append("")
lines.append(f"Ranks the {n_partial} PARTIAL (\"amber\") EnergyPlus modules — those with a "
             "Python data-model/records loader but **no Mojo physics yet** — so the "
             "transpiler swarm converts the highest-leverage ones first.")
lines.append("**Ranking method:** by **inbound `#include` count** (how many other C++ "
             "modules depend on this one — a direct proxy for blast-radius/leverage), "
             "computed by `migraph` over `EnergyPlus/src/EnergyPlus/*.{cc,hh}`; ties broken by "
             "LOC (bigger port = more value unlocked). No profiler weighting applied: the "
             "existing `profile_snapshots` measure *runtime* self-time of already-ported "
             "(COMPLETE) code, not these unported modules, so they can't rank amber work.")
lines.append("")
lines.append("> **Heads-up for the runner:** rows marked **infra** are global data-structs / "
             "the IDD input processor / generic node-plumbing helpers that energyplus-mojo "
             "replaces *architecturally* (no 1:1 Mojo-physics port). They top this list only "
             "because everything `#include`s them. **Skip them for amber→green physics work** "
             "and start from the physics-priority table below.")
lines.append("")
lines.append(f"## Full inbound-#include ranking (top {len(rows)} of {n_partial} PARTIAL)")
lines.append("")
lines.append("| rank | C++ module | infra? | inbound #includes | LOC | current port target(s) in energyplus-mojo | note |")
lines.append("|---:|---|:--:|---:|---:|---|---|")
for r in rows:
    flag = "infra" if r["infra_replaced"] else ""
    lines.append(f"| {r['rank']} | `{r['module']}.cc` | {flag} | {r['inbound_includes']} | "
                 f"{r['loc']} | {esc(r['_tgt_full'])} | {esc(r['note'])[:160]} |")
lines.append("")

# physics-priority table (infra stripped) — the queue the swarm should actually pull
lines.append("## Physics-priority queue (infra stripped) — pull these first")
lines.append("")
lines.append("Same ranking, with the architecturally-replaced infra modules removed. These are "
             "real EnergyPlus component/physics modules with records already loadable and no Mojo "
             "kernel yet — the highest-leverage amber→green conversions.")
lines.append("")
lines.append("| rank | C++ module | inbound #includes | LOC | current port target(s) | note |")
lines.append("|---:|---|---:|---:|---|---|")
for i, n in enumerate(physics[:TOPN], 1):
    base = n["id"].split("/")[-1]
    tgt = n.get("tgt", "").strip()
    ker = n.get("ker", "").strip()
    tf = (f"{tgt} (+kernels: {ker})" if tgt else f"(kernels: {ker})") if ker and ker not in ("—", "—") else (tgt or "—")
    lines.append(f"| {i} | `{base}.cc` | {n.get('indeg',0)} | {n.get('loc',0)} | "
                 f"{esc(tf)} | {esc(notes.get(base,''))[:160]} |")
lines.append("")
(HERE / "swarm_worklist.md").write_text("\n".join(lines) + "\n", encoding="utf-8")

# ---- console summary for the report ----
print(f"PARTIAL total: {n_partial}")
print("== full inbound-#include top 10 (infra flagged) ==")
for r in rows[:10]:
    flag = " [INFRA]" if r["infra_replaced"] else ""
    print(f"{r['rank']:>2}. {r['module']:<28} indeg={r['inbound_includes']:>3} "
          f"loc={r['loc']:>5}{flag}")
print("== physics-priority top 10 (infra stripped) ==")
for i, n in enumerate(physics[:10], 1):
    base = n["id"].split("/")[-1]
    print(f"{i:>2}. {base:<28} indeg={n.get('indeg',0):>3} loc={n.get('loc',0):>5}  "
          f"-> {n.get('tgt','').strip() or '(no py target)'}")
print("wrote swarm_worklist.md + swarm_worklist.json")
