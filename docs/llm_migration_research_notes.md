# LLM-migration research notes: ideas mapped to this repo

Date: 2026-10-12. Scope: ideas from external work that could improve `transpilers`,
each checked against the current code. Repo status was verified by reading the
files cited (paths relative to the repo root; line numbers are as at this commit
and will drift). Source-side claims are summarised from the caller's earlier review
and were **not re-verified** in this pass, apart from one licence header (see
"Confidence and limits").

## Summary

- The repo already has most of the *verification* half of the literature: compile
  gates, a source-oracle behavioural verifier, a structural-fidelity gate, SMT
  checks, a tiered escalating repair loop, a flywheel and a gcov coverage gate in
  the dataset builders.
- The gaps are in the *repair* half. `escalating_repair` sends the whole source and
  whole previous output on every retry, always keeps the latest attempt even if it
  is worse, defaults to a compile-only verifier, and is not wired into the CLI or
  API (only the benchmark script and tests call it).
- The cheapest, highest-value items are: wire the behavioural verifier in as a
  first-class verifier with counterexample feedback; keep the best attempt and
  roll back regressions; guard against truncated output (the LLM client hard-codes
  `max_tokens=1024`); stop treating "unsupported" behavioural results as a pass
  by default; and add exact-hash and per-source grouping to dataset splits.
- Nothing here argues for dropping the IR. The PyMC and Medium sources are
  consistent with, or at best orthogonal to, the existing design.

## Status update: PR #130

