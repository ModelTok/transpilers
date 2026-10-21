"""Deterministic post-pass for LLM-drafted Mojo kernels (EnergyPlusMojo conventions).

Drafts from small or general models share mechanical defects that need no model to fix:

* C++ or pre-1.0 Mojo habits: ``//`` comments, ``fn``, ``let``, ``alias``, ``&&``/``||``/``!``,
  ``const``, ``Real64``, quoted-path imports, trailing semicolons;
* ``Array1D`` parameters walked element-wise (rewritten to ``List`` only where the 1-based
  versus 0-based index base cannot matter), and the old name ``DynamicVector``;
* a parameter that the body index-assigns but that is not declared ``mut``;
* products that feed an add or subtract. Mojo contracts ``a*b + c`` into a fused multiply-add
  while the C++ oracle (``-ffp-contract=off``) does not, so such a product is wrapped in
  ``nc_mul`` (``from fp_strict import nc_mul``).

Everything else it notices (C++ braces, ``Array1D``/``DynamicVector``, no ``@export`` entry) is
reported in ``PostpassResult.unresolved`` rather than guessed. Like ``scripts/sft/mojo_repair.py``
the rewrites are meant to be verify-gated downstream (compile, then compare with the oracle).
"""

from __future__ import annotations

import ast
import io
import re
import tokenize
from dataclasses import dataclass, field

_INT_NAMES_ANNOT = re.compile(r"\b(\w+)\s*:\s*U?Int(?:8|16|32|64)?\b")
_FLOAT_NAMES_ANNOT = re.compile(r"\b(\w+)\s*:\s*(?:Float(?:16|32|64)|SIMD\[)")
_VAR_FLOAT = re.compile(r"^\s*var\s+(\w+)\s*(?::\s*Float\w+\s*)?=\s*(?:-?\d+\.\d*|-?\d+\.?\d*[eE][-+]?\d+|Float\w+\()")
_VAR_ASSIGN = re.compile(r"^\s*var\s+(\w+)\s*=\s*(.+?)\s*(?:#.*)?$")
_FOR_RANGE = re.compile(r"^\s*for\s+(\w+)\s+in\s+range\b")
_VAR_INT = re.compile(r"^\s*var\s+(\w+)\s*=\s*(?:-?\d+\s*(?:#.*)?$|len\()")
_CONVENTIONS = {"mut", "var", "out", "read", "owned", "ref", "borrowed", "inout", "deinit"}
_MUT_CONTAINERS = {"List", "InlineArray", "Dict", "Set", "Deque"}
_CPP_LEFTOVERS = re.compile(r"\b(Array1D|Array2D|Array3D|ObjexxFCL)\b|std::")
_ARRAY1D_PARAM = re.compile(r"\b(\w+)\s*:\s*Array1D\[")
_ARRAY1D_LOOP = re.compile(
    r"^(\s*)for\s+(\w+)\s+in\s+range\(\s*(?:(\w+)\.l\(\)|1)\s*,\s*(\w+)\.u\(\)\s*\+\s*1\s*\)\s*:(\s*#.*)?$"
)
_EQUAL_DIMS = re.compile(r"\bequal_dimensions\(\s*(\w+)\s*,\s*(\w+)\s*\)")


@dataclass
class PostpassResult:
    code: str
    changes: list[str] = field(default_factory=list)
    unresolved: list[str] = field(default_factory=list)


# ---------------------------------------------------------------------------------------------
# Pass 1: syntax normalisation
# ---------------------------------------------------------------------------------------------


