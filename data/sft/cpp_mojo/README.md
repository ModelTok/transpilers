# C++ → Mojo translator (model #1 in the 1:1 translator library)

A **single-direction** fine-tune: C++ → Mojo only. Part of a library where each
model owns exactly one source→target pair (no multitask squeezing). This is the
first one because it's the hard case: the base Qwen2.5-Coder-3B scores **0%** on
C++→Mojo (it doesn't know Mojo) — vs 90% on C++→Python, which barely needs a
model of its own.

## Why C++→Mojo gets its own model
Measured baseline (function-level, held-out, `run_heldout_eval.py`):

| Direction | base Qwen2.5-Coder-3B pass@1 |
|---|---|
| **C++→Mojo** | **0.0%** (0/10) — all compile-fail |
| C++→Python | 90.0% (9/10) |

So all the fine-tuning leverage is here. North-star metric = **C++→Mojo held-out
pass@1** (`heldout_eval.jsonl`), nothing else.

## Files
| File | Role |
|---|---|
| `train_translation.jsonl` | 41 **behaviorally-verified** C++→Mojo pairs, CodePivot schema (`{instruction,input,system,output}`) with rich faithful `<think>` reasoning. The task. |
| `mojo_acquisition.json` | 1357 Mojo-target examples (kernel corpus + Manual/Reference docs + syntax-correction skill). Teaches the model Mojo — the *target* language, not a second translation language. |
| `heldout_eval.jsonl` | 14 held-out C++→Mojo pairs in verl format with regenerated `ground_truth={inputs,outputs}` test cases. **Excluded from training** — the clean metric. |
| `system.txt` | The transpiler system prompt (CodePivot's + a Mojo runtime entry encoding the Python-interop JSON idiom). Used in both training and eval. |
| `sft.yaml` | LLaMA-Factory config. |

All 41 training pairs are verified by the generate-and-verify pipeline (compile
both sides, run on ~125 sampled inputs, agree to ≤1e-9, full branch coverage);
4 of them required the new **dependency-bundling** transpiler feature, and the
set grew 40→55 total after the **`fmod` codegen fix** and bool-return fix.

## Train
```bash
# register the two datasets (see header of sft.yaml), then:
llamafactory-cli train data/sft/cpp_mojo/sft.yaml
```
**Two-phase (recommended if the single pass under-fits translation):** the
acquisition set (1357) dwarfs translation (41), so the task signal can get
diluted. Run acquisition first, then translation:
1. `dataset: mojo_acquisition`, 1–2 epochs → checkpoint A (model now "knows" Mojo).
2. resume from A with `dataset: cpp_mojo_translation`, 3–5 epochs, lower LR → final.

## Evaluate (the only number that matters)
```bash
# serve the checkpoint, point ENDPOINT at it, then:
uv run python scripts/sft/run_heldout_eval.py --tag ft
# compare ft vs the pre-registered base (heldout_baseline.json): C++→Mojo 0/10.
```

## Scope discipline
- **In scope:** C++ (source) and Mojo (target) only.
- **Out of scope (separate models):** C++→Python, Python→Mojo, etc. Their seed
  data lives elsewhere; do not mix them in here.
