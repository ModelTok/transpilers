#!/usr/bin/env python3
"""migraph — render an interactive migration-progress graph.

A single 2D graph: the full upstream C++ module/#include graph (EnergyPlus by
default), every node coloured by its port status read from a MIGRATION_MAP.md,
plus a git-history timeline you can scrub/animate. Status legend:

  COMPLETE     green   physics + runtime ported (kernel + wrapper + dispatch)
  PARTIAL      amber   data model parsed/loadable, no runtime physics yet
  NOT_STARTED  red     explicitly listed in the map, no port
  unmapped     gray    not in the map (infra / not yet triaged)

Usage:
  python -m migraph migration [--map PATH] [--repo PATH] [--cpp-src PATH] [--out PATH]
  python migraph/migration_graph.py --map ../energyplus-mojo/.migration_progress/MIGRATION_MAP.md

Paths (all overridable; sensible defaults so it runs arg-free inside a target repo):
  --map      migration map markdown   (default: ./.migration_progress/MIGRATION_MAP.md)
  --repo     target repo for the git-history timeline (default: git root of the map)
  --cpp-src  upstream C++ source       (default: $ENERGYPLUS_SRC, then ../EnergyPlus/src/EnergyPlus)
  --out      output html               (default: <repo>/docs/migration_graph.html)
If the C++ source or map is missing, it prints a warning and exits 0 (never
blocks a commit hook).
"""
import os, re, json, sys, collections, subprocess, argparse
from pathlib import Path

def _git_root(start: Path):
    try:
        return Path(subprocess.run(["git", "-C", str(start), "rev-parse", "--show-toplevel"],
                                   capture_output=True, text=True, check=True).stdout.strip())
    except Exception:
        return None

def _resolve_cpp(repo: Path, explicit) -> Path | None:
    cands = []
    if explicit:
        cands.append(Path(explicit))
    if os.environ.get("ENERGYPLUS_SRC"):
        cands.append(Path(os.environ["ENERGYPLUS_SRC"]))
    cands += [repo.parent / "EnergyPlus" / "src" / "EnergyPlus",
              Path("/home/db/EnergyPlus/src/EnergyPlus")]
    return next((c for c in cands if c.is_dir()), None)

ap = argparse.ArgumentParser(prog="migraph migration", description="Migration-progress graph")
ap.add_argument("--map", help="migration map markdown")
ap.add_argument("--repo", help="target repo for git-history timeline")
ap.add_argument("--cpp-src", dest="cpp_src", help="upstream C++ source dir")
ap.add_argument("--out", help="output html path")
ap.add_argument("--classify", help="kernel-class JSON sidecar (kernel vs application)")
args = ap.parse_args()

MAP = Path(args.map).resolve() if args.map else (Path.cwd() / ".migration_progress" / "MIGRATION_MAP.md")
REPO = (Path(args.repo).resolve() if args.repo else (_git_root(MAP.parent) or MAP.parent.parent))
OUT = Path(args.out).resolve() if args.out else (REPO / "docs" / "migration_graph.html")
CPP = _resolve_cpp(REPO, args.cpp_src)

# optional kernel-vs-application overlay (from `migraph classify`)
CLASS_PATH = Path(args.classify) if args.classify else (MAP.parent / "kernel_class.json")
KCLASS = json.loads(CLASS_PATH.read_text()) if CLASS_PATH.is_file() else {}

if CPP is None:
    print("migraph: upstream C++ source not found (set --cpp-src or $ENERGYPLUS_SRC); "
          "skipping.", file=sys.stderr)
    sys.exit(0)
if not MAP.is_file():
    print(f"migraph: migration map {MAP} not found; skipping.", file=sys.stderr)
    sys.exit(0)

# ---- parse migration map: basename(no ext) -> (status, targets, kernels) ----
RANK = {"NOT_STARTED": 0, "PARTIAL": 1, "COMPLETE": 2}
status_map = {}
for ln in MAP.read_text().splitlines():
    if not ln.strip().startswith("|"):
        continue
    cells = [c.strip() for c in ln.strip().strip("|").split("|")]
    if len(cells) < 2:
        continue
    m = re.search(r"`([^`]+)\.(?:cc|hh|h)`", cells[0])
    if not m:
        continue
    st = cells[1].replace("*", "").strip().upper()
    if st not in RANK:
        continue
    key = m.group(1)
    tgt = cells[2].replace("`", "") if len(cells) > 2 else ""
    ker = cells[3].replace("`", "") if len(cells) > 3 else ""
    if key not in status_map or RANK[st] > RANK[status_map[key][0]]:
        status_map[key] = (st, tgt, ker)

