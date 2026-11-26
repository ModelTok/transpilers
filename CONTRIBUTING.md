# Contributing to transpilers

How changes land in this repository. What the transpiler does and how to run it are in
[README.md](README.md) and [RUN.md](RUN.md).

## Branches and commit messages

- Branch: `<type>/<description>`, for example `refactor/cpp-parser-core` or
  `chore/deps-security-2026-10-22`. Types in use: `feat`, `fix`, `refactor`, `chore`, `docs`.
- Commit subject and pull request title: conventional commits, `<type>(<scope>): <summary>`, with
  the scope optional, for example `refactor(cpp): explicit imports in parser/core.py`. The scope
  is the frontend, backend or area (`cpp`, `frontends`, `deps`).

## Pull requests

Open a pull request against `main` and merge it with a merge commit (the GitHub "Create a merge
commit" button), as #152-#158 were. Dependabot pull requests are reviewed and merged the same way.

## Checks before a change lands

There is no CI. GitHub Actions were removed on 2026-08-05 (commit `3ad279f`, "all checks should be
in pre-commit hooks"); the local checks are the gate.

```bash
git config core.hooksPath .githooks   # once per clone
just check   # just lint (ruff check src tests) + just test (uv run pytest)
just fmt     # ruff format src tests
```

`.githooks/pre-commit` checks the staged files for merge-conflict markers and syntax. It does not
run the test suite: run `just check` yourself and say in the pull request what ran.

Use `uv` for every Python command (`uv sync`, `uv run ...`), not bare `pip`. The API server binds
port 21300 (`PORT` overrides it); stay inside this repository's block, 21300-21319.

## Source comments

Source files carry no explanatory comments (removed in #134). Keep docstrings (argparse reads
`__doc__`), lint and type pragmas (`# noqa`, `# type: ignore`) and third-party licence notices;
say what a change does in the commit message or pull request instead.

## Closing a session

Before you end a session that changed this repository, whether you are a person or an agent:

1. List every rule, decision or convention the owner gave during the session that is not yet
   written down in this file. Examples: naming, paths, release steps, tools to avoid.
2. Write each one down in the same change, or open an issue if it needs discussion. A rule that
   exists only in the chat is lost at the next context limit.
3. If work is left half done, put a short dated hand-over note in the pull request description:
   what landed, what ran and what did not, what is still open, and ONE next action.
4. In your final report, say which rules you recorded and where, and which you did not.

Write prose in UK English.
