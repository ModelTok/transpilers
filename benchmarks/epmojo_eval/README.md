# EnergyPlusMojo evaluation harness

Measures how good a transpiler's Mojo drafts are on a hard criterion: **bit-for-bit identical results to the
verbatim C++ they came from**. It was built to evaluate the repo's fine-tuned C++ → Mojo adapter together with
the deterministic post-pass (`src/transpilers/repair/mojo_postpass.py`) and best-of-n selection
(`transpile-llm --samples/--verify-cmd`).

## What it needs
- An **EnergyPlusMojo checkout**. The harness reads three things from it and changes nothing: the extracted C++
  routines (`tests/oracles/*.upstream.inc`), the oracle shim header, and the `cpp2mojo` signature parser and
  oracle-driver generator (`scripts/module_parity/`). Point to it with `--epmojo DIR` or `EPMOJO_DIR`.
  The published sets were made on EnergyPlusMojo commit `6ae386b2`; a different commit may lack some routines
  (`make_set.py --from-list` says so).
- **Mojo and g++** where scoring runs (Linux, or WSL on Windows), plus numpy. EnergyPlusMojo's pixi
  environment has all three. The oracle is built with `g++ -O2 -DNDEBUG -ffp-contract=off`.
- For generation: a model behind an OpenAI-compatible endpoint (Ollama by default) and this repo installed
  (`uv sync`).

## How a draft is scored
The draft is built with Mojo behind a thin batch wrapper, the verbatim routine is built with g++, and the bits of
every result are compared on EnergyPlusMojo's edge-case inputs (3,000 rows: magnitudes 1e-2 to 1e3, negatives,
0, 1, and IEEE specials: inf, NaN, -0, subnormals, 1e300). Per routine the status is:

| Status | Meaning |
|---|---|
| `exact` | builds, and every result is bit-identical |
| `mismatch` | builds; the detail is how many rows differ |
| `build_fail` | Mojo rejected the draft; the detail is the first error |
| `no_function` | no `def`/`fn` with the routine's name (for example the model wrapped it in a struct) |
| `arity` | the function takes a different number of parameters than the C++ routine |

`score.py` scores every draft twice: `raw` (as the model wrote it) and `postpass` (after
`transpilers.repair.mojo_postpass`, given the C++ source as context).

## Workflow
Paths below assume the transpilers repo as the working directory.

```sh
# 1. Rebuild a published routine selection from your EnergyPlusMojo checkout
python benchmarks/epmojo_eval/make_set.py --out work/dev \
    --from-list benchmarks/epmojo_eval/sets/dev.json --epmojo /path/to/EnergyPlusMojo

# 2. Draft every routine with the local model (one named run; raw answers are stored)
uv run python benchmarks/epmojo_eval/generate.py --set-dir work/dev --runs work/runs --run control \
    --model transpiler-15b-v2

# 3. Score raw and post-passed drafts (where Mojo and g++ work; here inside EnergyPlusMojo's pixi env)
pixi run --manifest-path /path/to/EnergyPlusMojo/pixi.toml python benchmarks/epmojo_eval/score.py \
    --set-dir work/dev --runs work/runs control --epmojo /path/to/EnergyPlusMojo
```

`make_set.py` without `--from-list` selects fresh routines by the documented rules (pure `Real64 → Real64`,
no callees, 4-45 lines, at most 3 per extract, unique names, shortest first); `--exclude` skips names already
used, which is how a held-out set is made.

### Best-of-n with the oracle as verifier
`verify_one.py` accepts a draft (exit 0) only if it is bit-exact; pass it to `transpile-llm`:

```sh
uv run python benchmarks/epmojo_eval/generate.py --set-dir work/greedy_failures --runs work/runs --run bestof8 -- \
    --postpass --samples 8 --temperature 0.8 \
    --verify-cmd "python benchmarks/epmojo_eval/verify_one.py {target} --set-dir work/greedy_failures"
```

On Windows with Mojo in WSL, use `verify_wsl.py` as the command; it converts paths and forwards the call:

```sh
--verify-cmd "python benchmarks/epmojo_eval/verify_wsl.py {target} --set-dir work/greedy_failures --python /root/epm/.pixi/envs/default/bin/python3 --epmojo /root/epm"
```

## Published sets (`sets/`)
These hold only routine names and metadata; the C++ text is read from your checkout, never copied here.

| File | Routines | Purpose |
|---|---|---|
| `dev.json` | 40 (31 unique names; the same routine appears in several extracts) | the rules in the post-pass were written while looking at its failures, so its scores are inflated |
| `heldout.json` | 21, unique, none in `dev` | routines the rules had not seen |
| `greedy_failures.json` | 3 | the routines greedy decoding fails, for best-of-n |

## Reference results
The repo's local adapter (Ollama, no guidance, temperature 0 unless stated), 3,000 inputs per routine. From
PR #146's measurements; reproduce with the commands above.

| Configuration | Exact |
|---|---|
| Raw output, `dev` | 8 of 40 |
| Raw output, `heldout` | 1 of 21 |
| With the post-pass, `dev` | 39 of 40 |
| With the post-pass, `heldout`, before the struct rule | 16 of 21 (the unbiased estimate) |
| With the post-pass, `heldout`, after the struct rule | 19 of 21 (optimistic: the rule was written after seeing that failure pattern) |
| Best-of-8 with this verifier, `greedy_failures` | 2 of 3 recovered (single sampling run) |

## Limits
- **Narrow coverage.** Only short, stateless numeric routines: no arrays, state, output parameters, callees or
  `bool` handling. That is not the real EnergyPlus workload, and scores there will be lower. Extending it needs
  oracles for those routines.
- **Small.** 52 unique routines in total; differences of a point or two are noise.
- **Assertions are off** in the oracle (`-DNDEBUG`), because the verbatim routines assert on input domains that
  the edge-case inputs deliberately violate.
- Scoring is only as good as the oracle's input generator: bit-identical on 3,000 rows is strong evidence,
  not proof.
- Results depend on the EnergyPlusMojo and Mojo versions; the sets record the commit they were made on.

## Files
`harness.py` shared code (sets, interface check, oracle, Mojo build, scoring, reporting) · `make_set.py` ·
`generate.py` · `score.py` · `verify_one.py` · `verify_wsl.py` · `sets/` · tests in `tests/test_epmojo_eval.py`
(the end-to-end test runs only when `EPMOJO_DIR`, g++ and Mojo are available).
