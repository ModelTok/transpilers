#!/usr/bin/env python3
"""Deploy DiffusionGemma-26B on Vertex AI Model Garden (NVIDIA RTX PRO 6000).
Run with the env that has google-cloud-aiplatform:  ~/rocm-venv/bin/python this.py
Requires ADC:  gcloud auth application-default login
WARNING: this provisions a GPU endpoint that BILLS BY THE HOUR until undeployed.
"""
import vertexai
from vertexai import model_garden

vertexai.init(project="acquired-device-492820-b1", location="europe-west4")

model = model_garden.OpenModel("hf-google/diffusiongemma-26b-a4b-it@001")
endpoint = model.deploy(
    accept_eula=True,
    machine_type="g4-standard-48",
    accelerator_type="NVIDIA_RTX_PRO_6000",
    accelerator_count=1,
    serving_container_image_uri="us-docker.pkg.dev/vertex-ai/vertex-vision-model-garden-dockers/pytorch-vllm-serve:20260413_0916_RC01",
    endpoint_display_name="diffusiongemma-26b-a4b-it-mg-one-click-deploy",
    model_display_name="diffusiongemma-26b-a4b-it-1781208422414",
    use_dedicated_endpoint=True,
    reservation_affinity_type="NO_RESERVATION",
)

print("\n=== DEPLOYED ===")
print("endpoint resource name:", endpoint.resource_name)
try:
    print("dedicated DNS:", endpoint.gca_resource.dedicated_endpoint_dns)
except Exception:
    pass
print("\nReminder: this endpoint bills continuously. Undeploy when done:")
print(f"  gcloud ai endpoints undeploy-model ... --endpoint={endpoint.name} --region=europe-west4")
