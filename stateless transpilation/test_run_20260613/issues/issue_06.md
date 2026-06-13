# Issue 06 — gtest-aware prompt for 270 tst/EnergyPlus unit-test failures

**Parent:** TEST RUN on ENERGYPOS — stateless 100% LLM transpilation (mother issue)

## TL;DR
The 270 unit-test files (`.unit.cc` in `tst/EnergyPlus/unit/`) failed with "no FILE block" because the LLM gets confused by the gtest macros (`TEST()`, `EXPECT_EQ()`, `ASSERT_TRUE()`, fixture classes). Add a domain-specific prompt preamble that explains the gtest→Mojo translation rules and how to emit the equivalent.

## Scope
- 252 `error: no FILE block` + 9 `error: compile` + 7 pending = 270 files in `tst/EnergyPlus/unit/`
- 8,439 LOC total in this family
- Includes huge files like `UnitarySystem.unit.cc` (27,721 LOC), `HVACVariableRefrigerantFlow.unit.cc` (27,163 LOC), `AirflowNetworkHVAC.unit.cc` (21,797 LOC) — for these, the chunked-transpile approach (issue 01) is also needed.

## Approach
1. Add a prompt section to `2_transpile.md` (or a new `tst_transpile.md`) that:
   - Maps `TEST(SuiteName, TestName)` → `def test_suite_name_test_name(state: EnergyPlusData):` (or a simpler function form).
   - Maps `EXPECT_EQ(a, b)` → `assert a == b, "..."`.
   - Maps `EXPECT_NEAR(a, b, tol)` → `assert abs(a - b) <= tol`.
   - Maps `EXPECT_TRUE(x)` / `EXPECT_FALSE(x)` → `assert x` / `assert not x`.
   - Maps `ASSERT_*` to `assert ..., "msg"` (always-assert, can raise).
   - Maps `class TestFixture : public Base { ... };` → a class with `__init__` setting up state.
   - Maps `SetUp()` / `TearDown()` → Mojo `__init__` / `__del__` or a `with`-block.
2. Provide one worked example in the prompt (a small `.unit.cc` → Mojo unit test).
3. Re-run with `--backend claude` on a 10-file sample to verify pass rate improves.
4. If pass rate improves, batch-run on the full 270.

## Acceptance
- Pass rate of the gtest-specific prompt is >60% on a 10-file sample (vs the 0% on the current generic prompt).
- At least 150+ of the 270 files produce parseable Mojo.

## Cost
- Per file: ~5K prompt + ~2K completion tokens → ~$0.005 (cheap) to $0.05 (expensive) per file.
- Total: ~$1.4–$14 for the 270 files.
