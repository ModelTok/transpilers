#!/usr/bin/env python3
"""Build two interactive 2D graphs for the EnergyPlus C++ source, mirroring the
energyplus-mojo graphs:

  ep_code_graph.html   - symbol graph: modules, classes/structs, functions,
                         methods (+ contains / inherits / calls edges)
  ep_module_graph.html - file/include dependency graph between EnergyPlus modules

C++ is parsed with calibrated regexes (no clang/ctags available). Heuristics:
  * module        = a .cc/.hh stem under src/EnergyPlus  (Boilers.cc+Boilers.hh -> "Boilers")
  * class/struct  = `class X` / `struct X` in headers (+ `: public Base` -> inherits)
  * function/method = column-0 definition in .cc: `RetType [Class::]Name(`
  * calls         = identifiers followed by '(' inside a function body that match
                    a known function name (ambiguous names capped, like the py graph)
  * includes      = `#include <EnergyPlus/....hh>`
"""
import os, re, json, sys, collections

ROOT = "src/EnergyPlus"
PREFIX = "EnergyPlus/"

SYMBOL_TPL = r"""<!doctype html>
<html><head><meta charset="utf-8"><title>energyplus-mojo code graph</title>
<script src="https://cdnjs.cloudflare.com/ajax/libs/cytoscape/3.30.2/cytoscape.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/layout-base@2.0.1/layout-base.js"></script>
<script src="https://cdn.jsdelivr.net/npm/cose-base@2.2.0/cose-base.js"></script>
<script src="https://cdn.jsdelivr.net/npm/cytoscape-fcose@2.2.0/cytoscape-fcose.js"></script>
<style>
  html,body{margin:0;height:100%;font:13px system-ui,sans-serif;background:#0d1117;color:#c9d1d9}
  #cy{position:absolute;inset:0;left:300px}
  #panel{position:absolute;top:0;left:0;bottom:0;width:300px;padding:12px;box-sizing:border-box;
         overflow:auto;background:#161b22;border-right:1px solid #30363d}
  h1{font-size:15px;margin:0 0 4px} .sub{color:#8b949e;margin:0 0 12px}
  .row{margin:6px 0} label{cursor:pointer;display:flex;align-items:center;gap:6px}
  .sw{width:12px;height:12px;border-radius:3px;display:inline-block}
  input[type=text]{width:100%;box-sizing:border-box;background:#0d1117;border:1px solid #30363d;
       color:#c9d1d9;padding:6px;border-radius:6px}
  button{background:#21262d;border:1px solid #30363d;color:#c9d1d9;padding:5px 9px;border-radius:6px;cursor:pointer;margin:2px 0}
  button:hover{background:#30363d}
  hr{border:0;border-top:1px solid #30363d;margin:12px 0}
  #info{font-size:12px;white-space:pre-wrap;word-break:break-all;color:#8b949e}
  .stat{font-size:12px;color:#8b949e}
  #legend .row{display:flex;align-items:center;gap:6px}
</style></head>
<body>
<div id="panel">
  <h1>energyplus-mojo</h1>
  <p class="sub">symbol code graph</p>
  <div class="row"><input type="text" id="search" placeholder="search symbol / module..."></div>
  <div class="row">
    <button id="fit">Fit</button>
    <button id="relayout">Re-layout</button>
    <button id="reset">Reset filters</button>
  </div>
  <hr><b>Node types</b><div id="legend"></div>
  <hr><b>Edge types</b>
  <div class="row"><label><input type="checkbox" class="ef" value="contains" checked> contains</label></div>
  <div class="row"><label><input type="checkbox" class="ef" value="calls" checked> calls</label></div>
  <div class="row"><label><input type="checkbox" class="ef" value="inherits" checked> inherits</label></div>
  <div class="row"><label><input type="checkbox" class="ef" value="imports" checked> imports</label></div>
  <hr><b>Selection</b><div id="info">click a node…</div>
  <hr><div class="stat" id="stats"></div>
  <p class="stat">Tip: type a query to dim non-matches. Uncheck "contains" + "imports" to see only call/inherit structure.</p>
</div>
<div id="cy"></div>
<script>
const DATA = /*__DATA__*/;
const COLORS = {module:'#58a6ff',class:'#f778ba',function:'#3fb950',method:'#56d364',
  variable:'#d29922',mojo_fn:'#ff7b72',mojo_struct:'#bc8cff'};
const SIZE = {module:26,class:16,function:9,method:8,variable:7,mojo_fn:9,mojo_struct:14};

const legend=document.getElementById('legend');
Object.entries(COLORS).forEach(([t,c])=>{
  const r=document.createElement('div');r.className='row';
  r.innerHTML=`<label><input type="checkbox" class="nf" value="${t}" checked>
    <span class="sw" style="background:${c}"></span>${t}</label>`;
  legend.appendChild(r);
});

const els=[];
for(const n of DATA.nodes) els.push({data:{id:n.id,label:n.label,type:n.type,
  parent:n.parent&&n.type!=='module'?n.parent:undefined,file:n.file,line:n.line}});
for(const e of DATA.edges) els.push({data:{source:e.source,target:e.target,etype:e.type}});

cytoscape.use(window.cytoscapeFcose);
const cy=cytoscape({container:document.getElementById('cy'),elements:els,
  wheelSensitivity:0.2,
  style:[
   {selector:'node',style:{'background-color':e=>COLORS[e.data('type')]||'#888',
      'width':e=>SIZE[e.data('type')]||8,'height':e=>SIZE[e.data('type')]||8,
      'label':e=>(e.data('type')==='module'||e.data('type')==='class')?e.data('label'):'',
      'font-size':7,'color':'#c9d1d9','min-zoomed-font-size':6,'text-wrap':'none'}},
   {selector:':parent',style:{'background-opacity':0.07,'background-color':'#58a6ff',
      'border-color':'#30363d','border-width':1,'label':e=>e.data('label'),
      'font-size':9,'text-valign':'top','color':'#8b949e','shape':'round-rectangle'}},
   {selector:'edge',style:{'width':0.4,'line-color':'#30363d','curve-style':'haystack',
      'haystack-radius':0,'opacity':0.5}},
   {selector:'edge[etype="calls"]',style:{'line-color':'#3fb95055'}},
   {selector:'edge[etype="inherits"]',style:{'line-color':'#f778ba','width':1}},
   {selector:'edge[etype="imports"]',style:{'line-color':'#58a6ff55'}},
   {selector:'.dim',style:{'opacity':0.05}},
   {selector:'.hl',style:{'background-color':'#ffd33d','width':18,'height':18,'opacity':1,'z-index':99}},
   {selector:'.sel',style:{'border-width':3,'border-color':'#ffd33d'}}
  ],
  layout:{name:'fcose',quality:'default',animate:false,randomize:true,
    nodeSeparation:75,idealEdgeLength:50,nodeRepulsion:4500,packComponents:true}});

document.getElementById('stats').textContent=
  `${DATA.nodes.length} nodes · ${DATA.edges.length} edges`;

function applyFilters(){
  const nt=new Set([...document.querySelectorAll('.nf:checked')].map(c=>c.value));
  const et=new Set([...document.querySelectorAll('.ef:checked')].map(c=>c.value));
  cy.batch(()=>{
    cy.nodes().forEach(n=>n.style('display', nt.has(n.data('type'))?'element':'none'));
    cy.edges().forEach(e=>e.style('display', et.has(e.data('etype'))?'element':'none'));
  });
}
document.querySelectorAll('.nf,.ef').forEach(c=>c.addEventListener('change',applyFilters));

document.getElementById('search').addEventListener('input',e=>{
  const q=e.target.value.toLowerCase().trim();
  cy.batch(()=>{
    cy.elements().removeClass('dim hl');
    if(!q) return;
    cy.nodes().forEach(n=>{
      const hit=(n.data('label')||'').toLowerCase().includes(q)||n.id().toLowerCase().includes(q);
      n.addClass(hit?'hl':'dim');
    });
    cy.edges().addClass('dim');
  });
});

cy.on('tap','node',e=>{
  cy.elements().removeClass('sel');
  const n=e.target; n.addClass('sel'); n.neighborhood().addClass('sel');
  const d=n.data();
  document.getElementById('info').textContent=
    `${d.type}  ${d.label}\n${d.id}\n${d.file||''}${d.line?':'+d.line:''}\n`+
    `↳ out ${n.outgoers('edge').length}  ↲ in ${n.incomers('edge').length}`;
});
document.getElementById('fit').onclick=()=>cy.fit(undefined,40);
document.getElementById('relayout').onclick=()=>cy.layout({name:'fcose',animate:false,randomize:true}).run();
document.getElementById('reset').onclick=()=>{
  document.querySelectorAll('.nf,.ef').forEach(c=>c.checked=true);
  document.getElementById('search').value='';
  cy.elements().removeClass('dim hl sel');applyFilters();
};
</script></body></html>"""

