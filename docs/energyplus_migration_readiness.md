# Transpilers — EnergyPlus migration readiness review (2026-06-21)

**Question:** is the transpiler ready, and could it carry **≥50%** of the
EnergyPlus → Mojo migration?

**Answer (two halves):** ready for its niche — **yes**; carries ≥50% — **no**.

Evidence base: the repo README, `docs/cpp_mojo_autoresearch.md` (2026-06-20),
the EnergyPlusMojo migration scoreboard (`scripts/migration_priority.json`,
20,121 functions), and a **live boundary check** run for this review
(transpiling one real stateful EP method, below).

---

## What the repo is (and it is genuinely good)

A hybrid algorithmic + LLM N-to-M source-to-source transpiler — 11 frontends,
7 targets — with a disciplined design:

- LLMs fill **typed holes** only (never free-form text); every call declares a
  response shape + validator.
- Every LLM output is **verified** (parse, compile, behavioral/tests).
- All LLM calls are **cached** by `hash(prompt+model+temperature)` → reproducible.
- Promoted answers land in `stdlib_maps/` as data, bending the system from
  LLM-heavy toward algorithmic-heavy over time.

Two engines matter for EnergyPlus:

| Engine | What | Real-EP result |
|--------|------|----------------|
| **Strict** (deterministic, GPU-free) | typed IR pipeline, refuses what it can't model | scalar leaves **111/111 (100%)**, closures 7/7, out-of-line member fns 7/10, STL vector/Dict/tuple/string-index end-to-end; `transbench` 22/40 |
| **Lift** (never-refuse) | whole-file C++→Python 1:1 with `# TODO[lift]` stubs | ~96% "mechanical" on EnergyPlus |

For the **scalar-leaf + simple-container kernel tier, the strict engine is
mature and production-quality** — 100% verified against the C++ reference,
deterministic, reproducible. If the goal is "generate and verify scalar
kernels," it is ready today.

---

## Why it cannot carry ≥50% — three independent reasons

### 1. Paradigm mismatch (the crux)

The EnergyPlusMojo migration is **spec-driven reimplementation + oracle
verification**, not transpilation. The Mojo kernels are reimplementations, not
C++ translations; the live port is Python + ~125 Mojo kernels, oracle-validated
on 607 IDFs, ~47% faster than C++.

The transpiler adds value precisely on the tier that is **already cheap** —
small scalar functions — and **cannot touch the expensive tier**: stateful
physics, the `EnergyPlusData` god-object data model, and the **4,421 functions
blocked** on it. Even where it succeeds, its output still needs the **same**
oracle-verification already paid by hand. So it helps least where the cost is.

### 2. The addressable set is <2% of the corpus

~111 verified scalar leaves (+7 member-fn closures) against **20,121 total**
functions → **under 1% verified-addressable today** (a rough independent scan
corroborates the order of magnitude). The autoresearch doc states it plainly:

> "the real frontier is non-scalar/stateful physics, not scalars"
>
> "The high-ROI deterministic-engine work is complete… per-iteration ROI is
> low. Next real levers are elsewhere."

Member-field access (`this->field`) is named as *"the next real blocker"*;
stateful classes and graph/pointer structs are *"unreachable."*

### 3. The two numbers that look like "yes" both fail on inspection

- **GPU model "72% diverse held-out"** (1.5B adapter; 88% on the scalar set, per
  the leakage-free frozen ruler — corrected from an earlier 51% figure on
  transpilers-agent's note) — this is *exec-match@1 on a curated diverse
  benchmark*, categorically easier than production EP (god-object methods,
  templates, stateful physics), and exec-match ≠ verified migration. It also
  cannot run in this environment (no CUDA). Even at face value,
  72%-on-a-benchmark ≠ 50%-of-the-EP-migration.
- **Lift "96% mechanical"** — the dangerous one: 96%-mechanical = a **skeleton
  with `# TODO[lift]` stubs**, and the stubs are *exactly where the semantic
  work lives*. It targets **Python, not Mojo**, and the lifted trees do not
  compile (~997 errors on the pure-Mojo scaffold). "96% of lines get some
  output" is not "96% migrated."

---

## Live boundary check (run for this review)

Extracted a real stateful method — `TermUnitSizingData::applyTermUnitSizingCoolFlow`
(reads `this->SpecDesCoolSATRatio`, `this->SpecDesSensCoolingFrac`,
`this->SpecMinOAFrac`) — and ran `transpile --source cpp --target mojo`:

```
[taxonomy] bucket=parse stage=transpile construct='libclang parse errors:'
UnsupportedConstruct: libclang parse errors:
  unknown type name 'Real64'
  use of undeclared identifier 'TermUnitSizingData'
```

It fails at the **parse stage** out of context — the documented member-field /
preamble-completeness blocker, confirmed **current, not stale**. (The bench
harness reaches 7/10 on such methods only by supplying type-preamble + struct
context; raw stateful methods need context the bulk migration does not trivially
provide, and the verification burden remains.)

---

## Bottom line

| | |
|---|---|
| **Ready for the scalar/container kernel tier?** | **Yes** — mature, 100%-verified, deterministic. Use it to generate + verify kernels. |
| **Ready to carry ≥50% of the EP migration?** | **No** — addressable set <2%; the 50% threshold *is* the non-scalar/stateful/god-object tier it explicitly cannot do; the better model is GPU-gated and benchmark-scoped. |

**Recommendation:** use it as an **accelerator for the scalar-kernel tier**
(feeding verified leaf kernels into the hybrid port), not as a migration engine.
The lever to move past ~2% is the one the doc names: model the
`this->field`/stateful tier (member access → added params; record/replay for
unported deps) — but that is a research effort. The **dominant migration path
remains spec-driven reimplementation + oracle verification**, which is what is
actually moving the EnergyPlusMojo port.
