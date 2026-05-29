#!/usr/bin/env python3
"""Never-refuse C++ -> Python "lift" (Phase-1 whole-program migration).

Unlike the strict HIR transpiler (which REFUSES unsupported constructs), this
lifter translates the whole file 1:1, architecture preserved, and emits a
`# TODO[lift]` stub for anything it can't yet handle — so it ALWAYS produces
output and scales to the entire EnergyPlus repo. Coverage improves by adding
node handlers (the TODO count shrinks); the EnergyPlus oracle validates.

  python scripts/lift_to_python.py FILE.cc [--out OUT.py]

Design choices (the "lift" conventions):
  * struct/class            -> Python class; fields -> __init__ defaults
  * `a->b` and `a.b`        -> `a.b`   (unique_ptr / ref / value all collapse)
  * EnergyPlusData &state   -> just a parameter typed `state` (the state object
                               is itself a lifted class)
  * (T)x / static_cast / T(x) -> value passed through (dynamic Python)
  * x.size()                -> len(x)
  * unknown node            -> `# TODO[lift]: <kind>` + best-effort raw snippet
"""
import os, re, sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))
from transpilers.frontends.cpp import parser as _cfg  # configures libclang  # noqa: F401
import clang.cindex as ci

K = ci.CursorKind
IND = "    "
_stats = {"nodes": 0, "todo": 0}

def snake(name: str) -> str:
    name = name.split("::")[-1]
    s = re.sub(r"(?<=[a-z0-9])(?=[A-Z])", "_", name)
    return s.lower() if s else name

def toks(c):
    return [t.spelling for t in c.get_tokens()]

def src(c) -> str:
    try:
        e = c.extent
        raw = open(e.start.file.name, "rb").read()[e.start.offset:e.end.offset]
        return raw.decode("utf-8", "replace")
    except Exception:
        return c.spelling or "?"

def todo(c, why=""):
    _stats["todo"] += 1
    snippet = " ".join(src(c).split())[:90]
    return f"None  # TODO[lift]: {c.kind.name}{(' '+why) if why else ''} :: {snippet}"

# ---------- expressions ----------
def e(c) -> str:
    _stats["nodes"] += 1
    k = c.kind
    if k in (K.UNEXPOSED_EXPR, K.PAREN_EXPR, K.CXX_STATIC_CAST_EXPR,
             K.CSTYLE_CAST_EXPR, K.CXX_FUNCTIONAL_CAST_EXPR):
        kids = [x for x in c.get_children() if x.kind != K.TYPE_REF]
        return e(kids[-1]) if kids else "None"
    if k == K.INTEGER_LITERAL or k == K.FLOATING_LITERAL:
        t = toks(c); return (t[0].rstrip("uUlLfF") if t else "0")
    if k == K.CXX_BOOL_LITERAL_EXPR:
        return "True" if (toks(c) or ["false"])[0] == "true" else "False"
    if k == K.STRING_LITERAL:
        return c.spelling
    if k == K.DECL_REF_EXPR:
        return snake(c.spelling)
    if k == K.MEMBER_REF_EXPR:
        kids = list(c.get_children())
        base = e(kids[0]) if kids else "self"
        return f"{base}.{snake(c.spelling)}"
    if k == K.ARRAY_SUBSCRIPT_EXPR:
        a, i = list(c.get_children()); return f"{e(a)}[{e(i)}]"
    if k == K.BINARY_OPERATOR or k == K.COMPOUND_ASSIGNMENT_OPERATOR:
        kids = list(c.get_children())
        if len(kids) == 2:
            op = _binop(c)
            return f"{e(kids[0])} {op} {e(kids[1])}"
    if k == K.UNARY_OPERATOR:
        kids = list(c.get_children()); op = (toks(c) or ["?"])[0]
        inner = e(kids[0]) if kids else "None"
        if op == "!": return f"(not {inner})"
        if op == "-": return f"(-{inner})"
        if op in ("++", "--"): return inner  # effect handled at stmt level (approx)
        return inner
    if k == K.CALL_EXPR:
        argl = list(c.get_children())
        ref = c.referenced
        opname = (ref.spelling if ref else "") or c.spelling or ""
        # Overloaded operators (unique_ptr->, vector[], etc.) appear as CALL_EXPR.
        if opname.startswith("operator"):
            op = opname[len("operator"):]
            rest = argl[1:]  # argl[0] is the operator callee ref
            if op in ("->", "*") and rest:          # smart-ptr/iterator deref -> the object
                return e(rest[-1])
            if op == "[]" and len(rest) >= 2:
                return f"{e(rest[0])}[{e(rest[1])}]"
            if op == "()" and rest:
                return f"{e(rest[0])}({', '.join(e(a) for a in rest[1:])})"
            if op in ("+", "-", "*", "/", "%", "==", "!=", "<", "<=", ">", ">=") and len(rest) == 2:
                return f"{e(rest[0])} {op} {e(rest[1])}"
            return e(rest[-1]) if rest else "None"
        # method call x.f(...) — callee is a MEMBER_REF_EXPR
        if argl and argl[0].kind == K.MEMBER_REF_EXPR:
            recv = argl[0]; meth = snake(recv.spelling)
            rkids = list(recv.get_children())
            base = e(rkids[0]) if rkids else "self"
            rest = [e(a) for a in argl[1:]]
            if meth == "size" and not rest:
                return f"len({base})"
            return f"{base}.{meth}({', '.join(rest)})"
        # free call f(...) — argl[0] is the callee ref; real args follow
        name = snake(opname) if opname else "_call"
        rest = [e(a) for a in argl[1:]]
        return f"{name}({', '.join(rest)})"
    if k == K.CXX_THIS_EXPR:
        return "self"
    if k == K.CONDITIONAL_OPERATOR:
        kids = list(c.get_children())
        if len(kids) == 3:
            return f"({e(kids[1])} if {e(kids[0])} else {e(kids[2])})"
    if k == K.GNU_NULL_EXPR or k == K.CXX_NULL_PTR_LITERAL_EXPR:
        return "None"
    return todo(c)

