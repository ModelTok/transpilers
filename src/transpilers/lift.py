"""Never-refuse C++ -> Python "lift" (Phase-1 whole-program migration).

Unlike the strict HIR transpiler (which REFUSES unsupported constructs), this
lifter translates a whole file/snippet 1:1 — architecture preserved — and emits
a `# TODO[lift]` stub for anything it can't yet handle, so it ALWAYS produces
output and scales to a whole repo. Coverage grows by adding node handlers.

Lift conventions:
  * struct/class            -> Python class; fields -> __init__ defaults
  * `a->b` / `a.b`          -> `a.b`  (unique_ptr / ref / value collapse)
  * member chains           -> recovered from TOKENS when the AST is name-degraded
                               (so state.dataX->field works even without a full
                               type-resolving parse)
  * C-style for(i;c;inc)    -> init; while c: body; inc
  * (T)x / static_cast/T(x) -> value passed through
  * x.size()                -> len(x)
  * unknown node            -> `# TODO[lift]` + raw snippet
"""
from __future__ import annotations

import os
import re
import clang.cindex as ci

from transpilers.frontends.cpp import parser as _cfg  # noqa: F401  (configures libclang)

K = ci.CursorKind
IND = "    "


def snake(name: str) -> str:
    name = name.split("::")[-1]
    s = re.sub(r"(?<=[a-z0-9])(?=[A-Z])", "_", name)
    return s.lower() if s else name


def toks(c) -> list[str]:
    return [t.spelling for t in c.get_tokens()]


def src(c) -> str:
    try:
        e = c.extent
        raw = open(e.start.file.name, "rb").read()[e.start.offset:e.end.offset]
        return raw.decode("utf-8", "replace")
    except Exception:
        return c.spelling or "?"


def _toks_to_py(ts: list[str]) -> str:
    """Best-effort: concatenate a member/operand token stream into Python.

    Handles the dominant degraded-AST case (identifier chains like
    `state.dataCoolTower->GetInputFlag`) without any type resolution.
    """
    out = []
    for t in ts:
        if t in ("->", "."):
            out.append(".")
        elif t == "this":
            out.append("self")
        elif re.fullmatch(r"[A-Za-z_]\w*", t):
            out.append(snake(t))
        elif t in ("true", "false"):
            out.append("True" if t == "true" else "False")
        else:
            out.append(t)
    return "".join(out)


