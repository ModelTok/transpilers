"""Tests for the god-object vertical slicer (issue #69).

Synthetic multi-relational graphs (same node-link schema cbm_graph emits) so the
slice logic is tested without the live cbm binary or EnergyPlus index.
"""

from __future__ import annotations

import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
SCRIPTS_SFT = REPO / "scripts" / "sft"
sys.path.insert(0, str(SCRIPTS_SFT))

import god_object_slice as gos  # noqa: E402


def _graph():
    # call chain: entry -> mid -> leaf ; orphan is unreachable
    # entry writes f1(StateA); mid reads f2(StateA) + writes f3(StateB);
    # leaf reads f1; orphan writes f4(StateB) but is never reached
    nodes = [
        {"id": "p.entry", "name": "entry", "kind": "callable"},
        {"id": "p.mid", "name": "mid", "kind": "callable"},
        {"id": "p.leaf", "name": "leaf", "kind": "callable"},
        {"id": "p.orphan", "name": "orphan", "kind": "callable"},
        {"id": "p.StateA.f1", "name": "f1", "kind": "field", "owner": "p.StateA"},
        {"id": "p.StateA.f2", "name": "f2", "kind": "field", "owner": "p.StateA"},
        {"id": "p.StateB.f3", "name": "f3", "kind": "field", "owner": "p.StateB"},
        {"id": "p.StateB.f4", "name": "f4", "kind": "field", "owner": "p.StateB"},
    ]
    links = [
        {"source": "p.entry", "target": "p.mid", "type": "calls"},
        {"source": "p.mid", "target": "p.leaf", "type": "calls"},
        {"source": "p.entry", "target": "p.StateA.f1", "type": "writes_field"},
        {"source": "p.mid", "target": "p.StateA.f2", "type": "reads_field"},
        {"source": "p.mid", "target": "p.StateB.f3", "type": "writes_field"},
        {"source": "p.leaf", "target": "p.StateA.f1", "type": "reads_field"},
        {"source": "p.orphan", "target": "p.StateB.f4", "type": "writes_field"},
    ]
    return {"directed": True, "multigraph": True, "nodes": nodes, "links": links}


def test_resolve_entries_by_id_name_and_substring():
    g = _graph()
    assert gos.resolve_entries(g, ["p.entry"]) == {"p.entry"}
    assert gos.resolve_entries(g, ["entry"]) == {"p.entry"}
    assert gos.resolve_entries(g, ["mid"]) == {"p.mid"}


def test_reachable_callables_follows_calls_only():
    g = _graph()
    reach = gos.reachable_callables(g, {"p.entry"})
    assert reach == {"p.entry", "p.mid", "p.leaf"}  # orphan excluded


def test_reachable_respects_max_depth():
    g = _graph()
    assert gos.reachable_callables(g, {"p.entry"}, max_depth=1) == {"p.entry", "p.mid"}


def test_touched_fields_records_modes():
    g = _graph()
    reach = gos.reachable_callables(g, {"p.entry"})
    fields = gos.touched_fields(g, reach)
    assert set(fields) == {"p.StateA.f1", "p.StateA.f2", "p.StateB.f3"}  # f4 not touched
    assert fields["p.StateA.f1"]["modes"] == {"write", "read"}           # written + read
    assert fields["p.StateB.f3"]["modes"] == {"write"}


def test_slice_manifest_groups_by_sub_state_and_excludes_unreached():
    g = _graph()
    m = gos.slice_manifest(g, ["entry"])
    assert m["reachable_callables"] == 3
    assert m["touched_fields"] == 3
    assert m["sub_states"] == 2
    assert m["sub_state_sizes"] == {"StateA": 2, "StateB": 1}  # largest-first
    f1 = next(r for r in m["fields_by_owner"]["p.StateA"] if r["name"] == "f1")
    assert f1["mode"] == "read+write"
    # orphan's field never appears — the slice is genuinely path-specific
    flat = [r["field"] for rows in m["fields_by_owner"].values() for r in rows]
    assert "p.StateB.f4" not in flat


def test_field_centric_slice_is_call_graph_independent():
    g = _graph()
    # no entry / reachability — works purely off field edges, incl. orphan's f4
    m = gos.field_centric_slice(g)
    assert m["owners_matched"] == 2
    a = m["owners"]["StateA"]
    assert a["fields"] == 2                      # f1, f2
    assert "entry" in a["writer_fns"]            # entry writes f1
    b = m["owners"]["StateB"]
    assert "orphan" in b["writer_fns"]           # orphan writes f4 (unreached, still listed)


def test_field_centric_owner_filter():
    g = _graph()
    m = gos.field_centric_slice(g, "StateB")
    assert m["owners_matched"] == 1
    assert set(m["owners"]) == {"StateB"}
    assert m["owners"]["StateB"]["fields"] == 2  # f3 (write) + f4 (write)
