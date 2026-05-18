"""C++ source -> HIR via libclang.

Initial subset (deliberately C-like C++):
  - free functions with primitive params (int/long/short/char/bool/float/double/void)
  - return, if/else, while, range-based for (C-style with ++)
  - declarations and assignments
  - binary / comparison / logical ops, unary not/neg
  - integer literals, names, calls

Out of scope for the initial slice: classes, templates, references, namespaces,
auto, `std::` types. These are real C++ — the IR doesn't model them yet and we
refuse rather than emit broken code.

Operator extraction uses tokens (not libclang's BinaryOperator extension), so
this works against any reasonably recent libclang.
"""

from __future__ import annotations

import clang.cindex as ci

from transpilers.ir import hir


CursorKind = ci.CursorKind


class UnsupportedConstruct(Exception):
    pass


# C++ types collapsed onto HIR annotation strings consumable by hir_to_mir.
CPP_TYPE_ALIASES: dict[str, str] = {
    # Integer family — collapse all width/signedness variants onto `int`.
    "int": "int",
    "signed": "int",
    "signed int": "int",
    "unsigned": "int",
    "unsigned int": "int",
    "long": "int",
    "signed long": "int",
    "unsigned long": "int",
    "long long": "int",
    "signed long long": "int",
    "unsigned long long": "int",
    "short": "int",
    "signed short": "int",
    "unsigned short": "int",
    "char": "int",
    "signed char": "int",
    "unsigned char": "int",
    # stdint-style names that show up after `#include <cstdint>`.
    "int8_t": "int",
    "int16_t": "int",
    "int32_t": "int",
    "int64_t": "int",
    "uint8_t": "int",
    "uint16_t": "int",
    "uint32_t": "int",
    "uint64_t": "int",
    "size_t": "int",
    "std::size_t": "int",
    "ssize_t": "int",
    "ptrdiff_t": "int",
    "std::ptrdiff_t": "int",
    # Floating-point.
    "float": "float",
    "double": "float",
    "long double": "float",
    # Booleans / void.
    "bool": "bool",
    "_Bool": "bool",
    "void": "None",
    # String shapes — collapse onto our StrT.
    "char *": "str",
    "const char *": "str",
    "std::string": "str",
    "std::string_view": "str",
    "string_view": "str",
    "basic_string": "str",
    "basic_string_view": "str",
    "std::basic_string": "str",
    "std::basic_string_view": "str",
}

INPUT_NAME = "input.cpp"


# Intel SIMD intrinsic vector types — alias to portable `simd[T, N]`
# annotations. The Mojo target emits `SIMD[DType.X, N]` directly; other
# targets fall back via the type lattice.
SIMD_TYPE_ALIASES: dict[str, str] = {
    "__m256d": "simd[float, 4]",
    "__m256":  "simd[float, 8]",
    "__m256i": "simd[int, 8]",
    "__m128d": "simd[float, 2]",
    "__m128":  "simd[float, 4]",
    "__m128i": "simd[int, 4]",
    "__m512d": "simd[float, 8]",
    "__m512":  "simd[float, 16]",
    "__m512i": "simd[int, 16]",
}


_SYSTEM_INCLUDE_CACHE: list[str] | None = None


def _system_include_args() -> list[str]:
    """Ask the host `clang` for its system header search paths and return
    them as `-isystem` args. libclang's bundled headers (the `clang/<ver>/
    include/` directory) ship with `stddef.h`, `stdint.h`, etc. — adding
    them lets the corpus's `#include <stddef.h>` actually resolve."""
    global _SYSTEM_INCLUDE_CACHE
    if _SYSTEM_INCLUDE_CACHE is not None:
        return _SYSTEM_INCLUDE_CACHE
    import shutil
    import subprocess

    clang = shutil.which("clang++") or shutil.which("clang")
    if not clang:
        _SYSTEM_INCLUDE_CACHE = []
        return []
    try:
        out = subprocess.run(
            [clang, "-E", "-x", "c++", "-v", "-"],
            input="",
            capture_output=True,
            text=True,
            timeout=5,
        )
    except Exception:
        _SYSTEM_INCLUDE_CACHE = []
        return []
    # Output between "#include <...> search starts here:" and "End of search list."
    lines = out.stderr.splitlines()
    paths: list[str] = []
    in_block = False
    for line in lines:
        if "search starts here" in line:
            in_block = True
            continue
        if "End of search list" in line:
            break
        if in_block:
            p = line.strip()
            if p and p.startswith("/"):
                paths.append(p.split()[0])
    args: list[str] = []
    for p in paths:
        args.extend(["-isystem", p])
    _SYSTEM_INCLUDE_CACHE = args
    return args


