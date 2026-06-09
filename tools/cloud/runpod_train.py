#!/usr/bin/env python3
"""Local CLI that automates a full RunPod fine-tuning run for the C++/Python->Mojo
LoRA bundle in this directory.

It drives the *existing* ``train.py`` / ``run.sh`` unchanged: it only adds
provisioning + transport + lifecycle on top. One command does:

    provision a pod (by GPU type) -> push this bundle -> run training (live logs)
    -> download adapter.tgz -> auto-terminate the pod (guaranteed, even on Ctrl-C).

Usage:
    export RUNPOD_API_KEY=...                 # required (clear error if missing)
    pip install -r orchestrator-requirements.txt
    python runpod_train.py --model Qwen/Qwen2.5-Coder-7B-Instruct --gpu a40 --epochs 1 --extract

Free preview (no pod created):
    python runpod_train.py --gpu 4090 --dry-run

Cheapest real end-to-end smoke:
    python runpod_train.py --model Qwen/Qwen2.5-Coder-0.5B-Instruct --gpu 4090 \
        --epochs 1 --tr-up 1 --acq-n 20
"""
from __future__ import annotations

import argparse
import os
import sys
import time
from datetime import datetime, timezone

# Streamed pod logs are UTF-8 (tqdm bars use block chars); Windows' default cp1252
# console can't ENCODE them and print() would crash. Force UTF-8, drop the unencodable.
for _stream in (sys.stdout, sys.stderr):
    try:
        _stream.reconfigure(encoding="utf-8", errors="replace")
    except (AttributeError, ValueError):
        pass

HERE = os.path.dirname(os.path.abspath(__file__))

# Friendly GPU name -> RunPod gpu_type_id. IDs drift; use --gpu-id to override.
GPU_MAP = {
    "4090": "NVIDIA GeForce RTX 4090",
    "a40": "NVIDIA A40",
    "a6000": "NVIDIA RTX A6000",
    "a100": "NVIDIA A100 80GB PCIe",
    "l40s": "NVIDIA L40S",
}
# torch 2.8 (has float8_e8m0fnu) so current transformers/trl/peft import cleanly;
# the old 2.4.0 image was too old for train.py's modern TRL API. Tags drift -> --image.
DEFAULT_IMAGE = "runpod/pytorch:1.0.3-cu1281-torch280-ubuntu2204"
# Files/dirs from this bundle to push to the pod (keeps out/ and orchestrator junk off it).
BUNDLE_ITEMS = ["train.py", "run.sh", "requirements.txt", "data"]
# Training knobs forwarded to run.sh as env vars (only when the user sets them).
ENV_FORWARD = {
    "epochs": "EPOCHS", "tr_up": "TR_UP", "acq_n": "ACQ_N",
    "max_len": "MAX_LEN", "bs": "BS", "ga": "GA", "flash": "FLASH",
}


