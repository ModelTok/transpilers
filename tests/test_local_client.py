"""`transpile-llm --endpoint`: OpenAI-compatible local server support, tested against
a throwaway stdlib HTTP server. No network, no OpenRouter key."""

from __future__ import annotations

import json
import sys
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

import pytest

from transpilers.cli import transpile as t
from transpilers.cli.local_client import OpenAICompatClient

REPLY = "<<<FILE out.mojo>>>\nfn x():\n    pass\n<<<END>>>"


@pytest.fixture
def server():
    seen: list[dict] = []
    mode = {"status": 200}

    class H(BaseHTTPRequestHandler):
        def do_POST(self):
            body = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
            seen.append({"path": self.path, "auth": self.headers.get("Authorization"), "body": body})
            if mode["status"] != 200:
                self.send_response(mode["status"])
                self.end_headers()
                self.wfile.write(b'{"error": "boom"}')
                return
            payload = json.dumps({"choices": [{"message": {"content": REPLY}}]}).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(payload)

        def log_message(self, *a):
            pass

    srv = HTTPServer(("127.0.0.1", 0), H)
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    yield f"http://127.0.0.1:{srv.server_port}/v1", seen, mode
    srv.shutdown()


def test_client_posts_chat_completions_and_returns_content(server):
    base, seen, _ = server
    with OpenAICompatClient(base, "k", timeout=5) as c:
        r = c.chat.send(model="m", messages=[{"role": "user", "content": "hi"}],
                        temperature=0.0, max_tokens=50)
    assert r.choices[0].message.content == REPLY
    assert seen[0]["path"] == "/v1/chat/completions"
    assert seen[0]["auth"] == "Bearer k"
    assert seen[0]["body"]["model"] == "m" and seen[0]["body"]["max_tokens"] == 50


def test_client_raises_a_readable_error_on_http_failure(server):
    base, _, mode = server
    mode["status"] = 500
    with OpenAICompatClient(base, timeout=5) as c, pytest.raises(RuntimeError, match="HTTP 500"):
        c.chat.send(model="m", messages=[], temperature=0.0)


def test_client_reports_an_unreachable_server():
    with OpenAICompatClient("http://127.0.0.1:1/v1", timeout=2) as c, \
            pytest.raises(RuntimeError, match="cannot reach"):
        c.chat.send(model="m", messages=[], temperature=0.0)


def test_make_client_selects_by_endpoint():
    assert isinstance(t.make_client("http://x/v1", "k", 5), OpenAICompatClient)
    assert not isinstance(t.make_client(None, "k", 5), OpenAICompatClient)


def _config(tmp_path: Path) -> Path:
    src = tmp_path / "foo.upstream.inc"
    src.write_text("Real64 CalcFoo(Real64 const x) { return x; }\n")
    cfg = tmp_path / "config.json"
    cfg.write_text(json.dumps([{"id": 1, "source": str(src), "target": str(tmp_path / "foo.mojo"),
                                "decision": "pending"}]))
    return cfg


def test_main_with_endpoint_needs_a_model_but_no_openrouter_key(tmp_path, monkeypatch, capsys):
    monkeypatch.delenv("OPENROUTER_API_KEY", raising=False)
    monkeypatch.setattr(sys, "argv", ["transpile-llm", str(_config(tmp_path)), "--endpoint", "http://x/v1"])
    assert t.main() == 1
    assert "--model is required" in capsys.readouterr().err


def test_main_without_endpoint_still_requires_the_openrouter_key(tmp_path, monkeypatch, capsys):
    monkeypatch.delenv("OPENROUTER_API_KEY", raising=False)
    monkeypatch.setattr(sys, "argv", ["transpile-llm", str(_config(tmp_path))])
    assert t.main() == 1
    assert "OPENROUTER_API_KEY not set" in capsys.readouterr().err


def test_main_end_to_end_against_a_local_server(tmp_path, monkeypatch, server):
    base, seen, _ = server
    monkeypatch.delenv("OPENROUTER_API_KEY", raising=False)
    cfg = _config(tmp_path)
    monkeypatch.setattr(sys, "argv", ["transpile-llm", str(cfg), "--endpoint", base,
                                      "--model", "local-model", "--domain-prompts"])
    assert t.main() == 0
    assert (tmp_path / "foo.mojo").read_text().strip() == "fn x():\n    pass"
    assert seen[0]["body"]["model"] == "local-model"
    assert "ENERGYPLUSMOJO KERNEL RULES" in seen[0]["body"]["messages"][0]["content"]
    assert json.loads(cfg.read_text())[0]["decision"] == "done"
