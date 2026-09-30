"""Tests for opt-in gtest / Eigen prompt guidance (issues #96, #97)."""

from __future__ import annotations

from pathlib import Path
from types import SimpleNamespace

from transpilers.cli.domain_prompts import (
    EIGEN,
    GTEST,
    apply_domain_guidance,
    detect_domains,
    domain_guidance,
)

BASE = "RULES:\n- x\n\nOUTPUT FORMAT:\n<<<FILE t>>>\n<<<END>>>"

GTEST_SRC = "#include <gtest/gtest.h>\nTEST_F(Fx, A) { EXPECT_EQ(1, 1); }\n"
EIGEN_SRC = "#include <Eigen/Dense>\nEigen::MatrixXd m(2, 2);\n"


def test_detects_gtest():
    assert detect_domains(GTEST_SRC) == [GTEST]
    assert detect_domains("TEST(Suite, Name) {\n}\n") == [GTEST]


def test_detects_eigen_by_include_type_or_path():
    assert detect_domains(EIGEN_SRC) == [EIGEN]
    assert detect_domains("MatrixXd a;") == [EIGEN]
    assert detect_domains("int x;", "third_party\\ssc\\a.cpp") == [EIGEN]


def test_plain_source_has_no_domain():
    assert detect_domains("int main() { return 0; }", "src/a.cc") == []
    assert detect_domains("// TEST(a, b) mentioned in prose") == []


def test_both_domains_can_apply():
    assert detect_domains(GTEST_SRC + EIGEN_SRC) == [GTEST, EIGEN]


def test_guidance_content():
    g = domain_guidance([GTEST])
    for token in ("EXPECT_NEAR", "assert_almost_equal", "SetUp", "TearDown", "TEST_F"):
        assert token in g
    e = domain_guidance([EIGEN])
    for token in ("MatrixXd", "block", "llt", "sscapi_t", "cmod_", "tcstype"):
        assert token in e
    assert domain_guidance([]) == ""


def test_apply_inserts_before_output_format_and_is_noop_otherwise():
    out = apply_domain_guidance(BASE, GTEST_SRC)
    assert out.index("GOOGLETEST RULES") < out.index("OUTPUT FORMAT:")
    assert out.endswith("<<<END>>>")
    assert apply_domain_guidance(BASE, "int x;") == BASE
    assert apply_domain_guidance("no marker", GTEST_SRC).startswith("no marker")


def test_transpile_one_default_unchanged_and_opt_in(tmp_path: Path):
    from transpilers.cli import transpile as t

    prompts: list[str] = []

    class Client:
        class chat:
            @staticmethod
            def send(**kw):
                prompts.append(kw["messages"][0]["content"])
                msg = SimpleNamespace(content="<<<FILE x>>>\npass\n<<<END>>>")
                return SimpleNamespace(choices=[SimpleNamespace(message=msg)])

    src = tmp_path / "a.unit.cc"
    src.write_text(GTEST_SRC)
    entry = {"source": str(src), "target": str(tmp_path / "a.mojo")}
    t.transpile_one(dict(entry), "m", Client, False, 0)
    t.transpile_one(dict(entry), "m", Client, False, 0, domain_prompts=True)
    assert "GOOGLETEST RULES" not in prompts[0]
    assert "GOOGLETEST RULES" in prompts[1]