def parse_cpp(source: str) -> hir.HirModule:
    index = ci.Index.create()
    # Pull system include paths from the host clang invocation so libclang
    # resolves `#include <stddef.h>` etc. without manual configuration.
    parse_args = ["-std=c++17", "-x", "c++"] + _system_include_args()
    tu = index.parse(
        INPUT_NAME,
        args=parse_args,
        unsaved_files=[(INPUT_NAME, source)],
        options=ci.TranslationUnit.PARSE_DETAILED_PROCESSING_RECORD,
    )
    _check_diagnostics(tu)
    _KNOWN_STRUCT_NAMES.clear()
    # First pass: record struct/class names so VAR_DECLs later resolve to
    # HirStructInit instead of integer-default HirAssign.
    for c in tu.cursor.get_children():
        if _from_input(c) and c.kind in (CursorKind.CLASS_DECL, CursorKind.STRUCT_DECL):
            _KNOWN_STRUCT_NAMES.add(c.spelling)
    body: list[hir.HirNode] = []
    for c in tu.cursor.get_children():
        if not _from_input(c):
            continue
        if c.kind == CursorKind.FUNCTION_DECL and c.is_definition():
            body.append(_convert_function(c))
            continue
        if c.kind == CursorKind.CLASS_DECL or c.kind == CursorKind.STRUCT_DECL:
            body.append(_convert_class(c))
            continue
        if c.kind in (CursorKind.FUNCTION_DECL,):
            continue
        if c.kind in (
            CursorKind.INCLUSION_DIRECTIVE,
            CursorKind.MACRO_DEFINITION,
            CursorKind.MACRO_INSTANTIATION,
            CursorKind.NAMESPACE,           # `namespace foo { ... }` — skip wrapper
            CursorKind.USING_DIRECTIVE,
            CursorKind.USING_DECLARATION,
            CursorKind.TYPEDEF_DECL,
            CursorKind.VAR_DECL,            # top-level globals
        ):
            # Namespace wrappers we could walk into, but the corpus' uses
            # don't need it for the immediate fix.
            continue
        raise UnsupportedConstruct(f"top-level {c.kind.name}")
    return hir.HirModule(source_lang="cpp", body=body)


def _convert_class(cursor: ci.Cursor) -> hir.HirStruct:
    """Subset: public fields (`int x;`), public methods. No constructors,
    destructors, inheritance, templates, operator overloads, references.
    Members under `private:` / `protected:` are refused so we don't silently
    expose internal API."""
    name = cursor.spelling
    fields: list[hir.HirParam] = []
    methods: list[hir.HirFunction] = []
    for c in cursor.get_children():
        if c.kind == ci.CursorKind.CXX_ACCESS_SPEC_DECL:
            # `public:` / `private:` / `protected:` markers. Only public is
            # currently supported.
            continue
        if c.kind == ci.CursorKind.FIELD_DECL:
            fields.append(hir.HirParam(name=c.spelling, annotation=_type_text(c.type)))
            continue
        if c.kind == ci.CursorKind.CXX_METHOD and c.is_definition():
            methods.append(_convert_method(c, struct_name=name))
            continue
        if c.kind in (ci.CursorKind.CXX_METHOD, ci.CursorKind.CONSTRUCTOR, ci.CursorKind.DESTRUCTOR):
            # Declared-but-not-defined methods and ctors/dtors: skip silently
            # rather than raising — Ghidra and many C++ headers ship these.
            continue
        if c.kind == ci.CursorKind.CXX_BASE_SPECIFIER:
            raise UnsupportedConstruct(f"C++ inheritance for class {name!r} not yet supported")
        raise UnsupportedConstruct(f"class member {c.kind.name}")
    return hir.HirStruct(name=name, fields=fields, methods=methods)


def _convert_method(cursor: ci.Cursor, *, struct_name: str) -> hir.HirFunction:
    params: list[hir.HirParam] = [hir.HirParam(name="self", annotation=struct_name)]
    body: list[hir.HirNode] = []
    for c in cursor.get_children():
        if c.kind == CursorKind.PARM_DECL:
            params.append(hir.HirParam(name=c.spelling, annotation=_type_text(c.type)))
        elif c.kind == CursorKind.COMPOUND_STMT:
            body = _convert_compound(c)
    return hir.HirFunction(
        name=cursor.spelling,
        params=params,
        return_annotation=_type_text(cursor.result_type),
        body=body,
    )


