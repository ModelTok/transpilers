"""The EnergyPlusMojo evaluation harness (benchmarks/epmojo_eval): its pure parts always, and the
real build-and-compare path when an EnergyPlusMojo checkout, g++ and Mojo are available
(set EPMOJO_DIR; run where Mojo works, e.g. under EnergyPlusMojo's pixi environment)."""

from __future__ import annotations

import argparse
import importlib.util
import json
import os
import re
import shutil
import sys
from pathlib import Path

import pytest

HARNESS_DIR = Path(__file__).resolve().parents[1] / "benchmarks" / "epmojo_eval"
sys.path.insert(0, str(HARNESS_DIR))
import harness as h  # noqa: E402


def load(name: str):
    spec = importlib.util.spec_from_file_location(f"epmojo_eval_{name}", HARNESS_DIR / f"{name}.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


# --- published sets ----------------------------------------------------------------------------


def _sets():
    return {p.stem: json.loads(p.read_text(encoding="utf-8")) for p in sorted(h.SETS.glob("*.json"))}


def test_published_sets_are_well_formed():
    sets = _sets()
    assert {"dev", "heldout", "greedy_failures"} <= set(sets)
    for name, data in sets.items():
        assert data["epmojo_commit"] and data["description"], name
        tags = [r["tag"] for r in data["routines"]]
        assert tags and len(tags) == len(set(tags)), name
        for r in data["routines"]:
            assert set(r) == {"tag", "name", "file", "inputs", "lines"}, r
            assert r["inputs"] and all(isinstance(x, str) for x in r["inputs"])
            stem = r["file"].replace(".upstream.inc", "")
            assert r["tag"] == re.sub(r"\W", "_", f"{stem}__{r['name']}")
            assert r["file"].endswith(".upstream.inc")


def test_sets_have_the_documented_sizes_and_the_heldout_set_is_disjoint():
    sets = _sets()
    names = {k: {r["name"] for r in v["routines"]} for k, v in sets.items()}
    assert (len(sets["dev"]["routines"]), len(names["dev"])) == (40, 31)
    assert (len(sets["heldout"]["routines"]), len(names["heldout"])) == (21, 21)
    assert len(sets["greedy_failures"]["routines"]) == 3
    assert not names["dev"] & names["heldout"]


def test_the_sets_carry_no_upstream_source():
    for p in h.SETS.glob("*.json"):
        text = p.read_text(encoding="utf-8")
        assert "Real64 const" not in text and "return " not in text


# --- interface check, wrapper, reporting, paths --------------------------------------------------

R = h.Routine("f__Foo", "Foo", "f.upstream.inc", ["a", "b"], 5)


@pytest.mark.parametrize(
    "code, expected",
    [
        ("def Foo(a: Float64, b: Float64) -> Float64:\n    return a + b\n", None),
        ("fn Foo(a: Float64, b: Float64) -> Float64:\n    return a\n", None),
        ("def Foo(a: Float64) -> Float64:\n    return a\n", h.ARITY),
        ("def Foo(a: Float64, b: Float64, c: Float64) -> Float64:\n    return a\n", h.ARITY),
        ("struct Foo:\n    def call(a: Float64, b: Float64) -> Float64:\n        return a\n", h.NO_FUNCTION),
        ("def Bar(a: Float64, b: Float64) -> Float64:\n    return a\n", h.NO_FUNCTION),
        ("def Foo2(a: Float64, b: Float64) -> Float64:\n    return a\n", h.NO_FUNCTION),
    ],
)
def test_check_interface(code, expected):
    assert h.check_interface(code, R) == expected


def test_wrapper_calls_the_routine_once_per_packed_row():
    w = h.wrapper_source("Foo", 3)
    assert "@export\ndef eval_batch(n: Int, in_ptr: Int, out_ptr: Int):" in w
    assert "outp[c] = Foo(inp[3 * c + 0], inp[3 * c + 1], inp[3 * c + 2])" in w


def test_first_error_blanks_quoted_names_so_equal_errors_group():
    a = "x.mojo:3:4: error: use of unknown declaration 'Array1D'\n  ^"
    b = "y.mojo:9:1: error: use of unknown declaration 'Foo'\n  ^"
    assert h.first_error(a) == h.first_error(b) == "use of unknown declaration '_'"
    assert h.first_error("nothing useful") == "unknown"


def test_summarise_counts_every_status():
    rows = [("a", h.EXACT, "0"), ("b", h.EXACT, "0"), ("c", h.MISMATCH, "7"), ("d", h.BUILD_FAIL, "e"), ("e", h.NO_FUNCTION, ""), ("f", h.ARITY, "")]
    c = h.summarise(rows)
    assert (c["routines"], c["built"], c[h.EXACT], c[h.MISMATCH], c[h.BUILD_FAIL], c[h.NO_FUNCTION], c[h.ARITY]) == (6, 3, 2, 1, 1, 1, 1)


@pytest.mark.parametrize(
    "path, expected",
    [("C:\\Users\\bart\\a b\\x.mojo", "/mnt/c/Users/bart/a b/x.mojo"), ("d:/data/x", "/mnt/d/data/x"), ("/root/epm", "/root/epm"), ("rel\\p", "rel/p")],
)
def test_to_wsl_path(path, expected):
    assert h.to_wsl_path(path) == expected


def test_set_round_trip(tmp_path):
    h.write_set(tmp_path, [R], "abc1234")
    meta, routines = h.read_set(tmp_path)
    assert meta["epmojo_commit"] == "abc1234" and routines == [R]
    assert h.source_path(tmp_path, R) == tmp_path / "src" / "f__Foo.upstream.inc"


def test_epmojo_dir_explains_what_is_missing(tmp_path):
    with pytest.raises(SystemExit) as e:
        h.epmojo_dir(tmp_path)
    assert "EPMOJO_DIR" in str(e.value)


def test_verify_wsl_forwards_through_wsl_without_a_shell():
    mod = load("verify_wsl")
    args = argparse.Namespace(
        draft=Path("C:/work/runs/r/out/f__Foo.mojo"), set_dir=[Path("C:/work/dev")],
        python="/root/epm/.pixi/envs/default/bin/python3", epmojo="/root/epm", distro="Ubuntu", user="root",
    )
    cmd = mod.build_command(args)
    assert cmd[:7] == ["wsl", "-d", "Ubuntu", "-u", "root", "--", "/root/epm/.pixi/envs/default/bin/python3"]
    assert cmd[7].endswith("/benchmarks/epmojo_eval/verify_one.py") and cmd[7].startswith("/mnt/")
    assert cmd[8] == "/mnt/c/work/runs/r/out/f__Foo.mojo"
    assert "--set-dir" in cmd and cmd[-2:] == ["--epmojo", "/root/epm"]
    assert not any(c in " ".join(cmd) for c in ("bash -c", "$"))


def test_the_postpass_loads_from_the_repo_by_path():
    mod = h.load_postpass()
    assert mod.postpass("def f(a: Float64, b: Float64, c: Float64) -> Float64:\n    return a * b + c\n").code.count("nc_mul") >= 2


# --- the real build-and-compare path (needs an EnergyPlusMojo checkout, g++ and Mojo) ------------

EPM = os.environ.get("EPMOJO_DIR")
needs_toolchain = pytest.mark.skipif(
    not (EPM and Path(EPM).is_dir() and shutil.which("g++") and (shutil.which("mojo") or shutil.which("pixi") or (Path.home() / ".pixi" / "bin" / "pixi").exists())),
    reason="set EPMOJO_DIR to an EnergyPlusMojo checkout and run where g++ and Mojo work",
)


@needs_toolchain
def test_end_to_end_scoring_of_good_and_bad_drafts(tmp_path):
    pytest.importorskip("numpy")
    root = h.epmojo_dir(EPM)
    make_set = load("make_set")
    routine = h.Routine("ice_storage__TempSItoIP", "TempSItoIP", "ice_storage.upstream.inc", ["Temp"], 4)
    set_dir = tmp_path / "set"
    make_set.rebuild(root, set_dir, [routine])
    h.write_set(set_dir, [routine], h.epmojo_commit(root))
    oracle = h.Oracle(root, set_dir, routine, tmp_path)
    good = "def TempSItoIP(Temp: Float64) -> Float64:\n    return (Temp * 9.0 / 5.0) + 32.0\n"
    status, _ = h.evaluate(good, routine, oracle, root, tmp_path)
    assert status == h.EXACT
    wrong = "def TempSItoIP(Temp: Float64) -> Float64:\n    return Temp * 1.8 + 32.0\n"
    status, detail = h.evaluate(wrong, routine, oracle, root, tmp_path)
    assert status == h.MISMATCH and int(detail) > 0
    assert h.evaluate("def Other(Temp: Float64) -> Float64:\n    return Temp\n", routine, oracle, root, tmp_path)[0] == h.NO_FUNCTION
    status, detail = h.evaluate("def TempSItoIP(Temp: Float64) -> Float64:\n    return nope(Temp)\n", routine, oracle, root, tmp_path)
    assert status == h.BUILD_FAIL and "unknown declaration" in detail

    verify = load("verify_one")
    draft = tmp_path / "ice_storage__TempSItoIP.mojo"
    draft.write_text(good, encoding="utf-8")
    assert verify.main([str(draft), "--set-dir", str(set_dir), "--epmojo", str(root)]) == 0
    draft.write_text(wrong, encoding="utf-8")
    assert verify.main([str(draft), "--set-dir", str(set_dir), "--epmojo", str(root)]) == 1
