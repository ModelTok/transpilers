#!/usr/bin/env python3
"""Deterministic post-generation repair for LLM-emitted Mojo.

The 0.5B produces correct logic but drops mechanical boilerplate the rule-based
backend never would. Each rule is a pure-syntactic transform targeting a named
compile-error cluster from the diverse eval histogram. ALL rules are applied and
the result is VERIFY-GATED downstream (kept only if it compiles AND matches), so
aggressive rules are safe — a bad rewrite simply fails the gate and is discarded.

Rules (by cluster):
  - missing `from std.math import <fn>`         (~7 of 59 errors)
  - `x.size()` -> `len(x)`                       (List has no .size())
  - bare struct param `T` -> `Self.T`            (~3: "use 'Self.T' instead")
  - add `raises` to a def whose body `raise`s     (~3: "may raise in a context...")
"""
from __future__ import annotations
import re

# intrinsic-backed math fns that LINK under `-Xlinker -ldl` (no -lm). tanh/cbrt/
# sin/cos/sinh/cosh are EXCLUDED: they parse but fail to LINK.
_MATH = ["sqrt", "exp", "log", "log2", "log10", "atan", "atan2", "floor", "ceil",
         "trunc", "pow", "isqrt"]


def _add_math_imports(code: str) -> str:
    used = [m for m in _MATH if re.search(rf"\b{m}\s*\(", code)]
    if not used:
        return code
    imported = set()
    for line in code.splitlines():
        m = re.match(r"\s*from\s+(?:std\.)?math\s+import\s+(.+)", line)
        if m:
            imported |= {x.strip() for x in m.group(1).split(",")}
    missing = [m for m in used if m not in imported]
    return code if not missing else f"from std.math import {', '.join(missing)}\n" + code


def _size_to_len(code: str) -> str:
    # `name.size()` -> `len(name)` (Mojo List/collections use len(), not .size())
    return re.sub(r"\b([A-Za-z_]\w*)\.size\(\)", r"len(\1)", code)


def _self_qualify_params(code: str) -> str:
    # Inside `struct X[T: ...]:` blocks, a bare struct parameter must be `Self.T`.
    # Collect single-cap param names from struct headers, then qualify their bare
    # uses in type positions (`: T`, `-> T`, `[T]`, `Scalar[T]`).
    params = set(re.findall(r"struct\s+\w+\s*\[\s*([A-Z])\b", code))
    params |= set(re.findall(r"struct\s+\w+\s*\[[^\]]*?\b([A-Z])\s*:", code))
    for p in params:
        code = re.sub(rf"(:\s*){p}\b(?!\.)", rf"\1Self.{p}", code)
        code = re.sub(rf"(->\s*){p}\b(?!\.)", rf"\1Self.{p}", code)
        code = re.sub(rf"\[{p}\](?!\.)", f"[Self.{p}]", code)
    return code


def _add_raises(code: str) -> str:
    # For each `def NAME(...) -> RET:` whose indented body contains `raise` or a
    # raising idiom, add ` raises` before the colon if absent.
    lines = code.splitlines()
    out = list(lines)
    dre = re.compile(r"^(\s*)def\s+\w+\s*\([^)]*\)\s*(->\s*[^:]+?)?\s*:\s*$")
    for i, line in enumerate(lines):
        m = dre.match(line)
        if not m or "raises" in line:
            continue
        indent = len(m.group(1))
        body_raises = False
        for j in range(i + 1, len(lines)):
            s = lines[j]
            if s.strip() == "":
                continue
            cur = len(s) - len(s.lstrip())
            if cur <= indent:
                break
            if re.search(r"\braise\b", s):
                body_raises = True
                break
        if body_raises:
            out[i] = re.sub(r":\s*$", " raises:", line, count=1)
    return "\n".join(out)


_RULES = [_add_math_imports, _size_to_len, _self_qualify_params, _add_raises]


def repair_mojo(code: str) -> str:
    """Apply all repair rules. Verify-gated downstream — a no-op if nothing matches."""
    for rule in _RULES:
        code = rule(code)
    return code


if __name__ == "__main__":
    import sys
    print(repair_mojo(open(sys.argv[1]).read()))
