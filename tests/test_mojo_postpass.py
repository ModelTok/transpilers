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
    out = code(f"def f():\n    var y = {src}\n", syntax=False, mut=False, libm=False)
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
    r = postpass("def f(a: Array2D[Float64])\n{\n    a[0] = 1.0\n}\n")
    text = " ".join(r.unresolved)
    assert "braces" in text and "Array2D" in text and "@export" in text
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
    assert "def relax_array(mut a: List[Float64]," in r.code
    assert "for i in range(len(a)):" in r.code and "Array1D" not in r.code
    assert not any("Array1D" in u for u in r.unresolved)


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


# --- Array1D -> List (ObjexxFCL arrays walked element-wise) ------------------------------------

ARRAY_DEF = (
    "def relax(a: Array1D[Float64],  # to relax\n"
    "          b: Array1D[Float64],\n"
    "          r: Float64) -> None:\n"
    "    assert(equal_dimensions(a, b))\n"
    "    for i in range(a.l(), a.u() + 1):\n"
    "        a[i] = b[i] * r\n"
)


def test_canonical_array1d_loop_becomes_a_zero_based_list_loop():
    out = code(ARRAY_DEF, fma=False)
    assert "def relax(mut a: List[Float64],  # to relax" in out
    assert "      b: List[Float64]," in out.replace("          b", "      b")
    assert "assert(len(a) == len(b))" in out
    assert "for i in range(len(a)):" in out and "a[i] = b[i] * r" in out
    assert "Array1D" not in out and "equal_dimensions" not in out


def test_literal_lower_bound_and_several_loops():
    src = (
        "def f(a: Array1D[Float64], b: Array1D[Float64]):\n"
        "    for i in range(1, a.u() + 1):\n        b[i] = a[i]\n"
        "    for j in range(b.l(), b.u() + 1):\n        a[j] = b[j]\n"
    )
    out = code(src, fma=False)
    assert out.count("for i in range(len(a)):") == 1 and out.count("for j in range(len(b)):") == 1
    assert "List[Float64]" in out and "Array1D" not in out


@pytest.mark.parametrize(
    "body, reason",
    [
        ("    for i in range(a.l(), a.u() + 1):\n        a[i] = a[i] * i\n", "other than as a direct subscript"),
        ("    for i in range(a.l(), a.u() + 1):\n        a[i] = a[i + 1]\n", "other than as a direct subscript"),
        ("    for i in range(a.l(), a.u() + 1):\n        a[i] = 0.0\n    a[1] = 2.0\n", "outside an element-wise loop"),
        ("    var n = a.u()\n    for i in range(a.l(), a.u() + 1):\n        a[i] = 0.0\n", "outside an element-wise loop"),
        ("    a[0] = 1.0\n", "element-wise loop"),
        ("    for i in range(a.l(), a.u() + 1):\n        a[i] = a.u()\n", "inside the loop"),
    ],
)
def test_array1d_rewrite_refuses_when_the_index_base_could_matter(body, reason):
    src = f"def f(a: Array1D[Float64]):\n{body}"
    r = postpass(src, fma=False, mut=False)
    assert "Array1D[Float64]" in r.code and "List[" not in r.code
    assert any(reason in u for u in r.unresolved), r.unresolved


def test_array1d_rewrite_is_per_function_and_leaves_other_types_alone():
    src = (
        "def good(a: Array1D[Float64]):\n    for i in range(a.l(), a.u() + 1):\n        a[i] = 0.0\n\n"
        "def bad(a: Array1D[Float64]):\n    a[1] = 0.0\n\n"
        "def other(x: List[Float64]):\n    for i in range(len(x)):\n        x[i] = 0.0\n"
    )
    r = postpass(src, fma=False)
    assert "def good(mut a: List[Float64])" in r.code
    assert "def bad(a: Array1D[Float64])" in r.code
    assert "def other(mut x: List[Float64])" in r.code
    assert any("`bad`" in u for u in r.unresolved)


