"""Minimal OpenAI-compatible chat client for ``transpile-llm --endpoint``.

Talks to any server that exposes ``POST {base}/chat/completions`` (Ollama,
LM Studio, llama.cpp ``llama-server``, vLLM) using only the standard library. It
mirrors the one call ``transpile.transpile_one`` makes on the OpenRouter SDK,
``client.chat.send(model=..., messages=..., temperature=..., max_tokens=...)``,
so the rest of the driver is unchanged.
"""

from __future__ import annotations

import json
import urllib.error
import urllib.request
from types import SimpleNamespace


class _Chat:
    def __init__(self, base_url: str, api_key: str, timeout: float) -> None:
        self._url = base_url.rstrip("/") + "/chat/completions"
        self._api_key = api_key
        self._timeout = timeout

    def send(self, *, model, messages, temperature=0.0, max_tokens=None, **_ignored):
        payload = {"model": model, "messages": messages, "temperature": temperature}
        if max_tokens:
            payload["max_tokens"] = max_tokens
        request = urllib.request.Request(
            self._url,
            data=json.dumps(payload).encode("utf-8"),
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {self._api_key}",
            },
            method="POST",
        )
        try:
            with urllib.request.urlopen(request, timeout=self._timeout) as resp:
                body = json.load(resp)
        except urllib.error.HTTPError as e:
            detail = e.read().decode("utf-8", "replace")[:300]
            raise RuntimeError(f"HTTP {e.code} from {self._url}: {detail}") from e
        except urllib.error.URLError as e:
            raise RuntimeError(f"cannot reach {self._url}: {e.reason}") from e
        try:
            content = body["choices"][0]["message"]["content"]
        except (KeyError, IndexError, TypeError) as e:
            raise RuntimeError(f"unexpected response from {self._url}: {str(body)[:300]}") from e
        message = SimpleNamespace(content=content or "")
        return SimpleNamespace(choices=[SimpleNamespace(message=message)])


class OpenAICompatClient:
    """Context-manager client with a ``.chat.send`` method, like ``OpenRouter``."""

    def __init__(self, base_url: str, api_key: str = "local", timeout: float = 600) -> None:
        self.chat = _Chat(base_url, api_key, timeout)

    def __enter__(self) -> OpenAICompatClient:
        return self

    def __exit__(self, *_exc) -> None:
        return None
