"""Retry classification + model/temperature failover schedule for the stateless
OpenRouter backend (issue #94). No network: the SDK is replaced with a scripted
fake and the backoff sleep is captured instead of slept.
"""

from __future__ import annotations

import importlib.util
import sys
import types
from pathlib import Path

import pytest

REPO = Path(__file__).resolve().parents[1]

_spec = importlib.util.spec_from_file_location(
    "stateless_transpile", REPO / "stateless transpilation" / "2_transpile.py"
)
T = importlib.util.module_from_spec(_spec)
sys.modules["stateless_transpile"] = T
_spec.loader.exec_module(T)

PRIMARY, CHEAP, STRONG = "primary/model", "fallback/cheap", "fallback/strong"


# --- transient classification --------------------------------------------


@pytest.mark.parametrize(
    "msg",
    [
        "EOF while parsing a string at line 1 column 4096",
        "Response validation failed: choices missing",
        "429 Too Many Requests",
        "504 Gateway Timeout",
        "provider temporarily overloaded",
    ],
)
def test_transient_errors_are_retried(msg):
    assert T._transient(RuntimeError(msg))


@pytest.mark.parametrize(
    "msg",
    [
        "401 Unauthorized: bad api key",
        "402 Payment Required: insufficient credits",
        "400 Bad Request: model not found",
    ],
)
def test_non_transient_errors_fail_fast(msg):
    assert not T._transient(RuntimeError(msg))


# --- attempt schedule --------------------------------------------------------


def test_plan_escalates_models_then_temperature_over_six_retries():
    plan = [T._attempt_plan(PRIMARY, [CHEAP, STRONG], a, 6) for a in range(6)]
    assert plan == [
        (PRIMARY, 0.0),
        (PRIMARY, 0.0),
        (CHEAP, 0.0),
        (CHEAP, T._RETRY_TEMPERATURE),
        (STRONG, T._RETRY_TEMPERATURE),
        (STRONG, T._RETRY_TEMPERATURE),
    ]


def test_plan_reaches_last_model_on_a_small_budget():
    models = [T._attempt_plan(PRIMARY, [CHEAP, STRONG], a, 4)[0] for a in range(4)]
    assert models == [PRIMARY, PRIMARY, CHEAP, STRONG]


def test_plan_without_chain_stays_on_primary():
    assert {T._attempt_plan(PRIMARY, [], a, 6)[0] for a in range(6)} == {PRIMARY}


def test_plan_dedupes_primary_already_in_chain():
    models = [T._attempt_plan(CHEAP, [CHEAP, STRONG], a, 4)[0] for a in range(4)]
    assert models == [CHEAP, CHEAP, STRONG, STRONG]


# --- call_openrouter against a scripted SDK -----------------------------------


class _Usage:
    cost = 0.01

    def model_dump(self):
        return {"cost": self.cost}


def _install_fake_sdk(monkeypatch, script):
    """Fake `openrouter.OpenRouter`; each send() pops the next script step —
    an exception to raise or a string to return. Records (model, temperature)."""
    calls, sleeps = [], []

    class _Chat:
        def send(self, *, model, messages, temperature):
            calls.append((model, temperature))
            step = script[len(calls) - 1]
            if isinstance(step, Exception):
                raise step
            msg = types.SimpleNamespace(content=step)
            return types.SimpleNamespace(
                choices=[types.SimpleNamespace(message=msg)], usage=_Usage()
            )

    class _Client:
        def __init__(self, api_key):
            self.chat = _Chat()

        def __enter__(self):
            return self

        def __exit__(self, *exc):
            return False

    monkeypatch.setitem(
        sys.modules, "openrouter", types.SimpleNamespace(OpenRouter=_Client)
    )
    monkeypatch.setattr("time.sleep", sleeps.append)
    monkeypatch.setenv("OPENROUTER_API_KEY", "test-key")
    return calls, sleeps


def test_fails_over_to_next_model_after_malformed_responses(monkeypatch):
    monkeypatch.setattr(T, "_RETRIES", 6)
    monkeypatch.setattr(T, "_FAILOVER", [CHEAP, STRONG])
    calls, sleeps = _install_fake_sdk(
        monkeypatch,
        [
            ValueError("EOF while parsing a string"),
            ValueError("Response validation failed"),
            "<<<FILE out/x.py>>>\nok\n<<<END>>>",
        ],
    )

    text, meta = T.call_openrouter("prompt", PRIMARY, 60, None)

    assert text.startswith("<<<FILE")
    assert [m for m, _ in calls] == [PRIMARY, PRIMARY, CHEAP]
    assert all(t == 0.0 for _, t in calls)
    assert meta["model_used"] == CHEAP
    assert meta["attempts"] == 3
    assert meta["cost_usd"] == 0.01
    assert sleeps == [1, 2]


def test_non_transient_error_raises_without_retry(monkeypatch):
    monkeypatch.setattr(T, "_RETRIES", 6)
    monkeypatch.setattr(T, "_FAILOVER", [CHEAP])
    calls, sleeps = _install_fake_sdk(monkeypatch, [RuntimeError("401 Unauthorized")])

    with pytest.raises(RuntimeError, match="401"):
        T.call_openrouter("prompt", PRIMARY, 60, None)

    assert len(calls) == 1
    assert sleeps == []


def test_exhausted_budget_reraises_last_transient_error(monkeypatch):
    monkeypatch.setattr(T, "_RETRIES", 2)
    monkeypatch.setattr(T, "_FAILOVER", [])
    calls, sleeps = _install_fake_sdk(
        monkeypatch,
        [
            ValueError("EOF while parsing"),
            ValueError("504 Gateway Timeout"),
        ],
    )

    with pytest.raises(ValueError, match="504"):
        T.call_openrouter("prompt", PRIMARY, 60, None)

    assert len(calls) == 2
    assert sleeps == [1]


def test_missing_api_key_fails_before_any_call(monkeypatch):
    calls, _ = _install_fake_sdk(monkeypatch, [])
    monkeypatch.delenv("OPENROUTER_API_KEY")

    with pytest.raises(RuntimeError, match="OPENROUTER_API_KEY"):
        T.call_openrouter("prompt", PRIMARY, 60, None)

    assert calls == []
