#!/usr/bin/env python3
"""Multi-relational directed dependency graph from codebase-memory-mcp.

The regex planner (`migration_plan.py`) derives a single edge type (scalar-fn
`calls`) from text scraping. The codebase-memory-mcp knowledge graph already
stores the repo connections at full fidelity, so this module queries it instead
(issue: wire the planner to query cbm) and builds a *multi-relational* directed
graph (issue #69): typed edges for

  * `calls`        callable -> callable          (CALLS)
  * `writes_field` callable -> Field             (WRITES)   god-object writers
  * `reads_field`  callable -> Field             (USAGE)    god-object readers

Field nodes carry their `owner` (parent_class), so the EnergyPlusData-family
write/read sets needed for vertical god-object slicing fall straight out of the
graph. Callable nodes are annotated with strongly-connected-component id and
fan-in/out via the tested algorithms in `migration_plan` (#67/#68).

cbm has no HTTP API; it ships a single-shot CLI bridge:
    codebase-memory-mcp cli <tool> <json>
which we shell out to. The EnergyPlus C++ oracle is indexed as the project
`home-bart-Github-EnergyPlus`.

Output: data/sft/cpp_mojo/dep_graph_cbm.json  (node-link, networkx-loadable)
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
from pathlib import Path

from migration_plan import cyclic_components, fan_in, tarjan_scc

CBM_BIN = os.environ.get("CBM_BIN", str(Path.home() / ".local/bin/codebase-memory-mcp"))
DEFAULT_PROJECT = "home-bart-Github-EnergyPlus"
DEFAULT_SCOPE = "src/EnergyPlus/"            # file_path substring (relative paths)
DEFAULT_OWNER = "Data"                       # Field.parent_class substring (god-object family)
OUT = Path(__file__).resolve().parents[2] / "data/sft/cpp_mojo/dep_graph_cbm.json"


def extract_json(text):
    """Pull the single JSON result object out of cbm CLI stdout.

    The CLI prints `level=info ...` log lines before the JSON payload, so we
    return the first line that parses as a JSON object.
    """
    for line in text.splitlines():
        line = line.strip()
        if line.startswith("{"):
            try:
                return json.loads(line)
            except json.JSONDecodeError:
                continue
    raise ValueError("no JSON object found in cbm output")


def rows_of(payload):
    """Turn a cbm {columns, rows} payload into a list of row dicts."""
    cols = payload.get("columns", [])
    return [dict(zip(cols, row)) for row in payload.get("rows", [])]


def cbm_query(project, cypher, binary=CBM_BIN):
    """Run one Cypher query through the cbm CLI bridge; return row dicts."""
    out = subprocess.run(
        [binary, "cli", "query_graph", json.dumps({"project": project, "query": cypher})],
        capture_output=True, text=True, timeout=300,
    ).stdout
    return rows_of(extract_json(out))


def _short(qn):
    return qn.rsplit(".", 1)[-1] if qn else qn


def rows_to_multigraph(calls=(), writes=(), reads=()):
    """Assemble typed edge rows into a node-link multigraph (pure / testable).

    `calls` rows need {src, dst}; `writes`/`reads` rows need {src, dst, owner}.
    Nodes get a `kind` (`callable` or `field`) and fields keep their `owner`.
    """
    nodes = {}
    links = []

    def node(nid, kind, **attrs):
        if not nid:
            return
        rec = nodes.setdefault(nid, {"id": nid, "name": _short(nid), "kind": kind})
        for k, v in attrs.items():
            if v is not None:
                rec[k] = v

    for r in calls:
        node(r["src"], "callable")
        node(r["dst"], "callable")
        links.append({"source": r["src"], "target": r["dst"], "type": "calls"})
    for r in writes:
        node(r["src"], "callable")
        node(r["dst"], "field", owner=r.get("owner"))
        links.append({"source": r["src"], "target": r["dst"], "type": "writes_field"})
    for r in reads:
        node(r["src"], "callable")
        node(r["dst"], "field", owner=r.get("owner"))
        links.append({"source": r["src"], "target": r["dst"], "type": "reads_field"})

    return {"directed": True, "multigraph": True, "nodes": list(nodes.values()), "links": links}


def annotate_calls(graph):
    """Annotate callable nodes with scc id + fan-in/out over the `calls` subgraph.

    Reuses the tested graph algorithms from migration_plan (#67/#68). Returns
    (cyclic_components, scc_count) for reporting.
    """
    callables = {n["id"] for n in graph["nodes"] if n.get("kind") == "callable"}
    adj = {n: [] for n in callables}
    for e in graph["links"]:
        if e["type"] == "calls" and e["source"] in adj and e["target"] in callables:
            adj[e["source"]].append(e["target"])
    sccs = tarjan_scc(adj)
    comp_of = {n: i for i, comp in enumerate(sccs) for n in comp}
    fi = fan_in(adj)
    for n in graph["nodes"]:
        if n["id"] in adj:
            n["scc"] = comp_of[n["id"]]
            n["fan_in"] = fi[n["id"]]
            n["fan_out"] = len(adj[n["id"]])
    return cyclic_components(adj, sccs), len(sccs)


def build(project=DEFAULT_PROJECT, scope=DEFAULT_SCOPE, owner=DEFAULT_OWNER,
          with_fields=True, binary=CBM_BIN):
    """Query cbm and build the annotated multi-relational graph."""
    calls = cbm_query(project, (
        f"MATCH (a)-[:CALLS]->(b) "
        f"WHERE a.file_path CONTAINS '{scope}' AND b.file_path CONTAINS '{scope}' "
        f"RETURN a.qualified_name AS src, b.qualified_name AS dst"
    ), binary)
    writes = reads = []
    if with_fields:
        writes = cbm_query(project, (
            f"MATCH (w)-[:WRITES]->(f:Field) "
            f"WHERE w.file_path CONTAINS '{scope}' AND f.parent_class CONTAINS '{owner}' "
            f"RETURN w.qualified_name AS src, f.qualified_name AS dst, f.parent_class AS owner"
        ), binary)
        reads = cbm_query(project, (
            f"MATCH (u)-[:USAGE]->(f:Field) "
            f"WHERE u.file_path CONTAINS '{scope}' AND f.parent_class CONTAINS '{owner}' "
            f"RETURN u.qualified_name AS src, f.qualified_name AS dst, f.parent_class AS owner"
        ), binary)
    graph = rows_to_multigraph(calls, writes, reads)
    cycles, n_scc = annotate_calls(graph)
    graph["stats"] = {
        "calls": len(calls), "writes_field": len(writes), "reads_field": len(reads),
        "callables": sum(n.get("kind") == "callable" for n in graph["nodes"]),
        "fields": sum(n.get("kind") == "field" for n in graph["nodes"]),
        "scc_count": n_scc, "cyclic_scc_count": len(cycles),
        "cyclic_scc_sample": [[_short(x) for x in c] for c in cycles[:10]],
    }
    return graph


def main():
    ap = argparse.ArgumentParser(description="Build multi-relational dep graph from cbm.")
    ap.add_argument("--project", default=DEFAULT_PROJECT)
    ap.add_argument("--scope", default=DEFAULT_SCOPE, help="file_path substring filter")
    ap.add_argument("--owner", default=DEFAULT_OWNER, help="Field.parent_class substring (god-object family)")
    ap.add_argument("--no-fields", action="store_true", help="calls graph only, skip field edges")
    ap.add_argument("--binary", default=CBM_BIN)
    ap.add_argument("--out", default=str(OUT))
    args = ap.parse_args()

    graph = build(args.project, args.scope, args.owner, not args.no_fields, args.binary)
    Path(args.out).write_text(json.dumps(graph, indent=1))
    s = graph["stats"]
    print(f"cbm multi-relational graph for {args.project} (scope '{args.scope}'):")
    print(f"  nodes: {len(graph['nodes'])} ({s['callables']} callable, {s['fields']} field)")
    print(f"  edges: calls={s['calls']} writes_field={s['writes_field']} reads_field={s['reads_field']}")
    print(f"  call-graph cycles (SCC>1 / recursion): {s['cyclic_scc_count']}  e.g. {s['cyclic_scc_sample'][:3]}")
    print(f"  -> {args.out}")


if __name__ == "__main__":
    main()
