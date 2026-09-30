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
import re
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


# ---------------------------------------------------------------------------
# Sub-state struct codegen (the "split the god-object into per-module sub-states"
# half of #69). Turns a slice manifest into Mojo struct scaffolds: one struct
# per owning sub-state holding only the sliced fields, plus a thin sliced
# container that composes them. A function then pulls in the sub-struct it uses
# instead of the whole EnergyPlusData god-object.
# ---------------------------------------------------------------------------

# Field-name → Mojo type heuristics. The graph carries names, not C++ types, so
# fall back to Float64 (the dominant scalar in the runtime path) unless the name
# strongly signals a count/flag. Kept conservative: a wrong default is a
# one-line edit, and the slice's value is the *structure*, not the type guess.
def _mojo_type_for(name: str) -> str:
    n = (name or "").lower()
    if n.startswith(("is", "has", "do", "use")) or n.endswith(("flag", "_on")):
        return "Bool"
    if n.startswith(("num", "n_", "count", "index", "idx")) or n.endswith(
        ("num", "count", "index", "idx", "_no")
    ):
        return "Int"
    return "Float64"


# ---------------------------------------------------------------------------
# Header type join: stamp real C++ field types from `struct XxxData` headers.
# ---------------------------------------------------------------------------
_CPP_SCALARS = {
    "bool": "Bool",
    "int": "Int", "short": "Int", "long": "Int", "unsigned": "Int",
    "size_t": "Int", "std::size_t": "Int", "int32_t": "Int", "int64_t": "Int",
    "double": "Float64", "float": "Float64", "Real64": "Float64",
}
_STRUCT_RE = re.compile(r"\bstruct\s+(\w+)\s*(?::[^{;]*)?\{")
_FIELD_RE = re.compile(r"^\s*([A-Za-z_][\w:<>,\s\*&]*?)\s+(\w+)\s*(?:=[^;]*|\{[^;]*\}|\[[^\];]*\])?;\s*$")
_SKIP_WORDS = ("return", "using", "typedef", "friend", "static", "constexpr", "extern")


def parse_header_fields(text: str) -> dict[str, dict[str, str]]:
    """Map ``struct -> {field: cpp_type}`` from C++ header text.

    Only single-declaration member fields at the struct's top brace depth are
    kept; methods, nested structs, static/constexpr members and multi-name
    declarations (``int a, b;``) are ignored. Comments are stripped first.
    """
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    text = re.sub(r"//[^\n]*", "", text)
    out: dict[str, dict[str, str]] = {}
    for m in _STRUCT_RE.finditer(text):
        name, depth, i, start = m.group(1), 1, m.end(), m.end()
        while i < len(text) and depth:
            depth += {"{": 1, "}": -1}.get(text[i], 0)
            i += 1
        body, top, d = text[start:i - 1], [], 0
        buf, brace_init = "", False
        for ch in body:  # keep only top-level (depth 0) text
            if ch == "{":
                d += 1
                if d == 1 and buf.rstrip().endswith(")"):
                    buf = ""  # method body
                    continue
                if d == 1:
                    head = buf.rstrip()
                    brace_init = bool(re.search(r"\w$", head)) and not re.search(
                        r"\b(struct|class|enum|union|namespace)\b", head)
            elif ch == "}":
                d -= 1
                if d == 0:
                    if brace_init:
                        buf += "{}"  # keep `T name{...};` as a plain member
                    continue
            if d == 0 or ch == "{":
                buf += ch
            if ch == ";" and d == 0:
                top.append(buf)
                buf = ""
        fields: dict[str, str] = {}
        for stmt in top:
            stmt = " ".join(stmt.split())
            if "(" in stmt.split("=")[0] or stmt.startswith(_SKIP_WORDS):
                continue
            fm = _FIELD_RE.match(stmt)
            if fm and "," not in fm.group(1):
                fields[fm.group(2)] = " ".join(fm.group(1).split())
        out[name] = fields
    return out


def mojo_type_from_cpp(cpp_type: str) -> str | None:
    """Mojo scalar for a C++ scalar type, or None if not a plain scalar."""
    t = re.sub(r"\b(const|signed|mutable)\b", "", cpp_type).strip()
    t = t.replace("long long", "long").replace("unsigned int", "unsigned")
    t = " ".join(t.split())
    return _CPP_SCALARS.get(t)


_MOJO_DEFAULT = {"Bool": "False", "Int": "0", "Float64": "0.0"}


