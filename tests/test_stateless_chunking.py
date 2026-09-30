"""Chunked stateless transpile: split, per-chunk call, stitch, FILE-block
validation and the oversize guard (issues #91, #92). Mock client only; no network.
"""

from __future__ import annotations

import importlib.util
import re
import sys
from pathlib import Path

import pytest

REPO = Path(__file__).resolve().parents[1]

_spec = importlib.util.spec_from_file_location(
    "stateless_transpile_chunk", REPO / "stateless transpilation" / "2_transpile.py"
)
T = importlib.util.module_from_spec(_spec)
sys.modules["stateless_transpile_chunk"] = T
_spec.loader.exec_module(T)

SRC = """// header comment
#include <cmath>

// leading comment
double sq(double x) {
    return x * x; // {
}


int table[] = {1, 2, 3};

struct P {
    int a;
    const char* s = "}{";
};

double cube(double x) {
    /* } */
    return x * x * x;
}
"""


def test_compress_drops_comment_lines_and_blank_runs_only():
    out = T.compress_source(SRC)
    assert "header comment" not in out and "leading comment" not in out
    assert "return x * x; // {" in out  # code line kept intact
    assert "\n\n\n" not in out


def test_split_units_ignores_braces_in_strings_and_comments():
    units = T.split_units(SRC)
    assert len(units) == 4  # sq, table, P, cube (include attaches to sq)
    assert "double cube" in units[-1] and "/* } */" in units[-1]
    assert "".join(units) == SRC


def test_split_chunks_packs_and_never_cuts_a_unit():
    chunks = T.split_chunks(SRC, budget=140)
    assert len(chunks) > 1 and "".join(chunks) == SRC
    assert all(len(c) <= 140 for c in chunks)


def test_split_chunks_rejects_oversize_unit():
    with pytest.raises(ValueError, match="cannot split safely"):
        T.split_chunks(SRC, budget=20)


def test_stitch_hoists_and_dedupes_imports():
    out = T.stitch(["import math\n\ndef a():\n    return 1\n",
                    "import math\nfrom x import y\n\ndef b():\n    return 2\n"])
    assert out.startswith("import math\nfrom x import y\n")
    assert out.count("import math") == 1
    compile(out, "<t>", "exec")


# --- driver -------------------------------------------------------------------


@pytest.fixture
def env(tmp_path, monkeypatch):
    cc = tmp_path / "Big.cc"
    cc.write_text(SRC)
    monkeypatch.setattr(T, "BASE", tmp_path)
    monkeypatch.setattr(T, "_BY_NAME", {"Big": {"name": "Big", "cc_path": str(cc), "lang": "cpp"}})
    monkeypatch.setattr(T, "_oracle_paths", lambda f: (cc, None))
    return tmp_path


def _overhead():
    note = T._CHUNK_NOTE.format(i=99, n=99, file="Big")
    return len(T.build_prompt("Big", cc="", hh="", name="Big_part99", note=note))


def _client(calls, bad_chunk=None, bad_python=False):
    def fn(prompt, model, timeout, endpoint):
        calls.append(prompt)
        i = len(calls)
        stem = re.search(r"out/python/(\S+?)\.py", prompt).group(1)
        if i == bad_chunk:
            return "sorry, no blocks", {"cost_usd": 0.01}
        py = "def (:" if bad_python else f"import math\n\ndef f{i}():\n    return {i}"
        return (f"<<<FILE out/python/{stem}.py>>>\n{py}\n<<<END>>>\n"
                f"<<<FILE out/mojo/{stem}.mojo>>>\nfn f{i}() -> Int:\n    return {i}\n<<<END>>>",
                {"cost_usd": 0.01})
    return fn


def test_oversize_file_is_chunked_stitched_and_written(env):
    calls = []
    limit = _overhead() + 200
    r = T.transpile_chunked("Big", SRC, _client(calls), "m", 1, None, limit)
    assert r["status"] == "ok" and r["chunks"] == len(calls) > 1
    assert all(len(p) <= limit for p in calls)
    assert "chunk 1 of" in calls[0]
    py = (env / "out/python/Big.py").read_text()
    assert py.count("import math") == 1
    assert all(f"def f{i}" in py for i in range(1, len(calls) + 1))
    assert (env / "out/mojo/big.mojo").read_text().count("fn f") == len(calls)
    assert round(r["cost_usd"], 2) == round(0.01 * len(calls), 2)


def test_missing_file_block_fails_all_or_nothing(env):
    calls = []
    limit = _overhead() + 200
    r = T.transpile_chunked("Big", SRC, _client(calls, bad_chunk=2), "m", 1, None, limit)
    assert r["status"].startswith("error: chunk 2/") and r["written"] == []
    assert not (env / "out").exists()


def test_unparseable_stitched_python_is_rejected(env):
    limit = _overhead() + 200
    r = T.transpile_chunked("Big", SRC, _client([], bad_python=True), "m", 1, None, limit)
    assert "does not parse" in r["status"] and r["written"] == []


def test_transpile_one_guard_skips_without_chunk_and_compresses_or_chunks_with_it(env, monkeypatch):
    calls = []
    monkeypatch.setattr(T, "call_claude", _client(calls))
    full = len(T.build_prompt("Big"))
    small = len(T.build_prompt("Big", cc=T.compress_source(SRC)))
    assert small < full

    # oversize, chunking off: skipped, no LLM call
    r = T.transpile_one("Big", "claude", "m", 1, True, None, small - 1)
    assert r["status"].startswith("skip") and not calls

    # compression alone is enough: one single call, no chunk suffix
    r = T.transpile_one("Big", "claude", "m", 1, True, None, small, chunk=True)
    assert r["status"] == "ok" and len(calls) == 1 and "chunk 1 of" not in calls[0]

    # compression not enough: needs chunking
    calls.clear()
    body = "int g{i}(int x) {{\n    return x + {i};\n}}\n"
    (env / "Big.cc").write_text("".join(body.format(i=i) for i in range(30)))
    r = T.transpile_one("Big", "claude", "m", 1, True, None, _overhead() + 300, chunk=True)
    assert r["status"] == "ok" and len(calls) > 1
