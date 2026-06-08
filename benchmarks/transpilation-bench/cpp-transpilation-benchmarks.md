# C++ Transpilation & Code Migration Eval Benchmarks

A comprehensive landscape of evaluation benchmarks for C++ code transpilation and migration, grouped by scope and focus.

---

## 🔵 Function-Level Multi-Language (C++ included)

| Benchmark | Languages | Size | Metric | Data |
|---|---|---|---|---|
| **TransCoder Test Set** (Facebook, 2020) | C++ ↔ Java ↔ Python | 948 parallel functions | Pass@k (unit tests) | [GitHub](https://github.com/facebookresearch/TransCoder) |
| **G-TransEval** (ASE 2023) | Python, **C++**, Java, C#, JS — 4 difficulty tiers (token/syntactic/library/algorithm) | 400 pairs | CodeBLEU + Pass@k | [GitHub](https://github.com/polyeval/g-transeval) |
| **CodeTransOcean** ([arXiv:2310.04951](https://arxiv.org/abs/2310.04951)) | MultilingualTrans: C, **C++**, C#, Java, Python, Go, PHP, VB; + NicheTrans, LLMTrans, DLTrans | Large-scale multi-dataset | CodeBLEU, DSR@K | [GitHub](https://github.com/WeixiangYAN/CodeTransOcean) |
| **xCodeEval** (ACL 2024) | 17 langs incl. **C++**, from Codeforces | 25M examples / 7.5K problems | Execution-based Pass@k | [GitHub](https://github.com/ntunlp/xCodeEval) |
| **TRACE** ([arXiv:2508.11468](https://arxiv.org/abs/2508.11468)) | **C++**, Java, Python | 1,000 efficiency-critical tasks | **Time efficiency** (not just correctness) | See paper |

> **G-TransEval** is the most C++-focused general-purpose benchmark — its 4 tiers let you isolate *why* a model fails (syntax vs. library vs. algorithm reimplementation).

---

## 🟣 Class-Level & Repo-Level

| Benchmark | Languages | Size | Notes |
|---|---|---|---|
| **Class-level Code Translation** ([arXiv:2411.06145](https://arxiv.org/abs/2411.06145)) | Python → Java, **C++** | ~1,243 tasks | Extension of ClassEval; diverse class dependencies |
| **RustRepoTrans** ([arXiv:2411.13990](https://arxiv.org/abs/2411.13990)) | C, Java, Python → Rust | 375 repo-level tasks | Best model (DeepSeek-R1): 51.5% Pass@1 |

---

## 🟢 C/C++ → Rust (Memory-Safety Focus)

| Benchmark | Size | Notes | Data |
|---|---|---|---|
| **CRUST-Bench** ([arXiv:2504.15254](https://arxiv.org/abs/2504.15254)) | 100 C repos w/ manual Rust interfaces + tests | Whole-repo; o1 solves only 15/100 | [GitHub](https://github.com/anirudhkhatry/CRUST-bench) |
| **C2Rust-Bench** ([arXiv:2504.15144](https://arxiv.org/abs/2504.15144)) | 2,905 functions (filtered from 15,503) | Function-level C→Rust | See paper |

---

## 🟡 Third-Party Library / Real-World Dependencies

| Benchmark | Languages | Size | Key Finding |
|---|---|---|---|
| **TransLibEval** ([arXiv:2509.12087](https://arxiv.org/abs/2509.12087)) | Python, Java, **C++** | 200 real-world tasks | >60% accuracy drop vs library-free settings |

---

## 🟠 Code Migration (Version / Environment)

| Benchmark | Languages | Size | Tasks |
|---|---|---|---|
| **CodeMEnv** ([arXiv:2506.00894](https://arxiv.org/abs/2506.00894)) | Python & Java packages (19 pkgs) | 922 examples | API incompatibility detection, definition changes, code adaptation; avg Pass@1 = 26.5% |
| **JMigBench** ([arXiv:2602.09930](https://arxiv.org/abs/2602.09930)) | Java 8 → Java 11 | ~8 deprecated API categories | CodeBLEU-based; very Java-specific |

---

## 🔴 Repair / Post-Transpilation Fix

| Benchmark | Languages | Focus |
|---|---|---|
| **BatFix** (TOSEM 2024, [paper](https://danieltrt.github.io/papers/tosem24.pdf)) | Java→**C++**, Python→**C++** | Synthesizes patches for syntax + semantic bugs in transpiled code |

---

## ⚙️ Domain-Specific

| Benchmark | Languages | Notes |
|---|---|---|
| **OpenMP Fortran ↔ C++** ([arXiv:2307.07686](https://arxiv.org/abs/2307.07686)) | Fortran ↔ **C++** | HPC / scientific computing; parallel/SIMD annotations |
| **EffiBench-X** ([arXiv:2505.13004](https://arxiv.org/abs/2505.13004)) | Multi-language incl. C++ | Efficiency of LLM-generated code; [HF dataset](https://huggingface.co/datasets/EffiBench/effibench-x) |

---

## Recommended Starting Points by Use Case

| Goal | Best Benchmark |
|---|---|
| General C++ ↔ Java/Python translation quality | **G-TransEval** + **TransCoder test set** |
| Broad multilingual coverage incl. C++ | **CodeTransOcean** or **xCodeEval** |
| Real-world repo-level C++ migration | **CRUST-Bench** (C→Rust) or class-level benchmark |
| Library/API compatibility in C++ | **TransLibEval** |
| Runtime efficiency of translated C++ | **TRACE** + **EffiBench-X** |
| HPC / Fortran→C++ | OpenMP dataset |
| Fixing broken transpiled C++ output | **BatFix** |

---

## What's Missing / Gaps

- **No large-scale C++ version migration benchmark** exists yet (analogous to JMigBench but for C++11→C++17→C++20). This is an open area.
- **No C++ → Python** dedicated benchmark at repo scale.
- Most C++-targeting benchmarks still work at **function level**; class/repo level is very new (2024–2025).

---

## Sources

- [BatFix (TOSEM 2024)](https://danieltrt.github.io/papers/tosem24.pdf)
- [CRUST-Bench](https://arxiv.org/html/2504.15254v3)
- [C2Rust-Bench](https://arxiv.org/pdf/2504.15144)
- [CodeTransOcean](https://aclanthology.org/2023.findings-emnlp.337.pdf)
- [G-TransEval](https://github.com/polyeval/g-transeval)
- [xCodeEval](https://aclanthology.org/2024.acl-long.367.pdf)
- [Class-level benchmark](https://arxiv.org/html/2411.06145v3)
- [RustRepoTrans](https://arxiv.org/html/2411.13990v3)
- [TransLibEval](https://arxiv.org/html/2509.12087v1)
- [CodeMEnv](https://arxiv.org/abs/2506.00894)
- [TRACE](https://arxiv.org/pdf/2603.16479)
- [OpenMP Fortran↔C++](https://arxiv.org/pdf/2307.07686)
- [EffiBench-X](https://arxiv.org/pdf/2505.13004)
- [TransCoder GitHub](https://github.com/facebookresearch/TransCoder)
- [EffiBench-X HF dataset](https://huggingface.co/datasets/EffiBench/effibench-x)