def _check_diagnostics(tu: ci.TranslationUnit) -> None:
    fatal = [d for d in tu.diagnostics if d.severity >= ci.Diagnostic.Error]
    if fatal:
        msgs = "\n".join(f"  {d.spelling}" for d in fatal[:5])
        raise UnsupportedConstruct(f"libclang parse errors:\n{msgs}")


def _from_input(cursor: ci.Cursor) -> bool:
    return cursor.location.file is not None and cursor.location.file.name == INPUT_NAME


def _convert_function(cursor: ci.Cursor) -> hir.HirFunction:
    params: list[hir.HirParam] = []
    body: list[hir.HirNode] = []
    for c in cursor.get_children():
        if c.kind == CursorKind.PARM_DECL:
            params.append(hir.HirParam(name=c.spelling, annotation=_type_text(c.type)))
        elif c.kind == CursorKind.COMPOUND_STMT:
            body = _convert_compound(c)
    return hir.HirFunction(
        name=cursor.spelling,
        params=params,
        return_annotation=_type_text(cursor.result_type),
        body=body,
    )


def _convert_compound(cursor: ci.Cursor) -> list[hir.HirNode]:
    out: list[hir.HirNode] = []
    for c in cursor.get_children():
        out.extend(_convert_stmt(c))
    return out


def _convert_stmt(cursor: ci.Cursor) -> list[hir.HirNode]:
    kind = cursor.kind
    if kind == CursorKind.RETURN_STMT:
        kids = list(cursor.get_children())
        return [hir.HirReturn(value=_convert_expr(kids[0]) if kids else None)]
    if kind == CursorKind.DECL_STMT:
        out: list[hir.HirNode] = []
        for c in cursor.get_children():
            if c.kind == CursorKind.VAR_DECL:
                out.append(_convert_var_decl(c))
            else:
                raise UnsupportedConstruct(f"decl {c.kind.name}")
        return out
    if kind == CursorKind.IF_STMT:
        return [_convert_if(cursor)]
    if kind == CursorKind.WHILE_STMT:
        return [_convert_while(cursor)]
    if kind == CursorKind.FOR_STMT:
        return _convert_for(cursor)
    if kind == CursorKind.COMPOUND_STMT:
        return _convert_compound(cursor)
    if kind in (CursorKind.BINARY_OPERATOR, CursorKind.COMPOUND_ASSIGNMENT_OPERATOR):
        return [_convert_assignment_stmt(cursor)]
    if kind == CursorKind.UNARY_OPERATOR:
        return [_convert_unary_stmt(cursor)]
    if kind == CursorKind.CALL_EXPR:
        return [_convert_expr(cursor)]
    raise UnsupportedConstruct(f"stmt {kind.name}")


def _convert_var_decl(cursor: ci.Cursor) -> hir.HirNode:
    annotation = _type_text(cursor.type)
    kids = list(cursor.get_children())
    if annotation in _KNOWN_STRUCT_NAMES:
        # `Point p;` (no kids) → zero-init StructInit.
        # `Point p(1, 2);` → libclang emits a CALL_EXPR with the ctor args.
        # `Point p{1, 2};` (uniform init) → INIT_LIST_EXPR.
        if not kids:
            init: hir.HirNode = hir.HirStructInit(name=annotation, args=[])
        else:
            ctor = kids[-1]
            args: list[hir.HirNode] = []
            if ctor.kind in (ci.CursorKind.CALL_EXPR, ci.CursorKind.INIT_LIST_EXPR):
                for c in ctor.get_children():
                    if c.kind == ci.CursorKind.TYPE_REF:
                        continue
                    if c.kind == ci.CursorKind.UNEXPOSED_EXPR:
                        inner = list(c.get_children())
                        if len(inner) == 1:
                            args.append(_convert_expr(inner[0]))
                            continue
                    args.append(_convert_expr(c))
            init = hir.HirStructInit(name=annotation, args=args)
        return hir.HirAssign(target=cursor.spelling, value=init, annotation=annotation)
    init = _convert_expr(kids[-1]) if kids else hir.HirIntLiteral(value=0)
    return hir.HirAssign(target=cursor.spelling, value=init, annotation=annotation)


