# transpilation-flash

RunPod Flash agent for C++ → Python/Mojo transpilation using **DeepSeek-V4-Flash**.

## Architecture

```
client.py  ──►  RunPod Flash endpoint  ──►  vLLM (DeepSeek-V4-Flash)
               (queue-based GPU worker)      (OpenAI-compatible API)
```

## Deploy

```bash
# 1. Login to RunPod Flash
flash login

# 2. Deploy the worker (2× H200 or B300)
flash deploy --env prod

# 3. Note the endpoint ID printed after deploy
```

## Use — single call

```bash
# Via deployed endpoint
python client.py \
  --endpoint-id ep-xxxxx \
  --cpp "int add(int a, int b) { return a + b; }" \
  --target python

# Via local SSH tunnel (run tunnel in separate terminal first):
# ssh -L 8000:localhost:8000 <pod>@ssh.runpod.io -i ~/.ssh/id_ed25519 -N
python client.py --local \
  --cpp "long long fast_power(long long base, long long exp, long long mod) { ... }" \
  --target mojo \
  --path python_pivot
```

## Use — full bench run

```bash
# Run all 40 tasks against DeepSeek-V4-Flash and compare to hybrid transpiler
python client.py --local --bench --target python
python client.py --local --bench --target python --path python_pivot --repair 2

# Results written to:
# ../transpilation-bench/results/flash_deepseek_python_direct.json
```

## Input / Output

**Input:**
```json
{
  "cpp_source": "int add(int a, int b) { return a + b; }",
  "target": "python",
  "path": "direct",
  "repair_passes": 1,
  "tests": [{"args": [1, 2], "expected": "3"}]
}
```

**Output:**
```json
{
  "code": "def add(a: int, b: int) -> int:\n    return a + b",
  "path": "direct",
  "target": "python",
  "syntax_ok": true,
  "test_results": [{"args": [1, 2], "expected": "3", "actual": "3", "passed": true}],
  "pass_at_1": true,
  "repair_passes_used": 0,
  "model": "deepseek-ai/DeepSeek-V4-Flash"
}
```

## Translation paths

| path | description | LLM calls |
|------|-------------|-----------|
| `direct` | C++ → Python/Mojo in one call | 1 |
| `python_pivot` | C++ → Python → Mojo (two calls) | 2 |

## GPU sizing

DeepSeek-V4-Flash: 284B total / 13B active params, FP4+FP8 mixed.

- **1× B300** (192 GB HBM3e) — fits with full 1M context headroom
- **2× H200** (282 GB HBM3e) — fits, ~$7/hr
- **1× H100 80GB** — too small for full model; use quantized variant

The Flash `worker.py` is configured for 2× H200 (`gpu_count=2`). On a B300 pod
change `gpu_count=1`.
