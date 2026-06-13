# Issue 07 — Eigen-aware prompt for 170 third_party/ssc thermal-system failures

**Parent:** TEST RUN on ENERGYPLUS — stateless 100% LLM transpilation (mother issue)

## TL;DR
The 170 files in `third_party/ssc/` (System Advisor Model — solar thermal + battery simulation) failed because the C++ uses Eigen heavily (dense linear algebra), and the LLM doesn't have a strong training signal for Eigen→Mojo. Add a domain-specific prompt that explains how to translate the common Eigen idioms (`MatrixXd`, `VectorXd`, `ArrayXXd`, `.block()`, `.col()`, `.row()`, `.array() * .array()`, `LP/mixed-integer programming`) to Mojo equivalents.

## Scope
- 158 `error: no FILE block` + 1 `error: compile` + 4 LLM errors + 7 pending = 170 files
- 6,595,454 prompt tokens + 2,606,959 completion tokens estimated
- Subdirs with most failures: `third_party/ssc/tcs/` (102 files, 0% done) and `third_party/ssc/test/` (55+27 = 82 files, 0% done)

## Approach
1. Add an Eigen→Mojo translation table to the prompt:
   - `MatrixXd`, `VectorXd`, `ArrayXXd` → `DTypePointer[DType.float64]` + a tiny linear-algebra helper struct (or a `numpy` call if Python interop is acceptable).
   - `m * v` (matrix-vector) → use Mojo's `matmul()` once you have the matrix as a flat buffer.
   - `m.array() * v.array()` (elementwise) → manual loop or `numpy.multiply`.
   - `m.block(i,j,p,q)`, `m.col(j)`, `m.row(i)` → slice or stride tricks.
   - `Eigen::LLT<MatrixXd> llt(A); llt.solve(b)` → either a call to LAPACK (`dsptrf` + `dsptrs`) or a Python `numpy.linalg.solve`.
2. Also handle the SAM-specific idioms: `sscapi_t`, `ssc_data_t`, the `compute` modules (`cmod_*`), and the TCS (trough collector system) state machine.
3. **Strongly consider** rejecting the entire `third_party/ssc/` subtree and replacing it with a Python `pysam` or `pvlib` shim. The 1.17M LOC of SSC is a maintenance burden and the user-facing APIs (PVWatts, solar position, etc.) already exist in Python.

## Acceptance
- Either: 100+ of the 170 SSC files produce parseable Mojo using the Eigen-aware prompt, **or** (recommended): flip the `decision` for `third_party/ssc/` to `replace` and use `pvlib` / `pysam`.

## Cost
- 170 files × ~50K prompt + ~20K completion = ~$5–$60 (cheap–expensive) for the full batch.
- The `replace` path is $0 but requires ~2-3 days of dev.
