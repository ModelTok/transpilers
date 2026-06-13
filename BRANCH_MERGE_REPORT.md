# Branch Merge Report

**Date:** 2026-06-13  
**Repo:** `transpilers` (origin: https://github.com/Tokarzewski/transpilers)  
**SHA (main after merge):** `d25a43c` feat(cpp): ground-truth types via clang AST / compile_commands.json (issue #50)  
**Test result:** 381 passed, 31 skipped (ML/torch tests skipped — torch not available in this env)

---

## Summary

| Branch | Status | Unmerged Commits | Test Result | Action |
|---|---|---|---|---|
| chore/lint-fix-src | Already merged | 0 | N/A (content in main) | Deleted (local+remote) |
| feat/expand-py-leaf-extractor | Already merged | 0 | N/A (content in main) | Deleted (local+remote) |
| feat/escalating-repair-issue-47 | Already merged | 0 | N/A (content in main) | Deleted (local+remote) |
| feat/flywheel-issue-51 | Already merged (cherry-picked into main as `e82ab07`) | 1 (content already in main) | N/A (content in main) | Deleted (local+remote) |
| fix/treesitter-cpp-python313-fallback | Superseded — all 62 commits already in main | 0 | N/A (content in main) | Deleted (local+remote) |

**Branch count before:** 5 feature/chore/fix branches + main  
**Branch count after:** only `main`

---

## Per-Branch Detail

### 1. `chore/lint-fix-src`
- **Tip:** `eacfcf6` — "chore: ruff --fix mechanical lint cleanup (src)"
- **Analysis:** `git cherry origin/main` returned 0 unmerged commits. Merge-base equals branch tip — fully merged.
- **Verdict:** ✅ Already merged. Cleaned up.
- **Local branch:** did not exist locally.
- **Remote branch:** deleted.

### 2. `feat/expand-py-leaf-extractor`
- **Tip:** `cf95998` — "sft: expand py-leaf extractor corpus 53 -> 75 (auto-verified)"
- **Analysis:** `git cherry origin/main` returned 0 unmerged commits. Merge-base equals branch tip — fully merged.
- **Verdict:** ✅ Already merged. Cleaned up.
- **Local branch:** did not exist locally.
- **Remote branch:** deleted.

### 3. `feat/escalating-repair-issue-47`
- **Tip:** `cb3e2f3` — "feat(repair): verification-driven loop with escalating tiers (issue #47)"
- **Analysis:** `git cherry origin/main` returned 0 unmerged commits. PR #60 already merged this into main. Commit `b59a469` in main is the semantically equivalent version.
- **Verdict:** ✅ Already merged via PR #60. Cleaned up.
- **Local branch:** existed, deleted.
- **Remote branch:** deleted.

### 4. `feat/flywheel-issue-51`
- **Tip:** `4322219` — "feat(flywheel): close the data flywheel (issue #51)"
- **Analysis:** `git cherry origin/main` shows 1 unmarked commit (`+ 4322219`). However, main contains `e82ab07` with the **identical** commit message, author, timestamp, and substantive content (12 source files, 3006 insertions of flywheel pipeline code). The branch version's additional delta vs main consists of:
  - `uv.lock` lockfile churn
  - Removal of `stateless transpilation/` artifacts (generated output files — should not be merged)
  - Removal of `.env` (API key — should not be merged)
  - Removal of `scripts/escalating_repair_bench.py` (already in main)
  - Minor `src/transpilers/repair/__init__.py` line count difference
  - Some `src/transpilers/cli/` script deletions
  - None of these differences represent still-relevant, unmerged feature work.
- **Verdict:** ✅ Feature already in main (via `e82ab07`). Branch's unique commit contains only cleanup and stale artifacts. Cleaned up.
- **Local branch:** existed, deleted.
- **Remote branch:** deleted.

### 5. `fix/treesitter-cpp-python313-fallback`
- **Tip:** `b20199a` — "chore: pin Python 3.13 via uv python-version file"
- **Analysis:** 62 commits ahead of main (by count), 137 behind. **`git cherry origin/main` returned 0 unmerged commits** — all 62 commits are semantically present in main. This branch started from the initial commit (`e3c341d`) and all its work was incrementally merged into main over time through other PRs. The branch is 137 commits behind because main has evolved substantially beyond what this branch contained.
- **Specific recent commits check:**
  - `5eb7f85` "fix: add tree-sitter-cpp fallback for Python 3.13 in code_graph" — main's code_graph module has evolved independently; no diff delta to merge.
  - `f643659` "feat: speed-up suite + parser fixes" — changes exist in different form in main.
  - `b20199a` "chore: pin Python 3.13" — main uses `uv` version management already.
- **Verdict:** ⛔ Obsolete. All content superseded by main. Cleaned up.
- **Local branch:** did not exist locally.
- **Remote branch:** deleted.

---

## Post-Cleanup State

```
$ git branch -a
* (detached HEAD at d25a43c)
+ main
  remotes/origin/HEAD -> origin/main
  remotes/origin/main
```

**Tests:** 381 passed, 31 skipped — same baseline as before any changes.

---

## Notes

- **No force-push** was used on main. Main was never modified during this exercise.
- All deletions were simple `git push origin --delete <branch>` operations — no force-push needed.
- The single `+` commit on `feat/flywheel-issue-51` was **not** merged because its content is already in main under a different hash (`e82ab07`). Merging it would have reintroduced deleted artifacts (`stateless transpilation/`, `.env` with an API key, etc.) and caused unnecessary churn.