def _split_segments(line: str, in_triple: str | None) -> tuple[list[tuple[str, str]], str | None]:
    """Split a line into ('code'|'str'|'comment', text) segments; track triple-quoted strings."""
    segs: list[tuple[str, str]] = []
    i, n, buf = 0, len(line), ""
    quote = in_triple

    def flush(kind: str) -> None:
        nonlocal buf
        if buf:
            segs.append((kind, buf))
            buf = ""

    while i < n:
        if quote:
            end = line.find(quote, i)
            if end < 0:
                buf += line[i:]
                i = n
            else:
                buf += line[i : end + len(quote)]
                i = end + len(quote)
                flush("str")
                quote = None
            continue
        ch = line[i]
        if ch == "#":
            flush("code")
            segs.append(("comment", line[i:]))
            return segs, None
        if line.startswith('"""', i) or line.startswith("'''", i):
            flush("code")
            quote = line[i : i + 3]
            buf = quote
            i += 3
            continue
        if ch in "\"'":
            flush("code")
            j = i + 1
            while j < n and line[j] != ch:
                j += 2 if line[j] == "\\" else 1
            segs.append(("str", line[i : j + 1]))
            i = j + 1
            continue
        buf += ch
        i += 1
    flush("str" if quote else "code")
    return segs, quote


def _is_cpp_line_comment(before: str, rest: str) -> bool:
    """`//` is floor division between operands and a comment otherwise."""
    if not before.strip():
        return True
    if rest.startswith("="):  # `x //= 2`
        return False
    expr = rest.split("#", 1)[0].strip()
    if not expr:
        return True
    # closers in `rest` that belong to brackets opened before the `//` (`(a // 2 - 1) * x`)
    unmatched: list[str] = []
    depth = 0
    for ch in expr:
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            if depth:
                depth -= 1
            else:
                unmatched.append({")": "(", "]": "[", "}": "{"}[ch])
    candidate = "".join(reversed(unmatched)) + expr
    try:
        ast.parse(candidate.rstrip(",:").strip() or "0", mode="eval")
    except SyntaxError:
        return True
    return False


def _code_rewrites(code: str, changes: list[str], lineno: int) -> str:
    original = code
    code = re.sub(r"^(\s*)fn\s+", r"\1def ", code)
    code = re.sub(r"^(\s*)let\s+", r"\1var ", code)
    code = re.sub(r"^(\s*)alias\s+", r"\1comptime ", code)
    code = code.replace("&&", " and ").replace("||", " or ")
    code = re.sub(r"!(?!=)", "not ", code)
    code = re.sub(r"\btrue\b", "True", code)
    code = re.sub(r"\bfalse\b", "False", code)
    code = re.sub(r"\s*\bconst\b", "", code)
    code = re.sub(r"\bReal64\b", "Float64", code)
    code = re.sub(r"\bDynamicVector\b", "List", code)
    code = re.sub(r";\s*$", "", code)
    code = re.sub(r"[ \t]{2,}and[ \t]{2,}", " and ", code)
    code = re.sub(r"[ \t]{2,}or[ \t]{2,}", " or ", code)
    if code != original:
        changes.append(f"line {lineno}: C++/pre-1.0 syntax -> Mojo 1.0")
    return code


def _normalise_syntax(src: str, changes: list[str]) -> str:
    out: list[str] = []
    triple: str | None = None
    for lineno, line in enumerate(src.split("\n"), 1):
        if triple is None:
            unquoted = re.sub(r'^(\s*)from\s+"(?:[^"]*/)?([A-Za-z_]\w*)"\s+import\b', r"\1from \2 import", line)
            if unquoted != line:
                changes.append(f"line {lineno}: quoted-path import -> `from <module> import`")
                line = unquoted
        segs, triple = _split_segments(line, triple)
        rebuilt: list[str] = []
        pending_comment = False
        for idx, (kind, text) in enumerate(segs):
            if kind == "code":
                cut = None
                search = 0
                while True:
                    pos = text.find("//", search)
                    if pos < 0:
                        break
                    before = "".join(t for _, t in segs[:idx]) + text[:pos]
                    rest = text[pos + 2 :] + "".join(t for _, t in segs[idx + 1 :])
                    if _is_cpp_line_comment(before, rest):
                        cut = pos
                        break
                    search = pos + 2
                if cut is not None:
                    code_part = _code_rewrites(text[:cut], changes, lineno)
                    comment = text[cut + 2 :].rstrip()
                    rebuilt.append(code_part + ("#" if not code_part.strip() else "# ") + comment.lstrip())
                    changes.append(f"line {lineno}: `//` comment -> `#`")
                    pending_comment = True
                    break
                rebuilt.append(_code_rewrites(text, changes, lineno))
            else:
                rebuilt.append(text)
        line_out = "".join(rebuilt)
        if pending_comment:
            line_out = re.sub(r"^(\s*)#(\S)", r"\1# \2", line_out) if not line_out.lstrip().startswith("# ") else line_out
        out.append(line_out)
    return "\n".join(out)


