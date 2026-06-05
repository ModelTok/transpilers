"""LLM-client backend selection + model resolution (no network)."""

from __future__ import annotations

import pytest

from transpilers.llm.client import DEFAULT_MODEL, LlmClient


def test_model_resolves_from_env(monkeypatch, tmp_path):
    monkeypatch.setenv("TRANSPILER_LLM_MODEL", "Qwen2.5-Coder-3B-Instruct")
    assert LlmClient(cache_dir=tmp_path).model == "Qwen2.5-Coder-3B-Instruct"


def test_explicit_model_beats_env(monkeypatch, tmp_path):
    monkeypatch.setenv("TRANSPILER_LLM_MODEL", "env-model")
    assert LlmClient(model="explicit", cache_dir=tmp_path).model == "explicit"


def test_default_model_when_unset(monkeypatch, tmp_path):
    monkeypatch.delenv("TRANSPILER_LLM_MODEL", raising=False)
    assert LlmClient(cache_dir=tmp_path).model == DEFAULT_MODEL


def test_openai_backend_without_base_url_errors(monkeypatch, tmp_path):
    monkeypatch.setenv("TRANSPILER_LLM_BACKEND", "openai")
    monkeypatch.delenv("OPENAI_BASE_URL", raising=False)
    c = LlmClient(cache_dir=tmp_path)
    with pytest.raises(RuntimeError, match="OPENAI_BASE_URL"):
        c._call("prompt", 0.0)


def test_anthropic_backend_without_key_errors(monkeypatch, tmp_path):
    monkeypatch.setenv("TRANSPILER_LLM_BACKEND", "anthropic")
    monkeypatch.delenv("ANTHROPIC_API_KEY", raising=False)
    c = LlmClient(cache_dir=tmp_path)
    with pytest.raises(RuntimeError, match="ANTHROPIC_API_KEY"):
        c._call("prompt", 0.0)


def test_base_url_infers_openai_backend(monkeypatch, tmp_path):
    # No explicit backend, but OPENAI_BASE_URL set with a bogus host → the
    # openai path is chosen (it gets past the base_url guard and fails on the
    # network/import, not on the "OPENAI_BASE_URL not set" guard).
    monkeypatch.delenv("TRANSPILER_LLM_BACKEND", raising=False)
    monkeypatch.setenv("OPENAI_BASE_URL", "http://127.0.0.1:1/v1")
    monkeypatch.setenv("OPENAI_API_KEY", "EMPTY")
    c = LlmClient(cache_dir=tmp_path)
    with pytest.raises(Exception) as exc:  # noqa: PT011 — import or connection error, not the guard
        c._call("prompt", 0.0)
    assert "OPENAI_BASE_URL is not set" not in str(exc.value)