def test_dynamicvector_is_renamed_to_list():
    assert "a: List[Float64]" in code("fn f(a: DynamicVector[Float64]):\n    pass\n", fma=False, mut=False)


def test_cli_no_arrays_flag(tmp_path: Path, capsys):
    f = tmp_path / "k.mojo"
    f.write_text(ARRAY_DEF)
    assert main([str(f), "--no-arrays", "--no-fma"]) == 0
    assert "Array1D" in capsys.readouterr().out


# --- glibc-exact maths and ObjexxFCL min/max ----------------------------------------------------


def math(src: str, source: str | None = None, **kw) -> str:
    return postpass(f"def f(x: Float64, y: Float64) -> Float64:\n    var r = {src}\n", fma=False, source=source, **kw).code


@pytest.mark.parametrize("fn", ["exp", "log", "log10", "sin", "cos", "tan", "asin", "acos", "atan", "sinh", "cosh", "tanh"])
def test_libm_calls_are_routed_to_glibc(fn):
    out = math(f"{fn}(x)")
    assert f"var r = libm_{fn}(x)" in out
    assert f'external_call["{fn}", Float64, Float64](x)' in out
    assert "from std.ffi import external_call" in out


def test_two_argument_libm_and_pow_forms():
    out = math("pow(x, 0.25) + atan2(y, x)")
    assert "libm_pow(x, 0.25) + libm_atan2(y, x)" in out
    assert out.count("def libm_pow(") == 1 and out.count("def libm_atan2(") == 1
    assert 'external_call["pow", Float64, Float64, Float64](x, y)' in out
    assert "libm_pow(" in math("(1.4 * y) ** 6")


def test_squares_and_reciprocals_follow_the_c_compiler():
    assert "var r = nc_mul(x, x) + nc_mul(y, y)" in math("pow(x, 2) + y ** 2")
    assert "var r = nc_mul(x + y, x + y)" in math("pow(x + y, 2.0)")
    assert "var r = (1.0 / x)" in math("x ** -1")
    assert "libm_pow(x, 3)" in math("x ** 3")


def test_nested_calls_and_untouched_statements():
    out = math("exp(pow(x, 0.5) + sin(y))")
    assert "var r = libm_exp(libm_pow(x, 0.5) + libm_sin(y))" in out
    src = "def f(x: Float64) -> Float64:\n    return sqrt(x) + abs(x)\n"
    assert postpass(src, fma=False).code == src


def test_max_is_ep_max_and_min_follows_the_upstream_spelling():
    assert "var r = ep_max(x, 1e-05)" in math("max(x, 1e-05)")
    out = math("min(x, y)", source="Real64 f() { return std::min(a, b); }")
    assert "ep_min(x, y)" in out and "from fp_strict import ep_min" in out
    out = math("min(x, y)", source="Real64 f() { return min(a, b); }")
    assert "objexx_min(x, y)" in out
    r = postpass("def f(x: Float64, y: Float64) -> Float64:\n    var r = min(x, y)\n", fma=False)
    assert "var r = min(x, y)" in r.code and any("min" in u for u in r.unresolved)


def test_integer_max_min_and_pow_are_not_rewritten():
    src = "def f(n: Int, i: Int) -> Int:\n    var k = max(0, i - 1)\n    var m = min(n, 4)\n    var q = i ** 2\n    return k\n"
    assert postpass(src, fma=False).code == src


def test_math_pass_skips_gpu_kernels_and_can_be_disabled():
    gpu = "from std.gpu.host import DeviceContext\n\n\ndef f(x: Float64) -> Float64:\n    return exp(x)\n"
    assert postpass(gpu, fma=False).code == gpu
    assert "libm_exp" not in math("exp(x)", libm=False)