This note was written against `main` at `8c9607e`. Pull request
[#130](https://github.com/ModelTok/transpilers/pull/130) (`feat(repair): graded
compile score and opt-in suspect-region hint`) addresses part of items 5 and 10 and
none of the others. If it has merged, read those two items as follows:

- Item 10 (graded compile score): `verify/score.py` now exists, with
  `first_error_line()` for rustc, gcc/clang/mojo, gfortran and Python, and
  `graded_compile_score()`. The score is recorded per attempt but the loop does not
  use it to rank or keep candidates, so item 2 is still open.
- Item 5 (narrow the repair context): compile signals now carry `first_error_line`,
  and an opt-in `suspect_region` adds a numbered excerpt around it to the repair
  prompt. The whole source and previous output are still sent as well, `run_mismatch`
  signals get no region, and nothing maps a compiler line to the enclosing function.

The line numbers quoted below predate that change and will have moved in
`repair/loop.py`, `repair/signal.py` and `verify/taxonomy.py`.

## Idea table

Effort: S = under a day, M = a few days, L = a week or more (my estimates, not measured).

| # | Idea | Source | Repo status | Effort | Priority |
|---|------|--------|-------------|--------|----------|
| 1 | Behavioural verifier as default repair gate, counterexample fed back | Flourine, CoTran, MatchFixAgent | Partly | S-M | High |
| 2 | Keep best attempt, roll back regressions, baseline-aware gate | ENCRUST | Missing in loop; partly in `migrate.py` | S | High |
| 3 | Truncation / length-ratio guard on LLM output | CoTran | Missing | S | High |
| 4 | Do not count "cannot drive signature" as equivalence | MatchFixAgent | Missing (default is pass) | S | High |
| 5 | Narrow the repair context to suspect function or lines | tHinter, ENCRUST | Missing | M | High |
| 6 | Hash dedup and per-source grouping before train/held-out split | ml-intern skill | Missing in split scripts | S | Medium-high |
| 7 | Source coverage under the verification inputs | tHinter | Partly (dataset builders only) | M | Medium |
| 8 | Single, shared output comparator | CoTran (matching) | Partly (four divergent comparators) | S | Medium |
| 9 | Per-gap fill and rollback in the never-refuse lift | ENCRUST | Missing | M-L | Medium |
| 10 | Graded compile score to rank candidates | CoTran | Missing | S | Low-medium |
| 11 | Per-domain auto-loaded knowledge files | PyMC | Partly, not wired into repair | M | Low-medium |
| 12 | Token and cost telemetry per unit | PyMC, Google | Missing (calls and wall-clock only) | S | Low-medium |
| 13 | Batch-compile N candidates in one call | CoTran | Missing | S-M | Low |
| 14 | TransCoder GfG eval set | CoTran repo | Not present; licence is a blocker | S | Low |

## Per-idea notes

### 1. Behavioural verifier as default gate, with counterexample feedback

What the sources say: Flourine uses differential fuzzing as an I/O oracle and feeds
counterexamples back to the LLM. tHinter and MatchFixAgent also use differential
testing. CoTran uses symbolic-execution-derived tests.

Repo:
- Have: `src/transpilers/verify/behavioral.py` runs the Python source as oracle,
  replays seeded edge-case plus fuzz inputs on the target (Python or Rust only),
  and `make_behavioral_verifier` (line ~807) turns the first divergence into a
  `run_mismatch` signal with input, expected and actual
  (`repair/signal.py:130-155`). The prompt template has a "Diverging run" block
  (`llm/prompts/repair_with_signal.md`).
- Gap: `escalating_repair` defaults to `_wrap_legacy_verifier` (compile only,
  `repair/loop.py:110-137`, `424-425`). The behavioural verifier is exercised in
  tests but I found no production caller. The oracle is Python-source only
  (`behavioral.py`, `check_behavioral_equivalence`: any other `source_lang` returns
  unsupported) and the target runners are Python and Rust only (`_RUNNERS`, line 628).
  C++ oracles exist only in dataset scripts (`scripts/build_cpp_mojo_dataset.py`).
- Only the first divergence is returned, not a small set of distinct ones.
- Also: `repair/__init__.py:10-12` says a `--escalating-repair` CLI flag and a
  `/transpile/escalating-repair` endpoint wrap the loop. A grep for "escalating" in
  `src/transpilers/cli` and `src/transpilers/api` returns nothing; the API exposes
  only the legacy `/transpile/repair` (`api/server.py:215`). The docstring appears stale.

Suggested next step: a `verifier=` choice at the call site that composes compile then
behavioural; return up to N diverging inputs; fix or remove the stale docstring.

### 2. Best-attempt retention, rollback and a baseline-aware gate

ENCRUST (abstract only) rolls back failed per-function translations and gates the
agentic refinement stage on a baseline-aware verification check.

Repo:
- Gap: `repair/loop.py:528` is `current_code = fix_applied or current_code`: the
  latest model output always replaces the previous one, even if it fails an earlier
  gate that the previous attempt passed. On exhaustion the loop returns the *last*
  code, not the best (`loop.py:581-589`). An empty response silently re-verifies the
  old code and burns an attempt.
- Have (elsewhere): `scripts/sft/migrate.py` generates K candidates and accepts the
  first that verifies against the C++ reference, so nothing failing the gate is
  accepted (module docstring, lines 1-11). The stateless driver is all-or-nothing
  per file when chunking (`stateless transpilation/2_transpile.py:211-214`).
  `scripts/escalating_repair_bench.py` compares one-shot against the loop, which is
  a corpus-level baseline comparison, not a per-unit gate.

Suggested next step: track a "best so far" by gate depth reached (parse, compile,
behavioural pass-rate), revert to it when a retry regresses, and refuse rather than
return a worse result. Keep the existing refusal semantics.

### 3. Truncation and length-ratio guard

CoTran multiplies its reward by a Gaussian length-ratio penalty to discourage
truncated or padded output (as the caller reported from its reward code).

Repo:
- Gap: no length or ratio check anywhere in `repair/` or `verify/` (grep for
  "ratio"/"truncat" finds only unrelated hits).
- Related risk, verified: `llm/client.py:201` (OpenAI-compatible) and `:230`
  (Anthropic) hard-code `max_tokens=1024`, and the loop's `_call_llm`
  (`loop.py:365-377`) goes through that path. A whole-file rewrite longer than that
  budget would be cut off. Whether that has happened in practice I have not checked;
  a truncated file often fails compile, but not always (e.g. a cut at a function
  boundary in Python still compiles).

Suggested next step: make `max_tokens` configurable per call; reject a repair whose
length ratio to the previous attempt is outside a band (rather than adopting CoTran's
exact Gaussian, which was designed for RL reward shaping, not gating).

### 4. "Unsupported" is not "equivalent"

MatchFixAgent warns that existing test suites cause false equivalence claims, and
reports verdicts rather than silent passes.

Repo:
- Gap: `behavioral.py:845` returns `VerificationOutcome(ok=not require_supported, ...)`,
  so by default an undrivable signature passes the gate. The docstring justifies this
  ("not evidence of a bug"), which is reasonable for a gate but misleading for a
  reported pass rate.
- Have: `BehavioralReport` carries `supported` and `reason`, and `scripts/behavioral_sweep.py`
  prints the supported/unsupported split ("so coverage is honest", line 19).
- Suggested next step: a tri-state outcome (verified / refuted / unverified) in
  `VerificationOutcome`, with `unverified` recorded in `RepairOutcome` instead of
  being counted as a pass.

### 5. Narrow the repair context

tHinter (abstract): fuzzing, differential testing and a coverage heuristic flag
suspect lines; reports 71% fewer lines to review and 59% higher chance the LLM fixes
in one query (abstract does not say whether 59% is relative or absolute). ENCRUST
gives the LLM a narrow per-function prompt.

Repo:
- Gap: `_render_prompt` (`loop.py:154-199`) always substitutes the whole `source_code`
  and whole `broken_code`. The compile signal is one line: `classify_compile_stderr`
  (`verify/taxonomy.py:148-167`) keeps the first stderr line containing "error", and
  drops file/line/column. `python_compiles` puts `lineno` only inside the message string
  (`verify/python.py`). The behavioural signal names an input but not a function or line.
- Partly there: `ir/provenance.py` maps LIR nodes to HIR nodes with a source span and
  `--provenance` writes a sidecar (`cli/main.py:235-240, 464-475`), and its docstring
  says it enables "targeted repair". Nothing in `repair/` consumes it, and it maps nodes,
  not emitted target line numbers, so mapping a compiler line back to a source
  function would need new work.
- Have: unit granularity exists upstream (`levels.py` object level; `lift.py` emits one
  `def` per function), so a per-function repair prompt is structurally possible.

Suggested next step: parse the compiler's line number, find the enclosing target
function, and send only that function plus its source counterpart and callee
signatures. Measure on the existing corpus before claiming a benefit; the 71% and 59%
figures are for Java/C++/Python-style work in a different setup.

### 6. Dedup by hash, and group by source, before splitting

The local `ml-intern` skill's one relevant rule is to deduplicate by hash before the
train/test split.

Repo:
- Gap: `scripts/sft/build_codepivot_split.py` sorts by `function_name` and holds out
  every 4th item (`HOLDOUT_EVERY = 4`, line 31; sort at 120, test at 122). There is no
  content-hash step. `scripts/sft/assemble_131.py` dedups scalar pairs by name only
  (`setdefault`, lines 95-101), splits `i%4` and `i%3` (107, 117), and adds a
  name-based leakage guard (118-124).
- Have elsewhere: sha256 fingerprints in `scripts/crawl_github.py:1059-1062`; sha256 file
  dedup for the Mojo corpus (`data/dedup_corpus.py`); exact `(source, fixed_code)`
  dedup for flywheel records (`repair/flywheel.py:157`); token-Jaccard near-dup
  removal (`scripts/sft/dedup_dataset.py`, `build_frozen_benchmark.py`) and a post-hoc
  leakage measure (`scripts/sft/leakage_check.py`). None of these runs *before* the
  CodePivot split.
- I measured the working-tree data (read-only, whitespace-normalised sha256 of
  `cpp_source` / `input`): no exact duplicates in `data/cpp_mojo_pairs.jsonl` (98) or
  `data/sft/cpp_python_pairs.jsonl` (39), so hash dedup would currently be a no-op.
  However, the two lists are split independently, and by replaying the every-4th rule
  I count 7 functions held out for Mojo that are in the Python training set, and 6 the
  other way round. Whether that matters depends on whether one model sees both training
  sets; I did not check. Counts are approximate because a held-out candidate that fails
  oracle generation falls back into training (`build_codepivot_split.py:121-128`).

Suggested next step: group by C++ source hash, assign each group wholly to train or
held-out across *all* targets, then run `leakage_check.py` as an assertion.

### 7. Source coverage under the verification inputs

tHinter uses a coverage heuristic to localise suspect lines.

Repo:
- Have (dataset builders): `scripts/build_cpp_mojo_dataset.py` builds a threshold-aware
  input sampler (`_sample_inputs`, line 344) and a gcov gate (`_coverage_ok`, line 426)
  that rejects a pair if any computational line of the C++ body went unexercised.
  `scripts/sft/build_cpp_python_dataset.py` reuses it (lines 49-56, records
  `branch_coverage`).
- Gap: `verify/behavioral.py` records no coverage of the source under its inputs. Its
  inputs are fixed edge cases plus seeded fuzz by type tag (`_EDGE_CASES`, line 246;
  `generate_inputs`, line 275), not driven by branch constants. A passing run says
  nothing about unexercised branches. `passes/trace_types.py` uses `sys.settrace` for
  types only.
- Suggested next step: record executed lines of the Python oracle (`sys.settrace` or
  `coverage`), report "x of y lines exercised" in `BehavioralReport`, and reuse the
  constant-seeded sampling idea from `_sample_inputs`. Uncovered lines then also serve
  as a localiser for item 5.

### 8. One output comparator

CoTran's matching ignores case and whitespace and reduces numbers to a common form
(as reported). That is looser than this repo should be by default.

Repo (four comparators, verified):
- `verify/behavioral.py`: type-keyed canonical tokens (`canonical_token`, line 304):
  bool spellings normalised, floats to 6 dp with absolute tolerance 1e-6, ints exact,
  strings exact (case- and whitespace-sensitive). Inputs: edge cases plus seeded fuzz
  (items above).
- `verify/taxonomy.py:170-185` `classify_run`: `strip()` then exact; reports first
  differing line. `scripts/run_matrix.py:159` is also strip-only.
- `scripts/sft/py_verify.py:50-70`: token-wise, strips brackets and commas, bool to 1/0
  (case-insensitive), relative tolerance 1e-6.
- `scripts/sft/diff_verify.py:59-70`: relative tolerance 1e-6 else exact string.
- `scripts/build_cpp_mojo_dataset.py` uses 1e-9 relative error (docstring of `verify`).
- Note the mixed absolute vs relative tolerances; large-magnitude values compare very
  differently under them.
- Suggested next step: one `compare_outputs(expected, actual, mode)` helper with
  explicit modes (`exact`, `numeric`, `lenient`), used by all of the above. Keep
  case-insensitive string matching opt-in; it would hide real defects.

### 9. Per-gap fill and rollback in `lift.py`

ENCRUST wraps each function so an LLM translation can be dropped without damaging the
rest, then removes the wrappers deterministically.

Repo:
- Have: `lift.py` emits one `def` per function (`_Lifter.function`, line 938) and
  replaces unhandled nodes with `pass  # TODO[lift]: ...` statements or a
  `__todo__("...")` sentinel call that raises `NotImplementedError` (`todo_expr`,
  line 442; `_todo_stmt`, line 912). `scripts/ep_todo_cats.py` buckets the stubs.
- Gap: the lifter keeps only global counters (`_Lifter.nodes/todo`, returned by
  `_emit` as `{"nodes", "todo"}`), no per-function stub list; there is no LLM call,
  no gap-filling API and no per-function verify-and-revert. Stubs are inline strings,
  so a filler would have to re-parse the output to find them.
- Suggested next step: have `_emit` return per-function records (name, source
  extent, stub count, stub snippets). A filler would then substitute one function at a
  time, run `python_compiles` plus the behavioural check, and revert on failure,
  mirroring item 2. This is the most natural home for ENCRUST's idea here; the
  `# TODO[lift]` count also gives a ready-made work queue.

### 10. Graded compile score

CoTran's compile reward is `first_error_line / (n_lines + 1)`, or 2.0 if clean (as
reported). This repo does no RL, so the only use is *ranking* candidates in a best-of-K
or best-attempt scheme (item 2).