def _binop(c) -> str:
    # token-based: find the operator token between the two operands
    kids = list(c.get_children())
    if len(kids) == 2:
        n = len(list(kids[0].get_tokens()))
        tk = toks(c)
        if n < len(tk):
            op = tk[n]
            return {"&&": "and", "||": "or", "!=": "!=", "==": "==",
                    "=": "="}.get(op, op)
    return "?"

# ---------- statements ----------
def stmt(c, ind):
    _stats["nodes"] += 1
    k = c.kind
    p = ind * IND
    if k == K.COMPOUND_STMT:
        out = []
        for ch in c.get_children():
            out += stmt(ch, ind)
        return out or [p + "pass"]
    if k == K.DECL_STMT:
        out = []
        for v in c.get_children():
            if v.kind == K.VAR_DECL:
                init = [x for x in v.get_children()
                        if x.kind not in (K.TYPE_REF, K.TEMPLATE_REF, K.NAMESPACE_REF)]
                rhs = e(init[-1]) if init else "None"
                out.append(f"{p}{snake(v.spelling)} = {rhs}")
        return out or [p + "pass"]
    if k == K.RETURN_STMT:
        kids = list(c.get_children())
        return [p + ("return " + e(kids[0]) if kids else "return")]
    if k == K.IF_STMT:
        kids = list(c.get_children())
        cond = e(kids[0]); out = [f"{p}if {cond}:"]
        out += stmt(kids[1], ind + 1) if len(kids) > 1 and kids[1].kind == K.COMPOUND_STMT else _wrap(kids[1], ind + 1) if len(kids) > 1 else [p + IND + "pass"]
        if len(kids) > 2:
            out.append(f"{p}else:")
            out += stmt(kids[2], ind + 1) if kids[2].kind == K.COMPOUND_STMT else _wrap(kids[2], ind + 1)
        return out
    if k == K.WHILE_STMT:
        kids = list(c.get_children())
        out = [f"{p}while {e(kids[0])}:"]
        out += stmt(kids[-1], ind + 1) if kids[-1].kind == K.COMPOUND_STMT else _wrap(kids[-1], ind + 1)
        return out
    if k in (K.FOR_STMT, K.CXX_FOR_RANGE_STMT):
        return [f"{p}# TODO[lift]: {k.name} loop", p + "pass  # " + " ".join(src(c).split())[:70]]
    if k == K.BREAK_STMT:
        return [p + "break"]
    if k == K.CONTINUE_STMT:
        return [p + "continue"]
    if k == K.NULL_STMT:
        return []
    # expression-statement (call, assignment, ++/--)
    if k in (K.CALL_EXPR, K.BINARY_OPERATOR, K.COMPOUND_ASSIGNMENT_OPERATOR,
             K.UNARY_OPERATOR, K.UNEXPOSED_EXPR, K.MEMBER_REF_EXPR, K.PAREN_EXPR):
        return [p + _exprstmt(c, ind)]
    return [p + "# " + todo(c)]

