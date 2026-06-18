"""Tests for the DiffusionGemma client module (no network calls, no GPU required).

Tests cover configuration, prompt formatting, thinking-mode stripping, and
backend detection. Actual inference is NOT tested here (requires GGUF files
or vLLM server).
"""

from __future__ import annotations

import pytest

from transpilers.llm.diffusion import (
    DEFAULT_CANVAS_LEN,
    DEFAULT_MAX_DENOISING_STEPS,
    EB_SAMPLER_DEFAULTS,
    DiffusionGenerationConfig,
    DiffusionGemmaClient,
    DiffusionSamplerConfig,
    _default_model,
    _find_llamacpp_binary,
    make_diffusion_client,
    DIFFUSION_MODEL_ID,
    DIFFUSION_MODEL_GGUF_REPO,
)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def make_llamacpp_client(model: str = "/fake/model.gguf") -> DiffusionGemmaClient:
    """Create a DiffusionGemmaClient with a fake llamacpp binary path."""
    return DiffusionGemmaClient(
        backend="llamacpp",
        model=model,
        llamacpp_binary="/fake/llama-diffusion-cli",
    )


# ---------------------------------------------------------------------------
# DiffusionSamplerConfig tests
# ---------------------------------------------------------------------------


class TestDiffusionSamplerConfig:
    def test_defaults(self):
        cfg = DiffusionSamplerConfig()
        assert cfg.temperature_start == 0.8
        assert cfg.temperature_end == 0.4
        assert cfg.entropy_bound == 0.1
        assert cfg.confidence == 0.005
        assert cfg.max_steps == DEFAULT_MAX_DENOISING_STEPS
        assert cfg.adaptive_stopping is True

    def test_custom_values(self):
        cfg = DiffusionSamplerConfig(
            temperature_start=0.9,
            temperature_end=0.3,
            entropy_bound=0.05,
            max_steps=24,
            adaptive_stopping=False,
        )
        assert cfg.temperature_start == 0.9
        assert cfg.temperature_end == 0.3
        assert cfg.entropy_bound == 0.05
        assert cfg.max_steps == 24
        assert cfg.adaptive_stopping is False

    def test_eb_sampler_defaults_match(self):
        cfg = DiffusionSamplerConfig()
        assert EB_SAMPLER_DEFAULTS["temperature_start"] == cfg.temperature_start
        assert EB_SAMPLER_DEFAULTS["temperature_end"] == cfg.temperature_end
        assert EB_SAMPLER_DEFAULTS["entropy_bound"] == cfg.entropy_bound
        assert EB_SAMPLER_DEFAULTS["confidence"] == cfg.confidence
        assert EB_SAMPLER_DEFAULTS["max_steps"] == cfg.max_steps
        assert EB_SAMPLER_DEFAULTS["adaptive_stopping"] == cfg.adaptive_stopping


# ---------------------------------------------------------------------------
# DiffusionGenerationConfig tests
# ---------------------------------------------------------------------------


class TestDiffusionGenerationConfig:
    def test_defaults(self):
        cfg = DiffusionGenerationConfig()
        assert cfg.max_new_tokens == 1024
        assert cfg.canvas_len == DEFAULT_CANVAS_LEN
        assert isinstance(cfg.sampler, DiffusionSamplerConfig)
        assert cfg.thinking is False
        assert cfg.system_prompt == ""

    def test_custom(self):
        sampler = DiffusionSamplerConfig(max_steps=32)
        cfg = DiffusionGenerationConfig(
            max_new_tokens=2048,
            sampler=sampler,
            thinking=True,
            system_prompt="Be helpful.",
        )
        assert cfg.max_new_tokens == 2048
        assert cfg.sampler.max_steps == 32
        assert cfg.thinking is True
        assert cfg.system_prompt == "Be helpful."


# ---------------------------------------------------------------------------
# Prompt formatting tests
# ---------------------------------------------------------------------------