# ---------------------------------------------------------------------------------------------
# Pass 1b: ObjexxFCL `Array1D` parameters -> `List`, only where the index base cannot matter
# ---------------------------------------------------------------------------------------------


def _def_spans(lines: list[str]) -> list[tuple[int, int, int, str]]:
    """(def line, last signature line, end of body, name) of every `def`."""
    spans = []
    i = 0
    while i < len(lines):
        m = re.match(r"^(\s*)def\s+(\w+)\s*(?:\[[^\]]*\])?\s*\(", lines[i])
        if not m:
            i += 1
            continue
        indent = len(m.group(1))
        depth, sig_end = 0, i
        for k in range(i, len(lines)):
            code = _blank_non_code(lines[k])
            depth += code.count("(") - code.count(")")
            if depth <= 0 and ")" in code:
                sig_end = k
                break
        end = sig_end + 1
        while end < len(lines) and (not lines[end].strip() or len(lines[end]) - len(lines[end].lstrip()) > indent):
            end += 1
        spans.append((i, sig_end, end, m.group(2)))
        i = sig_end + 1
    return spans


def _fix_array1d(src: str, changes: list[str], unresolved: list[str]) -> str:
    """Rewrite `Array1D[T]` parameters to `List[T]` when the draft only ever walks them element-wise.

    An ObjexxFCL `Array1D` is indexed from `a.l()` to `a.u()` (1 by default) while a `List` starts
    at 0. The rewrite is therefore limited to the canonical loop
    `for i in range(a.l(), a.u() + 1)` whose variable is used only as a direct subscript `x[i]`
    of the Array1D parameters (visiting every element in order is the same in either base), plus
    `equal_dimensions(a, b)` -> `len(a) == len(b)`. Anything else that mentions the array (literal
    subscripts, bounds used in arithmetic, calls) is left alone and reported.
    """
    lines = src.split("\n")
    for start, sig_end, end, name in reversed(_def_spans(lines)):
        sig = "\n".join(_blank_non_code(ln) for ln in lines[start : sig_end + 1])
        arrays = set(_ARRAY1D_PARAM.findall(sig))
        if not arrays:
            continue
        names = "|".join(sorted(arrays))
        subscript = re.compile(rf"\b(?:{names})\s*\[\s*(\w+)\s*\]")
        loops: list[tuple[int, int, str, str]] = []  # (header line, block end, variable, array)
        reason = ""
        k = sig_end + 1
        while k < end:
            m = _ARRAY1D_LOOP.match(lines[k])
            if not m:
                k += 1
                continue
            var, lower, upper = m.group(2), m.group(3), m.group(4)
            if upper not in arrays or (lower is not None and lower != upper):
                k += 1
                continue
            indent = len(m.group(1))
            block_end = k + 1
            while block_end < end and (
                not lines[block_end].strip() or len(lines[block_end]) - len(lines[block_end].lstrip()) > indent
            ):
                block_end += 1
            block = "\n".join(_blank_non_code(ln) for ln in lines[k + 1 : block_end])
            rest = re.sub(rf"\b(?:{names})\s*\[\s*{re.escape(var)}\s*\]", " ", block)
            if re.search(rf"\b{re.escape(var)}\b", rest):
                reason = f"loop variable `{var}` is used other than as a direct subscript"
                break
            if re.search(rf"\b(?:{names})\b", rest):
                reason = "an Array1D parameter is used inside the loop other than as `x[i]`"
                break
            for sub in subscript.finditer(block):
                if sub.group(1) != var:
                    reason = f"subscript `[{sub.group(1)}]` is not the loop variable"
                    break
            if reason:
                break
            loops.append((k, block_end, var, upper))
            k = block_end
        if not reason:
            covered = {j for lo, hi, _, _ in loops for j in range(lo, hi)}
            for j in range(sig_end + 1, end):
                if j in covered:
                    continue
                code = _EQUAL_DIMS.sub(" ", _blank_non_code(lines[j]))
                if re.search(rf"\b(?:{names})\b", code):
                    reason = f"an Array1D parameter is used outside an element-wise loop (line {j + 1})"
                    break
        if not loops and not reason:
            reason = "no element-wise loop over the Array1D parameters"
        if reason:
            unresolved.append(f"Array1D rewrite skipped in `{name}`: {reason}")
            continue
        for j in range(start, sig_end + 1):
            lines[j] = re.sub(r"\bArray1D\[", "List[", lines[j])
        for lo, _, var, arr in loops:
            m = _ARRAY1D_LOOP.match(lines[lo])
            lines[lo] = f"{m.group(1)}for {var} in range(len({arr})):{m.group(5) or ''}"
        for j in range(sig_end + 1, end):
            lines[j] = _EQUAL_DIMS.sub(r"len(\1) == len(\2)", lines[j])
        changes.append(
            f"line {start + 1}: `{name}`: Array1D -> List, {len(loops)} element-wise loop(s) now 0-based"
        )
    return "\n".join(lines)


