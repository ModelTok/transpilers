#!/usr/bin/env python3
"""Extract a symbol-level code graph (functions, classes, variables) for the
energyplus_mojo package + Mojo kernels and emit a self-contained interactive
2D HTML viewer (cytoscape.js + fcose layout, loaded from CDN).

Nodes : module, class, function, method, variable, mojo_fn, mojo_struct
Edges : contains (module->symbol, class->method)
        calls    (function -> function/class, best-effort by name)
        inherits (class -> base class)
        imports  (module -> module, internal)
"""
import ast, os, re, json, sys

HTML_TEMPLATE = r"""<!doctype html>
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

PKG_ROOT = "src/energyplus_mojo"
KERNELS_MOJO = "src/kernels"
OUT = "code_graph.html"

nodes = {}          # id -> dict
edges = []          # list of dict
name_index = {}     # symbol short-name -> list of node ids (for call resolution)

def add_node(nid, label, ntype, parent=None, file=None, line=None):
    if nid in nodes:
        return
    nodes[nid] = {"id": nid, "label": label, "type": ntype,
                  "parent": parent, "file": file, "line": line}

def add_edge(s, t, etype):
    edges.append({"source": s, "target": t, "type": etype})

def modid(rel):                       # energyplus_mojo/foo/bar.py -> energyplus_mojo.foo.bar
    return rel[:-3].replace(os.sep, ".")

# ---------- Python ----------
py_files = []
for root, _, fs in os.walk(PKG_ROOT):
    for f in fs:
        if f.endswith(".py"):
            py_files.append(os.path.join(root, f))

for path in sorted(py_files):
    rel = os.path.relpath(path, "src")
    mid = modid(rel)
    add_node(mid, mid.split(".")[-1] + "/", "module", parent=None, file=rel)
    try:
        tree = ast.parse(open(path, encoding="utf-8").read())
    except Exception:
        continue

    def walk_body(body, parent_id, class_ctx=None):
        for n in body:
            if isinstance(n, ast.ClassDef):
                cid = f"{parent_id}::{n.name}"
                add_node(cid, n.name, "class", parent=parent_id, file=rel, line=n.lineno)
                name_index.setdefault(n.name, []).append(cid)
                add_edge(parent_id, cid, "contains")
                for base in n.bases:
                    bn = base.id if isinstance(base, ast.Name) else (
                        base.attr if isinstance(base, ast.Attribute) else None)
                    if bn:
                        n.__dict__.setdefault("_bases", []).append((cid, bn))
                        pending_inherit.append((cid, bn))
                walk_body(n.body, cid, class_ctx=cid)
            elif isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef)):
                fid = f"{parent_id}::{n.name}"
                ntype = "method" if class_ctx else "function"
                add_node(fid, n.name, ntype, parent=parent_id, file=rel, line=n.lineno)
                name_index.setdefault(n.name, []).append(fid)
                add_edge(parent_id, fid, "contains")
                # record calls inside this function
                for c in ast.walk(n):
                    if isinstance(c, ast.Call):
                        fn = c.func
                        callee = fn.id if isinstance(fn, ast.Name) else (
                            fn.attr if isinstance(fn, ast.Attribute) else None)
                        if callee:
                            pending_calls.append((fid, callee))
            elif isinstance(n, ast.Assign):
                for tgt in n.targets:
                    if isinstance(tgt, ast.Name) and parent_id == mid:
                        vid = f"{mid}::{tgt.id}"
                        add_node(vid, tgt.id, "variable", parent=mid, file=rel, line=n.lineno)
                        add_edge(mid, vid, "contains")
            elif isinstance(n, ast.AnnAssign):
                if isinstance(n.target, ast.Name) and parent_id == mid:
                    vid = f"{mid}::{n.target.id}"
                    add_node(vid, n.target.id, "variable", parent=mid, file=rel, line=n.lineno)
                    add_edge(mid, vid, "contains")

    pending_calls = globals().get("pending_calls", [])
    pending_inherit = globals().get("pending_inherit", [])
    if "pending_calls" not in globals(): pending_calls = []; globals()["pending_calls"]=pending_calls
    if "pending_inherit" not in globals(): pending_inherit = []; globals()["pending_inherit"]=pending_inherit
    walk_body(tree.body, mid)

    # internal import edges
    cur = mid.split(".")
    for n in ast.walk(tree):
        if isinstance(n, ast.ImportFrom):
            if n.level:
                base = cur[:len(cur)-n.level]
                target = ".".join(base + ([n.module] if n.module else []))
            else:
                target = n.module or ""
            if target.startswith("energyplus_mojo"):
                add_edge(mid, target, "imports")
        elif isinstance(n, ast.Import):
            for a in n.names:
                if a.name.startswith("energyplus_mojo"):
                    add_edge(mid, a.name, "imports")

# resolve calls (best-effort by unique short name)
for caller, callee in globals().get("pending_calls", []):
    tgts = name_index.get(callee)
    if tgts and len(tgts) <= 3:        # skip ultra-ambiguous names
        for t in tgts:
            if t != caller:
                add_edge(caller, t, "calls")
# resolve inheritance
for cid, base in globals().get("pending_inherit", []):
    tgts = name_index.get(base, [])
    for t in tgts:
        if nodes.get(t, {}).get("type") == "class":
            add_edge(cid, t, "inherits")

# ---------- Mojo kernels ----------
fn_re = re.compile(r'^\s*(?:async\s+)?(?:fn|def)\s+([A-Za-z_]\w*)')
struct_re = re.compile(r'^\s*struct\s+([A-Za-z_]\w*)')
if os.path.isdir(KERNELS_MOJO):
    for f in sorted(os.listdir(KERNELS_MOJO)):
        if not f.endswith(".mojo"): continue
        rel = os.path.join("kernels", f)
        mid = "mojo." + f[:-5]
        add_node(mid, f, "module", parent=None, file=os.path.join(KERNELS_MOJO, f))
        for i, line in enumerate(open(os.path.join(KERNELS_MOJO, f), encoding="utf-8", errors="ignore"), 1):
            m = fn_re.match(line)
            if m:
                nid = f"{mid}::{m.group(1)}"
                add_node(nid, m.group(1), "mojo_fn", parent=mid, file=rel, line=i)
                add_edge(mid, nid, "contains")
            m = struct_re.match(line)
            if m:
                nid = f"{mid}::{m.group(1)}"
                add_node(nid, m.group(1), "mojo_struct", parent=mid, file=rel, line=i)
                add_edge(mid, nid, "contains")

# keep only edges whose endpoints exist
nids = set(nodes)
edges = [e for e in edges if e["source"] in nids and e["target"] in nids]

data = {"nodes": list(nodes.values()), "edges": edges}
print(f"nodes={len(data['nodes'])} edges={len(data['edges'])}", file=sys.stderr)
by_type = {}
for n in data["nodes"]:
    by_type[n["type"]] = by_type.get(n["type"], 0) + 1
print("by type:", by_type, file=sys.stderr)

html = HTML_TEMPLATE.replace("/*__DATA__*/", json.dumps(data))
open(OUT, "w", encoding="utf-8").write(html)
print(f"wrote {OUT}", file=sys.stderr)