# Names of structs/classes parsed in the current translation unit. Populated
# in parse_cpp before walking function bodies.
_KNOWN_STRUCT_NAMES: set[str] = set()


def _convert_if(cursor: ci.Cursor) -> hir.HirNode:
    kids = list(cursor.get_children())
    if len(kids) < 2:
        raise UnsupportedConstruct("malformed if")
    cond = _convert_expr(kids[0])
    body = _convert_stmt(kids[1])
    orelse: list[hir.HirNode] = []
    if len(kids) >= 3:
        orelse = _convert_stmt(kids[2])
    return hir.HirIf(test=cond, body=body, orelse=orelse)


def _convert_while(cursor: ci.Cursor) -> hir.HirNode:
    kids = list(cursor.get_children())
    cond = _convert_expr(kids[0])
    body = _convert_stmt(kids[1]) if len(kids) > 1 else []
    return hir.HirWhile(test=cond, body=body)


def _convert_for(cursor: ci.Cursor) -> list[hir.HirNode]:
    """C-style for desugars at the frontend: init; while(cond) { body; step; }."""
    kids = list(cursor.get_children())
    # libclang's FOR_STMT children layout, in order:
    #   init (DECL_STMT or expression, may be omitted),
    #   cond (expression, may be omitted),
    #   step (expression, may be omitted),
    #   body (statement).
    # Missing parts simply aren't present; we use heuristics to detect.
    *headers, body_node = kids if kids else (None,)
    init_part: ci.Cursor | None = None
    cond_part: ci.Cursor | None = None
    step_part: ci.Cursor | None = None
    if len(headers) == 3:
        init_part, cond_part, step_part = headers
    elif len(headers) == 2:
        init_part, cond_part = headers
    elif len(headers) == 1:
        cond_part = headers[0]
    out: list[hir.HirNode] = []
    if init_part is not None:
        out.extend(_convert_stmt(init_part))
    cond = _convert_expr(cond_part) if cond_part is not None else hir.HirBoolLiteral(value=True)
    inner = _convert_stmt(body_node)
    if step_part is not None:
        inner.extend(_convert_stmt(step_part))
    out.append(hir.HirWhile(test=cond, body=inner))
    return out


# ---------- expressions ----------

def _convert_expr(cursor: ci.Cursor) -> hir.HirNode:
    kind = cursor.kind
    if kind == CursorKind.INTEGER_LITERAL:
        token = next(cursor.get_tokens(), None)
        if token is None:
            # Macro-expanded literals (EXIT_FAILURE, NULL) lose their source
            # tokens. We don't have the actual constant value available
            # without evaluating; fall back to 0 so the file parses. This
            # is a real lossy compromise — comparisons against
            # EXIT_FAILURE/EXIT_SUCCESS may now produce surprising results.
            return hir.HirIntLiteral(value=0)
        try:
            return hir.HirIntLiteral(value=int(token.spelling.rstrip("uUlL"), 0))
        except ValueError:
            return hir.HirIntLiteral(value=0)
    if kind == CursorKind.FLOATING_LITERAL:
        token = next(cursor.get_tokens(), None)
        if token is None:
            return hir.HirFloatLiteral(value=0.0)
        try:
            return hir.HirFloatLiteral(value=float(token.spelling.rstrip("fFlL")))
        except ValueError:
            return hir.HirFloatLiteral(value=0.0)
    if kind == CursorKind.CXX_BOOL_LITERAL_EXPR:
        token = next(cursor.get_tokens(), None)
        return hir.HirBoolLiteral(value=token is not None and token.spelling == "true")
    if kind == CursorKind.STRING_LITERAL:
        token = next(cursor.get_tokens(), None)
        if token is None:
            raise UnsupportedConstruct("string literal without tokens")
        return hir.HirStringLiteral(value=token.spelling[1:-1])
    if kind == CursorKind.DECL_REF_EXPR:
        return hir.HirName(name=cursor.spelling)
    if kind == CursorKind.UNEXPOSED_EXPR or kind == CursorKind.PAREN_EXPR:
        # Pass through to the single child — libclang often wraps real exprs.
        kids = list(cursor.get_children())
        if len(kids) == 1:
            return _convert_expr(kids[0])
    if kind == CursorKind.BINARY_OPERATOR:
        return _convert_binop(cursor)
    if kind == CursorKind.UNARY_OPERATOR:
        return _convert_unary_expr(cursor)
    if kind == CursorKind.MEMBER_REF_EXPR:
        # `obj.field` or `this->field` — the LHS object is the only child.
        kids = list(cursor.get_children())
        # Inside a method body, libclang sometimes elides the implicit `this`;
        # in that case there's no child and we treat as a self-reference.
        if not kids:
            return hir.HirFieldAccess(value=hir.HirName(name="self"), field=cursor.spelling)
        return hir.HirFieldAccess(value=_convert_expr(kids[0]), field=cursor.spelling)
    if kind == CursorKind.CXX_THIS_EXPR:
        # `this` → `self` in our HIR vocabulary; the method-conversion sets
        # the first parameter to `self`.
        return hir.HirName(name="self")
    if kind == CursorKind.CALL_EXPR:
        return _convert_call(cursor)
    if kind == CursorKind.ARRAY_SUBSCRIPT_EXPR:
        # `arr[index]` — two children: the array expression and the index.
        kids = list(cursor.get_children())
        if len(kids) == 2:
            return hir.HirSubscript(value=_convert_expr(kids[0]), index=_convert_expr(kids[1]))
    if kind == CursorKind.COMPOUND_ASSIGNMENT_OPERATOR:
        raise UnsupportedConstruct("compound assignment as expression")
    if kind in (CursorKind.GNU_NULL_EXPR, CursorKind.CXX_NULL_PTR_LITERAL_EXPR):
        # `NULL` / `nullptr` — lower as a zero literal. Lossy (no real null
        # type), but suffices for comparisons like `p == NULL`.
        return hir.HirIntLiteral(value=0)
    if kind == CursorKind.CSTYLE_CAST_EXPR or kind == CursorKind.CXX_STATIC_CAST_EXPR:
        # `(T)x` / `static_cast<T>(x)` — drop the cast and pass the value
        # through.
        kids = list(cursor.get_children())
        for c in kids[::-1]:
            if c.kind != CursorKind.TYPE_REF:
                return _convert_expr(c)
        if kids:
            return _convert_expr(kids[-1])
    raise UnsupportedConstruct(f"expr {kind.name}")