class _Lifter:
    def __init__(self):
        self.nodes = 0
        self.todo = 0

    def todo_expr(self, c, why="") -> str:
        self.todo += 1
        return f"None  # TODO[lift]: {c.kind.name}{(' ' + why) if why else ''} :: {' '.join(src(c).split())[:80]}"

    # ----------------------------- expressions ----------------------------- #
    def e(self, c) -> str:
        self.nodes += 1
        k = c.kind
        if k in (K.UNEXPOSED_EXPR, K.PAREN_EXPR, K.CXX_STATIC_CAST_EXPR,
                 K.CSTYLE_CAST_EXPR, K.CXX_FUNCTIONAL_CAST_EXPR):
            kids = [x for x in c.get_children() if x.kind != K.TYPE_REF]
            return self.e(kids[-1]) if kids else self._tok_fallback(c)
        if k in (K.INTEGER_LITERAL, K.FLOATING_LITERAL):
            t = toks(c); return (t[0].rstrip("uUlLfF") if t else "0")
        if k == K.CXX_BOOL_LITERAL_EXPR:
            return "True" if (toks(c) or ["false"])[0] == "true" else "False"
        if k == K.STRING_LITERAL:
            return c.spelling
        if k in (K.GNU_NULL_EXPR, K.CXX_NULL_PTR_LITERAL_EXPR):
            return "None"
        if k == K.CXX_THIS_EXPR:
            return "self"
        if k == K.DECL_REF_EXPR:
            return snake(c.spelling) if c.spelling else self._tok_fallback(c)
        if k == K.MEMBER_REF_EXPR:
            field = c.spelling
            kids = list(c.get_children())
            if field and kids:
                return f"{self.e(kids[0])}.{snake(field)}"
            # name-degraded chain: reconstruct from tokens (recovers state.dataX->f)
            return self._tok_fallback(c)
        if k == K.ARRAY_SUBSCRIPT_EXPR:
            a, i = list(c.get_children()); return f"{self.e(a)}[{self.e(i)}]"
        if k in (K.BINARY_OPERATOR, K.COMPOUND_ASSIGNMENT_OPERATOR):
            kids = list(c.get_children())
            if len(kids) == 2:
                return f"{self.e(kids[0])} {self._binop(c)} {self.e(kids[1])}"
        if k == K.UNARY_OPERATOR:
            kids = list(c.get_children()); op = (toks(c) or ["?"])[0]
            inner = self.e(kids[0]) if kids else "None"
            if op == "!": return f"(not {inner})"
            if op == "-": return f"(-{inner})"
            return inner
        if k == K.CONDITIONAL_OPERATOR:
            kids = list(c.get_children())
            if len(kids) == 3:
                return f"({self.e(kids[1])} if {self.e(kids[0])} else {self.e(kids[2])})"
        if k == K.CALL_EXPR:
            return self._call(c)
        return self._tok_fallback(c)

    def _tok_fallback(self, c) -> str:
        ts = toks(c)
        if ts and all(re.fullmatch(r"[A-Za-z_]\w*|->|\.|\[|\]|[0-9]+", t) for t in ts):
            return _toks_to_py(ts)
        return self.todo_expr(c)

    def _binop(self, c) -> str:
        kids = list(c.get_children())
        if len(kids) == 2:
            n = len(list(kids[0].get_tokens())); tk = toks(c)
            if n < len(tk):
                return {"&&": "and", "||": "or"}.get(tk[n], tk[n])
        return "?"

    def _call(self, c) -> str:
        argl = list(c.get_children())
        ref = c.referenced
        opname = (ref.spelling if ref else "") or c.spelling or ""
        if opname.startswith("operator"):
            op = opname[len("operator"):]
            recv = argl[0] if argl else None          # receiver is the object
            rest = argl[1:]
            if op in ("->", "*") and rest: return self.e(rest[-1])
            if op == "[]" and recv is not None and rest: return f"{self.e(recv)}[{self.e(rest[0])}]"
            if op == "()" and recv is not None:
                return f"{self.e(recv)}({', '.join(self.e(a) for a in rest)})"
            if op in ("+", "-", "*", "/", "%", "==", "!=", "<", "<=", ">", ">=") and len(rest) == 2:
                return f"{self.e(rest[0])} {op} {self.e(rest[1])}"
            return self.e(rest[-1]) if rest else "None"
        if argl and argl[0].kind == K.MEMBER_REF_EXPR:
            recv = argl[0]; meth = snake(recv.spelling)
            rest = [self.e(a) for a in argl[1:]]
            if not meth:        # name-degraded method -> recover the whole receiver chain from tokens
                return f"{self._tok_fallback(recv)}({', '.join(rest)})"
            rk = list(recv.get_children()); base = self.e(rk[0]) if rk else "self"
            if meth == "size" and not rest: return f"len({base})"
            return f"{base}.{meth}({', '.join(rest)})"
        # free call (or call through a name-degraded callee -> recover from tokens)
        if not opname and argl:
            return f"{self._tok_fallback(argl[0])}({', '.join(self.e(a) for a in argl[1:])})"
        name = snake(opname) if opname else "_call"
        return f"{name}({', '.join(self.e(a) for a in argl[1:])})"

    # ----------------------------- statements ------------------------------ #
    def stmt(self, c, ind) -> list[str]:
        self.nodes += 1
        k = c.kind; p = ind * IND
        if k == K.COMPOUND_STMT:
            out = []
            for ch in c.get_children():
                out += self.stmt(ch, ind)
            return out or [p + "pass"]
        if k == K.DECL_STMT:
            out = []
            for v in c.get_children():
                if v.kind == K.VAR_DECL:
                    init = [x for x in v.get_children()
                            if x.kind not in (K.TYPE_REF, K.TEMPLATE_REF, K.NAMESPACE_REF)]
                    out.append(f"{p}{snake(v.spelling)} = {self.e(init[-1]) if init else 'None'}")
            return out or [p + "pass"]
        if k == K.RETURN_STMT:
            kids = list(c.get_children())
            return [p + ("return " + self.e(kids[0]) if kids else "return")]
        if k == K.IF_STMT:
            kids = list(c.get_children())
            out = [f"{p}if {self.e(kids[0])}:"] + self._body(kids[1], ind + 1)
            if len(kids) > 2:
                out += [f"{p}else:"] + self._body(kids[2], ind + 1)
            return out
        if k == K.WHILE_STMT:
            kids = list(c.get_children())
            return [f"{p}while {self.e(kids[0])}:"] + self._body(kids[-1], ind + 1)
        if k == K.FOR_STMT:
            return self._for(c, ind)
        if k == K.BREAK_STMT:
            return [p + "break"]
        if k == K.CONTINUE_STMT:
            return [p + "continue"]
        if k == K.NULL_STMT:
            return []
        if k in (K.CALL_EXPR, K.BINARY_OPERATOR, K.COMPOUND_ASSIGNMENT_OPERATOR,
                 K.UNARY_OPERATOR, K.UNEXPOSED_EXPR, K.MEMBER_REF_EXPR, K.PAREN_EXPR):
            return [p + self._exprstmt(c)]
        self.todo += 1
        return [f"{p}pass  # TODO[lift]: {k.name} :: {' '.join(src(c).split())[:70]}"]

    def _body(self, c, ind):
        return self.stmt(c, ind) if c.kind == K.COMPOUND_STMT else self.stmt(c, ind)

    def _for(self, c, ind):
        p = ind * IND
        kids = list(c.get_children())
        body = kids[-1] if kids and kids[-1].kind == K.COMPOUND_STMT else None
        clauses = kids[:-1] if body is not None else kids
        if len(clauses) != 3:           # only the canonical for(init;cond;inc) form
            self.todo += 1
            return [f"{p}# TODO[lift]: {c.kind.name} :: {' '.join(src(c).split())[:70]}", p + "pass"]
        init, cond, inc = clauses
        out = (self.stmt(init, ind) if init.kind == K.DECL_STMT else [p + self._exprstmt(init)])
        out.append(f"{p}while {self.e(cond)}:")
        out += self.stmt(body, ind + 1) if body is not None else [p + IND + "pass"]
        out.append(p + IND + self._exprstmt(inc))
        return out

    def _exprstmt(self, c) -> str:
        if c.kind in (K.BINARY_OPERATOR, K.COMPOUND_ASSIGNMENT_OPERATOR):
            kids = list(c.get_children())
            if len(kids) == 2:
                op = self._binop(c)
                if op == "=" or op.endswith("="):
                    return f"{self.e(kids[0])} {op} {self.e(kids[1])}"
        if c.kind == K.UNARY_OPERATOR:
            t = toks(c); kids = list(c.get_children())
            if "++" in t: return f"{self.e(kids[0])} += 1"
            if "--" in t: return f"{self.e(kids[0])} -= 1"
        return self.e(c)

    # ------------------------------ top level ------------------------------ #
    def function(self, c, ind=0, cls=False):
        p = ind * IND
        params = ["self"] if cls else []
        params += [snake(a.spelling) or "arg" for a in c.get_arguments()]
        body = next((x for x in c.get_children() if x.kind == K.COMPOUND_STMT), None)
        name = snake(c.spelling)
        if body is None:
            return [f"{p}def {name}({', '.join(params)}): ...  # decl only"]
        return [f"{p}def {name}({', '.join(params)}):"] + self.stmt(body, ind + 1)

    def record(self, c):
        out = [f"class {c.spelling or 'Anon'}:", f"{IND}def __init__(self):"]
        fields = [f for f in c.get_children() if f.kind == K.FIELD_DECL]
        if not fields:
            out.append(f"{IND}{IND}pass")
        for f in fields:
            init = [x for x in f.get_children()
                    if x.kind not in (K.TYPE_REF, K.TEMPLATE_REF, K.NAMESPACE_REF)]
            default = self.e(init[-1]) if init else _default_for(f.type)
            out.append(f"{IND}{IND}self.{snake(f.spelling)} = {default}")
        for m in (x for x in c.get_children() if x.kind == K.CXX_METHOD and x.is_definition()):
            out.append("")
            out += [IND + ln for ln in self.function(m, ind=0, cls=True)]
        return out


