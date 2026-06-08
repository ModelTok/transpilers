#!/usr/bin/env python3
"""Subpackage-level dependency graph for energyplus_mojo.

Nodes = top-level subpackages (file count -> node size).
Edges = aggregated internal imports between subpackages (count -> width).
Renders a layered DAG (cytoscape.js + dagre) to module_graph.html.
"""
import ast, os, json, sys, collections

PKG_ROOT = "src/energyplus_mojo"
OUT = "module_graph.html"

def subpkg(rel):
    parts = rel.split(os.sep)
    return parts[1] if len(parts) > 2 else "(root)"

files = collections.Counter()
edges = collections.Counter()

py = []
for root, _, fs in os.walk(PKG_ROOT):
    for f in fs:
        if f.endswith(".py"):
            py.append(os.path.join(root, f))

for path in py:
    rel = os.path.relpath(path, "src")
    src = subpkg(rel)
    files[src] += 1
    cur = rel[:-3].split(os.sep)
    try:
        tree = ast.parse(open(path, encoding="utf-8").read())
    except Exception:
        continue
    for n in ast.walk(tree):
        targets = []
        if isinstance(n, ast.ImportFrom):
            if n.level:
                base = cur[:len(cur) - n.level]
                targets = [".".join(base + ([n.module] if n.module else []))]
            else:
                targets = [n.module or ""]
        elif isinstance(n, ast.Import):
            targets = [a.name for a in n.names]
        for t in targets:
            if t.startswith("energyplus_mojo"):
                p = t.split(".")
                dst = p[1] if len(p) > 1 else "(root)"
                if dst != src:
                    edges[(src, dst)] += 1

nodes = [{"id": k, "files": v} for k, v in files.items()]
elist = [{"s": a, "t": b, "w": c} for (a, b), c in edges.items()]
data = {"nodes": nodes, "edges": elist}
print(f"subpackages={len(nodes)} edges={len(elist)}", file=sys.stderr)

HTML = r"""<!doctype html><html><head><meta charset="utf-8">
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
open(OUT, "w").write(HTML.replace("__DATA__", json.dumps(data)))
print(f"wrote {OUT}", file=sys.stderr)
