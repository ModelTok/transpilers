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


# --- single fenced block fallback (fine-tuned adapter answers with ```mojo ... ```) ---------


FENCED = "```mojo\ndef f(x: Float64) -> Float64:\n    return x\n```"


def test_extract_accepts_one_fenced_mojo_block_without_file_markers():
    assert t.extract_file_block(FENCED) == "def f(x: Float64) -> Float64:\n    return x"
    assert t.extract_file_block("Here you go:\n" + FENCED + "\nDone.") == (
        "def f(x: Float64) -> Float64:\n    return x"
    )


def test_extract_prefers_file_markers_over_a_fence():
    text = "<<<FILE out.mojo>>>\nfn a():\n    pass\n<<<END>>>\n" + FENCED
    assert t.extract_file_block(text) == "fn a():\n    pass"


def test_extract_refuses_to_guess_between_several_or_wrong_fences():
    assert t.extract_file_block(FENCED + "\n\n" + FENCED) is None
    assert t.extract_file_block("```python\nx = 1\n```") is None
    assert t.extract_file_block("```\nuntagged\n```") is None
    assert t.extract_file_block("```mojo\ndef f():\n    pass\n") is None  # never closed
    assert t.extract_file_block("no code here") is None


def test_main_end_to_end_accepts_a_fenced_reply(tmp_path, monkeypatch, server):
    base, seen, _ = server
    monkeypatch.delenv("OPENROUTER_API_KEY", raising=False)
    cfg = _config(tmp_path)
    # the fake server reads the module-level REPLY on every request
    monkeypatch.setattr(sys.modules[__name__], "REPLY", FENCED)
    monkeypatch.setattr(sys, "argv", ["transpile-llm", str(cfg), "--endpoint", base, "--model", "m"])
    assert t.main() == 0
    assert (tmp_path / "foo.mojo").read_text() == "def f(x: Float64) -> Float64:\n    return x"


def test_temperature_flag_reaches_the_model_call(tmp_path, monkeypatch, server):
    base, seen, _ = server
    monkeypatch.delenv("OPENROUTER_API_KEY", raising=False)
    cfg = _config(tmp_path)
    monkeypatch.setattr(sys, "argv", ["transpile-llm", str(cfg), "--endpoint", base, "--model", "m"])
    assert t.main() == 0
    assert seen[-1]["body"]["temperature"] == 0.0
    data = json.loads(cfg.read_text())
    data[0]["decision"] = "pending"
    cfg.write_text(json.dumps(data))
    monkeypatch.setattr(sys, "argv", ["transpile-llm", str(cfg), "--endpoint", base, "--model", "m",
                                      "--temperature", "0.8"])
    assert t.main() == 0
    assert seen[-1]["body"]["temperature"] == 0.8


# --- best-of-n against a verification command ----------------------------------------------------


def _cycling_server(replies):
    state = {"n": 0}
    seen = []

    class H(BaseHTTPRequestHandler):
        def do_POST(self):
            body = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
            seen.append(body)
            content = replies[state["n"] % len(replies)]
            state["n"] += 1
            payload = json.dumps({"choices": [{"message": {"content": content}}]}).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(payload)

        def log_message(self, *a):
            pass

    srv = HTTPServer(("127.0.0.1", 0), H)
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    return srv, seen


def _checker(tmp_path: Path, marker: str) -> str:
    script = tmp_path / "check.py"
    script.write_text(
        "import sys\n"
        f"sys.exit(0 if {marker!r} in open(sys.argv[1], encoding='utf-8').read() else 3)\n"
    )
    return f'"{sys.executable}" "{script}" "{{target}}"'


def _reply(body: str) -> str:
    return f"<<<FILE x>>>\n{body}\n<<<END>>>"


def test_best_of_n_stops_at_the_first_verified_draft(tmp_path, monkeypatch):
    srv, seen = _cycling_server([_reply("bad 1"), _reply("bad 2"), _reply("GOOD"), _reply("never asked")])
    cfg = _config(tmp_path)
    monkeypatch.delenv("OPENROUTER_API_KEY", raising=False)
    monkeypatch.setattr(sys, "argv", [
        "transpile-llm", str(cfg), "--endpoint", f"http://127.0.0.1:{srv.server_port}/v1", "--model", "m",
        "--samples", "5", "--temperature", "0.8", "--verify-cmd", _checker(tmp_path, "GOOD"),
    ])
    try:
        assert t.main() == 0
    finally:
        srv.shutdown()
    assert len(seen) == 3 and all(b["temperature"] == 0.8 for b in seen)
    assert (tmp_path / "foo.mojo").read_text().strip() == "GOOD"
    assert json.loads(cfg.read_text())[0]["decision"] == "done"


def test_best_of_n_reports_when_no_sample_verifies(tmp_path, monkeypatch, capsys):
    srv, seen = _cycling_server([_reply("bad")])
    cfg = _config(tmp_path)
    monkeypatch.delenv("OPENROUTER_API_KEY", raising=False)
    monkeypatch.setattr(sys, "argv", [
        "transpile-llm", str(cfg), "--endpoint", f"http://127.0.0.1:{srv.server_port}/v1", "--model", "m",
        "--samples", "3", "--temperature", "0.5", "--verify-cmd", _checker(tmp_path, "GOOD"),
    ])
    try:
        t.main()
    finally:
        srv.shutdown()
    assert len(seen) == 3
    assert "no verified draft in 3 samples" in capsys.readouterr().out
    assert json.loads(cfg.read_text())[0]["decision"] == "error"
    assert (tmp_path / "foo.mojo").read_text().strip() == "bad"  # the last draft stays for inspection


def test_samples_needs_a_verifier_and_a_temperature(tmp_path, monkeypatch, capsys):
    cfg = _config(tmp_path)
    for extra in (["--samples", "3", "--temperature", "0.8"], ["--samples", "3", "--verify-cmd", "true"]):
        monkeypatch.setattr(sys, "argv", ["transpile-llm", str(cfg), "--endpoint", "http://x/v1", "--model", "m", *extra])
        with pytest.raises(SystemExit):
            t.main()
    assert "--samples needs" in capsys.readouterr().err


def test_a_single_sample_ignores_the_verifier(tmp_path):
    srv, seen = _cycling_server([_reply("whatever")])
    entry = {"source": str(_config(tmp_path).parent / "foo.upstream.inc"), "target": str(tmp_path / "o.mojo")}
    try:
        with t.make_client(f"http://127.0.0.1:{srv.server_port}/v1", "k", 5) as client:
            r = t.transpile_verified(entry, 1, _checker(tmp_path, "NEVER"), 5, model="m", client=client,
                                     repair=False, max_retries=0)
    finally:
        srv.shutdown()
    assert r["status"] == "ok" and "attempts" not in r and len(seen) == 1