def _exprstmt(c, ind):
    # handle assignment / ++ / -- specially, else plain expression
    if c.kind in (K.BINARY_OPERATOR, K.COMPOUND_ASSIGNMENT_OPERATOR):
        kids = list(c.get_children())
        if len(kids) == 2:
            op = _binop(c)
            if op == "=" or op.endswith("="):
                return f"{e(kids[0])} {op} {e(kids[1])}"
    if c.kind == K.UNARY_OPERATOR:
        kids = list(c.get_children()); t = (toks(c) or [""])
        if "++" in t: return f"{e(kids[0])} += 1"
        if "--" in t: return f"{e(kids[0])} -= 1"
    return e(c)

def _wrap(c, ind):  # single (non-compound) statement body
    return stmt(c, ind)

# ---------- top level ----------
def lift_function(c, ind=0, cls=False):
    p = ind * IND
    params = [("self" if cls else None)] if cls else []
    params = ["self"] if cls else []
    for a in c.get_arguments():
        params.append(snake(a.spelling) or "arg")
    body_cur = next((x for x in c.get_children() if x.kind == K.COMPOUND_STMT), None)
    name = snake(c.spelling)
    out = [f"{p}def {name}({', '.join(params)}):"]
    if body_cur is None:
        return [f"{p}def {name}({', '.join(params)}): ...  # decl only"]
    out += stmt(body_cur, ind + 1)
    return out

def lift_record(c):
    name = c.spelling or "Anon"
    out = [f"class {name}:", f"{IND}def __init__(self):"]
    fields = [f for f in c.get_children() if f.kind == K.FIELD_DECL]
    if not fields:
        out.append(f"{IND}{IND}pass")
    for f in fields:
        init = [x for x in f.get_children() if x.kind not in (K.TYPE_REF, K.TEMPLATE_REF, K.NAMESPACE_REF)]
        default = e(init[-1]) if init else _default_for(f.type)
        out.append(f"{IND}{IND}self.{snake(f.spelling)} = {default}")
    methods = [m for m in c.get_children()
               if m.kind in (K.CXX_METHOD,) and m.is_definition()]
    for m in methods:
        out.append("")
        out += [IND + ln for ln in lift_function(m, ind=0, cls=True)]
    return out

def _default_for(t) -> str:
    s = t.spelling
    if any(x in s for x in ("int", "long", "short", "size_t")) and "*" not in s and "<" not in s: return "0"
    if any(x in s for x in ("double", "float", "Real64")): return "0.0"
    if "bool" in s: return "False"
    if any(x in s for x in ("string", "char")): return '""'
    if any(x in s for x in ("vector", "Array1D", "Array2D", "list", "[")): return "[]"
    if "map" in s: return "{}"
    return "None"

def main():
    args = sys.argv[1:]
    out_path = None
    incs = []
    if "--out" in args:
        i = args.index("--out"); out_path = args[i+1]; del args[i:i+2]
    while "--inc" in args:
        i = args.index("--inc"); incs.append(args[i+1]); del args[i:i+2]
    path = args[0]
    idx = ci.Index.create()
    parse_args = ["-std=c++17", "-x", "c++"] + [f"-I{d}" for d in incs]
    tu = idx.parse(path, args=parse_args,
                   options=ci.TranslationUnit.PARSE_DETAILED_PROCESSING_RECORD)
    lines = [f'"""Lifted 1:1 from {os.path.basename(path)} (Phase-1 C++->Python lift). Auto-generated."""', ""]
    def from_file(c):
        try: return c.location.file and os.path.samefile(c.location.file.name, path)
        except Exception: return False
    def walk(node):
        for c in node.get_children():
            if not from_file(c):
                if c.kind in (K.NAMESPACE,):  # descend into namespaces from this file? check children
                    walk(c)
                continue
            if c.kind in (K.STRUCT_DECL, K.CLASS_DECL) and c.is_definition():
                lines.extend(lift_record(c)); lines.append("")
            elif c.kind in (K.FUNCTION_DECL, K.CXX_METHOD) and c.is_definition():
                lines.extend(lift_function(c)); lines.append("")
            elif c.kind == K.NAMESPACE:
                walk(c)
    walk(tu.cursor)
    text = "\n".join(lines) + "\n"
    if out_path:
        open(out_path, "w").write(text)
    print(text)
    cov = 100 * (1 - _stats["todo"] / max(_stats["nodes"], 1))
    print(f"# lift stats: {_stats['nodes']} nodes, {_stats['todo']} TODO  (~{cov:.0f}% mechanical)", file=sys.stderr)

if __name__ == "__main__":
    main()
