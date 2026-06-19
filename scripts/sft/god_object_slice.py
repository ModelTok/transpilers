#!/usr/bin/env python3
"""God-object vertical slicer — automate the Route-B prune (issue #69).

EnergyPlusData is too big to port wholesale and sits in every function's
closure. The fix is to port only a *path-specific slice*: pick a runtime
scenario (entry functions), and port just the state fields that scenario
actually touches, split per owning sub-state (DataHeatBalance, DataSurfaces, …).

This used to be done by hand (Minimal.idf: 46->22 fields, cone 152->23). The
multi-relational graph from `cbm_graph.py` makes it mechanical:

  reachable callables  = transitive closure over `calls` from the entries
  touched fields       = `writes_field` / `reads_field` targets of those callables
  per-module sub-state = those fields grouped by their owner (parent_class)

Output: a slice manifest — the minimal set of sub-states + fields to port for
that runtime path, with read/write mode per field.

Pure graph functions (testable); the live graph comes from `cbm_graph.build()`
or a previously written node-link JSON.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path


def _callables(graph):
    return {n["id"]: n for n in graph["nodes"] if n.get("kind") == "callable"}


def _fields(graph):
    return {n["id"]: n for n in graph["nodes"] if n.get("kind") == "field"}


def resolve_entries(graph, entries):
    """Resolve entry specs (exact id, exact short name, or substring) to ids."""
    cs = _callables(graph)
    by_name = {}
    for nid, n in cs.items():
        by_name.setdefault(n.get("name"), []).append(nid)
    out = set()
    for e in entries:
        if e in cs:
            out.add(e)
        elif e in by_name:
            out.update(by_name[e])
        else:
            out.update(nid for nid, n in cs.items() if e in nid or e in (n.get("name") or ""))
    return out


def _calls_adjacency(graph):
    cs = set(_callables(graph))
    adj = {c: [] for c in cs}
    for e in graph["links"]:
        if e["type"] == "calls" and e["source"] in adj and e["target"] in cs:
            adj[e["source"]].append(e["target"])
    return adj


def reachable_callables(graph, entry_ids, max_depth=None):
    """Transitive `calls` closure from entry ids (BFS, optional depth cap)."""
    adj = _calls_adjacency(graph)
    seen = {i for i in entry_ids if i in adj}
    frontier, depth = list(seen), 0
    while frontier and (max_depth is None or depth < max_depth):
        nxt = []
        for n in frontier:
            for d in adj[n]:
                if d not in seen:
                    seen.add(d)
                    nxt.append(d)
        frontier, depth = nxt, depth + 1
    return seen


def touched_fields(graph, callable_ids):
    """Fields written/read by the given callables → {field_id: {owner,name,modes}}."""
    cset = set(callable_ids)
    fmeta = _fields(graph)
    out = {}
    for e in graph["links"]:
        if e["source"] in cset and e["type"] in ("writes_field", "reads_field"):
            fid = e["target"]
            rec = out.setdefault(fid, {
                "owner": fmeta.get(fid, {}).get("owner"),
                "name": fmeta.get(fid, {}).get("name"),
                "modes": set(),
            })
            rec["modes"].add("write" if e["type"] == "writes_field" else "read")
    return out


def slice_manifest(graph, entries, max_depth=None):
    """Minimal god-object slice for a runtime path defined by `entries`."""
    entry_ids = resolve_entries(graph, entries)
    calls = reachable_callables(graph, entry_ids, max_depth)
    fields = touched_fields(graph, calls)
    by_owner = {}
    for fid, rec in fields.items():
        owner = rec["owner"] or "<unknown>"
        by_owner.setdefault(owner, []).append({
            "field": fid,
            "name": rec["name"],
            "mode": "+".join(sorted(rec["modes"])),
        })
    for rows in by_owner.values():
        rows.sort(key=lambda r: r["name"] or "")
    ordered = dict(sorted(by_owner.items(), key=lambda kv: (-len(kv[1]), kv[0])))
    return {
        "entries_resolved": len(entry_ids),
        "reachable_callables": len(calls),
        "touched_fields": len(fields),
        "sub_states": len(ordered),
        "sub_state_sizes": {o.rsplit(".", 1)[-1]: len(v) for o, v in ordered.items()},
        "fields_by_owner": ordered,
    }


def field_centric_slice(graph, owner_substr=""):
    """Sub-state breakdown from the dense field edges (call-graph independent).

    For god-object sub-states whose owner matches `owner_substr`, list each
    field's writer/reader functions. The union of writers per sub-state is the
    *port-together set* — the functions that produce that piece of state, which
    must be migrated to make the slice self-consistent. Unlike `slice_manifest`,
    this does not depend on call-graph completeness, only on WRITES/USAGE edges.
    """
    fmeta = _fields(graph)
    per_field = {}
    for e in graph["links"]:
        if e["type"] not in ("writes_field", "reads_field"):
            continue
        fid = e["target"]
        owner = (fmeta.get(fid, {}) or {}).get("owner") or ""
        if owner_substr and owner_substr not in owner:
            continue
        rec = per_field.setdefault(fid, {
            "owner": owner, "name": (fmeta.get(fid, {}) or {}).get("name"),
            "writers": set(), "readers": set(),
        })
        (rec["writers"] if e["type"] == "writes_field" else rec["readers"]).add(e["source"])

    by_owner = {}
    for rec in per_field.values():
        by_owner.setdefault(rec["owner"], []).append(rec)

    owners = {}
    for owner, recs in by_owner.items():
        writers, readers = set(), set()
        for r in recs:
            writers |= r["writers"]
            readers |= r["readers"]
        owners[owner.rsplit(".", 1)[-1] or owner] = {
            "owner": owner,
            "fields": len(recs),
            "writers": len(writers),
            "readers": len(readers),
            "writer_fns": sorted({w.rsplit(".", 1)[-1] for w in writers}),
        }
    return {
        "owner_filter": owner_substr,
        "owners_matched": len(owners),
        "owners": dict(sorted(owners.items(), key=lambda kv: -kv[1]["fields"])),
    }


def main():
    ap = argparse.ArgumentParser(description="Compute a god-object vertical slice.")
    ap.add_argument("--graph", help="node-link graph JSON (default: build live from cbm)")
    ap.add_argument("--entry", action="append",
                    help="reachability slice: entry function (id/name/substring); repeatable")
    ap.add_argument("--owner", help="field-centric slice: sub-state owner substring (e.g. EnergyPlusData)")
    ap.add_argument("--max-depth", type=int, default=None, help="cap call-closure depth (--entry mode)")
    ap.add_argument("--out", default=None)
    args = ap.parse_args()
    if not args.entry and args.owner is None:
        ap.error("provide --entry (reachability) or --owner (field-centric)")

    if args.graph:
        graph = json.loads(Path(args.graph).read_text())
    else:
        import cbm_graph
        graph = cbm_graph.build()

    if args.owner is not None:
        manifest = field_centric_slice(graph, args.owner)
        print(f"field-centric slice (owner ~ '{args.owner}'): {manifest['owners_matched']} sub-states")
        for short, info in list(manifest["owners"].items())[:10]:
            print(f"  {short:32} fields={info['fields']:4} writers={info['writers']:4} readers={info['readers']:4}")
    else:
        manifest = slice_manifest(graph, args.entry, args.max_depth)
        print(f"entries resolved: {manifest['entries_resolved']}")
        print(f"reachable callables: {manifest['reachable_callables']}")
        print(f"god-object slice: {manifest['touched_fields']} fields across "
              f"{manifest['sub_states']} sub-states")
        print(f"top sub-states (fields touched): {list(manifest['sub_state_sizes'].items())[:8]}")

    if args.out:
        Path(args.out).write_text(json.dumps(manifest, indent=1))
        print(f"-> {args.out}")


if __name__ == "__main__":
    main()
