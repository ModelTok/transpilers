"""Dry-run planner for the Mojo 1.0 package re-layout (issue #95).

Pure functions only: nothing here reads or moves real files. Given the
package-relative paths of generated ``.mojo`` files and their source text, it
plans (a) which directories need an ``__init__.mojo`` and (b) how each
absolute ``from X.Y.Z import n`` line becomes a relative-dot import
(``.X``, ``..X``, ``..SubPkg.X``). Imports whose target is not in the file
set are reported as unresolved and left untouched.

It does not dedupe ``struct EnergyPlusData`` nor strip C++ leftovers, and no
Mojo toolchain has verified the output compiles.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import PurePosixPath

_FROM_RE = re.compile(r"^(?P<indent>\s*)from\s+(?P<mod>[A-Za-z_][\w.]*)\s+import\s+(?P<rest>.+)$")


@dataclass(frozen=True)
class ImportRewrite:
    file: str
    line: int  # 1-based
    old: str
    new: str


@dataclass
class LayoutPlan:
    init_files: list[str] = field(default_factory=list)
    rewrites: list[ImportRewrite] = field(default_factory=list)
    unresolved: list[tuple[str, int, str]] = field(default_factory=list)


def _module_parts(path: str) -> tuple[str, ...]:
    p = PurePosixPath(path)
    return (*p.parent.parts, p.stem)


def plan_init_files(paths: list[str]) -> list[str]:
    """Every directory containing a .mojo file, plus ancestors, gets an __init__.mojo."""
    dirs: set[PurePosixPath] = set()
    for path in paths:
        for parent in PurePosixPath(path).parents:
            if str(parent) != ".":
                dirs.add(parent)
    existing = {p for p in paths if PurePosixPath(p).name == "__init__.mojo"}
    return sorted(
        f"{d}/__init__.mojo" for d in dirs if f"{d}/__init__.mojo" not in existing
    )


def relative_module(importer: str, target: tuple[str, ...]) -> str:
    """Relative-dot module string for ``target`` as seen from ``importer``."""
    pkg = PurePosixPath(importer).parent.parts
    common = 0
    for a, b in zip(pkg, target[:-1]):
        if a != b:
            break
        common += 1
    dots = len(pkg) - common + 1
    return "." * dots + ".".join(target[common:])


def plan_layout(sources: dict[str, str], root: str = "") -> LayoutPlan:
    """Plan the re-layout. ``sources`` maps package-relative path -> text.

    ``root`` is the dotted prefix of the package root (e.g. ``EnergyPlus``)
    that absolute imports may carry; it is stripped before resolution when the
    module is not found verbatim.
    """
    known = {_module_parts(p) for p in sources}
    plan = LayoutPlan(init_files=plan_init_files(list(sources)))
    root_parts = tuple(root.split(".")) if root else ()
    for path in sorted(sources):
        for n, line in enumerate(sources[path].splitlines(), start=1):
            m = _FROM_RE.match(line)
            if not m or m["mod"].startswith("."):
                continue
            parts = tuple(m["mod"].split("."))
            target = parts
            if target not in known and root_parts and parts[: len(root_parts)] == root_parts:
                target = parts[len(root_parts):]
            if target not in known:
                plan.unresolved.append((path, n, line.strip()))
                continue
            new = f"{m['indent']}from {relative_module(path, target)} import {m['rest']}"
            plan.rewrites.append(ImportRewrite(path, n, line, new))
    return plan