def parse_args(argv=None):
    p = argparse.ArgumentParser(
        description="Automate a RunPod fine-tuning run for the C++/Python->Mojo LoRA bundle.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    p.add_argument("--model", default="Qwen/Qwen2.5-Coder-1.5B-Instruct",
                   help="HF base model id (forwarded to train.py as MODEL).")
    g = p.add_mutually_exclusive_group()
    g.add_argument("--gpu", choices=sorted(GPU_MAP), default="4090",
                   help="Friendly GPU type, mapped to a RunPod gpu_type_id.")
    g.add_argument("--gpu-id", help="Raw RunPod gpu_type_id (bypasses --gpu; IDs drift over time).")
    # Training knobs (forwarded as env to run.sh; left unset => train.py defaults apply).
    p.add_argument("--epochs", type=float, help="num_train_epochs (default in train.py: 2).")
    p.add_argument("--tr-up", type=int, help="translation upsample factor (default 4).")
    p.add_argument("--acq-n", type=int, help="acquisition examples to mix in (default 300).")
    p.add_argument("--max-len", type=int, help="max sequence length (default 8192).")
    p.add_argument("--bs", type=int, help="per-device batch size (default 2).")
    p.add_argument("--ga", type=int, help="gradient accumulation steps (default 4).")
    p.add_argument("--flash", action="store_true", help="enable flash-attention-2 (Ampere+).")
    # Pod / lifecycle
    p.add_argument("--cloud", choices=["secure", "community"], default="secure",
                   help="RunPod cloud tier.")
    p.add_argument("--disk", type=int, default=50, help="container disk size (GB).")
    p.add_argument("--image", default=DEFAULT_IMAGE, help="pod container image (override if tag drifts).")
    p.add_argument("--ssh-key", default=os.path.expanduser("~/.ssh/id_ed25519"),
                   help="private SSH key; its public key must be registered in RunPod settings.")
    p.add_argument("--keep-alive", action="store_true",
                   help="do NOT terminate the pod afterwards (you must terminate it manually).")
    p.add_argument("--extract", action="store_true",
                   help="untar the downloaded adapter into data/sft/cpp_mojo/adapter_<tag>.")
    p.add_argument("--timeout", type=int, default=600,
                   help="seconds to wait for the pod to become SSH-ready.")
    p.add_argument("--provision-attempts", type=int, default=3,
                   help="re-provision a fresh pod this many times if SSH never comes up.")
    p.add_argument("--dry-run", action="store_true",
                   help="validate key + resolve GPU id + print the pod spec; create no pod (free).")
    return p.parse_args(argv)


def model_tag(model: str) -> str:
    """Qwen/Qwen2.5-Coder-7B-Instruct -> qwen2.5-coder-7b-instruct"""
    return model.split("/")[-1].lower()


def build_env(args) -> dict[str, str]:
    env = {"MODEL": args.model}
    for attr, var in ENV_FORWARD.items():
        val = getattr(args, attr)
        if attr == "flash":
            if val:
                env[var] = "1"
        elif val is not None:
            env[var] = str(val)
    return env


def env_prefix(env: dict[str, str]) -> str:
    # safe: values are model ids / numbers, but quote defensively
    return " ".join(f"{k}={_shq(v)}" for k, v in env.items())


def _shq(s: str) -> str:
    return "'" + s.replace("'", "'\\''") + "'"