Repo: gap. `CompileResult` is `ok` plus `stderr` only. Note that gcc and rustc report
many errors but `classify_compile_stderr` keeps one. A cheap score would be
"errors counted" or "first error line fraction"; either needs the line parsing from
item 5.

### 11. Domain knowledge as auto-loaded files

PyMC loads per-model-type markdown skills automatically.

Repo (verified):
- `src/transpilers/cli/domain_prompts.py`: regex-detected gtest and Eigen guidance
  strings, opt-in (`--domain-prompts`, `cli/transpile.py:159-160`), used only by the
  per-file Mojo driver. Not read by `repair/loop.py`, and held as Python strings, not
  files.
- `src/transpilers/stdlib_maps/`: data tables (`auto_generated.yaml`, 67 lines,
  `python_to_rust.toml` is a stub with commented example). `load_stdlib_maps` has no
  caller under `src/`; `hir_to_mir.py:530` and `infer_types.py:441` only mention it as
  a future home. So the README claim that promoted answers "bend the system" is
  implemented on the write side (`scripts/sft/promote_repair.py`, `flywheel_run.py`)
  but not on the read side that I could find.
- `src/transpilers/rag/zim_rag.py`: offline docs lookup keyed on a hard-coded hint
  table; used by `scripts/gen_stdlib_maps.py` only. `scripts/rag/*` plus
  `scripts/sft/few_shot.py` (TF-IDF retrieval of verified pairs) feed
  `scripts/sft/migrate.py`, not the engine or loop.
