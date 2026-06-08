# Best & Cost-Efficient Methods for Transpilation — Research Survey (2022–2025)

---

## Method Taxonomy

There are **7 distinct families** of approaches, with very different cost/accuracy tradeoffs:

---

### 1. 🧠 Pure Neural / Seq2Seq (Fine-tuned Models)

**Core idea:** Train an encoder-decoder on parallel or monolingual code corpora.

| Paper | Method | Languages | Result |
|---|---|---|---|
| **TransCoder** ([arXiv:2006.03511](https://arxiv.org/abs/2006.03511), Facebook 2020) | Unsupervised seq2seq on 2.8M GitHub repos | C++ ↔ Java ↔ Python | Baseline for the field |
| **TransCoder-ST** (2022) | TransCoder + unit-test filtering | Same | Better functional correctness |
| **SteloCoder** ([arXiv:2310.15539](https://arxiv.org/abs/2310.15539)) | Decoder-only MoE + LoRA + curriculum learning | Multi-language → Python | SOTA on several benchmarks, efficient inference |
| **CoTran** ([arXiv:2306.06755](https://arxiv.org/abs/2306.06755)) | RL fine-tuning with **compiler feedback + symbolic execution** | Java ↔ Python (57K pairs) | 48.68% FEqAcc vs 38.26% PLBART; +14.89% over CodeT5 |
| **EffiReasonTrans** ([arXiv:2510.18863](https://arxiv.org/abs/2510.18863)) | RL on reasoning-augmented data; 2-stage training | 6 translation pairs | +49.2% CA, +27.8% CodeBLEU, **−29% inference latency** |

**Cost:** High upfront (training), low per-inference once deployed. Not practical unless you own a large parallel corpus.

---

### 2. 🔁 Iterative Repair / Test-Driven (Prompting + Feedback Loops)

**Core idea:** Translate once, run tests, feed errors back to LLM to repair. No fine-tuning needed.

| Paper | Method | Result |
|---|---|---|
| **UniTrans** ([arXiv:2404.14646](https://arxiv.org/abs/2404.14646), FSE 2024) | Auto-generate tests for source → translate → iterative repair loop; works with any LLM | "Substantial improvements" on Python/Java/C++ with GPT-3.5, LLaMA-7B/13B |
| **SafeTrans** ([arXiv:2505.10708](https://arxiv.org/abs/2505.10708)) | Few-shot guided repair with error-type-specific examples; 6 LLMs compared | **54% → 80%** success rate on 2,653 C programs with GPT-4o |
| **BatFix** (TOSEM 2024) | Patch synthesis for transpiled Java→C++ and Python→C++ bugs | Fills gap after initial translation |
| **TransCoder-ST** | Filter outputs by test pass | Cleaner than vanilla TransCoder |

**Cost:** Zero training. API costs only. GPT-4o + multiple repair rounds = expensive per token but no infra. Smaller models (LLaMA) make it much cheaper.

**⭐ Best cost-efficiency for most use cases.**

---

### 3. 🤖 Multi-Agent / Agentic Alignment

**Core idea:** Multiple specialized agents — one translates, one verifies, one repairs, one aligns.

| Paper | Method | Result |
|---|---|---|
| **BabelCoder** ([arXiv:2512.06902](https://arxiv.org/abs/2512.06902)) | **Alignment Agent** compares source vs. translated code block-by-block using internal variable values to find divergence | **94.16% avg accuracy**, +0.5%–13.5% over baselines across all language pairs |
| **TransAgent** ([arXiv:2409.19894](https://arxiv.org/abs/2409.19894)) | Fine-grained execution alignment; localises error-prone blocks | **+33.3%** over UniTrans, **+56.7%** over Agentless repair |
| **Semantic Alignment (TransAGENT)** | Multi-agent with error localisation | Strong generalisation across LLMs |

**BabelCoder is currently the highest-accuracy method for function/class-level translation.** The block-by-block alignment is the key differentiator — it catches semantic drift that test-only approaches miss.

**Cost:** Multiple LLM calls per translation (~3–5×). Worth it when correctness matters.

---

### 4. 🏗️ Compositional / Structural Decomposition

**Core idea:** Break the repository into dependency-ordered units; translate bottom-up.

| Paper | Method | Languages | Result |
|---|---|---|---|
| **AlphaTrans** ([arXiv:2410.24117](https://arxiv.org/abs/2410.24117), FSE 2025) | Reverse call-order decomposition on 17,874 fragments from 10 real projects (836 classes, 8,575 methods) | Repo-level Java→Python | **96.4% syntactic**, 27% runtime, 25% functional correctness; devs fixed remainder in **~20 hrs** avg |
| **Skeleton-Guided** ([arXiv:2501.16050](https://arxiv.org/abs/2501.16050), EMNLP 2025) | First translate structural skeletons (class/method signatures), then fill bodies guided by skeleton | Java → C# (repo-level) | DeepSeek-v3 best model; fine-grained test-level metrics |
| **Call Graph Analysis** (IJCAI 2025) | Use call graphs as context for LLM, better dependency awareness | Multiple | Beats baseline LLMs |
| **EvoC2Rust** ([arXiv:2508.04295](https://arxiv.org/abs/2508.04295)) | Skeleton-guided C→Rust at project level | C → Rust | Recent (2025) |

**Key insight:** Compositional decomposition is the only approach that reliably scales to **full repositories** (not just functions). The 96% syntactic / 25% functional gap in AlphaTrans shows this is still unsolved at the semantic level.

---

### 5. 🔬 IR / Compiler-Assisted

**Core idea:** Use the compiler's own semantic representation (LLVM IR) to ground the model.

| Paper | Method | Languages | Result |
|---|---|---|---|
| **TransCoder + LLVM IR** ([arXiv:2207.03578](https://arxiv.org/abs/2207.03578), ICLR 2023) | Append LLVM IR to source as input signal | C++, Java, Rust, Go | **+11% avg**, **+79%** Java→Rust |
| **Meta LLM Compiler** | Pretrained on 422 GB of LLVM-IR | Compiler tasks | Specialised compiler optimisation |

**Why it works:** IR exposes types, memory layout, and control flow that are invisible in source text. Any language with an LLVM frontend (C, C++, Rust, Go, Swift, Kotlin, Julia…) can use this.

**Cost:** Requires compiler toolchain at inference time. Adds build step but no extra LLM calls.

---

### 6. 🧮 Neuro-Symbolic / Formally Verified

**Core idea:** Combine LLM generation with symbolic solvers or proof generation for correctness guarantees.

| Paper | Method | Languages | Result |
|---|---|---|---|
| **Guess & Sketch** ([arXiv:2309.14396](https://arxiv.org/abs/2309.14396)) | LM generates candidates with confidence → symbolic solver resolves equivalence | **Assembly** transpilation | **+57.6%** vs GPT-4, **+39.6%** vs engineered transpiler |
| **LLMLift** ([arXiv:2406.03003](https://arxiv.org/abs/2406.03003), NeurIPS 2024) | LLM translates DSL + generates **formal correctness proofs**; verified lifting | 4 DSLs | Outperforms symbolic-only tools; avg solve time **2s vs 41s** for C2TACO |
| **Berkeley formal reasoning** (2025) | Analysis: testing alone is insufficient; formal compositional reasoning needed for correctness | C++, Java | Argues the field needs formal methods, not just test-passing |

**LLMLift is the only approach with functional correctness guarantees.** The 2s vs 41s speedup over prior symbolic tools is a remarkable cost win.

**Cost:** Proof generation adds overhead but eliminates the cost of post-deployment bugs.

---

### 7. 🔄 Hybrid / Static Analysis Augmented

| Paper | Method | Key idea |
|---|---|---|
| **TransAGENT** | Translate + static analysis to map features | Handles library mismatches |
| **Lost in Translation** ([arXiv:2308.03109](https://arxiv.org/abs/2308.03109)) | Empirical study of LLM bugs + prompt-crafting to fix | Better prompt structure reduces 41% of failures |

---

## 📊 Cost vs. Accuracy Tradeoff Summary

```
High Accuracy
     │
     │  ● BabelCoder (94%, multi-agent)
     │  ● LLMLift (verified, DSL-specific)
     │  ● Guess & Sketch (assembly, +58% vs GPT-4)
     │
     │  ● SafeTrans / UniTrans (80%, iterative repair)
     │  ● TransCoder+LLVM IR (+11–79%)
     │  ● AlphaTrans (96% syntactic, 25% functional)
     │
     │  ● CoTran / EffiReasonTrans (RL-trained, fast)
     │  ● SteloCoder (LoRA MoE, cheap inference)
     │
     │  ● Plain GPT-4 prompting (~40-60%)
     │
Low  └──────────────────────────────────────
    Low cost                          High cost
    (no training, single API call)    (training or many API calls)
```

| Goal | Best approach |
|---|---|
| **Highest accuracy, correctness matters** | BabelCoder (agentic) or LLMLift (verified) |
| **Best accuracy/cost for function-level** | UniTrans or SafeTrans (iterative repair + tests) |
| **Repo/project-level scale** | AlphaTrans + Skeleton-Guided |
| **Training a smaller dedicated model** | EffiReasonTrans (RL, −29% latency) or SteloCoder |
| **Assembly/low-level** | Guess & Sketch (neurosymbolic) |
| **Semantic correctness guarantees** | LLMLift + formal proofs |
| **Adding IR grounding cheaply** | LLVM IR augmentation (just a compile step) |

---

## What's Consistent Across All Research

1. **Testing alone is insufficient** — the Berkeley 2025 report argues explicitly that even passing all tests doesn't guarantee semantic equivalence; formal methods are needed
2. **Iterative repair always helps** — every approach that adds repair loops beats one-shot translation by 10–30%
3. **Repo-level is the open problem** — function-level is nearly solved (~90%+); full-project translation is ~25% functional correctness even with SOTA
4. **Block-level alignment > global correctness** — BabelCoder's block-by-block comparison is the most principled approach to catching semantic drift

---

## Sources

- [UniTrans / Exploring LLMs (FSE 2024)](https://arxiv.org/abs/2404.14646)
- [BabelCoder](https://arxiv.org/abs/2512.06902)
- [TransAgent](https://arxiv.org/abs/2409.19894)
- [AlphaTrans](https://arxiv.org/abs/2410.24117)
- [Skeleton-Guided-Translation](https://arxiv.org/abs/2501.16050)
- [LLMLift / Verified Transpilation (NeurIPS 2024)](https://arxiv.org/abs/2406.03003)
- [Guess & Sketch](https://arxiv.org/abs/2309.14396)
- [CoTran](https://arxiv.org/abs/2306.06755)
- [EffiReasonTrans](https://arxiv.org/abs/2510.18863)
- [SafeTrans](https://arxiv.org/abs/2505.10708)
- [LLM Code Translation Needs Formal Reasoning (Berkeley)](https://www2.eecs.berkeley.edu/Pubs/TechRpts/2025/EECS-2025-174.pdf)
- [Scalable Validated Translation (Amazon)](https://assets.amazon.science/0e/ab/c10459dd4013a7c02f09b8c96f3f/scalable-validated-code-translation-of-entire-projects-using-large-language-models.pdf)
- [Lost in Translation](https://arxiv.org/abs/2308.03109)
- [Call Graph Analysis (IJCAI 2025)](https://www.ijcai.org/proceedings/2025/0848.pdf)
- [TransCoder + LLVM IR (ICLR 2023)](https://arxiv.org/abs/2207.03578)
- [SteloCoder](https://arxiv.org/abs/2310.15539)
- [BatFix (TOSEM 2024)](https://danieltrt.github.io/papers/tosem24.pdf)
- [EvoC2Rust](https://arxiv.org/abs/2508.04295)
