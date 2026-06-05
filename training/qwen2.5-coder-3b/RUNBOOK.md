# Qwen2.5-Coder-3B — train / serve / wire into the transpiler

Base: **`Qwen/Qwen2.5-Coder-3B-Instruct`** (dense, code-specialized — the small
member of the CodePivot lineage). Pipeline mirrors CodePivot/CodeNexus:
Python-as-IR **SFT** → optional **GRPO RL** → **serve** as the transpiler's
`llm_fill` backend.

Data lives in the CodePivot dataset (`dataset.zip`, ~11.5 GB unzipped):
- `sft_data.json` — alpaca format (`instruction`=transpile-this-Python, `output`=target code).
- `evaluation_py2others.jsonl`, `evaluation_others2all.jsonl` — verl-format eval (prompt + test cases).
- `PyTrans_Data.jsonl` (9.5 GB) — full RL corpus.

> Provenance/licensing: the dataset + CodeNexus pipeline (LLaMA-Factory configs,
> verl recipe) are upstream artifacts with no clear license — keep them out of
> this repo (they're gitignored). The files in *this* directory are first-party.

---

## 0. Cost / hardware (Qwen2.5-Coder-3B, RunPod, ±30%)
| Step | GPUs | ~Cost |
|---|---|---|
| Serve (vLLM) | 1× 16 GB | ~$0.25/hr |
| QLoRA SFT | 1× 24 GB | ~$15–35 |
| Full-FT SFT (ZeRO-3) | 1–2× 80 GB | ~$30–100 |
| GRPO RL | 2–4× 80 GB | ~$0.5–1.5k |

---

## 1. Serve first (no training) — make the hole-filler real
On a RunPod pod with a ≥16 GB GPU + vLLM:
```bash
pip install vllm
vllm serve Qwen/Qwen2.5-Coder-3B-Instruct --port 8000 --served-model-name Qwen2.5-Coder-3B-Instruct
```
Expose port 8000 (RunPod TCP proxy gives you a public `host:port`). Then point
the transpiler at it:
```bash
export TRANSPILER_LLM_BACKEND=openai
export OPENAI_BASE_URL=http://<runpod-host>:<port>/v1
export OPENAI_API_KEY=EMPTY                       # vLLM ignores it
export TRANSPILER_LLM_MODEL=Qwen2.5-Coder-3B-Instruct
PYTHONPATH=src python -m transpilers.cli.main <file> --target rust --infer-with-llm
```
Measure hole-fill quality against the compile+behavioral verification before
deciding whether to fine-tune.

---

## 2. SFT (if step 1 isn't good enough)
RunPod pod with the toolchain:
```bash
pip install -U "huggingface_hub[cli]"
git clone https://github.com/hiyouga/LLaMA-Factory && cd LLaMA-Factory && pip install -e ".[torch,deepspeed]"
```
Prep data — convert the SFT split to a file LLaMA-Factory can read and register it:
```bash
# unzip sft_data.json from the CodePivot dataset.zip into LLaMA-Factory/data/
# then add to data/dataset_info.json:
#   "transpilation_sft": { "file_name": "sft_data.json",
#     "columns": { "prompt": "instruction", "query": "input", "response": "output" } }
```
Train (config: `training/qwen2.5-coder-3b/sft.yaml`):
```bash
llamafactory-cli train /path/to/sft.yaml          # full-FT + ZeRO-3
# cheaper: set finetuning_type: lora, remove the deepspeed line → 1x 24 GB
```
Push the checkpoint to HF:
```bash
huggingface-cli upload <you>/qwen2.5-coder-3b-transpilation saves/Qwen2.5-Coder-3B-Instruct/full/transpilation-sft
```

---

## 3. GRPO RL (optional — the APF reward stage)
Uses verl + a sandbox-execution reward server (runs generated code against the
per-task test cases in the data). From CodeNexus `verl/recipe/grpo/`:
```bash
# start the 11-language sandbox (scripts/install.sh, Ubuntu-20.04-oriented), then:
cd verl/recipe/grpo
# edit run_grpo_qwen_7b.sh: model.path = your SFT checkpoint,
#   data.val_files = eval parquet, sandbox_fusion.url = localhost:8080
bash run_grpo_qwen_7b.sh
```
Reduce GPU count vs the 7B recipe (3B policy is smaller). Push the RL checkpoint
to HF, then re-run step 1 pointing vLLM at it.

---

## 4. Wire-in is permanent once served
The transpiler change is already in place: `LlmClient` selects the OpenAI-
compatible backend when `TRANSPILER_LLM_BACKEND=openai` (or `OPENAI_BASE_URL` is
set). Cache is keyed by model name, so re-runs against the same served model are
free. Default backend remains Anthropic when these vars are unset.
