"""Tests for the dry-run Mojo package layout planner (issue #95)."""

from transpilers.pipeline.mojo_layout import plan_layout, plan_init_files, relative_module


def test_init_files_cover_ancestors_and_skip_existing():
    paths = ["a/b/X.mojo", "a/Y.mojo", "c/__init__.mojo", "c/Z.mojo"]
    assert plan_init_files(paths) == ["a/__init__.mojo", "a/b/__init__.mojo"]


def test_relative_module_dots():
    assert relative_module("a/b/X.mojo", ("a", "b", "Y")) == ".Y"
    assert relative_module("a/b/X.mojo", ("a", "Y")) == "..Y"
    assert relative_module("a/b/X.mojo", ("a", "c", "Y")) == "..c.Y"
    assert relative_module("a/b/X.mojo", ("Top",)) == "...Top"


def test_plan_layout_rewrites_and_reports_unresolved():
    sources = {
        "Data/A.mojo": "from EnergyPlus.Data.B import foo\nfrom EnergyPlus.Util.C import bar, baz\n",
        "Data/B.mojo": "from ObjexxFCL import Array1D\n",
        "Util/C.mojo": "    from Data.A import x\n",
    }
    plan = plan_layout(sources, root="EnergyPlus")
    new = {(r.file, r.line): r.new for r in plan.rewrites}
    assert new[("Data/A.mojo", 1)] == "from .B import foo"
    assert new[("Data/A.mojo", 2)] == "from ..Util.C import bar, baz"
    assert new[("Util/C.mojo", 1)] == "    from ..Data.A import x"
    assert plan.unresolved == [("Data/B.mojo", 1, "from ObjexxFCL import Array1D")]
    assert plan.init_files == ["Data/__init__.mojo", "Util/__init__.mojo"]


def test_already_relative_imports_untouched():
    plan = plan_layout({"a/X.mojo": "from .Y import z\n", "a/Y.mojo": ""})
    assert plan.rewrites == [] and plan.unresolved == []