# ---------------------------------------------------------------------------------------------
# Pass 2: `mut` for parameters that the body index-assigns
# ---------------------------------------------------------------------------------------------


def _blank_non_code(line: str) -> str:
    """The line with comments and string literals replaced by spaces (same length)."""
    segs = _split_segments(line, None)[0]
    return "".join(t if kind == "code" else " " * len(t) for kind, t in segs)


def _fix_mut(src: str, changes: list[str]) -> str:
    """Add `mut` to a parameter that the body index-assigns (`a[i] = ...`, `a[i] += ...`)."""
    lines = src.split("\n")
    inserts: list[tuple[int, int, str]] = []  # (line index, column, parameter name)
    i = 0
    while i < len(lines):
        m = re.match(r"^(\s*)def\s+\w+\s*(?:\[[^\]]*\])?\s*\(", lines[i])
        if not m:
            i += 1
            continue
        indent = len(m.group(1))
        depth, sig_end = 0, i
        params: list[tuple[int, int, str]] = []  # (line, start col, text) of each top-level parameter
        cur_line, cur_col, cur_text = i, 0, ""
        for k in range(i, len(lines)):
            code = _blank_non_code(lines[k])
            c0 = m.end() if k == i else 0
            if k == i:
                depth = 1
            for c in range(c0, len(code)):
                ch = code[c]
                if ch in "([":
                    depth += 1
                elif ch in ")]":
                    depth -= 1
                    if depth == 0:
                        if cur_text.strip():
                            params.append((cur_line, cur_col, cur_text))
                        sig_end = k
                        break
                if depth == 1 and ch == ",":
                    if cur_text.strip():
                        params.append((cur_line, cur_col, cur_text))
                    cur_text, cur_line, cur_col = "", k, c + 1
                    continue
                if not cur_text.strip() and ch.strip():
                    cur_line, cur_col = k, c
                    cur_text = ""
                cur_text += ch
            else:
                cur_text += "\n"
                continue
            break
        body_end = sig_end + 1
        while body_end < len(lines) and (
            not lines[body_end].strip() or len(lines[body_end]) - len(lines[body_end].lstrip()) > indent
        ):
            body_end += 1
        body = "\n".join(_blank_non_code(ln) for ln in lines[sig_end + 1 : body_end])
        for pline, pcol, text in params:
            pm = re.match(r"\s*((?:\w+\s+)*?)(\w+)\s*:\s*(.+)$", text, re.DOTALL)
            if not pm:
                continue
            words, name, annot = pm.group(1).split(), pm.group(2), pm.group(3).strip()
            if any(w in _CONVENTIONS for w in words):
                continue
            base = re.match(r"\w+", annot)
            if not base or base.group(0) not in _MUT_CONTAINERS:
                continue
            if re.search(rf"\b{name}\s*\[[^\]]*\]\s*[-+*/]?=(?!=)", body):
                inserts.append((pline, pcol, name))
        i = sig_end + 1
    for pline, pcol, name in sorted(inserts, reverse=True):
        ln = lines[pline]
        at = ln.index(name, pcol)
        lines[pline] = ln[:at] + "mut " + ln[at:]
        changes.append(f"line {pline + 1}: parameter `{name}` is index-assigned -> `mut {name}`")
    return "\n".join(lines)


