# Migration status report

`scripts/migration_status.py` compares an upstream ("before") repository with
its port ("after") and reports lines of code on both sides, file/function
counts, the migration-map status and test results, optionally across two git
revisions of the port so progress over time is visible.

Standard library only, Python >= 3.10. It runs under `uv run` on Windows and
under the system `python3` inside WSL.

## Subcommands

| Command | Purpose |
|---|---|
| `snapshot` | Metrics for ONE repo or revision as versioned JSON (`schema_version`). |
| `report` | Markdown from one snapshot, a source/target(/baseline) set, or a `--before`/`--after` pair with deltas. |
| `compare` | `snapshot` of source and target (plus a baseline revision of the target) and `report` in one go. |

Run `python scripts/migration_status.py <command> --help` for every option.

## What is measured, and how reliable it is

* **LOC** (code / comment / blank) from a small per-language scanner. It is
  approximate. Spot checks: on EnergyPlus `src/EnergyPlus` the C/C++ code-line
  total was within 0.1 % of tokei (618,720 vs 619,367). tokei counts Python
  docstrings as code, this tool counts triple-quoted strings that start a line
  as comments, so Python and Mojo "code" figures are lower than tokei's.
* **Production vs test** is decided by path convention only (`tests/`, `tst/`,
  `test_*`, `*_test.*`, ...). `scripts/diff_test.py`-style names are classed as test.
* **Functions/classes**: Python via `ast`; Mojo and C/C++ via heuristics (marked `~`
  in the report). C/C++ was spot-checked against libclang 13 on a random sample
  of EnergyPlus files (24 `.cc` and 40 `.hh` for the early version, 60 `.cc`
  after fixes): functions agreed to within about 1 %, classes matched on the
  header sample. Code under `#else` branches is not counted, so it can differ
  from a real compiler on conditionally compiled code.
* **Declared test functions** is a static count (no parametrisation); the number
  of tests pytest collects is higher.
* **Test results** appear only if you pass `--tests` (run) or `--collect`
  (count only). A pass count is never reported when the command timed out or
  ended before a summary: it is shown as unknown with the reason. Counts come
  from `--junitxml` (injected through `PYTEST_ADDOPTS`, which also works through
  `pixi run`/`just`), falling back to the summary line.
* **Migration map**: `| Upstream File | Status | ... |` tables, joined to upstream
  files by file stem. Files with no row are reported as UNMAPPED. Statuses are
  taken as written by the port's authors, not verified.
* **Baseline revision** (`--baseline-rev REV` or `--baseline-before DATE`):
  static metrics only, from a `git archive` stream extracted into a temporary
  directory (deleted afterwards; the real worktree is never touched). The
  current target is then measured over git-tracked files only so both sides are
  comparable. Tests at the baseline run only with `--baseline-run-tests` and are
  flagged in the report (a clean export has no built artefacts).

## EnergyPlus -> EnergyPlusMojo

Machine layout used when this was written: the working clone of the port is in
WSL (distro `Ubuntu`, user `root`, `/root/epm`, with a pixi env and built
`build/kernels/*.so`); the C++ source is `/root/EnergyPlus`. Scope choices:

* before: `src/EnergyPlus` (the simulation engine) as production code and
  `tst/EnergyPlus` as test code; `third_party/` and the rest of the repo are out of scope.
* after: `src` (minus vendored `src/emberjson`), `spike`, `tests`. `scripts/`
  (development tooling), `third_party/`, `tst/` and `oracle/` are out of scope.

Full report, run inside WSL (the script is reachable through `/mnt/c`; adjust
`W` to your checkout of this repo). The test commands mirror `pixi run test`
(`pytest tests/unit -q`) using the pixi env's python directly:

```bash
W=/mnt/c/Github/transpilers   # this repo, as seen from WSL
cd /root/epm
PY='PYTHONPATH=/root/epm/src PATH=/root/epm/.pixi/envs/default/bin:$PATH python -m pytest'
PYTHONDONTWRITEBYTECODE=1 python3 $W/scripts/migration_status.py compare \
  --source /root/EnergyPlus --source-label EnergyPlus \
  --source-include src/EnergyPlus --source-include tst/EnergyPlus \
  --target /root/epm --target-label EnergyPlusMojo \
  --target-include src --target-include spike --target-include tests \
  --target-exclude src/emberjson \
  --baseline-before 2026-09-09 \
  --target-tests "golden=$PY tests/golden -q" \
  --target-tests "kernels=$PY tests/kernels -q" \
  --target-tests "unit=$PY tests/unit -q" \
  --timeout 10800 \
  --save-snapshots $W/reports/migration_status_energyplusmojo \
  --out $W/reports/migration_status_energyplusmojo.md
```

The migration map is auto-detected at `.migration_progress/MIGRATION_MAP.md` in
the target (override with `--map`). Quick, non-executing variant: replace each
`--target-tests` with `--target-collect`, or add `--collect-only`.

From Windows, the same tool can drive WSL for the test commands only
(`--target-wsl Ubuntu:root`); the cwd is translated (`C:\x` -> `/mnt/c/x`,
`\\wsl$\Ubuntu\root\epm` -> `/root/epm`) and the command runs under GNU
`timeout` inside the distro so a timed-out run does not linger. Static scanning
still reads `--source`/`--target` from the OS the tool runs on, so prefer running
the whole tool in WSL as above.

Snapshots (`reports/*.json`) are stable, versioned JSON and can be stored over
time and compared later without re-running anything:

```bash
python scripts/migration_status.py report --before reports/old/target.json --after reports/new/target.json
```

## Known limitations

* LOC and symbol counts are heuristic (see above); C/C++ raw strings,
  line-continued `//` comments and macro-generated code are not handled.
* Map join is by file stem, so same-stem files in different directories share
  one row's status, and a stem missing from the map is "unmapped", not
  necessarily "not started".
* Tests: pytest only (the summary parsers are pytest-specific); the C++ side's
  gtest suite is only counted statically, never built or run.
* Baseline tests run in a git export without untracked/built files.
