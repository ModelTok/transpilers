# transpilation-bench

A structured benchmark for evaluating LLM-based transpilation from **C++ → Python** and **C++ → Mojo**, covering a wide spectrum of programming concepts across four difficulty tiers.

---

## Motivation

Existing transpilation benchmarks (TransCoder, G-TransEval, CodeTransOcean) evaluate single-language pair translation with narrow concept coverage. This benchmark is designed to:

1. Cover **30 distinct programming concepts** — from bitwise operations to Dijkstra's algorithm — without duplication.
2. Support **four translation paths** and measure how intermediate representations affect accuracy.
3. Enable **multi-metric evaluation**: Pass@1, syntax validity, and (for pure functions) SMT-based formal verification.
4. Serve as the ground-truth corpus for fine-tuning 7B models that will eventually process 1M LOC C++ repositories.

---

## Benchmark Overview

### Difficulty Tiers

| Tier | Category | Description |
|------|----------|-------------|
| 1 | Token-level | Direct syntactic mapping; no semantic reasoning required |
| 2 | Syntactic | Control flow, standard containers, idiom conversion |
| 3 | Library / OOP | Classes, operator overloading, standard library equivalents |
| 4 | Algorithmic | Graph algorithms, DP, data structures with non-trivial invariants |

### Task List

| ID | Name | Tier | Concept |
|----|------|------|---------|
| 001 | bitwise_ops | 1 | bitwise_arithmetic |
| 003 | string_reverse | 1 | string_manipulation |
| 004 | is_palindrome | 1 | string_validation |
| 006 | fizzbuzz | 1 | conditional_loops |
| 002 | fast_power | 2 | fast_exponentiation |
| 005 | run_length_encode | 2 | string_encoding |
| 007 | collatz_length | 2 | number_sequences |
| 008 | fibonacci_recursive | 2 | recursion |
| 010 | binary_search | 2 | divide_and_conquer |
| 012 | max_subarray | 2 | sliding_window |
| 013 | merge_sort | 2 | sorting |
| 023 | gcd_lcm | 2 | number_theory |
| 009 | fibonacci_memo | 3 | memoization |
| 011 | two_sum | 3 | hash_map |
| 014 | frequency_count | 3 | hash_map |
| 015 | set_ops | 3 | set_operations |
| 016 | min_stack | 3 | oop_stack |
| 017 | bst_insert_search | 3 | binary_search_tree |
| 018 | bfs_shortest_path | 3 | graph_bfs |
| 019 | has_cycle | 3 | graph_dfs |
| 020 | vector2d | 3 | operator_overloading |
| 021 | matrix_multiply | 3 | linear_algebra |
| 022 | statistics_ops | 3 | statistics |
| 024 | sieve_primes | 3 | sieve_algorithm |
| 030 | newton_sqrt | 3 | numerical_methods |
| 025 | coin_change | 4 | dynamic_programming_1d |
| 026 | edit_distance | 4 | dynamic_programming_2d |
| 027 | activity_selection | 4 | greedy |
| 028 | dijkstra | 4 | shortest_path |
| 029 | union_find | 4 | disjoint_set_union |

---

## Repository Structure

```
transpilation-bench/
├── README.md
├── generate_tasks.py     # Generates benchmarks/tasks/*.json from embedded implementations
├── run_eval.py           # Evaluation harness — runs LLMs against tasks, produces metrics
├── benchmarks/
│   ├── schema.json       # Task JSON schema
│   └── tasks/            # 30 task JSON files (001_bitwise_ops.json … 030_newton_sqrt.json)
├── results/
│   ├── leaderboard.json  # Aggregated results across all model/path runs
│   └── *.json            # Per-run result files
└── metrics/
    └── smt_equivalence.py  # (planned) z3-based formal verification for pure functions
```

---

## Task Format

Each task JSON file follows the schema in `benchmarks/schema.json`:

```json
{
  "id": "001",
  "name": "bitwise_ops",
  "tier": 1,
  "concept": "bitwise_arithmetic",
  "tags": ["bitwise", "low-level", "arithmetic"],
  "description": "Perform bitwise AND, OR, XOR, left-shift and right-shift on two integers.",
  "cpp_source": "...",
  "python_reference": "...",
  "mojo_reference": "...",
  "tests": [
    {"args": [12, 10], "expected": "(8, 14, 6, 12288, 0)"},
    ...
  ]
}
```

---

## Evaluation

### Quick start

```bash
# Evaluate GPT-4o with direct C++ → Mojo translation on all tasks
python run_eval.py --model gpt-4o --path direct --target mojo

# Evaluate Claude with Python-pivot path on tier-1 tasks only
python run_eval.py --model claude-3-5-sonnet-20241022 --path python_pivot --tier 1

# Evaluate a local vLLM endpoint (e.g., Qwen2.5-Coder-7B on RunPod)
VLLM_BASE_URL=http://<runpod-ip>:8000 \
  python run_eval.py --model local:qwen2.5-coder-7b-instruct --path direct

# Dry-run: print first 3 prompts without calling any LLM
python run_eval.py --model gpt-4o --path direct --dry-run
```

### Translation paths

| Path | Description | LLM calls |
|------|-------------|-----------|
| `direct` | C++ → Mojo in one call | 1 |
| `python_pivot` | C++ → Python → Mojo (inspired by LLMLift, arXiv:2406.003) | 2 |
| `ir_pivot` | C++ → LLVM IR (clang) → Mojo | 1 (+clang) |
| `ir_python_pivot` | C++ → LLVM IR → Python → Mojo | 2 (+clang) |

### Metrics

| Metric | Description |
|--------|-------------|
| `pass@1` | Fraction of tasks where all test cases pass |
| `syntax_ok_rate` | Fraction of tasks with syntactically valid output |
| `tier_breakdown` | `pass@1` per difficulty tier |
| `concept_breakdown` | `pass@1` per programming concept |

### Output

Results are written to `results/<model>_<path>_<timestamp>.json` and aggregated into `results/leaderboard.json`.

---

## Reproducing the Reference Translations

The `python_reference` and `mojo_reference` fields were hand-authored to be idiomatic (not mechanical transliterations). To regenerate all task JSONs from the source implementations in `generate_tasks.py`:

```bash
python generate_tasks.py
```

---

## Planned Extensions

- **SMT verification** (`metrics/smt_equivalence.py`): z3-based formal equivalence checking for pure mathematical functions (tasks 001–006, 023, 030).
- **LLVM IR pivot** evaluation: requires `clang` in PATH; tasks 001–006 emit clean IR with `-O0 -S -emit-llvm`.
- **Fine-tuning split**: `benchmarks/tasks/` can be used directly as SFT data with `cpp_source` as input and `python_reference`/`mojo_reference` as target.
- **Iterative repair**: `run_eval.py` will add `--repair-passes N` to enable test-failure-driven retry loops.

---

## Related Work

- **G-TransEval** (arXiv:2210.XXXXX) — 4-tier difficulty taxonomy adopted here
- **LLMLift** (NeurIPS 2024, arXiv:2406.03003) — Python as universal IR pivot; SMT verification
- **BabelCoder** (2024) — block-by-block alignment agent; 94.16% accuracy
- **Meta LLM Compiler** (arXiv:2407.18943) — 546B IR token training; 7B/13B models on HuggingFace
- **TransLibEval** — >60% accuracy drop without library documentation (motivation for Zim RAG)
- **AlphaTrans** — call-graph-ordered translation of full repositories

---

## License

MIT