class TestPromptFormatting:
    def test_format_basic(self):
        client = make_llamacpp_client()
        cfg = DiffusionGenerationConfig()
        result = client._format_prompt("Hello", cfg)
        assert result == "Hello"

    def test_format_with_system(self):
        client = make_llamacpp_client()
        cfg = DiffusionGenerationConfig(system_prompt="You are a bot.")
        r = client._format_prompt("Hi", cfg)
        assert "You are a bot." in r
        assert "Hi" in r

    def test_format_with_thinking(self):
        client = make_llamacpp_client()
        cfg = DiffusionGenerationConfig(thinking=True)
        r = client._format_prompt("Hello", cfg)
        assert "<|think|>" in r

    def test_format_with_system_and_thinking(self):
        client = make_llamacpp_client()
        cfg = DiffusionGenerationConfig(system_prompt="Sys.", thinking=True)
        r = client._format_prompt("Hello", cfg)
        assert "Sys." in r and "<|think|>" in r and "Hello" in r


# ---------------------------------------------------------------------------
# Thinking-mode stripping
# ---------------------------------------------------------------------------


class TestStripThinking:
    def test_no_thinking(self):
        assert DiffusionGemmaClient._strip_thinking("Hello world") == "Hello world"

    def test_basic_thinking_block(self):
        text = "<|channel>thought reasoning...<channel|> Answer"
        r = DiffusionGemmaClient._strip_thinking(text)
        assert "Answer" in r
        assert "thought" not in r

    def test_think_token(self):
        r = DiffusionGemmaClient._strip_thinking("<|think|>thinking<|think|> Final")
        assert "Final" in r and "<|think|>" not in r

    def test_multiline_thinking(self):
        text = "<|channel>thought\na\nb\n<channel|>\nOut"
        r = DiffusionGemmaClient._strip_thinking(text)
        assert "Out" in r and "a\nb" not in r

    def test_normal_text_unchanged(self):
        text = "Regular text with <b>tags</b>"
        assert DiffusionGemmaClient._strip_thinking(text) == text


# ---------------------------------------------------------------------------
# Default model resolution
# ---------------------------------------------------------------------------


class TestDefaultModel:
    def test_llamacpp_returns_gguf(self):
        assert ".gguf" in _default_model("llamacpp").lower()

    def test_vllm_returns_hf_id(self):
        assert "google/diffusion-gemma" in _default_model("vllm")

    def test_unsloth_returns_hf_id(self):
        assert "google/diffusion-gemma" in _default_model("unsloth")


# ---------------------------------------------------------------------------
# Binary detection
# ---------------------------------------------------------------------------


class TestFindLlamaCppBinary:
    def test_empty_when_not_found(self, monkeypatch):
        monkeypatch.setenv("PATH", "/nonexistent")
        assert _find_llamacpp_binary() == ""

    def test_finds_binary(self, tmp_path, monkeypatch):
        binary = tmp_path / "llama-diffusion-cli"
        binary.write_text("")
        binary.chmod(0o755)
        monkeypatch.setenv("PATH", str(tmp_path))
        assert _find_llamacpp_binary() == str(binary)


# ---------------------------------------------------------------------------
# Factory function
# ---------------------------------------------------------------------------


class TestMakeDiffusionClient:
    def test_creates_llamacpp_client(self):
        client = make_diffusion_client(
            backend="llamacpp",
            model="/fake.gguf",
            llamacpp_binary="/fake/llama-diffusion-cli",
        )
        assert isinstance(client, DiffusionGemmaClient)
        assert client.backend == "llamacpp"

    def test_vllm_requires_base_url(self):
        with pytest.raises(RuntimeError, match="base URL"):
            DiffusionGemmaClient(backend="vllm", model="test")

    def test_vllm_accepts_env(self, monkeypatch):
        monkeypatch.setenv("DIFFUSION_VLLM_BASE_URL", "http://localhost:8000/v1")
        client = DiffusionGemmaClient(backend="vllm", model="test")
        assert client.backend == "vllm"

    def test_llamacpp_requires_binary(self, monkeypatch):
        monkeypatch.setenv("PATH", "/nonexistent")
        with pytest.raises(RuntimeError, match="llama-diffusion-cli"):
            DiffusionGemmaClient(backend="llamacpp", model="test")


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------


class TestConstants:
    def test_canvas_len(self):
        assert DEFAULT_CANVAS_LEN == 256

    def test_max_denoising_steps(self):
        assert DEFAULT_MAX_DENOISING_STEPS == 48

    def test_model_id(self):
        assert DIFFUSION_MODEL_ID == "google/diffusion-gemma-26b-it"

    def test_gguf_repo(self):
        assert "diffusiongemma" in DIFFUSION_MODEL_GGUF_REPO
