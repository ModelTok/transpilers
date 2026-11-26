"""Defects found by the CodeQL code-quality scan (issue #162)."""

from __future__ import annotations

import pytest

from transpilers.llm import ModelTier


@pytest.fixture
def code_graph():
    # transpilers.graph needs networkx, which is not a declared dependency.
    pytest.importorskip("networkx")
    from transpilers.graph import code_graph

    return code_graph


def test_model_tier_supports_every_ordering_operator():
    # Only __lt__ was defined, so <=, > and >= raised TypeError.
    assert ModelTier.CACHED <= ModelTier.CACHED
    assert ModelTier.CACHED <= ModelTier.FRONTIER
    assert ModelTier.FRONTIER > ModelTier.LOCAL_FINETUNED
    assert ModelTier.FRONTIER >= ModelTier.FRONTIER
    assert not ModelTier.CACHED >= ModelTier.FRONTIER
    assert sorted(ModelTier, reverse=True) == list(reversed(ModelTier.ordered()))


@pytest.mark.parametrize(
    "prefix", ["[[nodiscard]] ", "[[nodiscard]] static ", "inline [[nodiscard]] "]
)
def test_cpp_definition_match_includes_the_nodiscard_attribute(code_graph, prefix):
    # `[[nodiscard]]` in the pattern was a character class, not the attribute,
    # so a definition's match started after it.
    source = f"{prefix}int area(int w, int h) {{ return mul(w, h); }}\n"
    m = code_graph._CPP_FUNC_DEF.search(source)
    assert m is not None
    assert m.group(1) == "area"
    assert m.start() == 0


def test_cpp_definition_pattern_does_not_eat_stray_brackets(code_graph):
    # The character class matched one of "[nodiscar" then "]", so text such as
    # "d]" was swallowed as a specifier.
    source = "x[d] int area(int w) { return w; }\n"
    m = code_graph._CPP_FUNC_DEF.search(source)
    assert m is not None
    assert m.group(1) == "area"
    assert source[m.start():].lstrip().startswith("int")