MODULE_TPL = r"""<!doctype html><html><head><meta charset="utf-8">
<title>energyplus-mojo module graph</title>
<script src="https://cdnjs.cloudflare.com/ajax/libs/cytoscape/3.30.2/cytoscape.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/dagre/0.8.5/dagre.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/cytoscape-dagre@2.5.0/cytoscape-dagre.min.js"></script>
<style>
 html,body{margin:0;height:100%;background:#0d1117;color:#c9d1d9;font:13px system-ui,sans-serif}
 #cy{position:absolute;inset:0;left:230px}
 #p{position:absolute;left:0;top:0;bottom:0;width:230px;padding:14px;box-sizing:border-box;
    background:#161b22;border-right:1px solid #30363d;overflow:auto}
 h1{font-size:15px;margin:0 0 2px} .s{color:#8b949e;margin:0 0 12px;font-size:12px}
 button{background:#21262d;border:1px solid #30363d;color:#c9d1d9;padding:6px 10px;border-radius:6px;cursor:pointer;margin:3px 0}
 button:hover{background:#30363d}
 #info{font-size:12px;color:#8b949e;white-space:pre-wrap}
 hr{border:0;border-top:1px solid #30363d;margin:12px 0}
 .lg{font-size:11px;color:#8b949e;line-height:1.6}
</style></head><body>
<div id="p">
 <h1>energyplus-mojo</h1><p class="s">subpackage dependency graph</p>
 <button id="fit">Fit</button> <button id="dir">Toggle layout</button>
 <hr><b>Selected</b><div id="info">click a node…</div>
 <hr><div class="lg">
  • node size = #python files<br>
  • edge width = #imports<br>
  • arrows point importer → imported<br>
  • layers top→bottom = dependency depth<br><br>
  <span style="color:#58a6ff">■</span> orchestration / model<br>
  <span style="color:#3fb950">■</span> leaf (low fan-out)<br>
  <span style="color:#f778ba">■</span> domain hub (high fan-in)
 </div>
</div><div id="cy"></div>
<script>
const DATA=__DATA__;
const fin={},fout={};
DATA.edges.forEach(e=>{fin[e.t]=(fin[e.t]||0)+e.w;fout[e.s]=(fout[e.s]||0)+e.w;});
function color(id){const i=fin[id]||0,o=fout[id]||0;
  if(o>30)return '#58a6ff'; if(i>15&&o<8)return '#f778ba'; if(o<3)return '#3fb950'; return '#8b949e';}
const els=[];
DATA.nodes.forEach(n=>els.push({data:{id:n.id,label:n.id+'\n('+n.files+')',
  size:18+Math.sqrt(n.files)*9,col:color(n.id)}}));
DATA.edges.forEach(e=>els.push({data:{source:e.s,target:e.t,w:e.w}}));
cytoscape.use(window.cytoscapeDagre);
let rk='TB';
const cy=cytoscape({container:document.getElementById('cy'),elements:els,wheelSensitivity:0.2,
 style:[
  {selector:'node',style:{'background-color':'data(col)','label':'data(label)','color':'#0d1117',
    'font-size':9,'font-weight':'bold','text-wrap':'wrap','text-valign':'center','text-halign':'center',
    'width':'data(size)','height':'data(size)','text-outline-color':'data(col)','text-outline-width':2}},
  {selector:'edge',style:{'width':e=>Math.min(8,0.6+e.data('w')*0.6),'line-color':'#484f58',
    'target-arrow-color':'#484f58','target-arrow-shape':'triangle','curve-style':'bezier','arrow-scale':0.8,'opacity':0.7}},
  {selector:'.hl',style:{'line-color':'#ffd33d','target-arrow-color':'#ffd33d','opacity':1,'z-index':9}},
  {selector:'.sel',style:{'border-width':3,'border-color':'#ffd33d'}}
 ],
 layout:{name:'dagre',rankDir:rk,nodeSep:30,rankSep:70}});
cy.on('tap','node',e=>{cy.elements().removeClass('sel hl');const n=e.target;n.addClass('sel');
  n.connectedEdges().addClass('hl');n.neighborhood('node').addClass('sel');
  document.getElementById('info').textContent=
    n.id()+'\nimports out: '+(fout[n.id()]||0)+'\nimported by: '+(fin[n.id()]||0);});
document.getElementById('fit').onclick=()=>cy.fit(undefined,40);
document.getElementById('dir').onclick=()=>{rk=rk==='TB'?'LR':'TB';
  cy.layout({name:'dagre',rankDir:rk,nodeSep:30,rankSep:70}).run();};
</script></body></html>"""