def main(argv=None) -> int:
    args = parse_args(argv)

    api_key = os.environ.get("RUNPOD_API_KEY")
    if not api_key:
        print("ERROR: RUNPOD_API_KEY is not set in the environment.", file=sys.stderr)
        return 2

    gpu_type_id = args.gpu_id or GPU_MAP[args.gpu]
    cloud_type = args.cloud.upper()
    env = build_env(args)
    tag = model_tag(args.model)
    ts = datetime.now(timezone.utc).strftime("%Y%m%d-%H%M%S")
    pod_name = f"transpilers-{tag}-{ts}"

    spec = {
        "name": pod_name,
        "image_name": args.image,
        "gpu_type_id": gpu_type_id,
        "gpu_count": 1,
        "container_disk_in_gb": args.disk,
        "cloud_type": cloud_type,
        "ports": "22/tcp",
        "support_public_ip": True,
        "start_ssh": True,
    }

    print("=== RunPod training run ===")
    print(f"  model     : {args.model}")
    print(f"  gpu       : {args.gpu_id or args.gpu}  -> {gpu_type_id}")
    print(f"  cloud     : {cloud_type}   disk: {args.disk}GB   image: {args.image}")
    print(f"  train env : {env_prefix(env) or '(train.py defaults)'}")
    print(f"  teardown  : {'KEPT ALIVE (manual terminate!)' if args.keep_alive else 'auto-terminate (finally)'}")

    if args.dry_run:
        import runpod  # validate the import path even on dry-run
        runpod.api_key = api_key
        print("\n[dry-run] API key present; pod spec resolved below. No pod created (free).")
        for k, v in spec.items():
            print(f"    {k} = {v}")
        return 0

    # Real run: lazy imports so --dry-run / --help work without the deps installed.
    import runpod
    import paramiko
    from scp import SCPClient

    runpod.api_key = api_key

    key_path = os.path.expanduser(args.ssh_key)
    if not os.path.isfile(key_path):
        print(f"ERROR: SSH key not found: {key_path}\n"
              f"       Generate one (ssh-keygen -t ed25519) and register the .pub in RunPod settings.",
              file=sys.stderr)
        return 2

    pod_id = None
    ssh = None
    try:
        # Provisioning can hit a flaky pod that never exposes SSH. Re-provision a
        # fresh one (terminating the unready pod first) instead of failing the run.
        for attempt in range(1, args.provision_attempts + 1):
            print(f"\n>>> creating pod (attempt {attempt}/{args.provision_attempts}) ...")
            pod_id = runpod.create_pod(**spec)["id"]
            print(f"    pod id: {pod_id}")
            try:
                host, port = wait_for_ssh(runpod, pod_id, args.timeout)
                print(f"    SSH ready at {host}:{port}")
                ssh = ssh_connect(paramiko, host, port, key_path)
                break
            except (TimeoutError, ConnectionError) as e:
                print(f"    provisioning failed: {e}", file=sys.stderr)
                try:
                    runpod.terminate_pod(pod_id)
                    print(f"    terminated unready pod {pod_id}")
                except Exception:  # noqa: BLE001
                    pass
                pod_id = None
                if attempt == args.provision_attempts:
                    print(f"ERROR: no SSH-ready pod after {args.provision_attempts} attempts.",
                          file=sys.stderr)
                    return 1
        try:
            print(">>> uploading bundle -> /workspace/cloud ...")
            upload_bundle(ssh, SCPClient)

            # Normalize CRLF -> LF on the pod: files checked out on Windows carry \r,
            # which breaks bash (set -e\r) and turns every path into 'name\r' on Linux.
            normalize = r"sed -i 's/\r$//' run.sh requirements.txt train.py"
            cmd = f"cd /workspace/cloud && {normalize} && {env_prefix(env)} bash run.sh"
            print(f">>> running: {cmd}\n" + "-" * 60)
            exit_status = stream_exec(ssh, cmd)
            print("-" * 60 + f"\n>>> training exit status: {exit_status}")
            if exit_status != 0:
                print("ERROR: training failed on the pod (see logs above).", file=sys.stderr)
                return 1

            # Don't trust exit 0 alone: confirm the adapter archive actually exists and is
            # non-trivial on the pod (a broken run.sh can still exit 0 with an empty tar).
            remote_tgz = "/workspace/cloud/adapter.tgz"
            size = remote_size(ssh, remote_tgz)
            if size < 100_000:  # a real 0.5B LoRA adapter is many MB
                print(f"ERROR: {remote_tgz} missing or too small ({size} bytes) - training "
                      f"did not produce a valid adapter (see logs above).", file=sys.stderr)
                return 1

            out_dir = os.path.join(HERE, "out", f"{tag}-{ts}")
            os.makedirs(out_dir, exist_ok=True)
            local_tgz = os.path.join(out_dir, "adapter.tgz")
            print(f">>> downloading adapter.tgz ({size/1e6:.1f} MB) -> {local_tgz} ...")
            with SCPClient(ssh.get_transport()) as scp:
                scp.get(remote_tgz, local_tgz)
            local = os.path.getsize(local_tgz)
            if local != size:
                print(f"ERROR: download size mismatch (remote {size} != local {local}).", file=sys.stderr)
                return 1
            print(f"    saved: {local_tgz} ({local/1e6:.1f} MB)")

            if args.extract:
                dest = extract_adapter(local_tgz, tag)
                print(f">>> extracted adapter -> {dest}")
        finally:
            ssh.close()
        return 0

    except KeyboardInterrupt:
        print("\n!!! interrupted - tearing down the pod so it stops billing ...", file=sys.stderr)
        return 130
    finally:
        if pod_id and not args.keep_alive:
            try:
                runpod.terminate_pod(pod_id)
                print(f">>> pod {pod_id} terminated (no further billing).")
            except Exception as e:  # noqa: BLE001 - teardown must never raise
                print(f"WARNING: failed to terminate pod {pod_id}: {e}\n"
                      f"         Terminate it manually in the RunPod console to avoid charges!",
                      file=sys.stderr)
        elif pod_id and args.keep_alive:
            print(f">>> pod {pod_id} left RUNNING (--keep-alive). Terminate it manually when done.")


