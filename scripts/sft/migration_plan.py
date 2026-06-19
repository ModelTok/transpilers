#!/usr/bin/env python3
"""Dependency-ordered migration planner for EnergyPlus -> Mojo.

The production test showed the limiter on real code is DEPENDENCY CLOSURE, not
translation skill: a function calling sibling EP functions (Le, pvstar) can't be
verified in isolation. So migrate in dependency order — leaf scalar functions
first. This scans EnergyPlus, finds scalar functions, builds the call graph among
them, and reports:
  * the LEAF FRONTIER — self-contained scalar fns whose only calls are shim
    helpers (pow_N/sign/mod/Constant) or std math => migratable + verifiable NOW
  * how many more unlock per dependency layer.
  * cyclic components (SCCs) — mutual recursion / dependency cycles that a plain
    topological order cannot sequence; condensed so the layering stays valid and
    surfaced for port-together or trait-seam handling.        (issue #67)
  * fan-in ranking — which (often non-leaf) functions unblock the most
    downstream work, so high-fan-in scaffolding can be ported first.  (issue #68)

GPU-free. Output: data/sft/cpp_mojo/migration_plan.json
"""
import json
import re
from pathlib import Path

EP = Path("/home/bart/Github/EnergyPlus/src/EnergyPlus")
OUT = Path("/home/bart/Github/transpilers/data/sft/cpp_mojo/migration_plan.json")

SIG = re.compile(r"\bReal64\s+(?:[A-Za-z_]\w*::)?([A-Za-z_]\w+)\s*\(([^;{)]*)\)\s*\{")
SCALAR_ARG = re.compile(r"^(?:const\s+)?(?:Real64|double|int|bool|Int64|Int)\b[^,&*]*$")
SHIM = {"pow_2","pow_3","pow_4","pow_5","pow_6","pow_7","root_4","root_8","sign","mod",
        "min","max","abs","fabs","exp","log","log10","sqrt","pow","floor","ceil","trunc","atan","atan2"}
KW = {"if","for","while","return","sizeof","switch","else","do"}


# ---------------------------------------------------------------------------
# Pure graph algorithms (importable + unit-tested without the EnergyPlus tree).
# A graph is a dict {node: iterable-of-successors}; an edge n -> d means
# "n depends on d" (n calls d), so d must be ported before n.
# ---------------------------------------------------------------------------
def tarjan_scc(graph):
    """Strongly-connected components via iterative Tarjan (no recursion limit).

    Returns a list of components (each a list of node names) in reverse
    topological order of the condensation. Successors outside `graph` are
    ignored. Singleton components are returned for acyclic nodes too.
    """
    index = {}
    low = {}
    on_stack = set()
    stack = []
    out = []
    counter = 0
    for root in graph:
        if root in index:
            continue
        work = [(root, iter(graph.get(root, ())))]
        index[root] = low[root] = counter
        counter += 1
        stack.append(root)
        on_stack.add(root)
        while work:
            node, succ_it = work[-1]
            descended = False
            for succ in succ_it:
                if succ not in graph:
                    continue  # external symbol, not part of this graph
                if succ not in index:
                    index[succ] = low[succ] = counter
                    counter += 1
                    stack.append(succ)
                    on_stack.add(succ)
                    work.append((succ, iter(graph.get(succ, ()))))
                    descended = True
                    break
                if succ in on_stack:
                    low[node] = min(low[node], index[succ])
            if descended:
                continue
            if low[node] == index[node]:
                comp = []
                while True:
                    w = stack.pop()
                    on_stack.discard(w)
                    comp.append(w)
                    if w == node:
                        break
                out.append(comp)
            work.pop()
            if work:
                parent = work[-1][0]
                low[parent] = min(low[parent], low[node])
    return out


def cyclic_components(graph, sccs=None):
    """SCCs that represent real cycles: size > 1, or a singleton self-loop.

    These are the components a plain topological sort cannot order; each needs
    port-together or a trait-seam to break the cycle. Sorted largest-first.
    """
    if sccs is None:
        sccs = tarjan_scc(graph)
    cyclic = []
    for comp in sccs:
        if len(comp) > 1:
            cyclic.append(sorted(comp))
        elif comp[0] in set(graph.get(comp[0], ())):
            cyclic.append([comp[0]])  # direct recursion
    cyclic.sort(key=lambda c: (-len(c), c[0] if c else ""))
    return cyclic


def fan_in(graph):
    """Map each node to how many nodes in `graph` directly depend on it.

    High fan-in => porting it unblocks the most downstream functions. Edges to
    nodes outside `graph` are ignored so the count reflects in-graph leverage.
    """
    fi = {n: 0 for n in graph}
    for deps in graph.values():
        for d in set(deps):
            if d in fi:
                fi[d] += 1
    return fi