# ---------------------------------------------------------------------------------------------
# Pass 3: nc_mul around products that feed an add or subtract
# ---------------------------------------------------------------------------------------------


def _int_names(src: str) -> set[str]:
    names: set[str] = set(_INT_NAMES_ANNOT.findall(src))
    lines = src.split("\n")
    for line in lines:
        for rx in (_FOR_RANGE, _VAR_INT):
            m = rx.match(line)
            if m:
                names.add(m.group(1))
    for _ in range(3):  # `var k = i * n + j` is an Int when i, n and j are
        for line in lines:
            m = _VAR_ASSIGN.match(line)
            if m and m.group(1) not in names:
                try:
                    expr = ast.parse(m.group(2), mode="eval").body
                except SyntaxError:
                    continue
                if _intish(expr, names):
                    names.add(m.group(1))
    return names


def _float_names(src: str) -> set[str]:
    names: set[str] = set(_FLOAT_NAMES_ANNOT.findall(src))
    for line in src.split("\n"):
        m = _VAR_FLOAT.match(line)
        if m:
            names.add(m.group(1))
        m = re.match(r"^\s*var\s+(\w+)\s*:\s*Float\w+", line)
        if m:
            names.add(m.group(1))
    return names


def _floatish(node: ast.AST, floats: set[str]) -> bool:
    if isinstance(node, ast.Constant):
        return isinstance(node.value, float)
    if isinstance(node, ast.Name):
        return node.id in floats
    if isinstance(node, ast.UnaryOp):
        return _floatish(node.operand, floats)
    if isinstance(node, ast.BinOp):
        return _floatish(node.left, floats) or _floatish(node.right, floats)
    if isinstance(node, ast.Call):
        return isinstance(node.func, ast.Name) and node.func.id.startswith("Float")
    return False


def _intish(node: ast.AST, ints: set[str]) -> bool:
    if isinstance(node, ast.Constant):
        return isinstance(node.value, int) and not isinstance(node.value, bool)
    if isinstance(node, ast.Name):
        return node.id in ints
    if isinstance(node, ast.Call):
        return isinstance(node.func, ast.Name) and node.func.id in {"len", "Int"}
    if isinstance(node, ast.UnaryOp):
        return _intish(node.operand, ints)
    if isinstance(node, ast.BinOp) and isinstance(node.op, (ast.Add, ast.Sub, ast.Mult, ast.FloorDiv, ast.Mod)):
        return _intish(node.left, ints) and _intish(node.right, ints)
    return False


def _power_of_two_literal(node: ast.AST) -> bool:
    if isinstance(node, ast.Constant) and isinstance(node.value, (int, float)) and not isinstance(node.value, bool):
        v = abs(float(node.value))
        if v == 0.0:
            return False
        import math

        m, _ = math.frexp(v)
        return m == 0.5
    return False


def _is_number(node: ast.AST) -> bool:
    return isinstance(node, ast.Constant) and isinstance(node.value, (int, float)) and not isinstance(node.value, bool)


