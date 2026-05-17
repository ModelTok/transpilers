"""LLM-driven variable rename pass.

Uses fake LLM callables so the tests are deterministic and don't depend on
API credentials. Demonstrates that the pass:
  - detects opaque names (Ghidra patterns: `local_X`, `param_N`, `iVarN`)
  - asks the injected callable for each one
  - applies all renames to the MIR
  - leaves non-opaque names untouched
  - disambiguates LLM-proposed names that collide
"""

from __future__ import annotations

import textwrap

import pytest

from transpilers.frontends.python import parse_python
from transpilers.passes import hir_to_mir, infer_types, llm_rename, mir_to_rust_lir
from transpilers.backends.rust import emit_rust


def _to_mir(source: str):
    hir_mod = parse_python(textwrap.dedent(source).lstrip())
    mir_mod = hir_to_mir(hir_mod)
    infer_types(mir_mod)
    return mir_mod


def test_rename_replaces_param_pattern():
    """`def f(param_1):` becomes whatever the fake LLM picks."""
    mir_mod = _to_mir("def factorial(param_1: int) -> int:\n    return param_1\n")
    chosen: dict[str, str] = {}

    def fake(old: str, ctx: dict) -> str:
        chosen[old] = ctx["old_name"]
        return "n"

    llm_rename(mir_mod, llm_fill=fake)
    assert chosen == {"param_1": "param_1"}
    out = emit_rust(mir_to_rust_lir(mir_mod))
    assert "fn factorial(n: i64)" in out
    assert "param_1" not in out


def test_rename_local_X_pattern():
    """Ghidra-style `local_10`, `local_c` (hex suffixes) are detected."""
    mir_mod = _to_mir(
        """
        def factorial(n: int) -> int:
            local_10: int = 1
            local_c: int = 1
            while local_c <= n:
                local_10 = local_10 * local_c
                local_c = local_c + 1
            return local_10
        """
    )

    def fake(old: str, _ctx: dict) -> str:
        return {"local_10": "result", "local_c": "i"}[old]

    llm_rename(mir_mod, llm_fill=fake)
    out = emit_rust(mir_to_rust_lir(mir_mod))
    assert "local_10" not in out
    assert "local_c" not in out
    assert "let mut result" in out
    assert "let mut i" in out
    assert "while i <= n" in out


def test_rename_skips_non_opaque_names():
    """Real names — `total`, `i`, `xs` — must not be touched."""
    mir_mod = _to_mir(
        """
        def sum_range(n: int) -> int:
            total: int = 0
            for i in range(n):
                total = total + i
            return total
        """
    )
    called: list[str] = []

    def fake(old: str, _ctx: dict) -> str:
        called.append(old)
        return "WRONG"

    llm_rename(mir_mod, llm_fill=fake)
    assert called == [], f"non-opaque names should not be sent to LLM: {called}"
    out = emit_rust(mir_to_rust_lir(mir_mod))
    assert "total" in out and "WRONG" not in out


def test_rename_disambiguates_colliding_proposals():
    """If the LLM proposes a name that's already in use (or has been
    proposed earlier this run), the pass appends a numeric suffix instead
    of silently shadowing."""
    mir_mod = _to_mir(
        """
        def f(param_1: int, param_2: int) -> int:
            return param_1 + param_2
        """
    )

    def fake(_old: str, _ctx: dict) -> str:
        return "x"  # both params will be renamed to "x" — must disambiguate

    llm_rename(mir_mod, llm_fill=fake)
    out = emit_rust(mir_to_rust_lir(mir_mod))
    assert "fn f(x: i64, x_1: i64)" in out
    assert "x + x_1" in out


def test_rename_iVar_uVar_patterns():
    """Other Ghidra prefixes: `iVar1`, `uVar2`, etc."""
    mir_mod = _to_mir(
        """
        def f(n: int) -> int:
            iVar1: int = 0
            uVar2: int = 1
            iVar1 = iVar1 + uVar2
            return iVar1
        """
    )

    def fake(old: str, _ctx: dict) -> str:
        return {"iVar1": "running_sum", "uVar2": "step"}[old]

    llm_rename(mir_mod, llm_fill=fake)
    out = emit_rust(mir_to_rust_lir(mir_mod))
    assert "let mut running_sum" in out
    # `step` is assigned once → emitted as immutable `let` (not `let mut`).
    assert "let step" in out
    assert "running_sum += step" in out


def test_rename_validator_rejects_bad_llm_output():
    """The LLM-side validator (in llm/inference.py) rejects non-identifier
    output before it ever reaches the pass — verify directly."""
    from transpilers.llm.inference import _parse_rename

    with pytest.raises(ValueError, match="non-identifier"):
        _parse_rename('{"name": "123start"}')
    with pytest.raises(ValueError, match="non-identifier"):
        _parse_rename('{"name": "with space"}')
    # Valid case round-trips cleanly.
    assert _parse_rename('{"name": "running_sum"}') == "running_sum"