def _default_for(t) -> str:
    s = t.spelling
    if "bool" in s: return "False"
    if any(x in s for x in ("double", "float", "Real64")): return "0.0"
    if any(x in s for x in ("string", "char")) and "*" not in s: return '""'
    if any(x in s for x in ("vector", "Array1D", "Array2D", "[")): return "[]"
    if "map" in s: return "{}"
    if any(x in s for x in ("int", "long", "short", "size_t", "Int")) and "*" not in s and "<" not in s:
        return "0"
    return "None"


# ----------------------------- public API ---------------------------------- #
def _emit(tu, path) -> tuple[str, dict]:
    lf = _Lifter()
    lines = [f'"""Lifted 1:1 from {os.path.basename(path)} (Phase-1 C++->Python lift)."""', ""]

    def from_file(c):
        f = c.location.file
        if not f:
            return False
        try:
            return os.path.samefile(f.name, path)
        except OSError:        # in-memory unsaved file (lift_source) — name compare
            return f.name == path or os.path.basename(f.name) == os.path.basename(path)

    def walk(node):
        for c in node.get_children():
            if c.kind == K.NAMESPACE:
                walk(c); continue
            if not from_file(c):
                continue
            if c.kind in (K.STRUCT_DECL, K.CLASS_DECL) and c.is_definition():
                lines.extend(lf.record(c)); lines.append("")
            elif c.kind in (K.FUNCTION_DECL, K.CXX_METHOD) and c.is_definition():
                lines.extend(lf.function(c)); lines.append("")

    walk(tu.cursor)
    return "\n".join(lines) + "\n", {"nodes": lf.nodes, "todo": lf.todo}


