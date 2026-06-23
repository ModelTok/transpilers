# Monetization strategy — `transpilers` as the best "source → verified Mojo" API

Concrete v1 plan for issue #55. Scope: the **`transpilers` tool as a product** —
a hosted, pay-per-use service that turns existing source (C++, Python, C,
Fortran, …) into **verified Mojo**. `energyplus-mojo` is a separate product and
out of scope.

## Thesis (why →Mojo, why now)

Code modernization is a ~$25B (2025) → ~$56B (2030) market, but the funded
activity targets **enterprise legacy** (COBOL/mainframe/Java→cloud: Mechanical
Orchard, Moderne/OpenRewrite, AWS Transform, IBM watsonx Code Assistant for Z,
TSRI) and the C→Rust niche (C2Rust, DARPA TRACTOR). **None target Mojo.**

A *generic* transpiler API loses — it fights both LLM commoditization and funded
incumbents. **→Mojo is whitespace and defensible:**

1. **Newness is the moat.** Mojo is young → frontier LLMs have little Mojo
   training data and emit poor Mojo. A model fine-tuned on *verified* pairs (our
   flywheel) beats them on Mojo specifically, and the gap **widens** as we mine
   more pairs.
2. **Verification-first.** Algorithmic IR + LLM hole-filling + compile + behavioral
   verify yields *trustworthy* Mojo — unlike LLM-only (unverifiable) or rule-only
   (no idiom inference). Competitors don't publish a verification rate; we can.
3. **Rides Modular's ecosystem** momentum (Mojo HPC/AI, SC'25 kernels paper).

## What "best" must mean (and is measurable today)

| claim | how we prove it | repo asset |
|-------|-----------------|------------|
| Beat frontier LLMs on Mojo `pass@1` | head-to-head on the frozen bench vs Claude/Gemini/GPT zero-shot | `benchmarks/transpilation-bench`, `scripts/sft/eval_transbench.py` |
| Multi-source coverage → Mojo | per-language verified pass-rate (C++/Python/C) | `scripts/sft/eval_diverse.py`, `data/sft/algorithms` (#57) |
| Real-world, not snippets | whole-file success on EnergyPlus C++ | `scripts/ep_compile_sweep.py`, `scripts/sft/diff_verify_ep.py` |
| Verification rate | % outputs that compile + match behavior | `src/transpilers/verify/behavioral.py` (#48) |

Publishing the `pass@1` delta vs frontier models **is** the marketing.

## Two layers to ship

1. **Hosting (no-infra → API).** Primary: **Replicate** (push a Cog image →
   instant HTTPS API, per-second GPU billing, scale-to-zero). Alternatives:
   Baseten, Modal, Together, Fireworks, Beam, RunPod Serverless.
2. **Monetization (earn from usage).** Primary: **OpenRouter** (list as a provider
   → paid API traffic + billing handled, we just host). Alternatives: AWS
   Bedrock/SageMaker or Azure AI marketplaces (list-and-earn); or DIY
   Baseten/Modal + **Stripe metered billing**.

## Recommended v1 (cheapest path to validated demand)

```
train on cloud (CUDA)            # docs/finetune_qwen7b.md, docs/cloud_training.md
  → merge base + adapter         # one merge step
  → package as Cog               # Replicate
  → deploy as "source→Mojo" API
  → monetize via OpenRouter      # or Stripe-metered gateway
  → publish pass@1 vs frontier   # the differentiator
```

Ship cheap, validate demand **before** any marketplace build.

## Unit economics (sketch — fill with measured numbers at deploy)

The repo's `docs/cost_analysis.md` already shows a fine-tuned 7B on a cheap GPU
serving ~1,500 tok/s at ~$0.40/hr — translating ~1M LOC for **$40–80** of
compute vs **$2,250–5,500** on frontier APIs. The product margin is the spread
between that serving cost and a per-token price competitive with frontier coding
APIs but justified by *verified Mojo* (which they cannot produce).

| line item | source |
|-----------|--------|
| serving $/1M output tok | measured on the deploy GPU (A10/L4/A40) |
| price $/1M output tok | benchmark vs OpenRouter coding-model rates |
| verify surcharge | optional "verified" tier (compile+behavior gate runs server-side) |

Two tiers worth pricing separately: **draft** (model output only) and
**verified** (server runs the compile + behavioral gate; the trust premium).

## Prerequisites / blockers

- **Needs the trained model first.** Local finetune is BLOCKED (PyTorch+ROCm
  RDNA3 backward-pass deadlock); train on **cloud CUDA** — `docs/cloud_training.md`
  and the launch-ready `docs/finetune_qwen7b.md` / `scripts/sft/train_7b.sh` (#41).
- `merge adapter → base` + Cog packaging step.
- ToS for a code-translation API (IP/licensing of submitted source).

## v1 acceptance checklist

- [ ] Trained 3B/7B Mojo transpiler deployed to a serverless host with a public API
- [ ] Benchmark proving our Mojo `pass@1` > frontier LLMs (the claim)
- [ ] Per-use billing validated (OpenRouter listing **or** Stripe-metered gateway)
- [ ] Pricing + unit-cost analysis ($/1M tok serve vs charge)
- [ ] `docs/` deploy-for-revenue runbook alongside `cloud_training.md`

## Risks

- **LLM commoditization reaches Mojo** as the ecosystem matures → mitigate by
  staying ahead on the verified-pairs flywheel and owning the verification gate.
- **Modular ships a first-party migrator** → partner/position as the verified
  layer rather than compete on raw generation.
- **Thin demand** → the own-closure path (energyplus-mojo + ModelTok needs)
  guarantees a first paying user even if the open market is slow.