# ---------------- regexes ----------------
RE_CLASS   = re.compile(r'^\s*(class|struct)\s+([A-Za-z_]\w*)\b(?!\s*;)(.*)$')
RE_INHERIT = re.compile(r':\s*(?:public|private|protected|virtual|\s)+([A-Za-z_][\w:]*)')
# column-0 function definition: optional return-type tokens, optional Class::, name, '('
RE_FUNC    = re.compile(r'^([A-Za-z_][\w:<>,&*\[\]\s]*?\s+)?(?:([A-Za-z_]\w*)::)?([A-Za-z_]\w*)\s*\(')
RE_INC     = re.compile(r'#include\s*<EnergyPlus/([^>]+)>')
RE_CALL    = re.compile(r'\b([A-Za-z_]\w*)\s*\(')
KEYWORDS   = {"if","for","while","switch","return","sizeof","catch","throw","do",
              "else","case","new","delete","static_cast","dynamic_cast","const_cast",
              "reinterpret_cast","and","or","not","template","typename","decltype",
              "noexcept","operator","explicit","static_assert","alignof"}

def stem(rel):                       # EnergyPlus/Data/Foo.hh -> Data/Foo
    p = rel[len(PREFIX):] if rel.startswith(PREFIX) else rel
    return re.sub(r'\.(cc|hh|h)$', '', p)

