"""Offline tests for the RunPod fine-tuning orchestrator (issue #98).

#98's live smoke test needs a real ``RUNPOD_API_KEY`` and creates a billable pod,
so it cannot run in CI. These tests cover the same logic with the
runpod/paramiko/scp transport faked, which makes the *safety* properties
verifiable for free — above all the teardown guarantee: a run that fails must
still terminate the pod, or it silently keeps billing.

    uv run pytest tests/test_runpod_train.py -q
"""

from __future__ import annotations

import sys
import types
from pathlib import Path

import pytest

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / "tools" / "cloud"))

import runpod_train  # noqa: E402

PAYLOAD = 200_000  # a "real" adapter.tgz; must clear main()'s 100_000-byte floor


class FakeRunpod(types.ModuleType):
    """Stand-in for the runpod SDK, recording every pod lifecycle call."""

    def __init__(self) -> None:
        super().__init__("runpod")
        self.api_key = None
        self.created: list[dict] = []
        self.terminated: list[str] = []

    def create_pod(self, **spec):
        self.created.append(spec)
        return {"id": "pod-123"}

    def terminate_pod(self, pod_id: str) -> None:
        self.terminated.append(pod_id)


class FakeSCPClient:
    """Writes a plausible payload so main()'s remote/local size check passes."""

    def __init__(self, *args, **kwargs) -> None:
        pass

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        return False

    def get(self, remote: str, local: str) -> None:
        Path(local).write_bytes(b"x" * PAYLOAD)


class FakeSSH:
    def get_transport(self):
        return object()

    def close(self) -> None:
        pass


@pytest.fixture
def fake_runpod(monkeypatch, tmp_path):
    """Install fake runpod/paramiko/scp modules, stub the transport helpers, and
    redirect ``HERE`` to ``tmp_path`` so downloads never litter the real bundle."""
    rp = FakeRunpod()
    monkeypatch.setattr(runpod_train, "HERE", str(tmp_path))
    monkeypatch.setitem(sys.modules, "runpod", rp)
    monkeypatch.setitem(sys.modules, "paramiko", types.ModuleType("paramiko"))
    scp = types.ModuleType("scp")
    scp.SCPClient = FakeSCPClient
    monkeypatch.setitem(sys.modules, "scp", scp)

    monkeypatch.setattr(runpod_train, "wait_for_ssh", lambda *a, **k: ("host", 2222))
    monkeypatch.setattr(runpod_train, "ssh_connect", lambda *a, **k: FakeSSH())
    monkeypatch.setattr(runpod_train, "upload_bundle", lambda *a, **k: None)
    monkeypatch.setattr(runpod_train, "stream_exec", lambda *a, **k: 0)
    monkeypatch.setattr(runpod_train, "remote_size", lambda *a, **k: PAYLOAD)
    return rp


@pytest.fixture
def ssh_key(tmp_path):
    key = tmp_path / "id_ed25519"
    key.write_text("private")
    return str(key)


# --------------------------------------------------------------------------- #
# pure helpers                                                               #
# --------------------------------------------------------------------------- #
def test_model_tag_strips_the_org_and_lowercases():
    assert runpod_train.model_tag("Qwen/Qwen2.5-Coder-7B-Instruct") == "qwen2.5-coder-7b-instruct"


def test_model_tag_passes_through_a_bare_name():
    assert runpod_train.model_tag("gpt2") == "gpt2"


def test_gpu_map_covers_the_documented_friendly_names():
    assert set(runpod_train.GPU_MAP) == {"4090", "a40", "a6000", "a100", "l40s"}
    assert runpod_train.GPU_MAP["a40"] == "NVIDIA A40"


def test_bundle_items_exclude_the_local_out_dir():
    assert "out" not in runpod_train.BUNDLE_ITEMS
    assert "train.py" in runpod_train.BUNDLE_ITEMS


def test_parse_args_defaults():
    args = runpod_train.parse_args([])

    assert args.model == "Qwen/Qwen2.5-Coder-1.5B-Instruct"
    assert args.gpu == "4090"
    assert args.cloud == "secure"
    assert args.disk == 50
    assert args.image == runpod_train.DEFAULT_IMAGE
    assert args.dry_run is False and args.keep_alive is False


def test_gpu_and_gpu_id_are_mutually_exclusive():
    with pytest.raises(SystemExit):
        runpod_train.parse_args(["--gpu", "4090", "--gpu-id", "NVIDIA A40"])


def test_unknown_gpu_choice_is_rejected():
    with pytest.raises(SystemExit):
        runpod_train.parse_args(["--gpu", "h100"])


def test_build_env_always_sets_model_and_omits_unset_knobs():
    env = runpod_train.build_env(runpod_train.parse_args(["--model", "Qwen/Qwen2.5-Coder-0.5B-Instruct"]))

    assert env == {"MODEL": "Qwen/Qwen2.5-Coder-0.5B-Instruct"}
    # Unset knobs must stay absent so train.py's own defaults apply.
    assert "EPOCHS" not in env and "ACQ_N" not in env


def test_build_env_forwards_only_the_knobs_that_were_set():
    args = runpod_train.parse_args(["--epochs", "1", "--tr-up", "1", "--acq-n", "20"])

    env = runpod_train.build_env(args)

    assert env["EPOCHS"] == "1.0"
    assert env["TR_UP"] == "1"
    assert env["ACQ_N"] == "20"
    assert "MAX_LEN" not in env


