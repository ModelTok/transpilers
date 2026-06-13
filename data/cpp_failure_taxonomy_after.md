# C++ ground-truth impact (issue #50)

Root: `examples/samples/C++`
Targets: rust, mojo

| source | target | before ok | after ok | Δok | before unresolved-symbol | after unresolved-symbol | Δunresolved-symbol | before unfilled-UnknownT-hole | after unfilled-UnknownT-hole | Δunfilled |
|---|---|---|---|---|---|---|---|---|---|---|
| cpp | mojo | 0 | 49 | +49 | 0 | 0 | 0 | 0 | 0 | 0 |
| cpp | rust | 21 | 49 | +28 | 1 | 0 | -1 | 2 | 0 | -2 |

**Acceptance signal for issue #50**: a *decrease* in the ``unresolved-symbol`` and ``unfilled-UnknownT-hole`` columns between ``before`` and ``after``. The other buckets are orthogonal to the ground-truth pass and may move up or down for unrelated reasons.

**Notes on the numbers**: a baseline of 0 in the ``unresolved-symbol`` or ``unfilled-UnknownT-hole`` columns for a particular (source, target) pair almost always means the baseline couldn't reach that stage of the pipeline at all (a parse refusal short-circuited the run). In that case the ``after`` count is a *new* class of failure revealed by the preprocessor, not a regression -- the test now exercises a code path that the baseline never could.
