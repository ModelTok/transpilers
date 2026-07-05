"""Local (project-relative) `#include "X.h"` resolution for multi-file C++.

The strict engine's frontend is designed around single self-contained
translation units: ``preprocess.py`` strips every ``#include`` line
unconditionally (angle *and* quoted) so libclang never trips over a missing
system header. That works well for algorithm-corpus slices, but a real
multi-file C++ project splits declarations (``.h``) from definitions
(``.cpp``) across files -- feeding just the ``.cpp`` in means the class the
out-of-line methods belong to is never declared, and every method fails to
parse with "use of undeclared identifier".

``resolve_local_includes`` closes that specific gap: given an entry-point
file, it transitively inlines every ``#include`` it can actually find on
the search path -- base classes, shared typedefs, sibling declarations --
so the combined text is a self-contained translation unit before it ever
reaches ``preprocess_cpp``. An include that can't be found on the search
path is left completely alone; it's still stripped by the existing
``preprocess.py`` pipeline exactly as before (its real declarations were
never available toolchain-free anyway).

Whether a header is "local" is decided by *resolvability on the search
path*, not by ``"..."`` vs ``<...>`` spelling: real build systems routinely
put a project's own include directory on the ``-I`` search path, so a
project's own headers often use angle brackets too (e.g. Topologic's
`#include <Bitwise.h>` for its own sibling header) -- the angle/quote
distinction is only a *search-order* hint in the C++ standard, not a
local/system classification, and treating it as one would silently skip
exactly the includes this function exists to resolve.

This does not attempt to be a real preprocessor: no macro-guarded
conditional ``#include``, no distinct ``-I``/``-isystem`` search order
semantics, no handling of the same logical header appearing under two
different relative spellings. It solves the common case -- "this project's
own headers, once each" -- which is what unblocks real multi-file corpora
like a CAD kernel's core library.
"""
from __future__ import annotations

import re
from pathlib import Path

_INCLUDE_RE = re.compile(r'^\s*#\s*include\s*[<"]([^">]+)[>"]', re.MULTILINE)


def _find_header(name: str, requesting_dir: Path, include_dirs: list[Path]) -> Path | None:
    """Search alongside the including file first (the standard's own rule
    for ``"..."`` includes -- harmless to apply to ``<...>`` too here, since
    we only fall back to it after nothing already resolved), then each
    explicit search directory, in order."""
    candidate = requesting_dir / name
    if candidate.is_file():
        return candidate
    for d in include_dirs:
        candidate = d / name
        if candidate.is_file():
            return candidate
    return None


def resolve_local_includes(path: str | Path, include_dirs: list[str | Path] | None = None) -> str:
    """Return *path*'s content with every transitively-reachable local
    header inlined ahead of it, dependencies before dependents.

    Headers are deduplicated by resolved absolute path, so a diamond
    dependency (two headers both including a shared base) is only inlined
    once and cycles terminate. An include not found on the search path
    (typically because it actually names a vendored third-party header) is
    left as-is; the existing preprocessing pipeline strips the directive
    line either way.
    """
    entry = Path(path).resolve()
    dirs = [Path(d).resolve() for d in (include_dirs or [])]
    seen: set[Path] = set()
    order: list[str] = []

    def visit(file_path: Path) -> None:
        rp = file_path.resolve()
        if rp in seen:
            return
        seen.add(rp)
        text = file_path.read_text(encoding="utf-8", errors="replace")
        for name in _INCLUDE_RE.findall(text):
            dep = _find_header(name, file_path.parent, dirs)
            if dep is not None:
                visit(dep)
        order.append(text)

    visit(entry)
    return "\n".join(order)


__all__ = ["resolve_local_includes"]