def _needs_guard(mult: ast.BinOp, ints: set[str], floats: set[str]) -> bool:
    if _intish(mult, ints):
        return False
    if _is_number(mult.left) and _is_number(mult.right):  # constant-folded
        return False
    if _power_of_two_literal(mult.left) or _power_of_two_literal(mult.right):
        return False
    if (_intish(mult.left, ints) or _intish(mult.right, ints)) and not (
        _floatish(mult.left, floats) or _floatish(mult.right, floats)
    ):
        return False  # an Int times an unknown value: most likely index arithmetic
    return True


def _collect_guards(root: ast.AST, ints: set[str], floats: set[str], augmented_add: bool) -> set[int]:
    guards: set[int] = set()

    def visit(node: ast.AST) -> None:
        if isinstance(node, ast.Subscript):
            visit(node.value)
            return
        if isinstance(node, ast.BinOp) and isinstance(node.op, (ast.Add, ast.Sub)):
            for side in (node.left, node.right):
                if isinstance(side, ast.BinOp) and isinstance(side.op, ast.Mult) and _needs_guard(side, ints, floats):
                    guards.add(id(side))
        for child in ast.iter_child_nodes(node):
            visit(child)

    if augmented_add and isinstance(root, ast.BinOp) and isinstance(root.op, ast.Mult) and _needs_guard(root, ints, floats):
        guards.add(id(root))
    visit(root)
    return guards


def _render(node: ast.AST, text: str, guards: set[int], offs: list[int]) -> str:
    """Source text of `node` with every guarded product below (or at) it rewritten."""

    def span(n: ast.AST) -> tuple[int, int]:
        return offs[n.lineno - 1] + n.col_offset, offs[n.end_lineno - 1] + n.end_col_offset

    if id(node) in guards:
        return f"nc_mul({_render(node.left, text, guards, offs)}, {_render(node.right, text, guards, offs)})"
    start, end = span(node)
    pieces: list[tuple[int, int, str]] = []

    def descend(n: ast.AST) -> None:
        for child in ast.iter_child_nodes(n):
            if not hasattr(child, "lineno"):
                descend(child)
                continue
            if id(child) in guards or _contains_guard(child, guards):
                s, e = span(child)
                pieces.append((s, e, _render(child, text, guards, offs)))
            # a child without guards inside is left as written

    descend(node)
    pieces.sort()
    out, pos = [], start
    for s, e, repl in pieces:
        if s < pos:
            continue
        out.append(text[pos:s])
        out.append(repl)
        pos = e
    out.append(text[pos:end])
    return "".join(out)


def _contains_guard(node: ast.AST, guards: set[int]) -> bool:
    return any(id(n) in guards for n in ast.walk(node))


_AUG = {"+=", "-="}


def _statement_expressions(tokens: list[tokenize.TokenInfo]) -> list[tuple[int, int, bool]]:
    """(first token index, last token index, augmented_add) of each expression in a logical line."""
    sig = [i for i, t in enumerate(tokens) if t.type not in (tokenize.NL, tokenize.COMMENT, tokenize.INDENT, tokenize.DEDENT, tokenize.NEWLINE, tokenize.ENDMARKER)]
    if not sig:
        return []
    first = tokens[sig[0]]
    if first.type == tokenize.OP and first.string == "@":
        return []
    kw = first.string if first.type == tokenize.NAME else ""
    if kw in {"def", "struct", "import", "from", "comptime", "trait", "raise", "pass", "break", "continue"}:
        return []
    depth = 0
    assign_at: int | None = None
    aug = False
    colon_at: int | None = None
    for i in sig:
        t = tokens[i]
        if t.type == tokenize.OP:
            if t.string in "([{":
                depth += 1
            elif t.string in ")]}":
                depth -= 1
            elif depth == 0 and t.string == "=" and assign_at is None:
                assign_at = i
            elif depth == 0 and t.string in _AUG and assign_at is None:
                assign_at, aug = i, True
            elif depth == 0 and t.string == ":" and kw in {"if", "elif", "while", "for", "else"}:
                colon_at = i
    lo = sig[0]
    if assign_at is not None:
        lo = assign_at + 1
    elif kw in {"if", "elif", "while", "return", "assert"}:
        lo = sig[0] + 1
    elif kw == "for":
        ins = [i for i in sig if tokens[i].type == tokenize.NAME and tokens[i].string == "in"]
        lo = (ins[0] + 1) if ins else sig[0] + 1
    elif kw in {"var"}:
        return []
    hi = sig[-1]
    if colon_at is not None:
        hi = max(i for i in sig if i < colon_at) if any(i < colon_at for i in sig) else hi
    if lo > hi:
        return []
    return [(lo, hi, aug)]