def _struct_name(owner_short: str) -> str:
    """data<Module> — the EnergyPlus per-module sub-state convention.

    EnergyPlus owners are typically named ``DataHeatBalance``/``DataSurfaces``;
    the sub-state member is ``dataHeatBalance`` (the leading ``Data`` is dropped
    so we don't emit ``dataDataHeatBalance``).
    """
    short = owner_short.rsplit(".", 1)[-1] or owner_short
    if not short:
        return "dataUnknown"
    if short.startswith("Data") and len(short) > 4:
        short = short[4:]
    return "data" + short[0].upper() + short[1:]


def emit_substate_structs(manifest: dict, header_types: dict | None = None) -> str:
    """Emit Mojo sub-state structs + a sliced container from a slice manifest.

    Each owning sub-state becomes a ``struct data<Owner>`` holding only the
    sliced fields (with a no-arg ``__init__`` defaulting each), and a
    ``StateSlice`` struct composes them. This is scaffolding — types are
    name-heuristic guesses (see ``_mojo_type_for``); the win is that a function
    now depends on ``state.data<Owner>.<field>`` (one small struct) instead of
    the full god-object.

    ``header_types`` (from ``parse_header_fields``) stamps real scalar types:
    a field found in ``header_types[<owner>]`` or ``header_types[<owner>Data]``
    with a plain C++ scalar type uses it; anything else keeps the name heuristic.
    """
    by_owner = manifest.get("fields_by_owner", {})
    if not by_owner:
        return "# (empty slice — no sub-states)\n"
    chunks: list[str] = ["# Auto-generated god-object sub-state slice (#69).",
                         "# Per-module sub-states holding ONLY the sliced fields.\n"]
    members: list[tuple[str, str]] = []
    for owner, rows in by_owner.items():
        struct = _struct_name(owner)
        members.append((struct, struct))
        # Dedup field names (a field can appear read+write); keep mode in comment.
        seen: dict[str, str] = {}
        for r in rows:
            seen.setdefault(r["name"] or "field", r.get("mode", ""))
        short = owner.rsplit(".", 1)[-1]
        known = (header_types or {}).get(short) or (header_types or {}).get(short + "Data") or {}
        types = {f: (mojo_type_from_cpp(known.get(f, "")) or _mojo_type_for(f)) for f in seen}
        lines = [f"struct {struct}:"]
        for fname, mode in seen.items():
            lines.append(f"    var {fname}: {types[fname]}  # {mode}")
        lines.append("    fn __init__(out self):")
        for fname in seen:
            ty = types[fname]
            lines.append(f"        self.{fname} = {_MOJO_DEFAULT[ty]}")
        chunks.append("\n".join(lines) + "\n")
    # Composing container.
    cont = ["struct StateSlice:"]
    for var, ty in members:
        cont.append(f"    var {var}: {ty}")
    cont.append("    fn __init__(out self):")
    for var, ty in members:
        cont.append(f"        self.{var} = {ty}()")
    chunks.append("\n".join(cont) + "\n")
    return "\n".join(chunks)


def main():
    ap = argparse.ArgumentParser(description="Compute a god-object vertical slice.")
    ap.add_argument("--graph", help="node-link graph JSON (default: build live from cbm)")
    ap.add_argument("--entry", action="append",
                    help="reachability slice: entry function (id/name/substring); repeatable")
    ap.add_argument("--owner", help="field-centric slice: sub-state owner substring (e.g. EnergyPlusData)")
    ap.add_argument("--max-depth", type=int, default=None, help="cap call-closure depth (--entry mode)")
    ap.add_argument("--out", default=None)
    ap.add_argument("--emit-mojo", default=None,
                    help="write per-module sub-state Mojo struct scaffolds (--entry mode)")
    ap.add_argument("--headers", default=None,
                    help="dir of EnergyPlus .hh headers; stamps real scalar types (with --emit-mojo)")
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

    if args.emit_mojo:
        if "fields_by_owner" not in manifest:
            ap.error("--emit-mojo requires --entry (a reachability slice manifest)")
        header_types: dict = {}
        if args.headers:
            for hh in sorted(Path(args.headers).rglob("*.hh")):
                header_types.update(parse_header_fields(hh.read_text(errors="replace")))
        Path(args.emit_mojo).write_text(emit_substate_structs(manifest, header_types))
        print(f"sub-state structs -> {args.emit_mojo}")


if __name__ == "__main__":
    main()