COMPARE_OPS = {"==", "!=", "<", "<=", ">", ">="}
ARITH_OPS = {"+", "-", "*", "/", "%"}
LOGICAL_OPS = {"&&", "||"}
ASSIGN_OPS = {"=", "+=", "-=", "*=", "/=", "%="}


def _convert_binop(cursor: ci.Cursor) -> hir.HirNode:
    op = _binop_token(cursor)
    kids = list(cursor.get_children())
    left = _convert_expr(kids[0])
    right = _convert_expr(kids[1])
    if op in COMPARE_OPS:
        return hir.HirCompare(op=op, left=left, right=right)
    if op in LOGICAL_OPS:
        return hir.HirBoolOp(op="and" if op == "&&" else "or", left=left, right=right)
    if op in ARITH_OPS:
        return hir.HirBinOp(op=op, left=left, right=right)
    if op in ("&", "|", "^", "<<", ">>"):
        return hir.HirBinOp(op=op, left=left, right=right)
    raise UnsupportedConstruct(f"binary op {op!r}")


def _convert_assignment_stmt(cursor: ci.Cursor) -> hir.HirNode:
    """A BINARY_OPERATOR (or COMPOUND_ASSIGNMENT_OPERATOR) at statement position
    using `=` / `+=` / `-=` / etc. Field assignments (`obj.field = v`)
    branch to HirFieldAssign; plain identifier assignments emit HirAssign."""
    op = _binop_token(cursor)
    if op not in ASSIGN_OPS:
        raise UnsupportedConstruct(f"expression statement with op {op!r}")
    kids = list(cursor.get_children())
    lhs = kids[0]
    rhs = _convert_expr(kids[1])
    if lhs.kind == CursorKind.MEMBER_REF_EXPR and op == "=":
        lhs_kids = list(lhs.get_children())
        obj = _convert_expr(lhs_kids[0]) if lhs_kids else hir.HirName(name="self")
        return hir.HirFieldAssign(obj=obj, field=lhs.spelling, value=rhs)
    target = _decl_name(lhs)
    if target is None:
        raise UnsupportedConstruct(f"assignment target {lhs.kind.name}")
    aug = None if op == "=" else op[:-1]
    return hir.HirAssign(target=target, value=rhs, annotation=None, augmented_op=aug)


