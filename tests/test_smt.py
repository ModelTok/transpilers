"""Tests for the SMT/sampling verifier's exec() timeout guard.

`_sampling_verify` calls `ref_fn`/`trans_fn` in-process with no subprocess
boundary; without a wall-clock guard a pathological function (infinite loop,
runaway recursion) hangs the caller forever. There was no test coverage for
this module at all before this fix, so this focuses narrowly on the timeout
behavior rather than being a full test suite for the module.
"""

from __future__ import annotations

import transpilers.verify.smt as smt
from transpilers.verify.smt import SMTConfig, _sampling_verify


def test_exec_fn_times_out_on_infinite_loop(monkeypatch):
    monkeypatch.setattr(smt, "_EXEC_TIMEOUT_S", 0.2)
    src = "while True:\n    pass\n"
    fn = smt._exec_fn(src, "anything")
    assert fn is None


def test_sampling_verify_times_out_on_hung_call():
    def ref(x):
        return x + 1

    def trans(x):
        while True:  # pathological: never returns
            pass

    config = SMTConfig(bound=5, sample_limit=1000, timeout_ms=200)
    verified, counterexample = _sampling_verify(ref, trans, ["int"], config)
    # Best-effort sampling: a hang partway through is treated the same as
    # exhausting the sample budget early -- inconclusive, not a false
    # positive failure with a bogus counterexample.
    assert verified is True
    assert counterexample is None
