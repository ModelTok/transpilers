"""Tests for issue #50: C++ ground-truth types via clang AST.

These tests pin down the behaviour added by the preprocessor and the
``cpp_ground_truth`` MIR pass: macros are expanded, libclang gives
us resolved types, and the HIR->MIR hole-filling picks them up.
"""
from __future__ import annotations



from transpilers.frontends.cpp.parser import parse_cpp
from transpilers.frontends.cpp.parser.preprocess import (
    PARSER_PREAMBLE,
    preprocess_cpp,
)
from transpilers.frontends.cpp.parser.type_extractor import TypeGroundTruth
from transpilers.ir import hir, mir
from transpilers.ir.types import (
    IntT,
    ListT,
    NoneT,
    StrT,
    UnknownT,
)
from transpilers.passes.cpp_ground_truth import apply_ground_truth
from transpilers.passes import hir_to_mir


# ---------------------------------------------------------------------------
# Preprocessor
# ---------------------------------------------------------------------------


def test_preprocess_cpp_expands_object_like_macros():
    """`#define X 1` is fully expanded before libclang sees the source.

    Without this, every reference to `X` in the user's code reaches
    the parser as an undeclared identifier. With it, the AST sees
    `int x = 1;` and the inference pass can type the binding.
    """
    src = "#define X 1\nint x = X;\n"
    out = preprocess_cpp(src)
    assert "int x = 1" in out
    # The `#define` directive is stripped (not user code).
    assert "#define" not in out


def test_preprocess_cpp_strips_include_lines():
    """`<...>` and `"..."` includes are removed so the parser preamble
    is the only `std::` namespace libclang sees."""
    out = preprocess_cpp("#include <vector>\nint x = 1;\n")
    assert "#include" not in out
    assert "int x = 1" in out


def test_preprocess_cpp_strips_requires_clauses():
    """The C++20 `requires` constraint is dropped. libclang on the
    affected libclang versions chokes on `requires` in template
    parameter lists; we avoid the error by deleting the line
    entirely (the function still parses)."""
    out = preprocess_cpp(
        "template <typename T>\n"
        "requires std::totally_ordered<T>\n"
        "void sort(std::vector<T>&) {}\n"
    )
    assert "requires" not in out
    # The function body survives.
    assert "void sort" in out


def test_preprocess_cpp_handles_unspaced_include():
    """`#include<vector>` (no space) is matched by the stripper, not
    only `#include <vector>`. The corpus uses both forms."""
    out = preprocess_cpp("#include<vector>\nint x = 1;\n")
    assert "#include" not in out
    assert "int x = 1" in out


def test_preprocess_cpp_falls_back_when_no_clang():
    """No `clang` on PATH -> fall back to directive-stripping alone.
    The output is still usable (less accurate but functional)."""
    out = preprocess_cpp("#include <vector>\nint x = 1;\n", clang="/no/such/clang")
    assert "#include" not in out


def test_parser_preamble_declares_math_intrinsics():
    """`std::sqrt` / `std::swap` / `std::max` need declarations in the
    parser preamble so libclang doesn't error on the corpus. This
    is a regression guard for issue #50 — adding a missing
    `std::` declaration here re-enables a whole bucket of code
    that was previously failing with "no member named 'X' in std"."""
    for name in ("sqrt", "exp", "log", "swap", "min", "max"):
        assert name in PARSER_PREAMBLE, (
            f"parser preamble missing {name}"
        )

# ---------------------------------------------------------------------------
# parse_cpp returns (HirModule, TypeGroundTruth)
# ---------------------------------------------------------------------------


def test_parse_cpp_returns_tuple_with_ground_truth():
    """The new contract: parse_cpp(source) -> (hir, ground_truth).
    Tests and external code that pre-dates the tuple return can
    still call parse_cpp()[0]."""
    src = "int add(int a, int b) { return a + b; }"
    parsed = parse_cpp(src)
    assert isinstance(parsed, tuple)
    assert len(parsed) == 2
    hir_mod, truth = parsed
    assert isinstance(hir_mod, hir.HirModule)
    assert isinstance(truth, TypeGroundTruth)


def test_parse_cpp_ground_truth_collects_function_signature():
    """`int add(int, int)` -> func_returns['add'] == IntT(),
    func_params['add'] == [IntT(), IntT()]."""
    src = "int add(int a, int b) { return a + b; }"
    _, truth = parse_cpp(src)
    assert truth.func_returns.get("add") == IntT()
    assert truth.func_params.get("add") == [IntT(), IntT()]


