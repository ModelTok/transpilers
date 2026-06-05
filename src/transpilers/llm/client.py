"""Cached, typed-hole LLM client.

Three rules this module enforces:
  1. LLMs operate on typed holes, never free-form text. Every call declares an
     expected response shape and a validator.
  2. Results are cached by hash(prompt + model + temperature) so transpilation
     is reproducible and bills don't recur on re-runs.
  3. Validators reject malformed output before it touches the IR.

The Anthropic call is intentionally lazy-imported so the module is usable in
test/CI without API keys; algorithmic-only slices of the pipeline must not
require LLM credentials.
"""

from __future__ import annotations

import hashlib
import json
import os
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Generic, TypeVar


T = TypeVar("T")

DEFAULT_MODEL = "claude-opus-4-7"
DEFAULT_CACHE_DIR = Path(__file__).parent / "cache"


@dataclass
class TypedHole(Generic[T]):
    """A request the LLM is allowed to fill.

    `kind` keys the prompt template; `context` is serialized into the prompt;
    `validate` rejects malformed output. The hole's type T is what the
    validated answer deserializes to.
    """

    kind: str
    context: dict
    validate: Callable[[str], T]


class LlmClient:
    def __init__(self, model: str | None = None, cache_dir: Path = DEFAULT_CACHE_DIR) -> None:
        # Model resolves from (explicit arg) > TRANSPILER_LLM_MODEL env > default.
        # For a self-hosted vLLM server this is the served name, e.g.
        # "Qwen2.5-Coder-3B-Instruct".
        self.model = model or os.environ.get("TRANSPILER_LLM_MODEL", DEFAULT_MODEL)
        self.cache_dir = cache_dir
        self.cache_dir.mkdir(parents=True, exist_ok=True)

    def fill(self, hole: TypedHole[T], *, temperature: float = 0.0) -> T:
        prompt = self._render(hole)
        cache_key = self._cache_key(prompt, temperature)
        cached = self._cache_get(cache_key)
        raw = cached if cached is not None else self._call(prompt, temperature)
        if cached is None:
            self._cache_put(cache_key, raw)
        return hole.validate(raw)

    def _render(self, hole: TypedHole) -> str:
        template_path = Path(__file__).parent / "prompts" / f"{hole.kind}.md"
        template = template_path.read_text() if template_path.exists() else "{context}"
        return template.replace("{context}", json.dumps(hole.context, indent=2))

    def _cache_key(self, prompt: str, temperature: float) -> str:
        h = hashlib.sha256()
        h.update(self.model.encode())
        h.update(str(temperature).encode())
        h.update(prompt.encode())
        return h.hexdigest()

    def _cache_get(self, key: str) -> str | None:
        f = self.cache_dir / f"{key}.txt"
        return f.read_text() if f.exists() else None

    def _cache_put(self, key: str, value: str) -> None:
        (self.cache_dir / f"{key}.txt").write_text(value)

    def _call(self, prompt: str, temperature: float) -> str:
        # Backend select: TRANSPILER_LLM_BACKEND=openai|anthropic, else inferred
        # (openai when OPENAI_BASE_URL is set, otherwise anthropic). This lets a
        # self-hosted model (e.g. Qwen2.5-Coder-3B via vLLM) serve the holes
        # instead of a hosted API, at on-prem cost.
        backend = os.environ.get("TRANSPILER_LLM_BACKEND", "").lower()
        if not backend:
            backend = "openai" if os.environ.get("OPENAI_BASE_URL") else "anthropic"
        if backend == "openai":
            return self._call_openai(prompt, temperature)
        return self._call_anthropic(prompt, temperature)

    def _call_openai(self, prompt: str, temperature: float) -> str:
        """OpenAI-compatible chat endpoint — works with a self-hosted vLLM
        server (`vllm serve <model>`), HF TGI, or the OpenAI API. Configure with
        OPENAI_BASE_URL (e.g. ``http://<host>:8000/v1``) and OPENAI_API_KEY
        (vLLM accepts any token — use ``EMPTY`` if the server is unsecured)."""
        base_url = os.environ.get("OPENAI_BASE_URL")
        if not base_url:
            raise RuntimeError(
                "OpenAI-compatible LLM backend selected but OPENAI_BASE_URL is not set "
                "(e.g. http://<host>:8000/v1 for a vLLM server)."
            )
        from openai import OpenAI

        client = OpenAI(base_url=base_url, api_key=os.environ.get("OPENAI_API_KEY", "EMPTY"))
        resp = client.chat.completions.create(
            model=self.model,
            max_tokens=1024,
            temperature=temperature,
            messages=[{"role": "user", "content": prompt}],
        )
        return resp.choices[0].message.content or ""

    def _call_anthropic(self, prompt: str, temperature: float) -> str:
        if not os.environ.get("ANTHROPIC_API_KEY"):
            raise RuntimeError(
                "LLM hole reached and ANTHROPIC_API_KEY not set. Either annotate the source "
                "to keep the pipeline algorithmic, set the key, or point at a self-hosted model "
                "via TRANSPILER_LLM_BACKEND=openai + OPENAI_BASE_URL."
            )
        from anthropic import Anthropic

        client = Anthropic()
        resp = client.messages.create(
            model=self.model,
            max_tokens=1024,
            temperature=temperature,
            messages=[{"role": "user", "content": prompt}],
        )
        return resp.content[0].text
