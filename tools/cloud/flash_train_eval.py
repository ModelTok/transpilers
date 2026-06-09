#!/usr/bin/env python3
"""RunPod Flash orchestration for the C++/Python->Mojo fine-tune + eval.

Replaces the SSH/scp pod dance (runpod_train.py) with Flash @Endpoint functions:
no Docker, no SSH, no teardown management. A persistent network volume
(`n1b3o5cf72`, 100GB, US-KS-2) holds the HF model cache, the Mojo toolchain, the
datasets, and the produced adapters/eval results — populated once, reused by
every run, shared across the two parallel model jobs.

Local deps:  uv add runpod-flash   (RUNPOD_API_KEY in env)

Modes:
  python flash_train_eval.py --probe        # cheap: validate volume+deps+mojo+timeout
  python flash_train_eval.py --populate      # one-time: stage datasets + install Mojo on the volume
  python flash_train_eval.py --run           # the two models, in parallel

STATUS: probe is runnable to de-risk. populate/train_eval are wired to the proven
train.py recipe + the heldout Mojo gate, but the long-job timeout, Mojo-on-volume
install, and Gemma-4 (multimodal) loading are UNVALIDATED until the probe passes.
"""
from __future__ import annotations
import argparse, asyncio, json, os
from pathlib import Path

from runpod_flash import Endpoint, GpuType, NetworkVolume

REPO = Path(__file__).resolve().parents[2]
VOLUME_ID = "n1b3o5cf72"          # transpilers-models, 100GB, US-KS-2
VOL = NetworkVolume(id=VOLUME_ID)  # mounts at /runpod-volume
MNT = "/runpod-volume"

# Model under test -> (HF id, friendly tag). Gemma-4 is multimodal; see notes in train_eval.
MODELS = {
    "qwen7b": "Qwen/Qwen2.5-Coder-7B-Instruct",
    "gemma12b": "google/gemma-4-12B-it",
}
TRAIN_DEPS = ["torch", "transformers", "peft", "trl", "datasets", "accelerate", "huggingface_hub"]


# --------------------------------------------------------------------------- probe
@Endpoint(name="transpilers-probe", gpu=GpuType.NVIDIA_GEFORCE_RTX_4090,
          dependencies=["torch"], volume=VOL, execution_timeout_ms=900_000)
async def probe() -> dict:
    """Validate the unknowns cheaply on a 4090: volume mount + persistence, GPU,
    dep install, and whether a training-length window (~4 min) survives Flash's
    serverless timeout. (Mojo-on-volume install is validated separately.)"""
    import os, time, torch
    t0 = time.time()
    out = {"gpu": torch.cuda.get_device_name(0) if torch.cuda.is_available() else None}

    # 1) volume is writable + persistent across runs
    vp = "/runpod-volume/_probe.txt"
    os.makedirs("/runpod-volume", exist_ok=True)
    out["volume_preexisting_marker"] = os.path.exists(vp)  # True on a 2nd run => persistence
    with open(vp, "w") as f:
        f.write("ok")
    out["volume_writable"] = os.path.exists(vp)

    # 2) survive a training-length wall-clock window (the key serverless-timeout question)
    time.sleep(240)
    out["elapsed_s"] = round(time.time() - t0, 1)
    out["survived_4min"] = True
    return out


# ----------------------------------------------------------------------- train_eval
@Endpoint(name="transpilers-train-eval", gpu=[GpuType.NVIDIA_A40, GpuType.NVIDIA_A100_80GB_PCIe],
          dependencies=TRAIN_DEPS, system_dependencies=["curl"], volume=VOL,
          env={"HF_HOME": f"{MNT}/hf"}, execution_timeout_ms=14_400_000)
async def train_eval(model_id: str, tag: str, epochs: float = 1.0) -> dict:
    """Per-model: baseline eval (base) -> LoRA fine-tune -> post eval. Reads staged
    datasets + Mojo from the volume; writes adapter + eval JSONs back to the volume.

    NOTE/RISKS (validate via --probe first):
      * Gemma-4 is multimodal (any-to-any): AutoModelForCausalLM may not load it;
        may need AutoModelForImageTextToText + different LoRA target_modules.
      * Gemma chat template has no system role -> merge system into the user turn.
    """
    import os, json, time
    os.environ["HF_HOME"] = f"{MNT}/hf"
    # ... staged data at {MNT}/data, Mojo at {MNT}/mojo/.pixi/envs/default/bin/mojo ...
    # Reuses the train.py recipe (LoRA r16/all-linear, bf16) + the heldout Mojo gate
    # (run_heldout_eval.eval_mojo with MOJO_BIN pointed at the volume install).
    # Implemented after the probe confirms timeout + Mojo-on-volume + (for gemma) loader.
    raise NotImplementedError("fill in after probe validates timeout + mojo + gemma loader")


async def _run():
    results = await asyncio.gather(
        train_eval(MODELS["qwen7b"], "qwen7b"),
        train_eval(MODELS["gemma12b"], "gemma12b"),
    )
    for tag, r in zip(MODELS, results):
        print(tag, json.dumps(r, indent=2))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--probe", action="store_true", help="cheap validation run on a 4090")
    ap.add_argument("--populate", action="store_true", help="stage datasets + install Mojo on the volume")
    ap.add_argument("--run", action="store_true", help="parallel train+eval for both models")
    args = ap.parse_args()
    if not os.environ.get("RUNPOD_API_KEY"):
        raise SystemExit("RUNPOD_API_KEY not set")

    if args.probe:
        print(json.dumps(asyncio.run(probe()), indent=2))
    elif args.run:
        asyncio.run(_run())
    else:
        ap.error("pick a mode: --probe | --populate | --run")


if __name__ == "__main__":
    main()
