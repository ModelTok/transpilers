"""Tests for scripts/sft/boundary_inventory.py (dependency-boundary inventory, #66)."""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
_spec = importlib.util.spec_from_file_location(
    "boundary_inventory", REPO / "scripts/sft/boundary_inventory.py"
)
bi = importlib.util.module_from_spec(_spec)
sys.modules["boundary_inventory"] = bi
_spec.loader.exec_module(bi)

SAMPLE = """
// Constant::Ignored in a comment, sin(x) too
#include <cmath>
void f(Array1D<Real64> &a, Array2D<Real64> const &b, Array3D<int> c) {
    Real64 s = Constant::Pi * std::sin(a(1)) + pow(b(1, 2), 2) + Constant::Sigma;
    const char *t = "Constant::InString cos(";
    Real64 w = PsyPsatFnTemp(20.0) + PsyHFnTdbW(20.0, 0.01);
    x.sin(1);
}
"""


def test_scan_text_counts_and_ignores_noise():
    r = bi.scan_text(SAMPLE)
    assert r["arrays"] == {"Array1D": 1, "Array2D": 1, "Array3D": 1}
    assert r["constants"] == {"Pi": 1, "Sigma": 1}
    assert r["libm"] == {"sin": 1, "pow": 1}
    assert r["psychro"] == {"PsyPsatFnTemp": 1, "PsyHFnTdbW": 1}


def test_shim_coverage_reads_repo_shims():
    cov = bi.shim_coverage()
    assert {"Array1D", "Array2D"} <= cov["arrays"]
    assert {"Pi", "Sigma", "Gravity", "UniversalGasConstant"} <= cov["constants"]
    assert "PsyPsatFnTemp" in cov["psychro"]


def test_build_inventory_flags_unshimmed_and_groups_by_module(tmp_path):
    (tmp_path / "Alpha.cc").write_text(SAMPLE)
    (tmp_path / "Beta.hh").write_text("Real64 g() { return Constant::Pi + Constant::Nope; }")
    (tmp_path / "notes.txt").write_text("Constant::Pi")
    inv = bi.build_inventory([tmp_path])
    assert set(inv["by_module"]) == {"Alpha", "Beta"}
    assert inv["totals"]["constants"]["Pi"] == 2
    assert inv["unshimmed"]["constants"] == ["Nope"]
    assert inv["unshimmed"]["arrays"] == ["Array3D"]
    assert inv["unshimmed"]["psychro"] == ["PsyHFnTdbW"]
    assert "[NO SHIM]" in bi.render(inv)


def test_main_requires_path(monkeypatch, capsys):
    monkeypatch.delenv("EP_SRC", raising=False)
    assert bi.main([]) == 2