def test_parse_cpp_ground_truth_records_template_signature():
    """`template <typename T> void f(vector<T>&)` -> the template's
    signature is in the truth table, even though the body becomes
    a HirRaw hole."""
    src = (
        "template <typename T>\n"
        "requires std::totally_ordered<T>\n"
        "void bubble_sort(std::vector<T>& array) {}\n"
    )
    _, truth = parse_cpp(src)
    # The key is the bare name (the function isn't inside a
    # namespace in this test source) or any qualified key whose
    # last segment is `bubble_sort`.
    qualified = next(
        (k for k in truth.func_returns
         if k == "bubble_sort" or k.endswith("::bubble_sort")),
        None,
    )
    assert qualified is not None, f"missing bubble_sort in {list(truth.func_returns)}"
    assert truth.func_returns[qualified] == NoneT()
    assert truth.func_params[qualified][0] == ListT(elem="T")


# ---------------------------------------------------------------------------
# HIR nodes carry source_loc
# ---------------------------------------------------------------------------


def test_hir_node_base_has_source_loc():
    """Every HIR node has an optional `source_loc` field."""
    n = hir.HirName(name="x")
    assert n.source_loc is None  # default is None


def test_hir_module_preserves_user_decl_after_preamble():
    """Parser preamble types do NOT leak into user HIR."""
    src = "struct Point { int x; int y; };"
    hir_mod, _ = parse_cpp(src)
    names = [getattr(n, "name", None) for n in hir_mod.body]
    assert "Point" in names
    for preamble_name in ("exception", "string", "string_view"):
        assert preamble_name not in names


# ---------------------------------------------------------------------------
# apply_ground_truth fills UnknownT holes
# ---------------------------------------------------------------------------


def test_apply_ground_truth_fills_function_return_and_params():
    """A function with UnknownT return/params is filled from truth."""
    src = "int add(int a, int b) { return a + b; }"
    hir_mod, truth = parse_cpp(src)
    mir_mod = hir_to_mir(hir_mod)
    apply_ground_truth(mir_mod, truth, hir_mod)
    fn = mir_mod.functions[0]
    assert fn.name == "add"
    assert fn.return_type == IntT()
    assert [p.ty for p in fn.params] == [IntT(), IntT()]


def test_apply_ground_truth_is_noop_on_empty_truth():
    """Empty TypeGroundTruth is a no-op fast path."""
    from transpilers.ir.mir import MirFunction, MirModule
    fn = MirFunction(name="f", params=[], return_type=UnknownT(), body=[])
    mod = MirModule(functions=[fn])
    out = apply_ground_truth(mod, TypeGroundTruth())
    assert out is mod


def test_apply_ground_truth_preserves_user_supplied_types():
    """Already-resolved types on the MIR are NOT overwritten."""
    src = "int add(int a, int b) { return a + b; }"
    hir_mod, truth = parse_cpp(src)
    mir_mod = hir_to_mir(hir_mod)
    # Tamper: set the first param to a non-UnknownT type.
    mir_mod.functions[0].params[0] = mir.MirParam(
        name="a", ty=StrT(),  # wrong on purpose
    )
    apply_ground_truth(mir_mod, truth, hir_mod)
    # The pre-existing StrT survives -- we don't overwrite concrete types.
    assert mir_mod.functions[0].params[0].ty == StrT()
    assert mir_mod.functions[0].params[1].ty == IntT()


# ---------------------------------------------------------------------------
# End-to-end pipeline
# ---------------------------------------------------------------------------


def test_e2e_macro_expansion_flows_to_annotation():
    """`#define NULL 0` plus `int x = NULL;` transpiles to `var x: Int = 0`.

    The macro use is wrapped in a function -- module-level globals are
    inlined as module constants by the existing engine rather than
    emitted as declarations, so the e2e test of "the macro reaches
    the typed annotation" has to live inside a function body.
    """
    from transpilers.cli.main import transpile_cpp_to_mojo
    out = transpile_cpp_to_mojo(
        "#define NULL 0\nint f() { int x = NULL; return x; }\n"
    )
    assert "var x: Int = 0" in out


def test_e2e_uses_clang_resolved_intrinsic_signature():
    """`std::sqrt(x)` -> Mojo emits `from math import sqrt`."""
    from transpilers.cli.main import transpile_cpp_to_mojo
    out = transpile_cpp_to_mojo("double f(double x){ return std::sqrt(x); }")
    assert "from math import sqrt" in out


def test_e2e_template_definition_emits_todo_stub():
    """A C++ template definition is preserved as a HirRaw hole and
    every backend emits a TODO[port] stub. The ownership/RAII/
    template-instantiation is left for the inference / LLM pass."""
    from transpilers.cli.main import transpile_cpp_to_mojo
    out = transpile_cpp_to_mojo(
        "template <typename T>\n"
        "T add(T a, T b) { return a + b; }\n"
    )
    assert "TODO[port]" in out