- Not equivalent to PyMC's skills: those are curated per-domain instructions the agent
  always sees; here retrieval is by API name or similarity.
- Suggested next step: low priority until item 1 and 5 land; then inject matching
  `domain_prompts` text and any `stdlib_maps` hits into the repair prompt.

### 12. Token and cost telemetry

PyMC reports cost per model and notes a 200K-context overflow on a 3,000+ parameter
model. Repo: `RepairOutcome` records `n_llm_calls`, `n_repair_passes`, `wallclock_ms`
(`repair/outcomes.py:102-105`) but not tokens or cost, and neither client path reads
usage from the response (`llm/client.py`). Cheap to add, and needed to substantiate
cost claims in `docs/cost_analysis.md`-style documents.

### 13. Batch compile

CoTran compiles N candidates in one `javac` / `compileall` call. Repo: each verifier
writes a temp file and invokes the compiler once per candidate (`verify/rust.py`,
`verify/python.py` uses in-process `compile()`). Python needs no batching. For rustc,
mojo and gcc it only pays off if best-of-K sweeps become routine; defer.

### 14. TransCoder GeeksforGeeks eval set

Not in the repo (grep finds TransCoder only in docs and `benchmarks/*.md`). The repo
has its own 40-task benchmark (`benchmarks/`, `scripts/sft/eval_transbench.py`).
Licence: see below; treat as blocked pending a decision.