def fanin_ranked(graph, nodes=None):
    """`nodes` (default all) sorted by fan-in desc, ties broken by name."""
    fi = fan_in(graph)
    pool = list(graph) if nodes is None else [n for n in nodes if n in fi]
    return sorted(pool, key=lambda n: (-fi[n], n)), fi


def graph_node_link(graph, attrs=None, edge_type="calls"):
    """Serialize a directed graph as a node-link dict (the repo connections).

    Schema is networkx-compatible (`networkx.node_link_graph(d, edges="links")`)
    yet plain JSON, so it stores the actual directed graph — nodes with
    attributes and typed directed edges — rather than a flattened layer summary.
    A self-edge (n -> n) marks direct recursion. `attrs[node]` is merged into
    that node's record. Edges to nodes outside `graph` are dropped.
    """
    attrs = attrs or {}
    nodes = [{"id": n, **attrs.get(n, {})} for n in graph]
    links = [
        {"source": n, "target": d, "type": edge_type}
        for n in graph
        for d in graph[n]
        if d in graph
    ]
    return {"directed": True, "multigraph": False, "nodes": nodes, "links": links}


def main():
    # 1) discover all scalar Real64 functions across EnergyPlus
    funcs = {}   # name -> {file, scalar}
    allnames = set()
    for cc in sorted(EP.glob("*.cc")):
        try:
            txt = cc.read_text(errors="ignore")
        except Exception:
            continue
        for m in SIG.finditer(txt):
            name, args = m.group(1), m.group(2).strip()
            allnames.add(name)
            parts = [a.strip() for a in args.split(",") if a.strip()]
            scalar = bool(parts) and all(SCALAR_ARG.match(a) for a in parts)
            funcs.setdefault(name, {"file": cc.name, "scalar": scalar})

    # 2) for scalar fns, extract body + find which OTHER EP functions they call
    scalar_fns = {n: v for n, v in funcs.items() if v["scalar"]}
    for cc in sorted(EP.glob("*.cc")):
        try:
            txt = cc.read_text(errors="ignore")
        except Exception:
            continue
        for n in list(scalar_fns):
            if scalar_fns[n].get("deps") is not None:
                continue
            if scalar_fns[n]["file"] != cc.name:
                continue
            body = extract_body(txt, n)
            if body is None:
                continue
            called = set(re.findall(r"\b([A-Za-z_]\w+)\s*\(", body)) - KW - {n}
            ep_deps = (called & allnames) - SHIM           # calls to other EP functions
            self_recurses = bool(re.search(rf"\b{re.escape(n)}\s*\(", body))
            non_self = ("Array" in body) or ("state." in body) or ("EnergyPlusData" in body)
            scalar_fns[n]["deps"] = sorted(ep_deps)
            scalar_fns[n]["recursive"] = self_recurses
            scalar_fns[n]["leaf"] = (len(ep_deps) == 0) and not non_self

    # 2b) build the in-set dependency graph (edges to other scalar fns only).
    #     Self-recursion is kept as an explicit self-edge so cyclic_components
    #     can flag it.                                                  (#67)
    graph = {}
    for n, v in scalar_fns.items():
        deps = set(v.get("deps") or []) & set(scalar_fns)
        if v.get("recursive"):
            deps.add(n)
        graph[n] = sorted(deps)

    # 3) layers via SCC condensation so cycles don't stall a valid topo order (#67)
    sccs = tarjan_scc(graph)                       # reverse-topological order
    cycles = cyclic_components(graph, sccs)
    comp_of = {n: i for i, comp in enumerate(sccs) for n in comp}
    # condensed DAG: super-node -> super-nodes it depends on
    cgraph = {i: set() for i in range(len(sccs))}
    for n, deps in graph.items():
        for d in deps:
            if comp_of[n] != comp_of[d]:
                cgraph[comp_of[n]].add(comp_of[d])
    # a component is leaf-portable iff every member is a leaf scalar fn
    comp_leaf = [all(scalar_fns[n].get("leaf") for n in comp) for comp in sccs]

    done_comps = {i for i in cgraph if comp_leaf[i] and not cgraph[i]}
    layers_c = [sorted(done_comps)]
    pending = {i: set(d for d in cgraph[i]) for i in cgraph if i not in done_comps}
    while True:
        nxt = sorted(i for i, d in pending.items() if d <= done_comps)
        if not nxt:
            break
        layers_c.append(nxt)
        done_comps |= set(nxt)
        for i in nxt:
            pending.pop(i, None)

    # expand component-layers back to function names for the report
    layers = [sorted(n for i in layer for n in sccs[i]) for layer in layers_c]
    leaf = layers[0] if layers else []
    still_blocked_comps = list(pending)
    still_blocked = sorted(n for i in still_blocked_comps for n in sccs[i])
    blocked_by_cycle = sorted(
        n for i in still_blocked_comps for n in sccs[i] if len(sccs[i]) > 1
    )

    # 4) fan-in ranking — max-unlock scaffolding first (#68)
    ranked, fi = fanin_ranked(graph)
    non_leaf = [n for n in ranked if not scalar_fns[n].get("leaf")]

    # 4b) persist the actual directed graph (repo connections), not just the
    #     layered summary — node-link JSON, networkx-loadable.
    layer_of = {n: i for i, layer in enumerate(layers) for n in layer}
    node_attrs = {
        n: {
            "file": scalar_fns[n].get("file"),
            "leaf": bool(scalar_fns[n].get("leaf")),
            "recursive": bool(scalar_fns[n].get("recursive")),
            "fan_in": fi[n],
            "fan_out": len(graph[n]),
            "scc": comp_of[n],
            "layer": layer_of.get(n, -1),  # -1 == still blocked
        }
        for n in graph
    }
    digraph = graph_node_link(graph, node_attrs)
    GRAPH_OUT = OUT.with_name("dep_graph.json")
    GRAPH_OUT.write_text(json.dumps(digraph, indent=1))

    plan = {
        "scalar_fns_total": len(scalar_fns),
        "leaf_frontier_count": len(leaf),
        "leaf_frontier_sample": leaf[:40],
        "layer_sizes": [len(layer) for layer in layers],
        "still_blocked": len(still_blocked),
        # --- #67: cycles ---
        "cyclic_scc_count": len(cycles),
        "cyclic_scc_sample": cycles[:10],
        "blocked_by_cycle_count": len(blocked_by_cycle),
        "blocked_by_cycle_sample": blocked_by_cycle[:20],
        # --- #68: fan-in ---
        "top_fanin": [[n, fi[n]] for n in ranked[:20]],
        "top_fanin_scaffolding": [[n, fi[n]] for n in non_leaf[:20]],
    }
    OUT.write_text(json.dumps(plan, indent=1))
    print(f"scalar EP functions discovered: {len(scalar_fns)}")
    print(f"LEAF FRONTIER (self-contained, migratable+verifiable NOW): {len(leaf)}")
    print(f"dependency layers unlock: {plan['layer_sizes'][:8]}{'...' if len(layers)>8 else ''}")
    print(f"cyclic SCCs (need port-together / trait-seam): {len(cycles)}"
          f"  e.g. {cycles[:3]}")
    print(f"still blocked: {len(still_blocked)} ({len(blocked_by_cycle)} inside cycles)")
    print(f"top fan-in scaffolding (port first to unlock most): {plan['top_fanin_scaffolding'][:5]}")
    print(f"sample leaf frontier: {leaf[:15]}")
    print(f"directed graph: {len(digraph['nodes'])} nodes, {len(digraph['links'])} edges -> {GRAPH_OUT}")
    print(f"-> {OUT}")