# ---- IDD object coverage overlay --------------------------------------------
# Module status (above) is coarse: a whole .cc is COMPLETE/PARTIAL/UNMAPPED. But
# most migration work adds individual IDD *objects* inside already-mapped
# modules, which never moves the status. This overlay measures, per module, what
# fraction of the IDD object types it handles are actually loaded in the target
# repo — so object-level ports show up.
QSTR = re.compile(r'"([A-Za-z][A-Za-z0-9:_-]+)"')  # incl. '-' (e.g. EquivalentOne-Diode)


def _load_schema_classes(repo: Path):
    for cand in (repo / "src" / "energyplus_mojo" / "data" / "Energy+.schema.epJSON",
                 Path("/mnt/c/Github/energyplus-mojo/src/energyplus_mojo/data/Energy+.schema.epJSON")):
        try:
            return set(json.loads(cand.read_text()).get("properties", {}))
        except Exception:
            continue
    return set()


SCHEMA_CLASSES = _load_schema_classes(REPO)
# classes "loaded" = schema class names that appear as a quoted string anywhere
# in the target python src (excluding the idd schema-tooling dir). A class gains
# coverage the moment a records loader references it by name.
loaded_classes = set()
_all_toks: set[str] = set()
if SCHEMA_CLASSES:
    srcdir = REPO / "src" / "energyplus_mojo"
    for p in srcdir.rglob("*.py"):
        if f"{os.sep}idd{os.sep}" in str(p):
            continue
        toks = set(QSTR.findall(p.read_text(errors="ignore")))
        _all_toks |= toks
        loaded_classes |= (toks & SCHEMA_CLASSES)
    # variable-concatenated loaders: `epjson.get(base + "Suffix")` where `base`
    # is a quoted prefix ending in ':' and the suffix is a separate quoted token
    # (e.g. ThermostatSetpoint:ThermalComfort:Fanger:* split across base+suffix).
    bases = [t for t in _all_toks if t.endswith(":") and len(t) >= 12]
    for c in SCHEMA_CLASSES - loaded_classes:
        if any(c.startswith(b) and c[len(b):] in _all_toks for b in bases):
            loaded_classes.add(c)
mod_obj = collections.defaultdict(set)   # mid -> set of IDD object types it handles

# ---- EnergyPlus modules + include edges ----
RE_INC = re.compile(r"#include\s*<EnergyPlus/([^>]+)>")

def stem(rel: str) -> str:
    p = rel[len("EnergyPlus/"):] if rel.startswith("EnergyPlus/") else rel
    return re.sub(r"\.(cc|hh|h)$", "", p)

loc = collections.Counter()
inc = collections.Counter()
cpp_parent = CPP.parent
for root, _, fs in os.walk(CPP):
    for f in fs:
        if not f.endswith((".cc", ".hh", ".h")):
            continue
        path = Path(root) / f
        rel = os.path.relpath(path, cpp_parent)
        mid = stem(rel)
        txt = path.read_text(encoding="utf-8", errors="ignore")
        lines = txt.splitlines()
        loc[mid] += len(lines)
        if f.endswith(".cc") and SCHEMA_CLASSES:
            mod_obj[mid] |= (set(QSTR.findall(txt)) & SCHEMA_CLASSES)
        for l in lines:
            im = RE_INC.match(l.strip())
            if im:
                tg = re.sub(r"\.(hh|h)$", "", im.group(1))
                if tg != mid:
                    inc[(mid, tg)] += 1

def status_of(mid: str):
    return status_map.get(mid.split("/")[-1], ("UNMAPPED", "", ""))

ids = set(loc)
# inbound include count = how many modules depend on this one (leverage)
indeg = collections.Counter()
for (a, b), _ in inc.items():
    if a in ids and b in ids:
        indeg[b] += 1

# ---- migration timeline: when did each module's target files first land? ----
# The map has a single commit, so progress is reconstructed from git history:
# a module becomes PARTIAL when its first target/data module appears, and
# COMPLETE (for COMPLETE finals) when the last target file + kernel has landed.
def build_first_add_index() -> dict:
    try:
        out = subprocess.run(
            ["git", "-C", str(REPO), "log", "--diff-filter=A",
             "--reverse", "--format=C|%ct", "--name-only"],
            capture_output=True, text=True, check=True).stdout
    except Exception as e:  # not a git repo / git missing -> no timeline
        print(f"build_migration_graph: timeline unavailable ({e})", file=sys.stderr)
        return {}
    addt, ct = {}, None
    for line in out.splitlines():
        if line.startswith("C|"):
            ct = int(line[2:])
        elif line.strip():
            addt.setdefault(line.strip(), ct)
    return addt

ADDT = build_first_add_index()
HEAD_T = max(ADDT.values()) if ADDT else 0