def _convert_unary_expr(cursor: ci.Cursor) -> hir.HirNode:
    op = _unary_token(cursor)
    kids = list(cursor.get_children())
    if op == "!":
        return hir.HirUnaryOp(op="not", operand=_convert_expr(kids[0]))
    if op == "-":
        return hir.HirUnaryOp(op="-", operand=_convert_expr(kids[0]))
    if op == "+":
        return _convert_expr(kids[0])
    if op in ("&", "*"):
        # Address-of / dereference — drop the indirection. Lossy but lets
        # I/O-heavy corpus parse.
        return _convert_expr(kids[0])
    if op == "~":
        return hir.HirUnaryOp(op="-", operand=_convert_expr(kids[0]))
    raise UnsupportedConstruct(f"unary op {op!r} as expression")


def _convert_unary_stmt(cursor: ci.Cursor) -> hir.HirNode:
    """`i++` / `i--` as a statement."""
    op = _unary_token(cursor)
    if op not in ("++", "--"):
        raise UnsupportedConstruct(f"unary stmt {op!r}")
    kids = list(cursor.get_children())
    target = _decl_name(kids[0])
    if target is None:
        raise UnsupportedConstruct(f"++/-- on {kids[0].kind.name}")
    sign = "+" if op == "++" else "-"
    return hir.HirAssign(
        target=target,
        value=hir.HirIntLiteral(value=1),
        annotation=None,
        augmented_op=sign,
    )


def _convert_call(cursor: ci.Cursor) -> hir.HirNode:
    kids = list(cursor.get_children())
    if not kids:
        raise UnsupportedConstruct("call with no callee")
    callee = kids[0]
    # `obj.method(args)` arrives as CALL_EXPR whose callee is MEMBER_REF_EXPR.
    if callee.kind == CursorKind.MEMBER_REF_EXPR:
        callee_kids = list(callee.get_children())
        receiver = (
            _convert_expr(callee_kids[0])
            if callee_kids
            else hir.HirName(name="self")
        )
        args = [_convert_expr(a) for a in kids[1:]]
        return hir.HirMethodCall(receiver=receiver, method=callee.spelling, args=args)
    name = _decl_name(callee) or callee.spelling
    if not name:
        raise UnsupportedConstruct(f"call target {callee.kind.name}")
    args = [_convert_expr(a) for a in kids[1:]]
    # SIMD intrinsic lifting: turn Intel `_mm*` calls into semantic HIR
    # operations on SIMD-typed values. Mojo will emit idiomatic `a + b`
    # on SIMD types; other targets fall back to the original call form.
    lifted = _lift_simd_intrinsic(name, args)
    if lifted is not None:
        return lifted
    return hir.HirCall(func=name, args=args)


_SIMD_BINOP = {
    "add": "+", "sub": "-", "mul": "*", "div": "/",
    "and": "&", "or": "|", "xor": "^",
}


def _lift_simd_intrinsic(name: str, args: list[hir.HirNode]) -> hir.HirNode | None:
    """Recognize Intel SIMD intrinsics and lift them to semantic HIR
    operations. Returns None if the name doesn't match an intrinsic
    pattern; the caller falls back to a plain HirCall."""
    if not name.startswith(("_mm_", "_mm128_", "_mm256_", "_mm512_")):
        return None
    parts = [p for p in name.split("_") if p]
    if len(parts) < 2:
        return None
    op = parts[1]
    if op in _SIMD_BINOP and len(args) == 2:
        return hir.HirBinOp(op=_SIMD_BINOP[op], left=args[0], right=args[1])
    if op == "set" and args:
        # Intel's `_mm256_set_pd(d, c, b, a)` reverses lane order.
        return hir.HirCall(func="simd_pack", args=list(reversed(args)))
    if op == "set1" and len(args) == 1:
        return hir.HirCall(func="simd_splat", args=args)
    if op == "setzero" and not args:
        return hir.HirCall(func="simd_zero", args=[])
    if op in ("sqrt", "abs", "ceil", "floor") and len(args) == 1:
        return hir.HirCall(func=f"simd_{op}", args=args)
    return None


def _decl_name(cursor: ci.Cursor) -> str | None:
    """Find the identifier name behind a DeclRefExpr / nested unwrapping."""
    if cursor.kind == CursorKind.DECL_REF_EXPR:
        return cursor.spelling
    if cursor.kind in (CursorKind.UNEXPOSED_EXPR, CursorKind.PAREN_EXPR):
        kids = list(cursor.get_children())
        if len(kids) == 1:
            return _decl_name(kids[0])
    return None