def test_real_adapter_drafts_for_math_heavy_routines():
    src = (
        "from std.math import exp\n\ndef CalcSat(Temp: Float64) -> Float64:\n"
        "    return exp(18.6686 - 4030.183 / (Temp + 235.0))\n"
    )
    out = postpass(src).code
    assert "return libm_exp(18.6686 - 4030.183 / (Temp + 235.0))" in out
    src = "from std.math import pow\n\ndef Ra(Ts: Float64, Ta: Float64) -> Float64:\n    return (pow(Ts, 2) + pow(Ta, 2)) * (Ts + Ta)\n"
    assert "return (nc_mul(Ts, Ts) + nc_mul(Ta, Ta)) * (Ts + Ta)" in postpass(src).code


# --- products bound to variables, and ObjexxFCL pow_N --------------------------------------------


def test_product_bound_to_a_variable_and_later_added_is_guarded_at_its_definition():
    src = (
        "def f(a: Float64, b: Float64, c: Float64) -> Float64:\n"
        "    var hr: Float64 = a * b * (a + b)\n"
        "    return 1.0 / (c + hr)\n"
    )
    out = code(src, syntax=False, mut=False, libm=False)
    assert "var hr: Float64 = nc_mul(a * b, a + b)" in out
    assert "return 1.0 / (c + hr)" in out


def test_variable_products_that_are_never_added_or_are_integers_are_left_alone():
    src = (
        "def f(a: Float64, b: Float64, n: Int) -> Float64:\n"
        "    var p = a * b\n    var k = n * 4\n    var q = a * b\n    return p / q + Float64(k) + a\n"
    )
    assert code(src, syntax=False, mut=False, libm=False) == src


def test_reassigned_product_variable_is_guarded_too():
    src = "def f(a: Float64, b: Float64, c: Float64) -> Float64:\n    var t = 0.0\n    t = a * b\n    return t - c\n"
    assert "t = nc_mul(a, b)" in code(src, syntax=False, mut=False, libm=False)


POW_SRC = "return pow_6(1.4 * x) + 1.63 * pow_2(d) + pow_3(y) + std::pow(z, 0.25);"


@pytest.mark.parametrize(
    "expr, rewritten",
    [("(1.4 * y) ** 6", "pow_6(1.4 * y)"), ("pow(y, 2)", "pow_2(y)"), ("y ** 3", "pow_3(y)")],
)
def test_pow_n_follows_objexxfcl_when_the_source_uses_it(expr, rewritten):
    out = math(expr, source=POW_SRC)
    assert f"var r = {rewritten}" in out
    n = rewritten[4]
    assert f"def pow_{n}(x: Float64) -> Float64:" in out


def test_pow_n_helpers_match_the_oracle_definitions():
    out = math("y ** 6 + y ** 5 + y ** 4 + y ** 7", source="pow_4(a) pow_5(a) pow_6(a) pow_7(a)")
    assert "var t = x * x * x\n    return nc_mul(t, t)" in out  # pow_6: t = x*x*x; t*t
    assert "var t = x * x\n    return nc_mul(t * t, x)" in out  # pow_5: t = x*x; t*t*x
    assert "var t = x * x\n    return nc_mul(t, t)" in out  # pow_4
    assert "var t = x * x * x\n    return nc_mul(t * t, x)" in out  # pow_7


def test_without_pow_n_in_the_source_powers_use_libm():
    assert "libm_pow(y, 6)" in math("y ** 6", source="return std::pow(x, 6);")


def test_direct_pow_n_calls_get_their_definition():
    out = math("pow_3(x) + 1.0")
    assert "def pow_3(x: Float64) -> Float64:" in out and "from fp_strict import nc_mul" in out
    already = "def pow_3(x: Float64) -> Float64:\n    return x * x * x\n\n\ndef f(x: Float64) -> Float64:\n    var r = pow_3(x)\n"
    assert postpass(already, fma=False).code.count("def pow_3(") == 1