def target_times(tgt: str, ker: str):
    """(times of py/dir 'data-model' targets, times of kernel targets)."""
    cell = f"{tgt} {ker}"
    py = [f"src/energyplus_mojo/{p}" for p in re.findall(r"([\w/]+\.py)", cell)]
    moj = [f"src/kernels/{k}" for k in re.findall(r"([\w/]+\.mojo)", cell)]
    for d in re.findall(r"`([\w/]+)/`", cell):              # `schedules/` (full module)
        pref = f"src/energyplus_mojo/{d}/"
        py += [p for p in ADDT if p.startswith(pref)]
    tt = sorted({ADDT[p] for p in py if p in ADDT})
    kt = sorted({ADDT[p] for p in moj if p in ADDT})
    return tt, kt

def milestones(st, tgt, ker):
    """-> (partial_at, complete_at) unix seconds or None."""
    if st in ("UNMAPPED", "NOT_STARTED", "INFRA"):
        return None, None
    tt, kt = target_times(tgt, ker)
    allt = tt + kt
    if not allt:                       # mapped but files unresolved -> light at HEAD
        return (HEAD_T or None), (HEAD_T if st == "COMPLETE" else None)
    partial_at = min(tt) if tt else min(allt)
    complete_at = max(allt) if st == "COMPLETE" else None
    return partial_at, complete_at

# deterministic ordering so git diffs stay minimal
nodes = []
change_points = set()
for mid in sorted(loc):
    st, tgt, ker = status_of(mid)
    pat, cat = milestones(st, tgt, ker)
    if pat:
        change_points.add(pat)
    if cat:
        change_points.add(cat)
    kc = KCLASS.get(mid.split("/")[-1], {})
    mc = mod_obj.get(mid, set())
    ot = len(mc)
    ol = len(mc & loaded_classes)
    # A module that owns NO IDD object type and isn't in the map is C++
    # infrastructure (EnergyPlusData, RootFinder, UtilityRoutines, InputProcessor,
    # data structs, window/TARCOG numerics) that energyplus-mojo replaces with a
    # different architecture — not a 1:1 port target. Classify it INFRA so
    # UNMAPPED reflects only real portable debt (modules that own IDD objects but
    # have no records yet).
    if st == "NOT_STARTED" or (st == "UNMAPPED" and ot == 0):
        st = "INFRA"
    _scol = {"COMPLETE": "#3fb950", "PARTIAL": "#d29922",
             "INFRA": "#484f58", "UNMAPPED": "#6e7681"}
    nodes.append({"id": mid, "label": mid.split("/")[-1], "status": st,
                  "fill": _scol.get(st, "#6e7681"),
                  "loc": loc[mid], "tgt": tgt, "ker": ker,
                  "indeg": indeg.get(mid, 0), "parent": "G:" + st,
                  "pat": pat, "cat": cat,
                  "kind": kc.get("kind", "unknown"), "kscore": kc.get("kscore", 0.0),
                  "objT": ot, "objL": ol,
                  "objCov": (round(ol / ot, 3) if ot else None)})
edges = [{"s": a, "t": b, "w": w}
         for (a, b), w in sorted(inc.items()) if a in ids and b in ids]

# timeline frames = sorted change points, bracketed by a start and a final frame
timeline = []
if change_points and ADDT:
    cps = sorted(change_points)
    timeline = [min(cps) - 1] + cps                 # leading "nothing migrated" frame
    if timeline[-1] < HEAD_T:
        timeline.append(HEAD_T)
# ---- hard-set 2x2 quadrant coordinates (collision-free, baked per node) ----
import math
QW, QH, GUT = 1400, 980, 70                         # quadrant w/h + gutter between boxes
PADX, PAD_TOP, PAD_BOT = 55, 95, 45                 # inner padding (extra top room for label)
QUAD = {"COMPLETE": (0, 0), "PARTIAL": (1, 0),
        "INFRA": (0, 1), "UNMAPPED": (1, 1)}
_by_status = collections.defaultdict(list)
for n in nodes:
    _by_status[n["status"]].append(n)
for st, group in _by_status.items():
    c0, r0 = QUAD.get(st, (0, 0))
    bx, by = c0 * (QW + GUT), r0 * (QH + GUT)
    k = len(group)
    cols = max(1, math.ceil(math.sqrt(k)))
    rows = max(1, math.ceil(k / cols))
    uW, uH = QW - 2 * PADX, QH - PAD_TOP - PAD_BOT
    for i, n in enumerate(group):
        c, r = i % cols, i // cols
        x = bx + PADX + (uW * c / (cols - 1) if cols > 1 else uW / 2)
        y = by + PAD_TOP + (uH * r / (rows - 1) if rows > 1 else uH / 2)
        n["x"], n["y"] = round(x, 1), round(y, 1)