# gather files
cc, hh = [], []
for r, _, fs in os.walk(ROOT):
    for f in fs:
        if f.endswith(".cc"): cc.append(os.path.join(r, f))
        elif f.endswith((".hh", ".h")): hh.append(os.path.join(r, f))

nodes = {}; edges = []; name_index = collections.defaultdict(list)
def add_node(nid, label, t, parent=None, file=None, line=None):
    nodes.setdefault(nid, {"id": nid, "label": label, "type": t,
                           "parent": parent, "file": file, "line": line})
def add_edge(s, t, et): edges.append({"source": s, "target": t, "type": et})

module_loc = collections.Counter()
include_edges = collections.Counter()
pending_calls = []

def relpath(p): return os.path.relpath(p, "src")

# ---- pass 1: headers -> modules, classes, inheritance ----
for path in hh:
    rel = relpath(path); mod = stem(rel)
    mid = "mod:" + mod
    add_node(mid, mod.split("/")[-1], "module", file=rel)
    lines = open(path, encoding="utf-8", errors="ignore").read().splitlines()
    module_loc[mid] += len(lines)
    cur_class = None
    for i, ln in enumerate(lines, 1):
        m = RE_CLASS.match(ln)
        if m and "(" not in ln.split("//")[0]:
            cname = m.group(2)
            cid = f"cls:{cname}"
            add_node(cid, cname, "class", parent=mid, file=rel, line=i)
            name_index[cname].append(cid)
            add_edge(mid, cid, "contains")
            tail = m.group(3) or ""
            for bm in RE_INHERIT.finditer(tail):
                base = bm.group(1).split("::")[-1]
                pending_calls.append(("__inherit__", cid, base))