def lift_source(source: str, name: str = "input.cpp", inc=None) -> tuple[str, dict]:
    args = ["-std=c++17", "-x", "c++"] + [f"-I{d}" for d in (inc or [])]
    tu = ci.Index.create().parse(name, args=args, unsaved_files=[(name, source)])
    return _emit(tu, name)


def lift_file(path: str, inc=None) -> str:
    args = ["-std=c++17", "-x", "c++"] + [f"-I{d}" for d in (inc or [])]
    tu = ci.Index.create().parse(path, args=args)
    return _emit(tu, path)[0]


def main() -> None:
    import sys
    args = sys.argv[1:]
    out_path = None; incs = []
    if "--out" in args:
        i = args.index("--out"); out_path = args[i + 1]; del args[i:i + 2]
    while "--inc" in args:
        i = args.index("--inc"); incs.append(args[i + 1]); del args[i:i + 2]
    path = args[0]
    args2 = ["-std=c++17", "-x", "c++"] + [f"-I{d}" for d in incs]
    tu = ci.Index.create().parse(path, args=args2)
    text, st = _emit(tu, path)
    if out_path:
        open(out_path, "w").write(text)
    print(text)
    cov = 100 * (1 - st["todo"] / max(st["nodes"], 1))
    print(f"# lift: {st['nodes']} nodes, {st['todo']} TODO  (~{cov:.0f}% mechanical)", file=sys.stderr)


if __name__ == "__main__":
    main()