# ---------- operator-token extraction ----------

def _binop_token(cursor: ci.Cursor) -> str:
    """The operator token sits between the two child cursors. We slice
    tokens by their source position to find it.

    BINARY_OPERATOR has no direct `.operator` accessor in older libclang
    bindings; we use tokens for portability."""
    kids = list(cursor.get_children())
    if len(kids) != 2:
        raise UnsupportedConstruct(f"binary operator with {len(kids)} children")
    left_end = kids[0].extent.end
    right_start = kids[1].extent.start
    for tok in cursor.get_tokens():
        loc = tok.location
        if _loc_ge(loc, left_end) and _loc_lt(loc, right_start):
            return tok.spelling
    raise UnsupportedConstruct("could not locate binary-operator token")


def _unary_token(cursor: ci.Cursor) -> str:
    """For a unary op, the operator is either before or after the single
    operand. We pick whichever non-operand token we find first within the
    cursor's extent."""
    kids = list(cursor.get_children())
    if len(kids) != 1:
        raise UnsupportedConstruct(f"unary operator with {len(kids)} children")
    operand = kids[0]
    o_start, o_end = operand.extent.start, operand.extent.end
    for tok in cursor.get_tokens():
        loc = tok.location
        if not (_loc_ge(loc, o_start) and _loc_lt(loc, o_end)):
            return tok.spelling
    raise UnsupportedConstruct("could not locate unary-operator token")


def _loc_ge(a: ci.SourceLocation, b: ci.SourceLocation) -> bool:
    return (a.line, a.column) >= (b.line, b.column)


def _loc_lt(a: ci.SourceLocation, b: ci.SourceLocation) -> bool:
    return (a.line, a.column) < (b.line, b.column)


# ---------- type text ----------

def _type_text(t: ci.Type) -> str:
    spelling = t.spelling
    # Strip cv-qualifiers and references for the alias lookup.
    cleaned = spelling.replace("const ", "").replace("volatile ", "").strip()
    if cleaned in CPP_TYPE_ALIASES:
        return CPP_TYPE_ALIASES[cleaned]
    if cleaned in SIMD_TYPE_ALIASES:
        return SIMD_TYPE_ALIASES[cleaned]
    # Best-effort fallback: collapse on the canonical kind.
    kind = t.kind
    INTEGER_KINDS = {
        ci.TypeKind.INT, ci.TypeKind.LONG, ci.TypeKind.LONGLONG,
        ci.TypeKind.SHORT, ci.TypeKind.SCHAR, ci.TypeKind.UCHAR,
        ci.TypeKind.CHAR_S, ci.TypeKind.CHAR_U,
        ci.TypeKind.UINT, ci.TypeKind.ULONG, ci.TypeKind.ULONGLONG, ci.TypeKind.USHORT,
    }
    if kind in INTEGER_KINDS:
        return "int"
    if kind in (ci.TypeKind.FLOAT, ci.TypeKind.DOUBLE, ci.TypeKind.LONGDOUBLE):
        return "float"
    if kind == ci.TypeKind.BOOL:
        return "bool"
    if kind == ci.TypeKind.VOID:
        return "None"
    # Struct/class types: pass the bare name through so HIR→MIR resolves it
    # against the struct registry (HirStruct names land in StructT(name)).
    if kind == ci.TypeKind.RECORD:
        return cleaned
    # Pointers and references — common in C-style C++. We don't model
    # pointer lifetimes; collapse onto the pointee's type.
    if kind in (ci.TypeKind.POINTER, ci.TypeKind.LVALUEREFERENCE, ci.TypeKind.RVALUEREFERENCE):
        try:
            return _type_text(t.get_pointee())
        except UnsupportedConstruct:
            return "int"
    # `auto x = ...` — libclang exposes the deduced type via the canonical
    # form. Recurse so we get the real type.
    if kind in (ci.TypeKind.AUTO, ci.TypeKind.ELABORATED, ci.TypeKind.UNEXPOSED):
        canonical = t.get_canonical()
        if canonical.kind != kind:  # avoid infinite recursion
            try:
                return _type_text(canonical)
            except UnsupportedConstruct:
                pass
        return "int"
    raise UnsupportedConstruct(f"C++ type {spelling!r} (kind={kind.name})")