## Do not adopt

- **CoTran code and data.** The GitHub API returns no licence for
  `prithwishjana/cotran`, so default copyright applies. Borrow ideas only.
- **CoTran's Symflower reward path.** Symflower is proprietary, and
  `calculateRuntimeRewardSF` looked unfinished to the caller (iterates strings as
  `(index, code)` tuples; computes `numSucc/numSucc`). The repo already has a bounded
  z3 equivalence check for pure functions (`verify/smt.py:195`, `smt_verify`).
- **CoTran's `classify_errors.py`.** javac and Python bucket tables; this repo targets
  Rust, C, Mojo, Python and Fortran and already has `verify/taxonomy.py`.
- **CodeBLEU, ANTLR and tree-sitter material.** Frontends already use tree-sitter and
  libclang (`pyproject.toml`); CodeBLEU does not measure behaviour.
- **TransCoder GfG data, for now.** I read the first lines of the upstream
  `facebookresearch/TransCoder` `LICENSE` through the GitHub API on 2026-10-12: it is
  "Attribution-NonCommercial 4.0 International" (CC BY-NC 4.0), and GitHub reports it as
  "Other" (size 19,335 bytes). The copy of this evaluation data inside the CoTran repo
  (`CodeGen/data/transcoder_evaluation_gfg/LICENSE`, about 14 KB) is a different text:
  its header reads "Creative Commons Attribution-ShareAlike 2.0" (read through the
  GitHub API on 2026-10-12). I do not know why the two differ, and I did not confirm
  whether the evaluation data carries a separate licence of its own. Given
  `docs/monetization_strategy.md` (a hosted, pay-per-use product) and the repo's own
  all-rights-reserved `LICENSE`, do not train on it or ship it; whether internal,
  evaluation-only use is acceptable is a question for whoever owns licensing, not
  something this note settles.
