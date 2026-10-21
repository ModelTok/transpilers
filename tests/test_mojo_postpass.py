"""Deterministic Mojo post-pass: syntax normalisation, `mut`, and nc_mul around products that
feed an add/subtract (the FMA-contraction guard EnergyPlusMojo needs for bit-exact kernels)."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

from transpilers.cli import transpile as t
from transpilers.repair.mojo_postpass import main, postpass


def code(src: str, **kw) -> str:
    return postpass(src, **kw).code


# --- syntax ------------------------------------------------------------------------------------


def test_cpp_line_comments_become_hash_comments():
    assert code("// upstream: X.cc:1\ndef f():\n    pass\n", fma=False, mut=False).startswith("# upstream: X.cc:1\n")
    out = code("def f(a: Float64,  // the first\n      b: Float64):\n    pass\n", fma=False, mut=False)
    assert "# the first" in out and "//" not in out


def test_floor_division_is_not_mistaken_for_a_comment():
    src = "def f(n: Int) -> Int:\n    var h = (n + 1) // 2\n    return n // h\n"
    assert code(src, fma=False, mut=False) == src


def test_strings_are_left_alone():
    src = 'def f():\n    var s = "a // b && c != d"\n'
    assert code(src, fma=False, mut=False) == src


def test_old_mojo_and_cpp_keywords_are_modernised():
    out = code(
        'from "../Psychrometrics" import PsyRho\nalias N: Int = 3\n'
        "fn f(x: Real64 const) -> Float64:\n    let y: Float64 = 1.0;\n"
        "    if x > 0.0 && !(y != 2.0) || true:\n        return y\n    return x\n",
        fma=False,
        mut=False,
    )
    assert "from Psychrometrics import PsyRho" in out
    assert "comptime N: Int = 3" in out
    assert "def f(x: Float64)" in out
    assert "var y: Float64 = 1.0\n" in out
    assert "x > 0.0 and not (y != 2.0) or True" in out


# --- mut ---------------------------------------------------------------------------------------


def test_mut_added_for_index_assigned_parameter_only():
    out = code(
        "def f(a: List[Float64], b: List[Float64], r: Float64):\n    for i in range(len(a)):\n        a[i] = b[i] * r\n",
        fma=False,
    )
    assert "def f(mut a: List[Float64], b: List[Float64], r: Float64)" in out


def test_mut_not_added_for_pointers_scalars_or_existing_conventions():
    src = (
        "def f(p: UnsafePointer[Float64, MutAnyOrigin], mut a: List[Float64], n: Int):\n"
        "    p[0] = 1.0\n    a[0] = 2.0\n"
    )
    assert code(src, fma=False) == src


def test_mut_handles_multiline_signatures_with_comments():
    out = code(
        "def f(a: List[Float64],   # to relax\n      b: List[Float64],   # towards\n      r: Float64):\n    a[0] += b[0]\n",
        fma=False,
    )
    assert "def f(mut a: List[Float64],   # to relax" in out
    assert "      b: List[Float64]," in out


# --- nc_mul ------------------------------------------------------------------------------------


@pytest.mark.parametrize(
    "src, expected",
    [
        ("a * b + c", "nc_mul(a, b) + c"),
        ("c - a * b", "c - nc_mul(a, b)"),
        ("a * b - c", "nc_mul(a, b) - c"),
        ("r * b[i] + q * a[i]", "nc_mul(r, b[i]) + nc_mul(q, a[i])"),
        ("(1.0 - r) * a + r * b", "nc_mul(1.0 - r, a) + nc_mul(r, b)"),
        ("a * b * c + d", "nc_mul(a * b, c) + d"),
        ("x * (a * b + c)", "x * (nc_mul(a, b) + c)"),
        ("1.23 * (dT * dT) + pow(L, 0.25)", "nc_mul(1.23, dT * dT) + pow(L, 0.25)"),
    ],
)
def test_products_feeding_add_or_sub_are_guarded(src, expected):
    out = code(f"def f():\n    var y = {src}\n", syntax=False, mut=False)
    assert f"var y = {expected}\n" in out
    assert "from fp_strict import nc_mul" in out


@pytest.mark.parametrize(
    "src",
    ["a * b", "a / b + c", "a * (b + c)", "a * b * c", "0.5 * a + c", "2.0 * a - c", "i * stride + j"],
)
def test_nothing_to_guard(src):
    text = f"def f(i: Int, stride: Int, j: Int):\n    var y = {src}\n"
    assert code(text, syntax=False, mut=False) == text


def test_augmented_assignments_guard_the_product():
    out = code("def f():\n    acc += a * b\n    acc -= c * d\n    acc *= e\n", syntax=False, mut=False)
    assert "acc += nc_mul(a, b)" in out and "acc -= nc_mul(c, d)" in out and "acc *= e" in out


def test_integer_index_arithmetic_is_not_wrapped():
    src = "def f(n: Int, c: Int):\n    for k in range(n):\n        out[2 * c + k] = x[k] * w[k] + b\n"
    out = code(src, syntax=False, mut=False)
    assert "out[2 * c + k]" in out
    assert "nc_mul(x[k], w[k]) + b" in out


def test_conditions_returns_and_multiline_expressions():
    out = code(
        "def f():\n    if a * b + c > d:\n        return a * b - c\n"
        "    var y = (a * b +\n             c * d)  # note\n",
        syntax=False,
        mut=False,
    )
    assert "if nc_mul(a, b) + c > d:" in out
    assert "return nc_mul(a, b) - c" in out
    assert "(nc_mul(a, b) +\n             nc_mul(c, d))  # note" in out


def test_idempotent_and_already_guarded_code_is_untouched():
    src = "from fp_strict import nc_mul\n\n\ndef f():\n    var y = nc_mul(a, b) + c\n"
    assert code(src) == src
    first = code("def f():\n    var y = a * b + c\n")
    assert code(first) == first


def test_import_placement_and_extension():
    out = code("from std.math import sqrt\n\n\ndef f():\n    var y = a * b + c\n", syntax=False, mut=False)
    assert out.startswith("from std.math import sqrt\nfrom fp_strict import nc_mul\n")
    out = code("from fp_strict import ep_abs\n\n\ndef f():\n    var y = a * b + c\n", syntax=False, mut=False)
    assert "from fp_strict import ep_abs, nc_mul\n" in out
    out = code("def f():\n    var y = a * b + c\n", syntax=False, mut=False)
    assert out.startswith("from fp_strict import nc_mul\n\n\ndef f():")


def test_unparseable_statements_are_skipped_not_mangled():
    src = "def f():\n    var y = a ? b : c + d * e\n"
    assert "nc_mul" not in code(src, syntax=False, mut=False)


# --- reporting ---------------------------------------------------------------------------------


def test_unresolved_items_are_reported_not_guessed():
    r = postpass("def f(a: DynamicVector[Float64])\n{\n    a[0] = 1.0\n}\n")
    text = " ".join(r.unresolved)
    assert "braces" in text and "DynamicVector" in text and "@export" in text
    assert "@export" not in " ".join(postpass("@export\ndef k(n: Int):\n    pass\n").unresolved)


# --- drafts produced by real models (EnergyPlusMojo relax_array) --------------------------------

ADAPTER_CONTROL = (
    "def relax_array(mut a: List[Float64], b: List[Float64], r: Float64):\n"
    "    assert len(a) == len(b)\n    var q = 1.0 - r\n    for i in range(len(a)):\n"
    "        a[i] = r * b[i] + q * a[i]"
)
ADAPTER_GUIDED = (
    "def relax_array(a: List[Float64], b: List[Float64], r: Float64):\n"
    "    for i in range(len(a)):\n        a[i] = r * b[i] + (1.0 - r) * a[i]"
)
DIFFCODER_GUIDED = (
    "// upstream: HeatBalFiniteDiffManager.cc:1148\n"
    "def relax_array(a: Array1D[Float64],       # Array to relax\n"
    "                b: Array1D[Float64],       # Array to relax towards\n"
    "                r: Float64                 # Relaxation factor [0-1]\n"
    "               ) -> None:\n"
    "    var q = 1.0 - r\n    for i in range(a.l(), a.u() + 1):\n        a[i] = r * b[i] + q * a[i]"
)


def test_real_drafts():
    out = code(ADAPTER_CONTROL)
    assert "a[i] = nc_mul(r, b[i]) + nc_mul(q, a[i])" in out and out.startswith("from fp_strict import nc_mul")
    out = code(ADAPTER_GUIDED)
    assert "def relax_array(mut a: List[Float64]" in out
    assert "nc_mul(r, b[i]) + nc_mul(1.0 - r, a[i])" in out
    r = postpass(DIFFCODER_GUIDED)
    assert r.code.startswith("# upstream: HeatBalFiniteDiffManager.cc:1148\nfrom fp_strict import nc_mul")
    assert "mut a:" not in r.code  # unknown type: left for the model or the compiler
    assert any("Array1D" in u for u in r.unresolved)


# --- CLI and transpile-llm integration ---------------------------------------------------------


def test_cli_rewrites_in_place_and_reports(tmp_path: Path, capsys):
    f = tmp_path / "k.mojo"
    f.write_text("def f():\n    var y = a * b + c\n")
    assert main([str(f), "--in-place"]) == 0
    assert "nc_mul(a, b) + c" in f.read_text()
    err = capsys.readouterr().err
    assert "nc_mul" in err and "UNRESOLVED" in err
    assert main([str(f), "--no-fma"]) == 0
    assert "nc_mul(a, b) + c" in capsys.readouterr().out


def test_transpile_llm_postpass_flag(tmp_path: Path, monkeypatch):
    class Client:
        class chat:
            @staticmethod
            def send(**kw):
                from types import SimpleNamespace

                body = "<<<FILE x>>>\nfn f():\n    var y = a * b + c\n<<<END>>>"
                return SimpleNamespace(choices=[SimpleNamespace(message=SimpleNamespace(content=body))])

    src = tmp_path / "foo.cc"
    src.write_text("double f();\n")
    entry = {"source": str(src), "target": str(tmp_path / "foo.mojo")}
    res = t.transpile_one(dict(entry), "m", Client, False, 0)
    assert "fn f()" in (tmp_path / "foo.mojo").read_text() and "postpass_changes" not in res
    res = t.transpile_one(dict(entry), "m", Client, False, 0, postpass=True)
    out = (tmp_path / "foo.mojo").read_text()
    assert "def f()" in out and "nc_mul(a, b) + c" in out
    assert res["postpass_changes"] > 0 and "postpass_unresolved" in res
    monkeypatch.setattr(sys, "argv", ["x"])
    assert json.dumps(res)


# --- precision: things that must not be touched (found by scanning EnergyPlusMojo's kernels) ---


@pytest.mark.parametrize(
    "src",
    [
        "def f(n: Int):\n    var s = n\n    s //= 2\n",
        "def f(a: Float64, d: Float64):\n    var k = max(1, Int(a // d))\n",
        "def f(m: Int):\n    var mod = (m // 60) * 60 + m % 60  # note\n    sev(c, 4, r, m // 2, 0)  # message\n",
        "def f(m: Int):\n    var n = ((((15 if 15 > m else m) + 16) // 16) * 16) - 1  # SolarShading.cc:205\n",
    ],
)
def test_floor_division_is_never_turned_into_a_comment(src):
    assert code(src, fma=False, mut=False) == src


def test_signature_comments_inside_parentheses_are_still_converted():
    out = code("def f(a: Float64,  // Array to relax\n      r: Float64   // Relaxation factor [0-1]\n    ):\n    pass\n", fma=False, mut=False)
    assert "# Array to relax" in out and "# Relaxation factor [0-1]" in out and "//" not in out


def test_mut_only_for_known_mutable_containers():
    src = "def f(p: I64P, s: Sizer, a: Array1D[Float64]):\n    p[0] = 1\n    s[0] = 2\n    a[0] = 3.0\n"
    assert code(src, fma=False) == src
    assert "mut a: InlineArray[Float64, 3]" in code("def f(a: InlineArray[Float64, 3]):\n    a[0] = 1.0\n", fma=False)


def test_deliberate_fma_ok_and_constant_products_are_left_alone():
    src = "def f():\n    var h = (n // 2) * stride + j  # fma: ok (integer arithmetic)\n    var c = 1.7e-5 + 4.8e-8 * 20.0\n"
    assert code(src, syntax=False, mut=False) == src
    src = "# fma: ok comment above is not a marker for the next line\ndef f():\n    var y = a * b + c\n"
    assert "nc_mul(a, b) + c" in code(src, syntax=False, mut=False)


def test_integer_variables_inferred_from_assignments_and_wide_types():
    src = "def f(n: Int64, c: UInt32):\n    var k = n * 4 + 1\n    var j = k * n + c\n    var y = a * b + k\n"
    out = code(src, syntax=False, mut=False)
    assert "var k = n * 4 + 1" in out and "var j = k * n + c" in out
    assert "var y = nc_mul(a, b) + k" in out


def test_floor_division_inside_a_subscript_is_not_a_comment():
    src = "def f(i: Int):\n    rguess[i] = 1.0 / scon[i // 2]\n    t = x[(i + 1) // 4][j]\n"
    assert code(src, fma=False, mut=False) == src


# --- regressions found by compiling post-passed EnergyPlusMojo kernels --------------------------


def test_import_goes_after_a_multiline_import_statement():
    src = 'from std.math import (\n    abs,\n    round,\n)\n\n\ndef f():\n    var y = a * b + c\n'
    out = code(src, syntax=False, mut=False)
    assert out.startswith("from std.math import (\n    abs,\n    round,\n)\nfrom fp_strict import nc_mul\n")


def test_existing_multiline_fp_strict_import_is_not_extended_in_place():
    src = "from fp_strict import (\n    ep_abs,\n)\n\n\ndef f():\n    var y = a * b + c\n"
    out = code(src, syntax=False, mut=False)
    assert "from fp_strict import (\n    ep_abs,\n)\nfrom fp_strict import nc_mul\n" in out


def test_int_times_unknown_is_treated_as_index_arithmetic():
    src = "def f(ny: Int):\n    var ix = _find(x, g)\n    var base = ix * ny + iy\n    var h = (ix + 1) * ny + iy\n"
    assert code(src, syntax=False, mut=False) == src


def test_known_float_times_int_is_still_guarded():
    src = "def f(x: Float64, n: Int):\n    var y = x * n + c\n"
    assert "nc_mul(x, n) + c" in code(src, syntax=False, mut=False)


def test_gpu_kernels_are_not_given_nc_mul():
    src = "from std.gpu.host import DeviceContext\n\n\ndef f():\n    var y = a * b + c\n"
    r = postpass(src, syntax=False, mut=False)
    assert r.code == src and any("GPU" in u for u in r.unresolved)