# quadrant rectangles (for the box outlines drawn in the viewer)
quad_boxes = {st: {"x1": c * (QW + GUT), "y1": r * (QH + GUT), "w": QW, "h": QH}
              for st, (c, r) in QUAD.items()}

# self-check: every node inside its quadrant, no two quadrants overlapping
for n in nodes:
    b = quad_boxes[n["status"]]
    assert b["x1"] <= n["x"] <= b["x1"] + b["w"] and b["y1"] <= n["y"] <= b["y1"] + b["h"], \
        f"node {n['id']} outside its quadrant"
_bl = list(quad_boxes.values())
for i in range(len(_bl)):
    for j in range(i + 1, len(_bl)):
        a, b = _bl[i], _bl[j]
        overlap = (a["x1"] < b["x1"] + b["w"] and b["x1"] < a["x1"] + a["w"] and
                   a["y1"] < b["y1"] + b["h"] and b["y1"] < a["y1"] + a["h"])
        assert not overlap, "quadrant boxes overlap"

# global IDD object coverage (the headline that moves with every object port)
_handled = set().union(*mod_obj.values()) if mod_obj else set()
coverage = {
    "schemaTotal": len(SCHEMA_CLASSES),
    "loaded": len(loaded_classes),
    "handledTotal": len(_handled),
    "handledLoaded": len(_handled & loaded_classes),
}
data = {"nodes": nodes, "edges": edges, "timeline": timeline, "quads": quad_boxes,
        "coverage": coverage}
if timeline:
    import datetime as _dt
    _utc = _dt.timezone.utc
    span = (_dt.datetime.fromtimestamp(timeline[0], _utc).strftime("%Y-%m-%d"),
            _dt.datetime.fromtimestamp(timeline[-1], _utc).strftime("%Y-%m-%d"))
    print(f"timeline: {len(timeline)} frames, {span[0]} -> {span[1]}", file=sys.stderr)

cnt = collections.Counter(n["status"] for n in nodes)
locsum = collections.Counter()
for n in nodes:
    locsum[n["status"]] += n["loc"]
