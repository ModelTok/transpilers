# Data flywheel (issue #51)

This document describes the **closed data flywheel**: how every
behaviorally-verified repair is promoted back into the algorithmic side of
the transpiler, so that each run lowers the system's LLM dependence.

## What "closed loop" means here

The flywheel has three steps and a single north-star metric.

```
   ┌──────────────────┐     ┌──────────────────────┐     ┌──────────────────┐
   │  1. Harvest +    │     │  2. Promote verified  │     │  3. Refresh the  │
   │  verify (crawl,  │ ──> │  repairs back into   │ ──> │  metrics file    │
   │  batch_repair)   │     │  stdlib_maps + SFT    │     │  (trend line)    │
   └──────────────────┘     └──────────────────────┘     └──────────────────┘
            │                          │                          │
            └──── every unit lands a RepairOutcome in ─────────────┘
                          data/repair_outcomes.jsonl
```

* **Step 1** — `scripts/crawl_github.py` (or `scripts/batch_repair.py`)
  runs the transpiler on a unit, verifies it, and emits **one
  `RepairOutcome`** per unit into `data/repair_outcomes.jsonl`. Each
  outcome records *who* fixed it: `algorithmic`, `rule`, `llm`, or
  `unrepaired`.
* **Step 2** — `scripts/sft/promote_repair.py` reads the outcome log and
  pipes verified repairs back into:
  * `src/transpilers/stdlib_maps/auto_generated.yaml` — new
    `std::X` -> target-API mappings harvested from **frontier-only**
    repairs (the LLM was the only thing that got the unit to pass).
  * `data/sft/flywheel_pairs.jsonl` — Alpaca-schema training records
    for SFT. Frontier-only repairs get mix weight 4; llm-with-rule
    weight 3; rule-only weight 2; algorithmic weight 1. *Higher mix
    weight = more in-batch oversampling on the next LLaMA-Factory run.*
* **Step 3** — `scripts/sft/flywheel_metrics.py` re-aggregates the log
  and writes `data/flywheel_metrics.json` plus
  `docs/flywheel_metrics.md`. The trend line in those files is the loop's
  own self-monitoring.

The full loop is wrapped in `scripts/sft/flywheel_run.py`; one CLI
command runs all three steps. Issue #51's acceptance criterion
("documented loop where each run lowers LLM dependence") is met by that
script + this document.

### The live repair loop also feeds the log

