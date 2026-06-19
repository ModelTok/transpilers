"""Tests for the record/replay verifier's pure pieces (issue #65).

Codegen + fixture parsing are tested without g++/Mojo. The live record→replay
round-trip is exercised by scripts/sft/record_replay.py on real items.
"""

from __future__ import annotations

import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / "scripts" / "sft"))

import record_replay as rr  # noqa: E402


def test_fmt_forces_float_literals():
    assert rr._fmt(2) == "2.0"          # integer-looking -> float
    assert rr._fmt(0.5) == "0.5"
    assert "e" in rr._fmt(5.6697e-8)    # exponent preserved, already float-ish


def test_parse_fixtures_groups_by_dep_and_splits_args_ret():
    text = "G\t1\t2\t3\nG\t4\t5\t9\nH\t2\t4\n"
    fx = rr.parse_fixtures(text)
    assert fx["G"] == [((1.0, 2.0), 3.0), ((4.0, 5.0), 9.0)]
    assert fx["H"] == [((2.0,), 4.0)]   # 1-arg dep


def test_gen_replay_mojo_one_param_matches_recorded_return():
    src = rr.gen_replay_mojo("H", 1, [((2.0,), 4.0), ((3.0,), 9.0)])
    assert "def H(a0: Float64) raises -> Float64:" in src
    assert "var k0 = [2.0, 3.0]" in src
    assert "var rv = [4.0, 9.0]" in src
    assert "abs(a0 - k0[i])" in src
    assert "return rv[i]" in src


def test_gen_replay_mojo_two_params_ands_conditions():
    src = rr.gen_replay_mojo("G", 2, [((1.0, 2.0), 3.0)])
    assert "def G(a0: Float64, a1: Float64) raises" in src
    assert "var k0 = [1.0]" in src and "var k1 = [2.0]" in src
    assert "abs(a0 - k0[i])" in src and "and" in src and "abs(a1 - k1[i])" in src


def test_gen_replay_mojo_no_calls_raises():
    src = rr.gen_replay_mojo("G", 1, [])
    assert "no recorded calls" in src


def test_gen_recorder_cpp_wraps_dep_and_logs():
    item = {
        "name": "t", "inputs": [[1.0]],
        "f": {"name": "F", "params": 1, "cpp": "double F(double x){ return G(x); }", "mojo": ""},
        "deps": [{"name": "G", "params": 1, "cpp_impl": "double G_impl(double a){ return a*2.0; }"}],
    }
    cpp = rr.gen_recorder_cpp(item)
    assert "double G_impl(double a){ return a*2.0; }" in cpp
    assert "double G(double a0){ double _r = G_impl(a0);" in cpp   # wrapper calls impl
    assert "fprintf(_fx," in cpp                                   # logs the call
    assert "printf(\"%.17g\\n\", F(1.0));" in cpp                  # drives F on input


def test_gen_replay_program_includes_prelude_shims_and_driver():
    item = {
        "name": "t", "inputs": [[2.0]],
        "f": {"name": "F", "params": 1, "cpp": "", "mojo": "def F(x: Float64) raises -> Float64:\n    return G(x)"},
        "deps": [{"name": "G", "params": 1, "cpp_impl": ""}],
    }
    prog = rr.gen_replay_program(item, {"G": [((2.0,), 4.0)]})
    assert "def G(a0: Float64) raises" in prog        # replay shim present
    assert "def F(x: Float64)" in prog                # F present
    assert "print(F(2.0))" in prog                    # driver present
