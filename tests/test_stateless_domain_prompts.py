"""gtest guidance in the stateless runner (issue #96): the dual-port prompt
variant, opt-in wiring through build_prompt/transpile_one and the chunked path.
Mock client only; no network.
"""

from __future__ import annotations

import importlib.util
import re
import sys
from pathlib import Path

import pytest

from transpilers.cli.domain_prompts import (
    EIGEN,
    GTEST,
    domain_guidance,
    insert_guidance,
)

REPO = Path(__file__).resolve().parents[1]

_spec = importlib.util.spec_from_file_location(
    "stateless_transpile_domain", REPO / "stateless transpilation" / "2_transpile.py"
)
T = importlib.util.module_from_spec(_spec)
sys.modules["stateless_transpile_domain"] = T
_spec.loader.exec_module(T)

GTEST_SRC = """#include <gtest/gtest.h>
TEST_F(EnergyPlusFixture, A) {
    EXPECT_NEAR(1.0, f(), 0.1);
}

TEST_F(EnergyPlusFixture, B) {
    EXPECT_TRUE(g());
}
"""


@pytest.fixture
def env(tmp_path, monkeypatch):
    cc = tmp_path / "Foo.unit.cc"
    cc.write_text(GTEST_SRC)
    monkeypatch.setattr(T, "BASE", tmp_path)
    monkeypatch.setattr(T, "_BY_NAME", {"Foo": {"name": "Foo", "cc_path": str(cc), "lang": "cpp"}})
    monkeypatch.setattr(T, "_oracle_paths", lambda f: (cc, None))
    return tmp_path


def _client(calls):
    def fn(prompt, model, timeout, endpoint):
        calls.append(prompt)
        stem = re.search(r"out/python/(\S+?)\.py", prompt).group(1)
        return (f"<<<FILE out/python/{stem}.py>>>\ndef t():\n    pass\n<<<END>>>\n"
                f"<<<FILE out/mojo/{stem}.mojo>>>\nfn t():\n    pass\n<<<END>>>",
                {"cost_usd": 0.0})
    return fn


def test_dual_port_gtest_guidance_asks_for_both_ports_and_overrides_no_tests():
    g = domain_guidance([GTEST], dual_port=True)
    for token in ("BOTH <<<FILE", "do not write", "pytest.approx", "assert_almost_equal",
                  "SetUp", "TearDown", "WORKED EXAMPLE"):
        assert token in g
    assert "exactly one" not in g
    assert domain_guidance([GTEST]) != g


def test_dual_port_eigen_guidance_does_not_contradict_the_two_block_output():
    g = domain_guidance([EIGEN], dual_port=True)
    assert "exactly one <<<FILE" not in g and "both <<<FILE" in g
    assert "exactly one <<<FILE" in domain_guidance([EIGEN])


def test_insert_guidance_targets_either_output_heading():
    assert insert_guidance("a\n## Output format\nb", "G").index("G") < 6
    assert insert_guidance("a\nOUTPUT FORMAT:\nb", "G").index("G") < 4
    assert insert_guidance("a", "") == "a"
    assert insert_guidance("a", "G").endswith("G")


def test_build_prompt_default_unchanged_and_guidance_goes_before_output_format(env):
    plain = T.build_prompt("Foo")
    assert "GOOGLETEST RULES" not in plain
    with_domain = T.build_prompt("Foo", domains=[GTEST])
    assert with_domain.index("GOOGLETEST RULES") < with_domain.index("## Output format")
    assert with_domain.replace(domain_guidance([GTEST], dual_port=True) + "\n", "") == plain


def test_transpile_one_applies_guidance_only_when_opted_in(env, monkeypatch):
    calls = []
    monkeypatch.setattr(T, "call_claude", _client(calls))
    assert T.transpile_one("Foo", "claude", "m", 1, True, None, 10**6)["status"] == "ok"
    assert T.transpile_one("Foo", "claude", "m", 1, True, None, 10**6,
                           domain_prompts=True)["status"] == "ok"
    assert "GOOGLETEST RULES" not in calls[0]
    assert "GOOGLETEST RULES" in calls[1]


def test_non_gtest_source_gets_no_guidance_even_when_opted_in(env, monkeypatch):
    calls = []
    (env / "Foo.unit.cc").write_text("int f() { return 1; }\n")
    monkeypatch.setattr(T, "call_claude", _client(calls))
    T.transpile_one("Foo", "claude", "m", 1, True, None, 10**6, domain_prompts=True)
    assert "GOOGLETEST RULES" not in calls[0]


def test_chunks_keep_guidance_and_respect_the_budget(env, monkeypatch):
    calls = []
    monkeypatch.setattr(T, "call_claude", _client(calls))
    body = "TEST_F(EnergyPlusFixture, T{i}) {{\n    EXPECT_EQ({i}, f({i}));\n}}\n\n"
    (env / "Foo.unit.cc").write_text(
        "#include <gtest/gtest.h>\n" + "".join(body.format(i=i) for i in range(30)))
    note = T._CHUNK_NOTE.format(i=99, n=99, file="Foo")
    limit = len(T.build_prompt("Foo", cc="", hh="", domains=[GTEST], note=note)) + 400
    r = T.transpile_one("Foo", "claude", "m", 1, True, None, limit, chunk=True,
                        domain_prompts=True)
    assert r["status"] == "ok" and len(calls) > 1
    assert all("GOOGLETEST RULES" in p and len(p) <= limit for p in calls)
    # later chunks carry no #include, yet still get the guidance
    assert "#include <gtest" not in calls[-1].split("## Source")[1]


def test_dual_port_eigen_guidance_maps_both_ports_and_writes_through_views():
    g = domain_guidance([EIGEN], dual_port=True)
    for token in ("np.zeros", "np.linalg.solve", "set_block", "set_col", "WRITABLE VIEWS",
                  "WORKED EXAMPLE", "sscapi_t", "tcstype"):
        assert token in g
    assert g.count("WORKED EXAMPLE") == 1


def test_mojo_only_eigen_guidance_no_longer_treats_block_writes_as_copies():
    g = domain_guidance([EIGEN])
    assert "set_block" in g and "WRITABLE VIEWS" in g and "np.zeros" not in g
    assert "(copy)" not in g