Step 1 is not limited to the batch corpus scripts. The
verification-driven repair loop (`transpilers.repair.escalating_repair`,
issue #47) emits its own `RepairOutcome` per unit when given a
`RepairTracker`:

```python
from transpilers.repair import RepairTracker, escalating_repair

tracker = RepairTracker()  # → data/repair_outcomes.jsonl
escalating_repair(src, source_lang="cpp", target="mojo",
                  tiered_client=client, tracker=tracker)
```

The loop derives the verdict from the path the unit took: an attempt-1
pass (no LLM) is `algorithmic`; a pass on a later attempt is `llm`
(carrying `n_llm_calls`); budget exhaustion is `unrepaired`. The loop
does not apply deterministic rule patches itself, so it never emits the
`rule` verdict — that comes from `scripts/sft/mojo_repair` in the batch
path. If no tracker is passed, setting `$TRANSPILER_REPAIR_OUTCOMES_PATH`
opts the loop in against that log (mirrors `$TRANSPILER_FLYWHEEL_PATH`).

## The north-star metric

For every unit the pipeline produces one of four **verdicts**:

| Verdict | Meaning | LLM cost |
|---|---|---|
| `algorithmic` | The transpiler's staged pipeline emitted compile-clean code with **no** LLM call | 0 |
| `rule` | A deterministic rule (e.g. `scripts/sft/mojo_repair.py`) patched a mechanical defect | 0 |
| `llm` | An LLM (Claude / Qwen / etc.) was invoked to repair or fill a type hole | ≥ 1 |
| `unrepaired` | Even after repair attempts, the unit does not pass | (counted) |

The headline metric is the **LLM fraction**, the share of *passing* units
that needed an LLM:

```
llm_fraction = count(verdict == "llm") / count(verdict in {algorithmic, rule, llm})
```

A healthy flywheel lowers `llm_fraction` over time: as frontier-only
repairs are promoted into `stdlib_maps/` and the SFT corpus, more
constructs become handleable by the algorithmic emitter or the rule
patcher, so the LLM call count falls.

## Priority for promotion

The acceptance criterion says "prioritize cases only frontier+repair
could solve". Concretely, `promote_repair.py` sorts outcomes as:

1. **Frontier-only** (`verdict == "llm"` and `n_rule_passes == 0`) — the
   LLM was the only thing that got the unit to pass. *Highest value.*
2. LLM-with-rule-help (`verdict == "llm"` and `n_rule_passes > 0`) —
   the LLM did most of the work, but a rule also helped.
3. Rule-only (`verdict == "rule"`) — a deterministic rule fixed it.
4. Algorithmic (`verdict == "algorithmic"`) — the staged pipeline
   emitted it cold. Useful for corpus balance, but already cheap.

Frontier-only units are the ones we teach the algorithmic side next;
their SFT pairs get mix weight 4 (vs the typical 1-2 for normal SFT
pairs). stdlib_maps only accepts entries from frontier-only outcomes
so a bad rule never seeds a wrong mapping.

## Worked example

A run from a fresh checkout, with no `data/repair_outcomes.jsonl`:

```sh
$ uv run python scripts/sft/flywheel_metrics.py
================================================================
  Data Flywheel - algorithmic-vs-LLM ratio (issue #51)
================================================================

  Total outcomes       : 0
  Passed               : 0

  (no outcomes yet - run scripts/batch_repair.py or
   scripts/crawl_github.py to start populating the log)
```

After seeding three synthetic outcomes (one algorithmic, one rule, one
LLM-only frontier) and running `flywheel_run.py --skip-crawl`:

```
[flywheel] pass done in 0.43s  llm_frac=33.3%  alg_frac=66.7%  frontier_only=1
```

The frontier-only outcome promotes `std::pow` -> `math.pow` into
`src/transpilers/stdlib_maps/auto_generated.yaml`:

```yaml
cpp_to_mojo:
  "std::pow": ["math.pow"]   # flywheel-promoted (was empty)
  "std::vector": ["List[T]"]
```

Next run, the staged pipeline uses this mapping and emits
`math.pow(...)` for `std::pow(x, y)` *without* asking the LLM. The
verdict for the same source flips from `llm` to `algorithmic` and the
`llm_fraction` falls by one bin on the next metrics rollup.

## Files added by this issue

| Path | Purpose |
|---|---|
| `src/transpilers/repair/outcomes.py` | `RepairOutcome` dataclass + `RepairTracker` JSONL log + ratio aggregator |
| `scripts/sft/promote_repair.py` | Pipe verified repairs into `stdlib_maps/` and the SFT corpus |
| `scripts/sft/flywheel_metrics.py` | Text + markdown report; refreshes `data/flywheel_metrics.json` |
| `scripts/sft/flywheel_run.py` | One-command orchestrator: crawl -> promote -> metrics |
| `tests/test_repair_outcomes.py` | Tracker + verdict coercion tests |
| `tests/test_promote_repair.py` | YAML roundtrip + idempotency + priority tests |
| `tests/test_flywheel_metrics.py` | Trend-arrow + markdown rendering tests |
| `tests/test_flywheel_run.py` | End-to-end skip-crawl pass + CLI smoke |
| `docs/data_flywheel.md` | This document |
| `data/repair_outcomes.jsonl` | Append-only outcome log (gitignored) |
| `data/flywheel_metrics.json` | Snapshot of the latest ratio + trend (gitignored) |
| `docs/flywheel_metrics.md` | Auto-rendered markdown rollup of the metrics |

## Operations

### One-shot

```sh
# Refresh metrics from the current log, no new crawl, no promotion
uv run python scripts/sft/flywheel_metrics.py

# Promote everything in the log + refresh metrics
uv run python scripts/sft/promote_repair.py --refresh-metrics

# Full closed loop (requires GITHUB_TOKEN)
uv run python scripts/sft/flywheel_run.py --source cpp --targets mojo rust
```

### Cron / continuous

The crawler supports `--continuous`; the orchestrator supports
`--continuous --sleep N` to re-run the loop every N seconds. A
representative cron line:

```cron
# Every 6 hours: harvest 200 functions, promote, refresh metrics
0 */6 * * *  cd /path/to/transpilers && \
    GITHUB_TOKEN=... uv run python scripts/sft/flywheel_run.py \
        --source cpp --targets mojo --limit-fns 200
```

### Adding a new producer (other than GitHub crawl)

Anything that writes Alpaca-schema JSONL with a `metadata.fingerprint`
per record can be the *upstream* of the flywheel:

```json
{"instruction": "...", "output": "...", "metadata": {"fingerprint": "abc123"}}
```

The repair outcomes log is keyed on `(fingerprint, target)`, so
multi-source producers are fine.

## Why the metric falls over time

The transpiler is hybrid (algorithmic + LLM); the algorithmic side has
two growth surfaces:

1. **stdlib_maps** — every C++/Python API with a target-language
   equivalent can be looked up. The algorithmic emitter consults this
   table on every `std::X` call site. Each new entry eliminates one
   reason to invoke the LLM.
2. **SFT corpus** — every verified pair becomes a fine-tune example.
   Over time the model itself learns to map more constructs without an
   inline LLM call, so even unmodeled cases produce better first
   attempts (which the algorithmic pass often accepts).

The frontier-only filter keeps both surfaces clean: a unit only
contributes if no deterministic rule could have made it pass, so we
are only learning what truly required a frontier model.

## Limitations / known gaps

* The persistent log stores fingerprints and metadata, not the source
  code itself. The SFT-corpus promotion step accepts a `source_lookup`
  and `target_lookup` dict to fill in the bodies; when those are
  absent (e.g. for old log lines) the pair is silently skipped. A
  future iteration can hash-store the bodies alongside the log.
* `promote_stdlib_maps` uses a hand-rolled YAML parser matching the
  format `gen_stdlib_maps.py` writes. The file is small (<200 entries)
  so this is a deliberate trade for zero-dependency.
* The trend bins are fixed at 50 outcomes. With <50 outcomes you see
  one partial bin; with thousands you see many. Adjustable via
  `RepairTracker.aggregate(trend_window=...)` if needed.
* LLM calls in `crawl_github.py` are best-effort: missing toolchains
  fall back to `compile-only`, never to a silent pass. The
  `metadata.verification` field on each record reflects this.
