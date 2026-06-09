# Flash probe worker -- validates volume mount + GPU on a cheap 4090.
# run the project dev server:  flash dev
# or test this endpoint directly:  python probe_worker.py
from runpod_flash import Endpoint, GpuType, NetworkVolume

# Attach the existing volume by id (created earlier). Mounts at /runpod-volume.
VOL = NetworkVolume(id="n1b3o5cf72")  # transpilers-models, 100GB, US-KS-2


@Endpoint(name="transpilers_probe", gpu=GpuType.ANY,
          dependencies=["torch"], volume=VOL, execution_timeout_ms=0)
async def probe(input_data: dict) -> dict:
    import os, torch
    out = {"gpu": torch.cuda.get_device_name(0) if torch.cuda.is_available() else None}
    vp = "/runpod-volume/_probe.txt"
    out["volume_mounted"] = os.path.isdir("/runpod-volume")
    out["volume_preexisting_marker"] = os.path.exists(vp)  # True on a 2nd run => persistence
    if out["volume_mounted"]:
        with open(vp, "w") as f:
            f.write("ok")
        out["volume_writable"] = os.path.exists(vp)
    return out


if __name__ == "__main__":
    import asyncio
    print(asyncio.run(probe({"message": "validate volume + gpu"})))