# ---- pass 2: .cc -> functions/methods + record bodies for calls ----
for path in cc:
    rel = relpath(path); mod = stem(rel)
    mid = "mod:" + mod
    add_node(mid, mod.split("/")[-1], "module", file=rel)
    lines = open(path, encoding="utf-8", errors="ignore").read().splitlines()
    module_loc[mid] += len(lines)
    # find column-0 function definitions (def line not ending in ';')
    func_spans = []   # (start_line_idx, fid)
    for i, ln in enumerate(lines):
        if not ln or ln[0].isspace(): continue
        if ln.startswith(("//", "#", "}", "{", "*", "/")): continue
        m = RE_FUNC.match(ln)
        if not m: continue
        scope, name = m.group(2), m.group(3)
        if name in KEYWORDS: continue
        # filter obvious non-defs (e.g. macros / bare statements): require letters in name
        if scope:                                   # member function
            pid = f"cls:{scope}"
            if pid not in nodes:                    # class not seen in headers -> attach to module
                pid = mid
            fid = f"fn:{scope}::{name}"
            add_node(fid, name, "method", parent=pid, file=rel, line=i+1)
        else:
            fid = f"fn:{mod}::{name}"
            add_node(fid, name, "function", parent=mid, file=rel, line=i+1)
        add_edge(nodes[fid]["parent"] if nodes[fid]["parent"] else mid, fid, "contains")
        name_index[name].append(fid)
        func_spans.append((i, fid))
    # assign call edges: scan each function body until next def start
    func_spans.append((len(lines), None))
    for k in range(len(func_spans) - 1):
        start, fid = func_spans[k]; end = func_spans[k + 1][0]
        body = "\n".join(lines[start:end])
        for cm in RE_CALL.finditer(body):
            callee = cm.group(1)
            if callee in KEYWORDS: continue
            pending_calls.append(("__call__", fid, callee))
    # include edges
    for ln in lines:
        im = RE_INC.match(ln.strip())
        if im:
            tgt = "mod:" + re.sub(r'\.(hh|h)$', '', im.group(1))
            if tgt != mid:
                include_edges[(mid, tgt)] += 1
# include edges from headers too
for path in hh:
    rel = relpath(path); mid = "mod:" + stem(rel)
    for ln in open(path, encoding="utf-8", errors="ignore"):
        im = RE_INC.match(ln.strip())
        if im:
            tgt = "mod:" + re.sub(r'\.(hh|h)$', '', im.group(1))
            if tgt != mid:
                include_edges[(mid, tgt)] += 1

# resolve pending inherit/call edges by unique-ish short name
for kind, src, name in pending_calls:
    tgts = name_index.get(name, [])
    if kind == "__inherit__":
        for t in tgts:
            if nodes.get(t, {}).get("type") == "class":
                add_edge(src, t, "inherits")
    else:
        if 0 < len(tgts) <= 3:
            for t in tgts:
                if t != src:
                    add_edge(src, t, "calls")

# keep edges with valid endpoints
nids = set(nodes)
edges = [e for e in edges if e["source"] in nids and e["target"] in nids]
sym_data = {"nodes": list(nodes.values()), "edges": edges}

bt = collections.Counter(n["type"] for n in nodes.values())
print(f"SYMBOL graph: nodes={len(nodes)} edges={len(edges)} {dict(bt)}", file=sys.stderr)

# ---------------- module graph data ----------------
mod_files = collections.Counter()
for n in nodes.values():
    if n["type"] == "module":
        mod_files[n["id"]] += 1
mnodes = [{"id": mid[4:], "files": max(1, module_loc[mid] // 80)} for mid in module_loc]
medges = [{"s": a[4:], "t": b[4:], "w": c} for (a, b), c in include_edges.items()
          if a[4:] in {n["id"] for n in mnodes} and b[4:] in {n["id"] for n in mnodes}]
mod_data = {"nodes": mnodes, "edges": medges}
print(f"MODULE graph: nodes={len(mnodes)} edges={len(medges)}", file=sys.stderr)

# ---------------- emit ----------------
open("ep_code_graph.html", "w").write(SYMBOL_TPL.replace("/*__DATA__*/", json.dumps(sym_data)))
open("ep_module_graph.html", "w").write(MODULE_TPL.replace("__DATA__", json.dumps(mod_data)))
print("wrote ep_code_graph.html, ep_module_graph.html", file=sys.stderr)