- **The no-IR agent approach (PyMC).** It works there because a perfect reference
  oracle (PyTensor logp plus gradients) exists in a narrow domain, and it still has
  limits: a single-point spot check, a context overflow on a very large model, and
  speedups the authors' own reviewer attributes partly to a baseline gap. This repo
  makes cross-language guarantees via the typed IR (README rules 1-3); dropping it
  would give up determinism and traceability for no oracle in return.
- **RL fine-tuning of the translator.** CoTran's training route needs a large parallel
  corpus; this repo's fine-tuning is SFT on verified pairs and its repair loop is
  prompt-time. The ideas above take CoTran's *signals*, not its training.
- **Google's migration study.** Version and framework migrations, not cross-language
  translation; background only. Its "50% time saving" is the developers' own estimate.

## Medium article: practical nugget

Claude failed to write a grammar from scratch but succeeded when modifying an existing
Python grammar. Relevance here is small: every current frontend uses tree-sitter
grammars or libclang (`frontends/_treesitter.py`, `pyproject.toml`), so no grammar is
hand-written. If a language without a tree-sitter grammar is ever added, start from the
nearest existing grammar. The article's central argument (parser/AST pipelines with LLM
assistance beat LLM-only for determinism and traceability) matches README rules 1-3 and
changes nothing.

## Confidence and limits

- **Repo findings** are from reading the files cited, plus one read-only script over
  two data files (item 6). I did not run the test suite or any verifier. Line numbers
  were taken at this commit (`8c9607e`).
- **Read in full (by the caller):** the PyMC Labs post and the Medium article. Figures
  from them (cost per model, up to ~484K tokens, 3.3x-6.8x speedups, 104 of 120
  posteriordb models, criteria for "validated" not stated on the page) are the authors'.
- **Abstract only:** tHinter (arXiv 2501.09475), Flourine (2405.11514), ENCRUST
  (2604.04527), MatchFixAgent (ICML 2026 poster 64503), and Google's Ziftci et al.
  (2504.09691). Nothing here goes beyond what an abstract supports. Reported figures
  (tHinter 71% / 59%; Flourine 47% best-LLM with benchmark size unstated; MatchFixAgent
  99.2% verdicts and 50.6% vs 18.5% repaired; Google 74.45% LLM-generated of 595 changes)
  are the authors' and unreplicated. ENCRUST's abstract gives no numbers.
- **CoTran** repo details (reward formulae, batching, matching, Symflower code) come
  from the caller's earlier inspection of its code and were not re-read by me. The
  CoTran paper's reported results are already summarised in
  `docs/transpilation-methods-research.md`; I have not repeated them.
- **Not reviewed:** SACTOR, VERT, CINDER, SEDCoT, LAC2R, Airbnb's Enzyme-to-RTL
  migration, Amazon MigrationBench. They appeared only in search summaries.
- **Assumptions:** that effort estimates are rough; that the per-idea benefit is
  unproven on this corpus (none of the cited results was obtained on EnergyPlus or this
  repo's targets); that "no caller found" means no match by grep in the working tree,
  excluding `.venv` and `.claude/worktrees`.
- **Not legal advice:** the licence observations are factual readings of headers and
  API output only.

## Sources

- CoTran: https://github.com/prithwishjana/cotran ; paper https://arxiv.org/abs/2306.06755
- PyMC Labs, LLM transpiler (PyMC to Rust): https://www.pymc-labs.com/blog-posts/llm-transpiler-pymc-to-rust
- M. Choudhury, "Ideas for LLM-driven code migration" (27 Mar 2026):
  https://medium.com/@monojitchoudhury/ideas-for-llm-driven-code-migration-0455faa7a070
- tHinter: https://arxiv.org/abs/2501.09475
- Flourine: https://arxiv.org/abs/2405.11514
- ENCRUST: https://arxiv.org/abs/2604.04527
- MatchFixAgent: https://icml.cc/virtual/2026/poster/64503
- Ziftci et al., Migrating Code at Scale with LLMs: https://arxiv.org/abs/2504.09691
- TransCoder (licence check): https://github.com/facebookresearch/TransCoder
- Local: `C:\Github\skills_and_artifacts\skills\ml-intern\SKILL.md` (training policy;
  only the dedup-before-split rule is relevant)