def extract_body(text, name):
    m = re.search(rf"\bReal64\s+(?:[A-Za-z_]\w*::)?{re.escape(name)}\s*\(", text)
    if not m:
        return None
    i = text.find("{", m.start())
    if i < 0:
        return None
    depth = 0
    for j in range(i, len(text)):
        if text[j] == "{":
            depth += 1
        elif text[j] == "}":
            depth -= 1
            if depth == 0:
                return text[i:j+1]
    return None


def main_cbm():
    """Wire the planner to the codebase-memory-mcp graph instead of regex.

    Builds the multi-relational directed graph (calls + god-object field
    writes/reads) from cbm and writes it next to the regex artifacts.
    """
    import cbm_graph
    graph = cbm_graph.build()
    out = OUT.with_name("dep_graph_cbm.json")
    out.write_text(json.dumps(graph, indent=1))
    s = graph["stats"]
    print(f"cbm graph: {len(graph['nodes'])} nodes "
          f"({s['callables']} callable, {s['fields']} field), "
          f"calls={s['calls']} writes_field={s['writes_field']} reads_field={s['reads_field']}, "
          f"call cycles={s['cyclic_scc_count']}")
    print(f"-> {out}")


if __name__ == "__main__":
    import sys
    if "--cbm" in sys.argv:
        main_cbm()
    else:
        main()