def _fix_fma(src: str, changes: list[str], unresolved: list[str]) -> tuple[str, bool]:
    try:
        tokens = list(tokenize.generate_tokens(io.StringIO(src).readline))
    except (tokenize.TokenError, IndentationError, SyntaxError) as e:
        unresolved.append(f"nc_mul pass skipped: cannot tokenize ({e})")
        return src, False
    if re.search(r"^\s*(?:from|import)\s+(?:std\.)?gpu\b|\bDeviceContext\b", src, re.MULTILINE):
        unresolved.append("GPU kernel: nc_mul skipped (its inline assembly is host-only)")
        return src, False
    ints = _int_names(src)
    floats = _float_names(src)
    line_offs = [0]
    for ln in src.split("\n"):
        line_offs.append(line_offs[-1] + len(ln) + 1)

    def abs_off(pos: tuple[int, int]) -> int:
        return line_offs[pos[0] - 1] + pos[1]

    edits: list[tuple[int, int, str]] = []
    logical: list[tokenize.TokenInfo] = []
    for tok in tokens:
        logical.append(tok)
        if tok.type != tokenize.NEWLINE and tok.type != tokenize.ENDMARKER:
            continue
        for lo, hi, aug in _statement_expressions(logical):
            a, b = abs_off(logical[lo].start), abs_off(logical[hi].end)
            own = [t for t in logical if t.type not in (tokenize.NL, tokenize.COMMENT, tokenize.INDENT, tokenize.DEDENT)]
            first_row, last_row = own[0].start[0], own[-1].end[0]
            if "fma: ok" in "\n".join(src.split("\n")[first_row - 1 : last_row]):
                continue
            text = src[a:b]
            if not text.isascii():
                continue
            wrapped = "(" + text + ")"
            try:
                tree = ast.parse(wrapped, mode="eval").body
            except SyntaxError:
                continue
            guards = _collect_guards(tree, ints, floats, aug)
            if not guards:
                continue
            offs = [0]
            for ln in wrapped.split("\n"):
                offs.append(offs[-1] + len(ln) + 1)
            s0 = offs[tree.lineno - 1] + tree.col_offset
            e0 = offs[tree.end_lineno - 1] + tree.end_col_offset
            new = wrapped[1:s0] + _render(tree, wrapped, guards, offs) + wrapped[e0:-1]
            edits.append((a, b, new))
            changes.append(f"line {logical[lo].start[0]}: {len(guards)} product(s) feeding an add/subtract -> nc_mul")
        logical = []
    if not edits:
        return src, False
    for a, b, new in sorted(edits, reverse=True):
        src = src[:a] + new + src[b:]
    return src, True


