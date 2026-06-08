# migraph

Interactive 2D graphs for tracking a **source-to-source migration** — see, at a
glance, what's been ported and what's left, and **scrub/animate** the progress
over git history.

Built for the EnergyPlus (C++) → [energyplus-mojo](../energyplus-mojo) (Python +
Mojo) port, but the migration graph is parameterised and works for any project
that keeps a `MIGRATION_MAP.md` mapping upstream files to a port status.

## The migration graph

A single self-contained HTML viewer (cytoscape.js, no build step) showing the
full upstream C++ module / `#include` graph, every node coloured by port status:

| colour | status | meaning |
|---|---|---|
| 🟢 green | COMPLETE | physics + runtime ported (kernel + wrapper + dispatch) |
| 🟠 amber | PARTIAL | data model parsed/loadable, no runtime physics yet |
| 🔴 red | NOT_STARTED | explicitly listed in the map, no port |
| ⚫ gray | unmapped | not in the map (infra / not yet triaged) |

Features:
- **2×2 quadrant clusters** with hard-baked, collision-free coordinates
- **Timeline scrubber + ▶ play** — reconstructs *when* each module was ported
  from git history (first-add time of its target files) and animates the fill-in
- **Top-blockers panel** — unported modules ranked by inbound `#include`s
- node size = LOC · edges = `#include` deps · live status bars · search · filters

## Usage

```bash
# from inside the target repo (auto-detects map, git root, ../EnergyPlus):
cd ../energyplus-mojo
python -m migraph migration

# or fully explicit:
python -m migraph migration \
  --map     ../energyplus-mojo/.migration_progress/MIGRATION_MAP.md \
  --repo    ../energyplus-mojo \
  --cpp-src ../EnergyPlus/src/EnergyPlus \
  --out     ../energyplus-mojo/docs/migration_graph.html
```

`--cpp-src` also reads `$ENERGYPLUS_SRC`. If the source or map is missing the
tool warns and exits 0, so it's safe in a pre-commit hook.

### Keeping it fresh (pre-commit)

The target repo can regenerate its graph automatically whenever the map changes.
Example `repo: local` hook in the target's `.pre-commit-config.yaml`:

```yaml
- id: migration-graph
  name: regenerate migration progress graph
  entry: bash -c 'python -m migraph migration --repo . --map .migration_progress/MIGRATION_MAP.md --out docs/migration_graph.html && git add docs/migration_graph.html 2>/dev/null || true'
  language: system
  files: ^\.migration_progress/MIGRATION_MAP\.md$
  pass_filenames: false
```
(`migraph` must be importable — `pip install -e /home/db/migraph`, or prepend
`PYTHONPATH=/home/db/migraph`.)

## Other graph tools (bonus)

The same repo carries the code-graph generators built alongside migraph:

```bash
python -m migraph code     # symbol graph (functions/classes/vars) of a Python pkg
python -m migraph module   # subpackage import-dependency graph
python -m migraph cpp      # C++ symbol + module/#include graphs
```

These are currently EnergyPlus/energyplus-mojo-specific (paths near the top of
each module); generalise them the same way `migration_graph.py` was if needed.

## Layout

```
migraph/
  __main__.py        # subcommand dispatcher
  migration_graph.py # the flagship, parameterised
  code_graph.py      # Python symbol graph
  module_graph.py    # subpackage import graph
  cpp_graph.py       # C++ symbol + module graphs
```