def test_flash_is_forwarded_only_when_enabled():
    assert "FLASH" not in runpod_train.build_env(runpod_train.parse_args([]))
    assert runpod_train.build_env(runpod_train.parse_args(["--flash"]))["FLASH"] == "1"


def test_env_prefix_quotes_values_and_keeps_model_first():
    prefix = runpod_train.env_prefix({"MODEL": "Qwen/Qwen2.5-Coder-1.5B-Instruct", "EPOCHS": "1.0"})

    assert prefix == "MODEL='Qwen/Qwen2.5-Coder-1.5B-Instruct' EPOCHS='1.0'"


def test_shq_escapes_an_embedded_single_quote():
    assert runpod_train._shq("it's") == "'it'\\''s'"


# --------------------------------------------------------------------------- #
# guards that must not create a pod                                          #
# --------------------------------------------------------------------------- #
def test_missing_api_key_exits_2_without_creating_a_pod(monkeypatch, fake_runpod):
    monkeypatch.delenv("RUNPOD_API_KEY", raising=False)

    assert runpod_train.main([]) == 2
    assert fake_runpod.created == []
    assert fake_runpod.terminated == []


def test_dry_run_creates_no_pod(monkeypatch, fake_runpod):
    monkeypatch.setenv("RUNPOD_API_KEY", "k")

    assert runpod_train.main(["--dry-run"]) == 0
    assert fake_runpod.created == []
    assert fake_runpod.api_key == "k"


def test_missing_ssh_key_exits_2_without_creating_a_pod(monkeypatch, fake_runpod, tmp_path):
    monkeypatch.setenv("RUNPOD_API_KEY", "k")

    assert runpod_train.main(["--ssh-key", str(tmp_path / "absent")]) == 2
    assert fake_runpod.created == []


# --------------------------------------------------------------------------- #
# the teardown guarantee — a failed run must never keep billing              #
# --------------------------------------------------------------------------- #
def test_failed_training_still_terminates_the_pod(monkeypatch, fake_runpod, ssh_key):
    monkeypatch.setenv("RUNPOD_API_KEY", "k")
    monkeypatch.setattr(runpod_train, "stream_exec", lambda *a, **k: 1)

    assert runpod_train.main(["--ssh-key", ssh_key]) == 1
    assert fake_runpod.created and fake_runpod.terminated == ["pod-123"]


def test_exit_zero_with_a_tiny_adapter_still_terminates_the_pod(monkeypatch, fake_runpod, ssh_key):
    """Exit 0 is not proof: a broken run.sh can exit 0 with an empty tar."""
    monkeypatch.setenv("RUNPOD_API_KEY", "k")
    monkeypatch.setattr(runpod_train, "remote_size", lambda *a, **k: 999)

    assert runpod_train.main(["--ssh-key", ssh_key]) == 1
    assert fake_runpod.terminated == ["pod-123"]


def test_keyboard_interrupt_terminates_the_pod_and_returns_130(monkeypatch, fake_runpod, ssh_key):
    monkeypatch.setenv("RUNPOD_API_KEY", "k")

    def interrupt(*a, **k):
        raise KeyboardInterrupt

    monkeypatch.setattr(runpod_train, "stream_exec", interrupt)

    assert runpod_train.main(["--ssh-key", ssh_key]) == 130
    assert fake_runpod.terminated == ["pod-123"]


def test_keep_alive_leaves_the_pod_running(monkeypatch, fake_runpod, ssh_key):
    monkeypatch.setenv("RUNPOD_API_KEY", "k")

    assert runpod_train.main(["--ssh-key", ssh_key, "--keep-alive"]) == 0
    assert fake_runpod.created
    assert fake_runpod.terminated == []


def test_happy_path_downloads_the_adapter_and_terminates(monkeypatch, fake_runpod, ssh_key):
    monkeypatch.setenv("RUNPOD_API_KEY", "k")

    assert runpod_train.main(["--model", "Qwen/Qwen2.5-Coder-0.5B-Instruct", "--ssh-key", ssh_key]) == 0

    tgz = sorted(Path(runpod_train.HERE, "out").glob("qwen2.5-coder-0.5b-instruct-*/adapter.tgz"))[-1]
    assert tgz.stat().st_size == PAYLOAD
    assert fake_runpod.terminated == ["pod-123"]


def test_the_pod_spec_carries_the_resolved_gpu_id_and_ssh_port(monkeypatch, fake_runpod, ssh_key):
    monkeypatch.setenv("RUNPOD_API_KEY", "k")

    runpod_train.main(["--gpu", "a40", "--ssh-key", ssh_key])

    spec = fake_runpod.created[0]
    assert spec["gpu_type_id"] == "NVIDIA A40"
    assert spec["ports"] == "22/tcp" and spec["start_ssh"] is True
    assert spec["cloud_type"] == "SECURE" and spec["gpu_count"] == 1


def test_gpu_id_overrides_the_friendly_gpu(monkeypatch, fake_runpod, ssh_key):
    monkeypatch.setenv("RUNPOD_API_KEY", "k")

    runpod_train.main(["--gpu-id", "NVIDIA L40S", "--ssh-key", ssh_key])

    assert fake_runpod.created[0]["gpu_type_id"] == "NVIDIA L40S"