def _ensure_nc_mul_import(src: str, changes: list[str]) -> str:
    if re.search(r"^\s*from\s+fp_strict\s+import\b[^\n]*\bnc_mul\b", src, re.MULTILINE):
        return src
    m = re.search(r"^from\s+fp_strict\s+import\s+([^\n(\\]+)$", src, re.MULTILINE)
    if m:
        changes.append("added `nc_mul` to the existing fp_strict import")
        return src[: m.end()] + ", nc_mul" + src[m.end() :]
    lines = src.split("\n")
    last_import = -1
    first_code = None
    i = 0
    while i < len(lines):
        ln = lines[i]
        if re.match(r"^(from|import)\s", ln):
            end = i
            depth = ln.count("(") - ln.count(")")
            while depth > 0 and end + 1 < len(lines):
                end += 1
                depth += lines[end].count("(") - lines[end].count(")")
            last_import = end
            i = end + 1
            continue
        if first_code is None and re.match(r"^(def|@|comptime|struct|var)\b", ln):
            first_code = i
        i += 1
    changes.append("added `from fp_strict import nc_mul`")
    if last_import >= 0:
        lines.insert(last_import + 1, "from fp_strict import nc_mul")
    else:
        at = first_code if first_code is not None else 0
        lines[at:at] = ["from fp_strict import nc_mul", "", ""]
    return "\n".join(lines)


# ---------------------------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------------------------


def _report_unresolved(src: str, unresolved: list[str]) -> None:
    if re.search(r"^\s*[{}]\s*$|\)\s*\{\s*$|\{\s*$", src, re.MULTILINE):
        unresolved.append("C++ braces remain; the structure needs a model or manual rewrite")
    found = sorted(set(m.group(0) for m in _CPP_LEFTOVERS.finditer(src)))
    if found:
        unresolved.append("C++ / non-Mojo types remain: " + ", ".join(found))
    if not re.search(r"^\s*@export\b", src, re.MULTILINE):
        unresolved.append("no `@export` batch entry (EnergyPlusMojo kernel convention)")


def postpass(
    code: str, *, syntax: bool = True, arrays: bool = True, mut: bool = True, fma: bool = True
) -> PostpassResult:
    """Apply the mechanical fixes to Mojo source; see the module docstring."""
    changes: list[str] = []
    unresolved: list[str] = []
    text = code.replace("\r\n", "\n")
    if syntax:
        text = _normalise_syntax(text, changes)
    if arrays:
        text = _fix_array1d(text, changes, unresolved)
    if mut:
        text = _fix_mut(text, changes)
    if fma:
        text, changed = _fix_fma(text, changes, unresolved)
        if changed:
            text = _ensure_nc_mul_import(text, changes)
    _report_unresolved(text, unresolved)
    return PostpassResult(text, changes, unresolved)


def main(argv: list[str] | None = None) -> int:
    """`transpile-postpass FILE...`: print (or rewrite with --in-place) the fixed Mojo."""
    import argparse
    import sys
    from pathlib import Path

    ap = argparse.ArgumentParser(
        prog="transpile-postpass",
        description="Deterministic fixes for LLM-drafted Mojo kernels (syntax, mut, nc_mul)",
    )
    ap.add_argument("files", nargs="+", type=Path)
    ap.add_argument("--in-place", action="store_true", help="rewrite the files instead of printing")
    ap.add_argument("--no-syntax", action="store_true", help="skip C++/pre-1.0 syntax normalisation")
    ap.add_argument("--no-arrays", action="store_true", help="skip the Array1D -> List rewrite")
    ap.add_argument("--no-mut", action="store_true", help="skip adding `mut` to index-assigned parameters")
    ap.add_argument("--no-fma", action="store_true", help="skip wrapping products in nc_mul")
    args = ap.parse_args(argv)
    if len(args.files) > 1 and not args.in_place:
        ap.error("several files need --in-place")
    for path in args.files:
        res = postpass(
            path.read_text(encoding="utf-8"),
            syntax=not args.no_syntax,
            arrays=not args.no_arrays,
            mut=not args.no_mut,
            fma=not args.no_fma,
        )
        if args.in_place:
            path.write_text(res.code, encoding="utf-8", newline="\n")
        else:
            sys.stdout.write(res.code)
        for c in res.changes:
            print(f"{path}: {c}", file=sys.stderr)
        for u in res.unresolved:
            print(f"{path}: UNRESOLVED: {u}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