total_loc = sum(locsum.values()) or 1
_cov = data["coverage"]
_covpct = (100 * _cov["loaded"] // _cov["schemaTotal"]) if _cov["schemaTotal"] else 0
print(f"migration graph: {len(nodes)} modules, {len(edges)} edges  "
      f"{dict(cnt)}  "
      f"LOC%=" + ", ".join(f"{k} {100*v//total_loc}" for k, v in locsum.items())
      + f"  | IDD object coverage {_cov['loaded']}/{_cov['schemaTotal']} ({_covpct}%)",
      file=sys.stderr)

HTML = r"""<!doctype html><html><head><meta charset="utf-8">
<title>EnergyPlus -> mojo - migration progress</title>
<script src="https://cdnjs.cloudflare.com/ajax/libs/cytoscape/3.30.2/cytoscape.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/layout-base@2.0.1/layout-base.js"></script>
<script src="https://cdn.jsdelivr.net/npm/cose-base@2.2.0/cose-base.js"></script>
<script src="https://cdn.jsdelivr.net/npm/cytoscape-fcose@2.2.0/cytoscape-fcose.js"></script>
<style>
 html,body{margin:0;height:100%;background:#0d1117;color:#c9d1d9;font:13px system-ui,sans-serif}
 #cy{position:absolute;inset:0;left:260px}
 #p{position:absolute;left:0;top:0;bottom:0;width:260px;padding:14px;box-sizing:border-box;
    background:#161b22;border-right:1px solid #30363d;overflow:auto}
 h1{font-size:15px;margin:0 0 2px} .s{color:#8b949e;font-size:12px;margin:0 0 10px}
 input[type=text]{width:100%;box-sizing:border-box;background:#0d1117;border:1px solid #30363d;color:#c9d1d9;padding:6px;border-radius:6px}
 button{background:#21262d;border:1px solid #30363d;color:#c9d1d9;padding:5px 9px;border-radius:6px;cursor:pointer;margin:2px 0}
 button:hover{background:#30363d}
 label{display:flex;align-items:center;gap:7px;cursor:pointer;margin:5px 0}
 .sw{width:12px;height:12px;border-radius:3px;flex:none}
 hr{border:0;border-top:1px solid #30363d;margin:12px 0}
 #info{font-size:12px;color:#8b949e;white-space:pre-wrap;word-break:break-word}
 .bar{height:16px;border-radius:4px;overflow:hidden;display:flex;margin:8px 0}
 .bar div{height:100%} .lg{font-size:11px;color:#8b949e;line-height:1.6}
 table{font-size:11px;border-collapse:collapse;width:100%} td{padding:1px 3px}
 #blockers div{cursor:pointer;padding:3px 5px;border-radius:5px;display:flex;justify-content:space-between;gap:6px}
 #blockers div:hover{background:#21262d} #blockers .nm{overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
 #blockers .dg{color:#8b949e;flex:none;font-variant-numeric:tabular-nums}
 .tab{display:flex;gap:4px;margin:6px 0} .tab button{flex:1;font-size:11px}
 .tab button.on{background:#1f6feb;border-color:#1f6feb;color:#fff}
 #tl{position:absolute;left:270px;right:14px;bottom:12px;background:#161b22ee;border:1px solid #30363d;
     border-radius:8px;padding:8px 12px;display:flex;align-items:center;gap:10px;backdrop-filter:blur(3px)}
 #tl.hidden{display:none}
 #tl input[type=range]{flex:1} #play{font-size:14px;width:34px}
 #tlabel{font-size:12px;color:#c9d1d9;min-width:200px;font-variant-numeric:tabular-nums}
 #tlabel b{color:#3fb950}
</style></head><body>
<div id="p">
 <h1>Migration progress</h1><p class="s">EnergyPlus C++ -> energyplus-mojo</p>
 <input type="text" id="search" placeholder="search module...">
 <div style="margin-top:8px"><button id="fit">Fit</button> <button id="relayout">Re-layout</button>
   <button id="cluster" class="on">Cluster</button></div>
 <hr><b>Colour by</b>
 <div class="tab" id="ctab">
   <button data-m="status" class="on">migration status</button>
   <button data-m="coverage">object coverage</button>
   <button data-m="kernel">kernel ↦ Mojo</button>
 </div>
 <div id="klegend" style="display:none;font-size:11px;color:#8b949e;margin-top:4px"></div>
 <hr><b>Show status</b><div id="filters"></div>
 <hr><b>IDD object coverage</b>
 <p class="lg" style="margin:2px 0">fraction of all EnergyPlus IDD object types with a records loader — moves with every object port, even inside already-mapped modules.</p>
 <div class="bar" id="barCov"></div><div id="covnum" class="lg" style="margin:-4px 0 6px"></div>
 <hr><b>By module count</b><div class="bar" id="barC"></div>
 <b>By lines of code</b><div class="bar" id="barL"></div>
 <table id="tbl"></table>
 <hr><b>Top blockers left to port</b>
 <p class="lg" style="margin:2px 0">unported modules ranked by how many others #include them — click to fly to it.</p>
 <div class="tab" id="btab">
   <button data-f="all" class="on">all left</button>
   <button data-f="PARTIAL">partial</button>
   <button data-f="UNMAPPED">unmapped</button>
   <button data-f="KERNEL">kernel↦Mojo</button>
 </div>
 <div id="blockers"></div>
 <hr><b>Selection</b><div id="info">click a node...</div>
</div><div id="cy"></div>
<div id="tl" class="hidden">
  <button id="play" title="play / pause">&#9654;</button>
  <input type="range" id="scrub" min="0" max="0" value="0" step="1">
  <span id="tlabel"></span>
  <button id="tlend" title="jump to today">today</button>
</div>
<script>
const DATA=__DATA__;
const COL={COMPLETE:'#3fb950',PARTIAL:'#d29922',INFRA:'#484f58',UNMAPPED:'#6e7681'};
const LABELS={COMPLETE:'Complete (runtime)',PARTIAL:'Partial (records loadable)',INFRA:'Infrastructure (architecturally replaced)',UNMAPPED:'Unmapped (portable debt)'};
const ORDER=['COMPLETE','PARTIAL','UNMAPPED','INFRA'];
const els=[];
ORDER.forEach(s=>els.push({data:{id:'G:'+s,label:LABELS[s],status:s,grp:true}}));
DATA.nodes.forEach(n=>els.push({data:{id:n.id,parent:n.parent,label:n.label,status:n.status,cur:n.status,
  tgt:n.tgt,ker:n.ker,loc:n.loc,indeg:n.indeg,pat:n.pat,cat:n.cat,x:n.x,y:n.y,
  kind:n.kind,kscore:n.kscore,fill:COL[n.status],
  objT:n.objT,objL:n.objL,objCov:n.objCov,
  size:Math.min(28,3+Math.sqrt(n.loc)*0.28)},position:{x:n.x,y:n.y}}));
DATA.edges.forEach(e=>els.push({data:{source:e.s,target:e.t,w:e.w}}));
cytoscape.use(window.cytoscapeFcose);
const cy=cytoscape({container:document.getElementById('cy'),elements:els,wheelSensitivity:0.2,
 style:[
  {selector:'node',style:{'background-color':'data(fill)','width':'data(size)','height':'data(size)',
     'border-width':0.5,'border-color':'#0d1117',
     'label':e=>e.data('size')>16?e.data('label'):'','font-size':6,'color':'#c9d1d9','min-zoomed-font-size':7}},
  {selector:':parent',style:{'background-color':e=>COL[e.data('status')],'background-opacity':0.07,
     'border-color':e=>COL[e.data('status')],'border-width':1,'shape':'round-rectangle','padding':18,
     'label':'data(label)','font-size':15,'font-weight':'bold','text-valign':'top','color':e=>COL[e.data('status')]}},
  {selector:'edge',style:{'width':e=>Math.min(5,0.3+e.data('w')*0.3),'line-color':'#30363d',
     'curve-style':'haystack','opacity':0.35}},
  {selector:'.dim',style:{'opacity':0.04}},
  {selector:'.hl',style:{'border-width':3,'border-color':'#58a6ff'}},
  {selector:'.sel',style:{'border-width':4,'border-color':'#fff','opacity':1}},
  {selector:'edge.sel',style:{'line-color':'#58a6ff','opacity':0.9,'width':1.5,'z-index':99}}
 ],
 layout:{name:'preset'}});

// current displayed status per module (mutated by the timeline); starts at final
const CUR={}; DATA.nodes.forEach(n=>CUR[n.id]=n.status);
const curOf=n=>CUR[n.id];
const tn=DATA.nodes.length;
const tl=DATA.nodes.reduce((a,n)=>a+n.loc,0);
function bar(el,vals,tot){el.innerHTML='';ORDER.forEach(s=>{if(!vals[s])return;
  const d=document.createElement('div');d.style.width=(100*vals[s]/tot)+'%';d.style.background=COL[s];
  d.title=LABELS[s]+': '+vals[s];el.appendChild(d);});}
function updateStats(){
  const cnt={},lc={}; ORDER.forEach(s=>{cnt[s]=0;lc[s]=0;});
  DATA.nodes.forEach(n=>{const s=curOf(n);cnt[s]++;lc[s]+=n.loc;});
  bar(document.getElementById('barC'),cnt,tn);
  bar(document.getElementById('barL'),lc,tl);
  const cov=DATA.coverage||{loaded:0,schemaTotal:1};
  const cpct=cov.schemaTotal?100*cov.loaded/cov.schemaTotal:0;
  document.getElementById('barCov').innerHTML=
    '<div style="width:'+cpct.toFixed(1)+'%;background:#3fb950"></div>'+
    '<div style="width:'+(100-cpct).toFixed(1)+'%;background:#30363d"></div>';
  document.getElementById('covnum').textContent=
    cov.loaded+' / '+cov.schemaTotal+' IDD object types loaded ('+cpct.toFixed(1)+'%)';
  document.getElementById('tbl').innerHTML=ORDER.map(s=>
    `<tr><td><span class="sw" style="display:inline-block;background:${COL[s]}"></span></td>`+
    `<td>${LABELS[s]}</td><td align=right>${cnt[s]}</td>`+
    `<td align=right>${(100*lc[s]/tl).toFixed(0)}% LOC</td></tr>`).join('');
}
updateStats();

// status filters
const fdiv=document.getElementById('filters');
ORDER.forEach(s=>{const l=document.createElement('label');
 l.innerHTML=`<input type="checkbox" class="sf" value="${s}" checked><span class="sw" style="background:${COL[s]}"></span>${LABELS[s]} (${cnt[s]})`;
 fdiv.appendChild(l);});
function applyF(){const on=new Set([...document.querySelectorAll('.sf:checked')].map(c=>c.value));
 cy.batch(()=>cy.nodes().forEach(n=>{if(n.data('grp'))return;
   n.style('display',on.has(n.data('status'))?'element':'none');}));}
document.querySelectorAll('.sf').forEach(c=>c.addEventListener('change',applyF));

// top-blockers panel
function focusNode(id){const n=cy.$id(id);if(!n.length)return;select(n);
  cy.animate({center:{eles:n},zoom:1.6},{duration:350});}
function renderBlockers(f){
  // "all left" = mapped-but-incomplete work (Partial+Not-started). KERNEL tab =
  // those that are numeric (kernel/mixed) -> prime Mojo-port candidates, ranked
  // by kernel-score. Uses the *current* timeline status so the list evolves.
  const left=n=>curOf(n)==='PARTIAL'||curOf(n)==='UNMAPPED';
  const kernelMode=(f==='KERNEL');
  let rows;
  if(kernelMode){
    rows=DATA.nodes.filter(n=>left(n)&&(n.kind==='kernel'||n.kind==='mixed'))
                   .sort((a,b)=>b.kscore-a.kscore||b.indeg-a.indeg);
  }else{
    rows=((f&&f!=='all')?DATA.nodes.filter(n=>curOf(n)===f)
                        :DATA.nodes.filter(left))
         .sort((a,b)=>b.indeg-a.indeg||b.loc-a.loc);
  }
  document.getElementById('blockers').innerHTML=rows.slice(0,18).map(n=>{
    const right=kernelMode?`k=${n.kscore}`:`${n.indeg}&#8599;`;
    return `<div data-id="${n.id}" title="${n.status} · ${n.kind} · ${n.loc} LOC"><span class="nm">`+
      `<span class="sw" style="display:inline-block;background:${COL[curOf(n)]};vertical-align:middle"></span> ${n.label}</span>`+
      `<span class="dg">${right}</span></div>`;}).join('');
  document.querySelectorAll('#blockers div').forEach(d=>d.onclick=()=>focusNode(d.dataset.id));
}
renderBlockers('all');
document.querySelectorAll('#btab button').forEach(b=>b.onclick=()=>{
  document.querySelectorAll('#btab button').forEach(x=>x.classList.remove('on'));
  b.classList.add('on');renderBlockers(b.dataset.f);});

document.getElementById('search').addEventListener('input',e=>{const q=e.target.value.toLowerCase().trim();
 cy.batch(()=>{cy.elements().removeClass('dim hl sel');if(!q)return;
   cy.nodes().forEach(n=>{if(n.data('grp'))return;
     const hit=n.data('label').toLowerCase().includes(q);n.addClass(hit?'hl':'dim');});
   cy.edges().addClass('dim');});});

function select(n){cy.elements().removeClass('sel dim');
 const nb=n.closedNeighborhood();cy.elements().not(nb).addClass('dim');nb.addClass('sel');
 const d=n.data();
 document.getElementById('info').textContent=
   `${d.label}.cc  [${d.status}]\nLOC ${d.loc}  ·  depended-on-by ${d.indeg}  ·  out ${n.outgoers('edge').length}`+
   `\nkind: ${d.kind} (k-score ${d.kscore} → ${d.kscore>=0.5?'Mojo kernel':'Python'})`+
   (d.objT?`\nIDD objects loaded: ${d.objL}/${d.objT} (${Math.round(100*d.objCov)}%)`:'')+
   (d.tgt?`\n\n-> ${d.tgt}`:'')+(d.ker?`\nkernels: ${d.ker}`:'');}
cy.on('tap','node',e=>{if(e.target.data('grp'))return;select(e.target);});
cy.on('tap',e=>{if(e.target===cy){cy.elements().removeClass('sel dim hl');}});

// ---- colour overlay: migration status / kernel-ness / object coverage ----
let COLORMODE='status';
function kfill(n){const k=n.data('kind');if(!k||k==='unknown')return '#484f58';
  const t=n.data('kscore')||0,L=(a,b)=>Math.round(a+(b-a)*t);   // app orange -> kernel teal
  return `rgb(${L(210,45)},${L(105,212)},${L(30,191)})`;}
function covfill(n){const c=n.data('objCov');
  if(c===null||c===undefined)return '#30363d';                  // module owns no IDD objects
  const L=(a,b)=>Math.round(a+(b-a)*c);                          // grey -> green by coverage
  return `rgb(${L(110,63)},${L(118,185)},${L(129,80)})`;}
function repaint(){cy.batch(()=>cy.nodes().forEach(n=>{if(n.data('grp'))return;
  let f=COL[CUR[n.id]];
  if(COLORMODE==='kernel')f=kfill(n); else if(COLORMODE==='coverage')f=covfill(n);
  n.style('background-color', f);}));}   // direct inline style — applies immediately
const KLEG={
 kernel:'<span style="color:rgb(45,212,191)">●</span> kernel → Mojo &nbsp; '+
  '<span style="color:rgb(210,105,30)">●</span> application → Python &nbsp; '+
  '<span style="color:#484f58">●</span> unknown<br>continuous by kernel-score (numeric content)',
 coverage:'<span style="color:#3fb950">●</span> all IDD objects loaded &nbsp; '+
  '<span style="color:#6e7681">●</span> none loaded &nbsp; '+
  '<span style="color:#30363d">●</span> module owns no IDD objects<br>'+
  'continuous green by fraction of the module’s IDD object types loaded as records'};
document.querySelectorAll('#ctab button').forEach(b=>b.onclick=()=>{
  document.querySelectorAll('#ctab button').forEach(x=>x.classList.remove('on'));
  b.classList.add('on');COLORMODE=b.dataset.m;
  const kl=document.getElementById('klegend');
  kl.innerHTML=KLEG[COLORMODE]||'';kl.style.display=KLEG[COLORMODE]?'block':'none';
  repaint();});

// ---- 2x2 quadrant clusters: positions are hard-baked per node (data x/y) ----
let clustered=true;
function layoutClustered(){            // restore the baked quadrant coordinates
  clustered=true; document.getElementById('cluster').classList.add('on');
  cy.batch(()=>{
    cy.nodes('[?grp]').style('display','element');
    cy.nodes().forEach(n=>{if(!n.data('grp')){
      n.move({parent:n.data('parent')});
      n.position({x:n.data('x'),y:n.data('y')});
    }});
  });
  fitView();
}
function layoutFlat(){
  clustered=false; document.getElementById('cluster').classList.remove('on');
  cy.nodes('[?grp]').style('display','none');
  cy.batch(()=>cy.nodes().forEach(n=>{if(!n.data('grp'))n.move({parent:null});}));
  cy.layout({name:'fcose',animate:false,randomize:true,packComponents:true,
    nodeSeparation:90,idealEdgeLength:65,nodeRepulsion:9000}).run();
}
function fitView(){                     // fit to what's actually on screen
  cy.elements().removeClass('sel dim hl');
  const vis=cy.nodes(':visible');
  cy.fit(vis.length?vis:cy.nodes(),40);
}
document.getElementById('cluster').onclick=()=>clustered?layoutFlat():layoutClustered();
document.getElementById('relayout').onclick=()=>clustered?layoutClustered():layoutFlat();
document.getElementById('fit').onclick=fitView;
layoutClustered();                       // initial render = even 2x2 grid
repaint();                               // apply initial fill colours

// ---------------- migration timeline ----------------
const TL=DATA.timeline||[];
const fmtDate=t=>new Date(t*1000).toISOString().slice(0,10);
function statusAt(n,t,isLast){
  if(isLast) return n.status;                 // final frame == the migration map exactly
  if(n.status==='UNMAPPED'||n.status==='INFRA') return n.status;
  if(n.cat!=null && t>=n.cat) return 'COMPLETE';
  if(n.pat!=null && t>=n.pat) return n.status==='COMPLETE'?'PARTIAL':n.status;
  return 'UNMAPPED';
}
// Clusters stay fixed in the 2x2 grid during playback; each quadrant lights up
// to its final colour in place (a node sits in its final-status box but is
// coloured by its status at the scrubbed moment).
function enterTimeline(){/* no-op: keep the fixed quadrant layout */}
function applyTime(idx){
  const t=TL[idx], isLast=idx===TL.length-1;
  cy.batch(()=>DATA.nodes.forEach(n=>{const s=statusAt(n,t,isLast);
    if(CUR[n.id]!==s){CUR[n.id]=s;cy.$id(n.id).data('cur',s);}}));
  if(COLORMODE==='status') repaint();     // recolour to the scrubbed moment
  const done=DATA.nodes.filter(n=>CUR[n.id]==='COMPLETE')
                       .reduce((a,n)=>a+n.loc,0);
  const pct=(100*done/tl).toFixed(0);
  document.getElementById('tlabel').innerHTML=
    `${fmtDate(t)} &nbsp; <b>${pct}% complete</b> by LOC` + (isLast?' &nbsp;(today)':'');
  updateStats();
  renderBlockers(document.querySelector('#btab button.on').dataset.f);
}
if(TL.length>1){
  document.getElementById('tl').classList.remove('hidden');
  const scrub=document.getElementById('scrub');
  scrub.max=TL.length-1; scrub.value=TL.length-1;
  applyTime(TL.length-1);                 // start at "today" (== static map)
  scrub.addEventListener('input',()=>{enterTimeline();stop();applyTime(+scrub.value);});
  let timer=null;
  const play=document.getElementById('play');
  function stop(){if(timer){clearInterval(timer);timer=null;play.innerHTML='&#9654;';}}
  function start(){enterTimeline();
    if(+scrub.value>=TL.length-1){scrub.value=0;applyTime(0);}
    play.innerHTML='&#10073;&#10073;';
    timer=setInterval(()=>{let i=+scrub.value+1;
      if(i>=TL.length-1){scrub.value=TL.length-1;applyTime(TL.length-1);stop();}
      else{scrub.value=i;applyTime(i);}},450);}
  play.onclick=()=>timer?stop():start();
  document.getElementById('tlend').onclick=()=>{stop();scrub.value=TL.length-1;applyTime(TL.length-1);};
}
</script></body></html>"""

OUT.parent.mkdir(parents=True, exist_ok=True)
OUT.write_text(HTML.replace("__DATA__", json.dumps(data)))
print(f"wrote {OUT.relative_to(REPO)}", file=sys.stderr)