def wait_for_ssh(runpod, pod_id, timeout):
    """Poll until the pod is RUNNING and its public SSH mapping for private port 22 appears."""
    deadline = time.time() + timeout
    last = None
    while time.time() < deadline:
        info = runpod.get_pod(pod_id)
        status = (info or {}).get("desiredStatus")
        runtime = (info or {}).get("runtime") or {}
        ports = runtime.get("ports") or []
        for pm in ports:
            if pm.get("privatePort") == 22 and pm.get("isIpPublic") and pm.get("ip") and pm.get("publicPort"):
                return pm["ip"], int(pm["publicPort"])
        msg = f"    waiting for SSH ... status={status} ports={len(ports)}"
        if msg != last:
            print(msg)
            last = msg
        time.sleep(5)
    raise TimeoutError(f"pod {pod_id} did not expose SSH within {timeout}s")


def ssh_connect(paramiko, host, port, key_path, attempts=12):
    """Connect with retries - sshd inside the pod lags the port mapping."""
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    pkey = _load_key(paramiko, key_path)
    last = None
    for _ in range(attempts):
        try:
            client.connect(hostname=host, port=port, username="root", pkey=pkey,
                           timeout=15, banner_timeout=15, auth_timeout=15)
            return client
        except Exception as e:  # noqa: BLE001
            last = e
            time.sleep(5)
    raise ConnectionError(f"could not SSH to {host}:{port}: {last}")


def _load_key(paramiko, key_path):
    for loader in (paramiko.Ed25519Key, paramiko.RSAKey, paramiko.ECDSAKey):
        try:
            return loader.from_private_key_file(key_path)
        except paramiko.SSHException:
            continue
    raise ValueError(f"unsupported/unreadable SSH key: {key_path}")


def upload_bundle(ssh, SCPClient):
    ssh.exec_command("mkdir -p /workspace/cloud")
    with SCPClient(ssh.get_transport()) as scp:
        for item in BUNDLE_ITEMS:
            local = os.path.join(HERE, item)
            if not os.path.exists(local):
                raise FileNotFoundError(f"bundle item missing: {local}")
            scp.put(local, recursive=os.path.isdir(local), remote_path="/workspace/cloud/")


def stream_exec(ssh, cmd):
    """Run cmd over SSH, streaming combined stdout/stderr live; return exit status."""
    chan = ssh.get_transport().open_session()
    chan.get_pty()
    chan.exec_command(cmd)
    buf = b""
    while True:
        if chan.recv_ready():
            buf += chan.recv(4096)
            *lines, buf = buf.split(b"\n")
            for ln in lines:
                print(ln.decode("utf-8", "replace"))
        elif chan.exit_status_ready() and not chan.recv_ready():
            break
        else:
            time.sleep(0.1)
    if buf:
        print(buf.decode("utf-8", "replace"))
    return chan.recv_exit_status()


def remote_size(ssh, path):
    """Bytes of a remote file, or -1 if it doesn't exist."""
    _in, out, _err = ssh.exec_command(f"stat -c %s {path} 2>/dev/null || echo -1")
    try:
        return int(out.read().decode().strip() or "-1")
    except ValueError:
        return -1


def extract_adapter(local_tgz, tag):
    import tarfile
    dest_root = os.path.join(HERE, "..", "..", "data", "sft", "cpp_mojo")
    dest_root = os.path.abspath(dest_root)
    with tarfile.open(local_tgz, "r:gz") as t:
        # filter='data' = the safe extraction mode (and the Python 3.14 default).
        t.extractall(dest_root, filter="data")  # contains a top-level 'adapter/' dir
    src = os.path.join(dest_root, "adapter")
    dest = os.path.join(dest_root, f"adapter_{tag}")
    if os.path.isdir(dest):
        dest = os.path.join(dest_root, f"adapter_{tag}_{int(time.time())}")
    os.replace(src, dest)
    return dest


if __name__ == "__main__":
    raise SystemExit(main())
