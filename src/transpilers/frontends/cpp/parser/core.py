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

import os as _os
import re as _re

import clang.cindex as ci

from transpilers.ir import hir

from .errors import UnsupportedConstruct
from .libclang_config import *
from .types import *
from .tokens import *
from .simd import _lift_simd_intrinsic
from .preprocess import preprocess_cpp
from .type_extractor import TypeGroundTruth

CursorKind = ci.CursorKind

_TypeKind = ci.TypeKind
_INTEGRAL_KINDS = frozenset(
    getattr(_TypeKind, k)
    for k in (
        "BOOL",
        "CHAR_U",
        "UCHAR",
        "CHAR16",
        "CHAR32",
        "USHORT",
        "UINT",
        "ULONG",
        "ULONGLONG",
        "UINT128",
        "CHAR_S",
        "SCHAR",
        "WCHAR",
        "SHORT",
        "INT",
        "LONG",
        "LONGLONG",
        "INT128",
        "ENUM",
    )
    if getattr(_TypeKind, k, None) is not None
)
_FLOATING_KINDS = frozenset(
    getattr(_TypeKind, k)
    for k in ("FLOAT", "DOUBLE", "LONGDOUBLE", "FLOAT128")
    if getattr(_TypeKind, k, None) is not None
)


def _is_integral_type(t) -> bool:
    try:
        return t.get_canonical().kind in _INTEGRAL_KINDS
    except Exception:
        return False


def _is_floating_type(t) -> bool:
    try:
        return t.get_canonical().kind in _FLOATING_KINDS
    except Exception:
        return False


def _operand_is_floating(cursor) -> bool:
    cur = cursor
    for _ in range(8):
        if _is_floating_type(cur.type):
            return True
        if cur.kind not in (CursorKind.UNEXPOSED_EXPR, CursorKind.PAREN_EXPR):
            break
        kids = [k for k in cur.get_children() if k.kind != CursorKind.TYPE_REF]
        if not kids:
            break
        cur = kids[-1]
    return _is_floating_type(cur.type)


_POSTFIX_EFFECT_STACK: list[list["hir.HirNode"]] = []


def _push_postfix_frame() -> None:
    _POSTFIX_EFFECT_STACK.append([])


def _pop_postfix_frame() -> "list[hir.HirNode]":
    return _POSTFIX_EFFECT_STACK.pop() if _POSTFIX_EFFECT_STACK else []


def _record_postfix_effect(node: "hir.HirNode") -> None:
    if _POSTFIX_EFFECT_STACK:
        _POSTFIX_EFFECT_STACK[-1].append(node)


INPUT_NAME = "input.cpp"

_PREAMBLE = """
typedef signed char int8_t; typedef short int16_t; typedef int int32_t;
typedef long long int64_t; typedef unsigned char uint8_t;
typedef unsigned short uint16_t; typedef unsigned int uint32_t;
typedef unsigned long long uint64_t; typedef unsigned long long size_t;
typedef long ssize_t; typedef long ptrdiff_t;
double exp(double); double log(double); double log10(double); double log2(double);
double sqrt(double); double cbrt(double); double pow(double, double);
double sin(double); double cos(double); double tan(double);
double asin(double); double acos(double); double atan(double); double atan2(double, double);
double sinh(double); double cosh(double); double tanh(double);
double fabs(double); double ceil(double); double floor(double); double round(double);
double trunc(double); double fmod(double, double); double hypot(double, double);
double fmin(double, double); double fmax(double, double); double fma(double, double, double);
double max(double, double); double min(double, double);
int max(int, int); int min(int, int); int abs(int); long labs(long);
double clamp(double, double, double); int clamp(int, int, int);
namespace std {
}
"""


def _project_preamble() -> str:
    """Project-specific declarations to prepend (e.g. EnergyPlus `Real64`), so
    domain typedefs resolve without baking them into the general core preamble.
      $TRANSPILERS_CPP_PREAMBLE       — inline declaration text
      $TRANSPILERS_CPP_PREAMBLE_FILE  — path to a declarations file
    """
    inline = _os.environ.get("TRANSPILERS_CPP_PREAMBLE", "")
    path = _os.environ.get("TRANSPILERS_CPP_PREAMBLE_FILE", "")
    if path and _os.path.isfile(path):
        try:
            inline += "\n" + open(path, encoding="utf-8").read()
        except OSError:
            pass
    return ("\n" + inline + "\n") if inline else ""


_PREAMBLE_REAL_MARKER = "// === TRANSPILERS: REAL PREAMBLE BELOW ==="


def _split_project_preamble() -> tuple[str, str]:
    """Split ``_project_preamble()`` into ``(stub_part, real_part)`` at
    ``_PREAMBLE_REAL_MARKER``. ``real_part`` is ``""`` if the preamble has
    no marker (the common case -- most project preambles are parse-only).

    ``real_part`` must land in the final translation unit *after*
    ``PARSER_PREAMBLE`` (the generic std:: shim, also excluded, and itself
    only added later inside ``preprocess_cpp``) and immediately before the
    user's own source -- not where it textually sits in the preamble file,
    right before ``PARSER_PREAMBLE``. ``parse_cpp`` prepends it directly to
    *source* for exactly this reason; see the call site there.
    """
    project = _project_preamble()
    marker_at = project.find(_PREAMBLE_REAL_MARKER)
    if marker_at == -1:
        return project, ""
    return project[:marker_at], project[marker_at:]


def _compute_user_first_line() -> int:
    from .preprocess import PARSER_PREAMBLE

    stub_part, _real_part = _split_project_preamble()
    return len((stub_part + PARSER_PREAMBLE).splitlines())


_UNKNOWN_TYPE_NAME_RE = _re.compile(r"unknown type name '([A-Za-z_][A-Za-z0-9_]*)'")
_SCREAMING_MACRO_RE = _re.compile(r"^[A-Z][A-Z0-9_]*$")
_MACRO_SUFFIX_RE = _re.compile(r"_(EXPORT|IMPORT|API|DLL|DECL)$")


def _macro_like_unknown_types(tu: ci.TranslationUnit) -> set[str]:
    """Names from "unknown type name '...'" diagnostics that look like an
    export / calling-convention macro (``FOO_API``, ``FOO_EXPORT``,
    ``DLLEXPORT``, ``WINAPI``, ``Standard_EXPORT``, ...) rather than a real
    missing type.

    Real-world C++ libraries almost universally gate their public API with
    a macro like this, defined in a header we never see (every #include is
    stripped before libclang runs, by design -- see ``preprocess.py``). Left
    alone, every function/class declaration in the file fails to parse on a
    token that carries no type information at all. SCREAMING_CASE (or a
    SCREAMING_CASE suffix on an otherwise-mixed-case name) is a near-
    universal C/C++ convention for macros and essentially never used for a
    real type name, so treating it as an empty ``-D`` define is safe: it can
    only remove a no-op qualifier, never rename or reinterpret real user
    code.
    """
    names: set[str] = set()
    for d in tu.diagnostics:
        if d.severity < ci.Diagnostic.Error:
            continue
        m = _UNKNOWN_TYPE_NAME_RE.search(d.spelling)
        if not m:
            continue
        name = m.group(1)
        if _SCREAMING_MACRO_RE.match(name) or _MACRO_SUFFIX_RE.search(name):
            names.add(name)
    return names


def parse_cpp(source: str):
    """Parse C++ source to HIR.

    Returns ``(hir_module, ground_truth)`` where *ground_truth* is a
    ``TypeGroundTruth`` populated from the same clang AST. The HIR
    carries ``source_loc`` fields on each node so a later pass
    (``transpilers.passes.cpp_ground_truth``) can match each HIR
    declaration to its concrete type. For backward compatibility
    callers that ignore the second value keep working; the legacy
    single-return shape is preserved as a private ``_parse_cpp_legacy``
    and any ``parse_cpp(source)[0]`` usage in the tests continues to
    pass.

    The pipeline threads the ground truth through to
    ``infer_types`` (see ``run_stages``); the legacy single-return
    behaviour is opt-in via the keyword arg below, but **new** code
    should always unpack the tuple.
    """
    index = ci.Index.create()
    predefs = [
        "-DNULL=0",
        "-DINT_MIN=(-2147483647 - 1)",
        "-DINT_MAX=2147483647",
        "-DLONG_MIN=(-9223372036854775807L - 1)",
        "-DLONG_MAX=9223372036854775807L",
        "-DLLONG_MIN=(-9223372036854775807LL - 1)",
        "-DLLONG_MAX=9223372036854775807LL",
        "-DUINT_MAX=4294967295U",
        "-DEXIT_SUCCESS=0",
        "-DEXIT_FAILURE=1",
        "-DM_PI=3.14159265358979323846",
        "-DM_PI_2=1.57079632679489661923",
        "-DM_PI_4=0.78539816339744830962",
        "-DM_2_PI=0.63661977236758134308",
        "-DM_E=2.71828182845904523536",
        "-DM_SQRT2=1.41421356237309504880",
        "-DM_SQRT1_2=0.70710678118654752440",
        "-DDBL_EPSILON=2.2204460492503131e-16",
        "-DFLT_EPSILON=1.19209290e-7F",
    ]
    triple_args = []
    triple = _host_triple()
    if triple:
        triple_args = [f"--target={triple}"]
    parse_args = (
        ["-std=c++20", "-x", "c++", "-nostdinc++", "-ferror-limit=0"]
        + triple_args
        + predefs
    )
    _stub_preamble, _real_preamble = _split_project_preamble()
    preprocessed = _stub_preamble + preprocess_cpp(_real_preamble + source)
    defined_macros: set[str] = set()
    tu = None
    for _attempt in range(4):
        tu = index.parse(
            INPUT_NAME,
            args=parse_args + [f"-D{name}=" for name in sorted(defined_macros)],
            unsaved_files=[(INPUT_NAME, preprocessed)],
            options=ci.TranslationUnit.PARSE_DETAILED_PROCESSING_RECORD,
        )
        new_macros = _macro_like_unknown_types(tu) - defined_macros
        if not new_macros:
            break
        defined_macros |= new_macros
    _check_diagnostics(tu)
    _KNOWN_STRUCT_NAMES.clear()
    _register_struct_names(tu.cursor.get_children())
    body: list[hir.HirNode] = []
    for c in tu.cursor.get_children():
        _convert_top_level(c, body)
    truth = TypeGroundTruth.from_tu(tu, only_input=True)
    return hir.HirModule(source_lang="cpp", body=body), truth


def _parse_cpp_legacy(source: str) -> hir.HirModule:
    return parse_cpp(source)[0]


def _register_struct_names(cursors) -> None:
    for c in cursors:
        if not _from_input(c):
            continue
        if c.kind in (CursorKind.CLASS_DECL, CursorKind.STRUCT_DECL):
            _KNOWN_STRUCT_NAMES.add(c.spelling)
        elif c.kind == CursorKind.NAMESPACE:
            _register_struct_names(c.get_children())


def _convert_top_level(c: ci.Cursor, body: list[hir.HirNode]) -> None:
    """Dispatch one translation-unit- or namespace-level declaration into
    `body`. Namespaces are flattened — Mojo has no namespace, so members are
    emitted at module scope (name collisions across namespaces are a caller
    risk until qualified-name mangling lands)."""
    if not _from_input(c):
        return
    if c.kind == CursorKind.NAMESPACE:
        for inner in c.get_children():
            _convert_top_level(inner, body)
        return
    if c.kind == CursorKind.FUNCTION_DECL and c.is_definition():
        body.append(_set_loc(c, _convert_function(c)))
        return
    if (
        c.kind in (CursorKind.CXX_METHOD, CursorKind.CONSTRUCTOR, CursorKind.DESTRUCTOR)
        and c.is_default_method()
    ):
        return
    if c.kind == CursorKind.CXX_METHOD and c.is_definition():
        cls = c.semantic_parent.spelling if c.semantic_parent else None
        for node in body:
            if isinstance(node, hir.HirStruct) and node.name == cls:
                node.methods.append(_convert_method(c, struct_name=cls))
                return
        body.append(_set_loc(c, _convert_function(c)))
        return
    if c.kind == CursorKind.CONSTRUCTOR and c.is_definition():
        cls = c.semantic_parent.spelling if c.semantic_parent else None
        for node in body:
            if isinstance(node, hir.HirStruct) and node.name == cls:
                node.methods.append(_convert_constructor(c, struct_name=cls))
                return
        return
    if c.kind == CursorKind.FUNCTION_TEMPLATE and c.is_definition():
        body.append(hir.HirRaw(snippet=_cursor_snippet(c)))
        return
    if c.kind in (CursorKind.CLASS_DECL, CursorKind.STRUCT_DECL):
        if not c.is_definition():
            return
        first = next(c.get_children(), None)
        if first is not None and first.kind == CursorKind.TYPE_REF:
            return
        for member in c.get_children():
            if member.kind == CursorKind.ENUM_DECL:
                body.extend(_convert_enum(member))
        body.append(_set_loc(c, _convert_class(c)))
        return
    if c.kind == CursorKind.FUNCTION_DECL:
        return
    if c.kind == CursorKind.VAR_DECL:
        try:
            body.append(_convert_var_decl(c))
        except UnsupportedConstruct:
            pass
        return
    if c.kind == CursorKind.ENUM_DECL:
        body.extend(_convert_enum(c))
        return
    if c.kind in (
        CursorKind.INCLUSION_DIRECTIVE,
        CursorKind.MACRO_DEFINITION,
        CursorKind.MACRO_INSTANTIATION,
        CursorKind.USING_DIRECTIVE,
        CursorKind.USING_DECLARATION,
        CursorKind.TYPEDEF_DECL,
        CursorKind.TYPE_ALIAS_DECL,
        CursorKind.CLASS_TEMPLATE,
        CursorKind.CLASS_TEMPLATE_PARTIAL_SPECIALIZATION,
        CursorKind.FUNCTION_TEMPLATE,
    ):
        return
    raise UnsupportedConstruct(f"top-level {c.kind.name}")


def _convert_enum(cursor: ci.Cursor) -> list[hir.HirNode]:
    """C-style `enum { A = 0, B = 1 }` → one module-level int constant per
    enumerator (libclang resolves implicit values via `enum_value`). These
    feed the module-constant table; references inline to their literal value
    on every target, so a dedicated enum IR node isn't required for the
    named-int case."""
    out: list[hir.HirNode] = []
    for c in cursor.get_children():
        if c.kind == ci.CursorKind.ENUM_CONSTANT_DECL:
            out.append(
                hir.HirAssign(
                    target=c.spelling,
                    value=hir.HirIntLiteral(value=int(c.enum_value)),
                    annotation="int",
                )
            )
    return out


def _convert_class(cursor: ci.Cursor) -> hir.HirStruct:
    """Subset: public fields (`int x;`), public methods. No constructors,
    destructors, inheritance, templates, operator overloads, references.
    Members under `private:` / `protected:` are refused so we don't silently
    expose internal API."""
    name = cursor.spelling
    fields: list[hir.HirParam] = []
    methods: list[hir.HirFunction] = []
    has_defaulted_default_ctor = False
    for c in cursor.get_children():
        if c.kind == ci.CursorKind.CXX_ACCESS_SPEC_DECL:
            continue
        if c.kind == ci.CursorKind.FIELD_DECL:
            fields.append(hir.HirParam(name=c.spelling, annotation=_type_text(c.type)))
            continue
        if (
            c.kind == ci.CursorKind.CXX_METHOD
            and c.is_definition()
            and not c.is_default_method()
        ):
            methods.append(_convert_method(c, struct_name=name))
            continue
        if (
            c.kind == ci.CursorKind.CONSTRUCTOR
            and c.is_definition()
            and not c.is_default_method()
        ):
            methods.append(_convert_constructor(c, struct_name=name))
            continue
        if (
            c.kind == ci.CursorKind.CONSTRUCTOR
            and c.is_default_method()
            and c.is_default_constructor()
        ):
            has_defaulted_default_ctor = True
            continue
        if c.kind in (
            ci.CursorKind.CXX_METHOD,
            ci.CursorKind.CONSTRUCTOR,
            ci.CursorKind.DESTRUCTOR,
        ):
            continue
        if c.kind == ci.CursorKind.CXX_BASE_SPECIFIER:
            raise UnsupportedConstruct(
                f"C++ inheritance for class {name!r} not yet supported"
            )
        if c.kind == ci.CursorKind.FRIEND_DECL:
            continue
        if c.kind == ci.CursorKind.ENUM_DECL:
            continue
        if c.kind == ci.CursorKind.FUNCTION_TEMPLATE:
            continue
        raise UnsupportedConstruct(f"class member {c.kind.name}")
    if has_defaulted_default_ctor and any(m.name == "__init__" for m in methods):
        methods.append(_synthesized_default_ctor(fields, struct_name=name))
    return hir.HirStruct(name=name, fields=fields, methods=methods)


def _default_value_for_annotation(annotation: str) -> hir.HirNode:
    """A best-effort zero/empty value for *annotation*, for synthesizing a
    defaulted 0-arg constructor's field-init body (see
    `_synthesized_default_ctor`). A struct-typed field recurses into that
    struct's own 0-arg construction (mirroring real C++ value-init
    semantics for a member with its own default ctor); anything else falls
    back to a scalar zero rather than refusing the whole class over it."""
    if annotation in _KNOWN_STRUCT_NAMES:
        return hir.HirStructInit(name=annotation, args=[])
    if annotation == "bool":
        return hir.HirBoolLiteral(value=False)
    if annotation in ("float", "double"):
        return hir.HirFloatLiteral(value=0.0)
    if annotation == "str":
        return hir.HirStringLiteral(value="")
    return hir.HirIntLiteral(value=0)


def _synthesized_default_ctor(
    fields: list[hir.HirParam], *, struct_name: str
) -> hir.HirFunction:
    """A `__init__(out self):` that zero/value-initializes every field, for
    a class with an explicitly-defaulted (`= default`) 0-arg constructor
    alongside other real, explicit constructors. Mojo's `@fieldwise_init`
    only auto-synthesizes a usable default ctor when a struct has *no*
    explicit `__init__` at all; once any other constructor is emitted, a
    defaulted 0-arg ctor needs this explicit counterpart too, or a 0-arg
    construction call site (`gp_Vec()`) has no matching overload."""
    body: list[hir.HirNode] = [
        hir.HirFieldAssign(
            obj=hir.HirName(name="self"),
            field=f.name,
            value=_default_value_for_annotation(f.annotation),
        )
        for f in fields
    ]
    return hir.HirFunction(
        name="__init__",
        params=[hir.HirParam(name="self", annotation=struct_name)],
        return_annotation="None",
        body=body,
    )


def _param_name(cursor: ci.Cursor, index: int) -> str:
    """A PARM_DECL's identifier, or a synthesized placeholder if it has
    none. C++ allows an unnamed parameter both in a declaration and, when
    the parameter is genuinely unused, in a definition too (e.g. OCCT's own
    `void gp_Pnt::DumpJson(Standard_OStream&, int) const`, whose second
    parameter is never referenced in the body). `cursor.spelling` is `""`
    in that case; every target needs *some* identifier there."""
    return cursor.spelling or f"_arg{index}"


def _convert_constructor(cursor: ci.Cursor, *, struct_name: str) -> hir.HirFunction:
    """C++ constructor → Mojo `__init__(out self, ...)`. The member-init list
    (`: x(a), y(b)`) appears in the AST as alternating MEMBER_REF / init-expr
    children before the body; each pair becomes a `self.<field> = <expr>`
    assignment, followed by the constructor body's statements."""
    params: list[hir.HirParam] = [hir.HirParam(name="self", annotation=struct_name)]
    field_inits: list[hir.HirNode] = []
    body_stmts: list[hir.HirNode] = []
    kids = list(cursor.get_children())
    i = 0
    pidx = 0
    while i < len(kids):
        c = kids[i]
        if c.kind == CursorKind.PARM_DECL:
            params.append(
                hir.HirParam(name=_param_name(c, pidx), annotation=_type_text(c.type))
            )
            pidx += 1
        elif c.kind == CursorKind.MEMBER_REF and i + 1 < len(kids):
            field_inits.append(
                hir.HirFieldAssign(
                    obj=hir.HirName(name="self"),
                    field=c.spelling,
                    value=_convert_expr(kids[i + 1]),
                )
            )
            i += 2
            continue
        elif c.kind == CursorKind.COMPOUND_STMT:
            body_stmts = _convert_compound(c)
        i += 1
    return hir.HirFunction(
        name="__init__",
        params=params,
        return_annotation="None",
        body=field_inits + body_stmts,
    )


_OPERATOR_DUNDERS: dict[str, str] = {
    "+": "__add__",
    "-": "__sub__",
    "*": "__mul__",
    "/": "__truediv__",
    "%": "__mod__",
    "==": "__eq__",
    "!=": "__ne__",
    "<": "__lt__",
    ">": "__gt__",
    "<=": "__le__",
    ">=": "__ge__",
    "&": "__and__",
    "|": "__or__",
    "^": "__xor__",
    "<<": "__lshift__",
    ">>": "__rshift__",
    "[]": "__getitem__",
    "()": "__call__",
    "+=": "__iadd__",
    "-=": "__isub__",
    "*=": "__imul__",
    "/=": "__itruediv__",
    "%=": "__imod__",
    "&=": "__iand__",
    "|=": "__ior__",
    "^=": "__ixor__",
    "<<=": "__ilshift__",
    ">>=": "__irshift__",
}


_UNARY_OPERATOR_DUNDERS: dict[str, str] = {
    "-": "__neg__",
    "+": "__pos__",
}


def _operator_name(cursor: ci.Cursor, *, unary_param_count: int) -> str:
    """Map an operator-overload to its dunder; otherwise the raw spelling.
    `operator+` → `__add__`, `operator==` → `__eq__`, etc. An operator token
    we don't recognize keeps the raw spelling (no refusal — same as before).

    `+`/`-` are ambiguous: unary negation/plus take one fewer explicit
    parameter than the binary form of the same token (a member
    `operator-()` has zero explicit params — just the implicit `self`;
    a free `operator-(x)` has one). *unary_param_count* is that
    threshold, so this same logic serves both member and free-function
    callers. Same token, different arity, different dunder in every
    target (`__neg__` takes no argument; `__sub__` requires one). Mapping
    both to `__sub__` produces a nonsensical zero-arg `__sub__`, which every
    target's own dunder-arity checker (Mojo's included) rejects outright.
    """
    spelling = cursor.spelling
    if spelling.startswith("operator"):
        token = spelling[len("operator") :].strip()
        n_params = sum(
            1 for c in cursor.get_children() if c.kind == ci.CursorKind.PARM_DECL
        )
        if token in ("-", "+") and n_params == unary_param_count:
            return _UNARY_OPERATOR_DUNDERS[token]
        if (
            token == "()"
            and n_params >= 2
            and cursor.result_type.kind
            in (ci.TypeKind.LVALUEREFERENCE, ci.TypeKind.RVALUEREFERENCE)
        ):
            return "__getitem__"
        if token in _OPERATOR_DUNDERS:
            return _OPERATOR_DUNDERS[token]
    return spelling


def _method_name(cursor: ci.Cursor) -> str:
    """Map an operator-overload member to its dunder; otherwise the spelling.
    See `_operator_name` — a member's implicit `self` means its unary forms
    take zero explicit parameters."""
    return _operator_name(cursor, unary_param_count=0)


def _convert_method(cursor: ci.Cursor, *, struct_name: str) -> hir.HirFunction:
    is_static = cursor.is_static_method()
    params: list[hir.HirParam] = (
        [] if is_static else [hir.HirParam(name="self", annotation=struct_name)]
    )
    body: list[hir.HirNode] = []
    pidx = 0
    for c in cursor.get_children():
        if c.kind == CursorKind.PARM_DECL:
            params.append(
                hir.HirParam(name=_param_name(c, pidx), annotation=_type_text(c.type))
            )
            pidx += 1
        elif c.kind == CursorKind.COMPOUND_STMT:
            body = _convert_compound(c)
    return hir.HirFunction(
        name=_method_name(cursor),
        params=params,
        return_annotation=_type_text(cursor.result_type),
        body=body,
        is_static=is_static,
    )


def _check_diagnostics(tu: ci.TranslationUnit) -> None:
    fatal = [d for d in tu.diagnostics if d.severity >= ci.Diagnostic.Error]
    if fatal:
        msgs = "\n".join(f"  {d.spelling}" for d in fatal[:5])
        raise UnsupportedConstruct(f"libclang parse errors:\n{msgs}")


def _from_input(cursor: ci.Cursor) -> bool:
    """True for cursors that come from the user code (not the parser
    preamble). The preamble is the first ``PARSER_PREAMBLE`` +
    ``_project_preamble`` lines of the unsaved file; anything at or
    before that line offset is the preamble and is not user code."""
    if cursor.location.file is None:
        return False
    if cursor.location.file.name != INPUT_NAME:
        return False
    try:
        first = _compute_user_first_line()
    except Exception:
        return True
    return cursor.location.line > first


def _cursor_loc(cursor: ci.Cursor) -> str | None:
    """Canonical ``file:line:col`` source-location string for *cursor*.

    Returns ``None`` for cursors that don't have a usable file location
    (built-in macros, implicit nodes) so the HIR field stays ``None`` and
    the ground-truth pass simply doesn't look them up.
    """
    try:
        loc = cursor.location
    except Exception:
        return None
    f = loc.file
    if f is None:
        return None
    return f"{f.name}:{loc.line}:{loc.column}"


def _set_loc(cursor: ci.Cursor, node: "hir.HirNode") -> "hir.HirNode":
    """Stamp *node*'s ``source_loc`` with *cursor*'s file:line:col.

    Used by the dispatchers (``_convert_top_level`` and the
    per-statement / per-expression converters) so every HIR node
    carries a back-reference to the libclang cursor it came from. The
    C++ ground-truth pass at issue #50 uses those locations to look up
    concrete types from the AST.
    """
    if node is None:
        return node
    loc = _cursor_loc(cursor)
    if loc is not None:
        try:
            object.__setattr__(node, "source_loc", loc)
        except Exception:
            pass
    return node


def _convert_function(cursor: ci.Cursor) -> hir.HirFunction:
    params: list[hir.HirParam] = []
    body: list[hir.HirNode] = []
    idx = 0
    for c in cursor.get_children():
        if c.kind == CursorKind.PARM_DECL:
            params.append(
                hir.HirParam(name=_param_name(c, idx), annotation=_type_text(c.type))
            )
            idx += 1
        elif c.kind == CursorKind.COMPOUND_STMT:
            body = _convert_compound(c)
    name = _operator_name(cursor, unary_param_count=1)
    if name.startswith("__") and name.endswith("__"):
        name = f"_operator{name}"
    return hir.HirFunction(
        name=name,
        params=params,
        return_annotation=_type_text(cursor.result_type),
        body=body,
    )


def _convert_compound(cursor: ci.Cursor) -> list[hir.HirNode]:
    out: list[hir.HirNode] = []
    for c in cursor.get_children():
        out.extend(_convert_stmt(c))
    return out


def _cursor_snippet(cursor: ci.Cursor) -> str:
    """Best-effort original source text for a cursor, for a HirRaw hole.

    Joins the cursor's tokens (whitespace-insensitive but faithful enough to
    show what was skipped). Falls back to the cursor kind name when no tokens
    are available (e.g. macro-expanded or implicit nodes)."""
    try:
        toks = [t.spelling for t in cursor.get_tokens()]
    except Exception:
        toks = []
    text = " ".join(toks).strip()
    if not text:
        return f"<{cursor.kind.name}>"
    if len(text) > 400:
        text = text[:400] + " ..."
    return text


def _convert_stmt(cursor: ci.Cursor) -> list[hir.HirNode]:
    """Never-refuse statement conversion: a caught UnsupportedConstruct is
    turned into a HirRaw hole carrying the source snippet, so one unsupported
    statement no longer aborts the whole function body."""
    _push_postfix_frame()
    try:
        result = _convert_stmt_inner(cursor)
    except UnsupportedConstruct:
        result = [hir.HirRaw(snippet=_cursor_snippet(cursor))]
    finally:
        effects = _pop_postfix_frame()
    return result + effects


def _convert_stmt_inner(cursor: ci.Cursor) -> list[hir.HirNode]:
    kind = cursor.kind
    if kind == CursorKind.RETURN_STMT:
        kids = list(cursor.get_children())
        if not kids:
            return [hir.HirReturn(value=None)]
        child = _strip_unexposed(kids[0])
        if child.kind == CursorKind.BINARY_OPERATOR:
            try:
                op = _binop_token(child)
            except UnsupportedConstruct:
                op = ""
            if op == "=":
                bk = list(child.get_children())
                try:
                    assign = _convert_assignment_stmt(child)
                    return_val = _lhs_as_subscript_or_name(bk[0])
                    return [assign, hir.HirReturn(value=return_val)]
                except UnsupportedConstruct:
                    pass
        return [hir.HirReturn(value=_convert_expr_stmt(kids[0]))]
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
    if kind == CursorKind.CXX_FOR_RANGE_STMT:
        return _convert_for_range(cursor)
    if kind == CursorKind.COMPOUND_STMT:
        return _convert_compound(cursor)
    if kind in (CursorKind.BINARY_OPERATOR, CursorKind.COMPOUND_ASSIGNMENT_OPERATOR):
        return [_convert_assignment_stmt(cursor)]
    if kind == CursorKind.UNARY_OPERATOR:
        return [_convert_unary_stmt(cursor)]
    if kind == CursorKind.CALL_EXPR:
        swapped = _convert_std_swap_stmt(cursor)
        if swapped is not None:
            return swapped
        return [_convert_expr_stmt(cursor)]
    if kind == CursorKind.BREAK_STMT:
        return [hir.HirBreak()]
    if kind == CursorKind.CONTINUE_STMT:
        return [hir.HirContinue()]
    if kind == CursorKind.NULL_STMT:
        return []
    if kind == CursorKind.SWITCH_STMT:
        return _convert_switch(cursor)
    if kind == CursorKind.UNEXPOSED_EXPR:
        kids = list(cursor.get_children())
        if len(kids) == 1:
            return _convert_stmt_inner(kids[0])
    raise UnsupportedConstruct(f"stmt {kind.name}")


_ARRAY_TYPE_KINDS = (
    ci.TypeKind.CONSTANTARRAY,
    ci.TypeKind.INCOMPLETEARRAY,
    ci.TypeKind.VARIABLEARRAY,
)


def _default_array_value(t: ci.Type) -> hir.HirNode:
    """A zero-filled nested list literal matching a native fixed-size
    array type's shape (`double[3][3]` -> a 3x3 list of `0.0`), for a
    VAR_DECL with no real initializer -- see `_convert_var_decl`'s
    no-initializer array handling."""
    if t.kind in _ARRAY_TYPE_KINDS:
        count = t.element_count if t.kind == ci.TypeKind.CONSTANTARRAY else 0
        return hir.HirList(
            elements=[_default_array_value(t.element_type) for _ in range(count)]
        )
    ann = _type_text(t)
    if ann in _KNOWN_STRUCT_NAMES:
        return hir.HirStructInit(name=ann, args=[])
    if ann == "bool":
        return hir.HirBoolLiteral(value=False)
    if ann == "float":
        return hir.HirFloatLiteral(value=0.0)
    if ann == "str":
        return hir.HirStringLiteral(value="")
    return hir.HirIntLiteral(value=0)


def _convert_var_decl(cursor: ci.Cursor) -> hir.HirNode:
    annotation = _type_text(cursor.type)
    if cursor.type.kind in _ARRAY_TYPE_KINDS and not any(
        t.spelling in ("=", "{") for t in cursor.get_tokens()
    ):
        return hir.HirAssign(
            target=cursor.spelling,
            value=_default_array_value(cursor.type),
            annotation=annotation,
        )
    kids = list(cursor.get_children())
    if annotation in _KNOWN_STRUCT_NAMES:
        if not kids:
            init: hir.HirNode = hir.HirStructInit(name=annotation, args=[])
        else:
            ctor = kids[-1]
            is_ctor = ctor.kind == ci.CursorKind.INIT_LIST_EXPR or (
                ctor.kind == ci.CursorKind.CALL_EXPR
                and (ctor.spelling or "") == annotation
            )
            if is_ctor:
                real = [
                    c for c in ctor.get_children() if c.kind != ci.CursorKind.TYPE_REF
                ]
                if len(real) == 1:
                    arg_ty = (
                        (real[0].type.spelling or "")
                        .replace("const ", "")
                        .rstrip("&")
                        .strip()
                    )
                    if arg_ty == annotation:
                        init = _convert_expr(real[0])
                        return hir.HirAssign(
                            target=cursor.spelling, value=init, annotation=annotation
                        )
                args: list[hir.HirNode] = []
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
            else:
                init = _convert_expr(ctor)
        return hir.HirAssign(target=cursor.spelling, value=init, annotation=annotation)
    init = _convert_expr(kids[-1]) if kids else hir.HirIntLiteral(value=0)
    if cursor.type.kind == ci.TypeKind.AUTO:
        annotation = None
    return hir.HirAssign(target=cursor.spelling, value=init, annotation=annotation)


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
    test_cursor = kids[0]
    body = _convert_stmt(kids[1]) if len(kids) > 1 else []
    stripped = _strip_unexposed(test_cursor)
    if stripped.kind == CursorKind.UNARY_OPERATOR and _unary_token(stripped) in (
        "--",
        "++",
    ):
        op = _unary_token(stripped)
        inner_kids = list(stripped.get_children())
        if inner_kids and inner_kids[0].kind == CursorKind.DECL_REF_EXPR:
            name = inner_kids[0].spelling
            cond = hir.HirCompare(
                op="!=", left=hir.HirName(name=name), right=hir.HirIntLiteral(value=0)
            )
            step = "-" if op == "--" else "+"
            update = hir.HirAssign(
                target=name,
                value=hir.HirIntLiteral(value=1),
                annotation=None,
                augmented_op=step,
            )
            return hir.HirWhile(test=cond, body=[update, *body])
    cond = _convert_expr(test_cursor)
    return hir.HirWhile(test=cond, body=body)


def _convert_switch(cursor: ci.Cursor) -> list[hir.HirNode]:
    """`switch (x) { case A: ...; break; case B: ...; ... default: ...; }`
    desugars to a chain of `if/elif/else`. Fall-through is *not* modelled —
    each case body terminates at its break (we strip those during conversion).
    Cases without an explicit break would semantically need fall-through
    support, but that's out of scope for the initial subset."""
    kids = list(cursor.get_children())
    if len(kids) < 2:
        raise UnsupportedConstruct("malformed switch")
    test_expr = _convert_expr(kids[0])
    body_cursor = kids[1]
    cases: list[tuple[hir.HirNode, list[hir.HirNode]]] = []
    default_body: list[hir.HirNode] = []

    body_kids = (
        list(body_cursor.get_children())
        if body_cursor.kind == CursorKind.COMPOUND_STMT
        else [body_cursor]
    )
    current_value: hir.HirNode | None = None
    current_body: list[hir.HirNode] = []
    is_default = False

    def flush() -> None:
        nonlocal current_value, current_body, is_default
        if is_default:
            default_body.extend(current_body)
        elif current_value is not None:
            cases.append((current_value, current_body))
        current_value = None
        current_body = []
        is_default = False

    for c in body_kids:
        if c.kind == CursorKind.CASE_STMT:
            flush()
            case_kids = list(c.get_children())
            if case_kids:
                current_value = _convert_expr(case_kids[0])
                for inner in case_kids[1:]:
                    current_body.extend(_convert_stmt(inner))
        elif c.kind == CursorKind.DEFAULT_STMT:
            flush()
            is_default = True
            for inner in c.get_children():
                current_body.extend(_convert_stmt(inner))
        else:
            current_body.extend(_convert_stmt(c))
    flush()

    def _strip_break(stmts: list[hir.HirNode]) -> list[hir.HirNode]:
        return [s for s in stmts if not isinstance(s, hir.HirBreak)]

    chain: list[hir.HirNode] = _strip_break(default_body)
    for value, body in reversed(cases):
        chain = [
            hir.HirIf(
                test=hir.HirCompare(op="==", left=test_expr, right=value),
                body=_strip_break(body),
                orelse=chain,
            )
        ]
    return chain


def _convert_for_range(cursor: ci.Cursor) -> list[hir.HirNode]:
    """`for (auto x : xs)` → indexed loop with x = xs[i] inside.

    libclang exposes the children as: VAR_DECL (loop var), iterable expr,
    then COMPOUND_STMT body (or a bare statement when no braces).
    Desugars to `for i in range(len(xs)): x = xs[i]; <body>`.
    """
    kids = list(cursor.get_children())
    var_decl = next((c for c in kids if c.kind == CursorKind.VAR_DECL), None)
    body_cursor = next((c for c in kids if c.kind == CursorKind.COMPOUND_STMT), None)
    iter_cursor = next(
        (
            c
            for c in kids
            if c.kind
            not in (CursorKind.VAR_DECL, CursorKind.COMPOUND_STMT, CursorKind.NULL_STMT)
        ),
        None,
    )
    if body_cursor is None and iter_cursor is not None:
        candidates = [
            c
            for c in kids
            if c.kind not in (CursorKind.VAR_DECL, CursorKind.NULL_STMT)
            and c is not iter_cursor
        ]
        body_cursor = candidates[-1] if candidates else None

    if var_decl is None or iter_cursor is None or body_cursor is None:
        raise UnsupportedConstruct("malformed range-for")

    iter_expr = _convert_expr(iter_cursor)
    var_name = var_decl.spelling
    idx_name = "__xpile_idx"

    if body_cursor.kind == CursorKind.COMPOUND_STMT:
        body = _convert_compound(body_cursor)
    else:
        body = _convert_stmt(body_cursor)

    bind = hir.HirAssign(
        target=var_name,
        value=hir.HirSubscript(value=iter_expr, index=hir.HirName(name=idx_name)),
        annotation=None,
    )
    loop = hir.HirFor(
        target=idx_name,
        iter=hir.HirCall(
            func="range",
            args=[
                hir.HirIntLiteral(value=0),
                hir.HirCall(func="len", args=[iter_expr]),
            ],
        ),
        body=[bind, *body],
    )
    return [loop]


def _convert_for(cursor: ci.Cursor) -> list[hir.HirNode]:
    """C-style for desugars at the frontend: init; while(cond) { body; step; }."""
    kids = list(cursor.get_children())
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
    cond = (
        _convert_expr(cond_part)
        if cond_part is not None
        else hir.HirBoolLiteral(value=True)
    )
    inner = _convert_stmt(body_node)
    if step_part is not None:
        inner.extend(_convert_stmt(step_part))
    out.append(hir.HirWhile(test=cond, body=inner))
    return out


def _convert_expr_stmt(cursor: ci.Cursor) -> hir.HirNode:
    """Never-refuse expression conversion at a statement boundary.

    Used where an expression is lowered in statement position (a bare
    expression statement, a return value). A caught UnsupportedConstruct
    becomes a HirRaw hole instead of aborting the enclosing function. Internal
    recursive expression conversion still uses `_convert_expr` (which raises),
    so the existing per-node fallbacks that probe alternative children keep
    working."""
    try:
        return _convert_expr(cursor)
    except UnsupportedConstruct:
        return hir.HirRaw(snippet=_cursor_snippet(cursor))


_PREDEF_INT_MACROS: dict[str, int] = {
    "NULL": 0,
    "EXIT_SUCCESS": 0,
    "EXIT_FAILURE": 1,
    "INT_MIN": -2147483648,
    "INT_MAX": 2147483647,
    "UINT_MAX": 4294967295,
    "LONG_MIN": -9223372036854775808,
    "LONG_MAX": 9223372036854775807,
    "LLONG_MIN": -9223372036854775808,
    "LLONG_MAX": 9223372036854775807,
}

_PREDEF_FLOAT_MACROS: dict[str, float] = {
    "M_PI": 3.14159265358979323846,
    "M_PI_2": 1.57079632679489661923,
    "M_PI_4": 0.78539816339744830962,
    "M_2_PI": 0.63661977236758134308,
    "M_E": 2.71828182845904523536,
    "M_SQRT2": 1.41421356237309504880,
    "M_SQRT1_2": 0.70710678118654752440,
    "DBL_EPSILON": 2.2204460492503131e-16,
    "FLT_EPSILON": 1.19209290e-7,
}


def _convert_expr(cursor: ci.Cursor) -> hir.HirNode:
    kind = cursor.kind
    if kind == CursorKind.INTEGER_LITERAL:
        token = _literal_token(cursor)
        if token is None:
            return hir.HirIntLiteral(value=0)
        if token.spelling in _PREDEF_INT_MACROS:
            return hir.HirIntLiteral(value=_PREDEF_INT_MACROS[token.spelling])
        try:
            return hir.HirIntLiteral(value=int(token.spelling.rstrip("uUlL"), 0))
        except ValueError:
            return hir.HirIntLiteral(value=0)
    if kind == CursorKind.FLOATING_LITERAL:
        token = _literal_token(cursor)
        if token is None:
            return hir.HirFloatLiteral(value=0.0)
        if token.spelling in _PREDEF_FLOAT_MACROS:
            return hir.HirFloatLiteral(value=_PREDEF_FLOAT_MACROS[token.spelling])
        try:
            return hir.HirFloatLiteral(value=float(token.spelling.rstrip("fFlL")))
        except ValueError:
            return hir.HirFloatLiteral(value=0.0)
    if kind == CursorKind.CXX_BOOL_LITERAL_EXPR:
        token = next(cursor.get_tokens(), None)
        return hir.HirBoolLiteral(value=token is not None and token.spelling == "true")
    if kind == CursorKind.CHARACTER_LITERAL:
        token = next(cursor.get_tokens(), None)
        if token is None:
            return hir.HirIntLiteral(value=0)
        spelling = token.spelling
        if len(spelling) >= 3 and spelling.startswith("'") and spelling.endswith("'"):
            inner = spelling[1:-1]
            escape_map = {
                "\\n": 10,
                "\\t": 9,
                "\\r": 13,
                "\\0": 0,
                "\\'": 39,
                "\\\\": 92,
            }
            if inner in escape_map:
                return hir.HirIntLiteral(value=escape_map[inner])
            if len(inner) == 1:
                return hir.HirIntLiteral(value=ord(inner))
        return hir.HirIntLiteral(value=0)
    if kind == CursorKind.STRING_LITERAL:
        token = next(cursor.get_tokens(), None)
        if token is None:
            raise UnsupportedConstruct("string literal without tokens")
        return hir.HirStringLiteral(value=token.spelling[1:-1])
    if kind == CursorKind.DECL_REF_EXPR:
        return hir.HirName(name=cursor.spelling)
    if kind == CursorKind.UNEXPOSED_EXPR or kind == CursorKind.PAREN_EXPR:
        kids = list(cursor.get_children())
        if len(kids) == 1:
            return _convert_expr(kids[0])
    if kind == CursorKind.BINARY_OPERATOR:
        return _convert_binop(cursor)
    if kind == CursorKind.UNARY_OPERATOR:
        return _convert_unary_expr(cursor)
    if kind == CursorKind.MEMBER_REF_EXPR:
        kids = list(cursor.get_children())
        if not kids:
            return hir.HirFieldAccess(
                value=hir.HirName(name="self"), field=cursor.spelling
            )
        return hir.HirFieldAccess(value=_convert_expr(kids[0]), field=cursor.spelling)
    if kind == CursorKind.CXX_THIS_EXPR:
        return hir.HirName(name="self")
    if kind == CursorKind.CALL_EXPR:
        return _convert_call(cursor)
    if kind == CursorKind.ARRAY_SUBSCRIPT_EXPR:
        kids = list(cursor.get_children())
        if len(kids) == 2:
            return hir.HirSubscript(
                value=_convert_expr(kids[0]), index=_convert_expr(kids[1])
            )
    if kind == CursorKind.COMPOUND_ASSIGNMENT_OPERATOR:
        raise UnsupportedConstruct("compound assignment as expression")
    if kind in (CursorKind.GNU_NULL_EXPR, CursorKind.CXX_NULL_PTR_LITERAL_EXPR):
        return hir.HirIntLiteral(value=0)
    if kind in (
        CursorKind.CSTYLE_CAST_EXPR,
        CursorKind.CXX_STATIC_CAST_EXPR,
        CursorKind.CXX_FUNCTIONAL_CAST_EXPR,
    ):
        kids = list(cursor.get_children())
        inner = None
        for c in kids[::-1]:
            if c.kind != CursorKind.TYPE_REF:
                inner = c
                break
        if inner is None and kids:
            inner = kids[-1]
        if inner is None:
            return hir.HirIntLiteral(value=0)
        value = _convert_expr(inner)
        if _is_integral_type(cursor.type) and _operand_is_floating(inner):
            return hir.HirCall(func="Int", args=[value])
        return value
    if kind == CursorKind.CONDITIONAL_OPERATOR:
        kids = list(cursor.get_children())
        if len(kids) == 3:
            return hir.HirCall(
                func="__ternary__",
                args=[
                    _convert_expr(kids[0]),
                    _convert_expr(kids[1]),
                    _convert_expr(kids[2]),
                ],
            )
    if kind == CursorKind.INIT_LIST_EXPR:
        return hir.HirList(elements=[_convert_expr(c) for c in cursor.get_children()])
    if kind in (CursorKind.CXX_UNARY_EXPR,):
        return hir.HirIntLiteral(value=0)
    if kind == CursorKind.CXX_NEW_EXPR:
        kids = list(cursor.get_children())
        for c in kids[::-1]:
            if c.kind != CursorKind.TYPE_REF:
                try:
                    return _convert_expr(c)
                except UnsupportedConstruct:
                    continue
        return hir.HirIntLiteral(value=0)
    if kind in (CursorKind.TYPE_REF, CursorKind.TEMPLATE_REF, CursorKind.NAMESPACE_REF):
        return hir.HirIntLiteral(value=0)
    if kind == CursorKind.UNEXPOSED_EXPR:
        kids = list(cursor.get_children())
        for c in kids[::-1]:
            if c.kind != CursorKind.TYPE_REF:
                try:
                    return _convert_expr(c)
                except UnsupportedConstruct:
                    continue
        return hir.HirIntLiteral(value=0)
    raise UnsupportedConstruct(f"expr {kind.name}")


def _strip_paren_unexposed(cursor: ci.Cursor) -> ci.Cursor:
    while cursor.kind in (CursorKind.UNEXPOSED_EXPR, CursorKind.PAREN_EXPR):
        kids = list(cursor.get_children())
        if len(kids) != 1:
            return cursor
        cursor = kids[0]
    return cursor


def _is_this_expr(cursor: ci.Cursor) -> bool:
    return _strip_paren_unexposed(cursor).kind == CursorKind.CXX_THIS_EXPR


def _is_addr_of_expr(cursor: ci.Cursor) -> bool:
    c = _strip_paren_unexposed(cursor)
    if c.kind != CursorKind.UNARY_OPERATOR or len(list(c.get_children())) != 1:
        return False
    try:
        return _unary_token(c) == "&"
    except UnsupportedConstruct:
        return False


def _convert_binop(cursor: ci.Cursor) -> hir.HirNode:
    op = _binop_token(cursor)
    kids = list(cursor.get_children())
    if op in ("==", "!=") and (
        (_is_this_expr(kids[0]) and _is_addr_of_expr(kids[1]))
        or (_is_this_expr(kids[1]) and _is_addr_of_expr(kids[0]))
    ):
        return hir.HirBoolLiteral(value=(op == "!="))
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
    if lhs.kind == CursorKind.MEMBER_REF_EXPR:
        lhs_kids = list(lhs.get_children())
        obj = _convert_expr(lhs_kids[0]) if lhs_kids else hir.HirName(name="self")
        if op == "=":
            value = rhs
        else:
            value = hir.HirBinOp(
                op=op[:-1],
                left=hir.HirFieldAccess(value=obj, field=lhs.spelling),
                right=rhs,
            )
        return hir.HirFieldAssign(obj=obj, field=lhs.spelling, value=value)
    sub = None
    if lhs.kind == CursorKind.ARRAY_SUBSCRIPT_EXPR:
        lk = list(lhs.get_children())
        if len(lk) == 2:
            sub = (_convert_expr(lk[0]), _convert_expr(lk[1]))
    elif lhs.kind == CursorKind.CALL_EXPR and lhs.spelling != "operator()":
        lk = [
            c
            for c in lhs.get_children()
            if c.kind not in (CursorKind.TYPE_REF, CursorKind.NAMESPACE_REF)
            and not (
                (c.spelling or "").startswith("operator")
                and c.kind != CursorKind.CALL_EXPR
            )
        ]
        if len(lk) >= 2:
            sub = (_convert_expr(lk[0]), _convert_expr(lk[-1]))
    if sub is not None:
        obj, index = sub
        if op == "=":
            value = rhs
        else:
            value = hir.HirBinOp(
                op=op[:-1], left=hir.HirSubscript(value=obj, index=index), right=rhs
            )
        return hir.HirSubscriptAssign(obj=obj, index=index, value=value)
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
        return _convert_expr(kids[0])
    if op == "~":
        return hir.HirUnaryOp(op="~", operand=_convert_expr(kids[0]))
    if op in ("++", "--"):
        target_name = _decl_name(kids[0])
        operand = _convert_expr(kids[0])
        if target_name is not None:
            sign = "+" if op == "++" else "-"
            _record_postfix_effect(
                hir.HirAssign(
                    target=target_name,
                    value=hir.HirIntLiteral(value=1),
                    annotation=None,
                    augmented_op=sign,
                )
            )
            return operand
        if isinstance(operand, hir.HirSubscript):
            sign = "+" if op == "++" else "-"
            _record_postfix_effect(
                hir.HirSubscriptAssign(
                    obj=operand.value,
                    index=operand.index,
                    value=hir.HirBinOp(
                        op=sign, left=operand, right=hir.HirIntLiteral(value=1)
                    ),
                )
            )
            return operand
        raise UnsupportedConstruct(f"postfix {op!r} on complex expression")
    raise UnsupportedConstruct(f"unary op {op!r} as expression")


def _convert_unary_stmt(cursor: ci.Cursor) -> hir.HirNode:
    """`i++` / `i--` as a statement."""
    op = _unary_token(cursor)
    if op not in ("++", "--"):
        raise UnsupportedConstruct(f"unary stmt {op!r}")
    kids = list(cursor.get_children())
    target = _decl_name(kids[0])
    sign = "+" if op == "++" else "-"
    if target is not None:
        return hir.HirAssign(
            target=target,
            value=hir.HirIntLiteral(value=1),
            annotation=None,
            augmented_op=sign,
        )
    operand = _convert_expr(kids[0])
    if isinstance(operand, hir.HirSubscript):
        return hir.HirSubscriptAssign(
            obj=operand.value,
            index=operand.index,
            value=hir.HirBinOp(op=sign, left=operand, right=hir.HirIntLiteral(value=1)),
        )
    raise UnsupportedConstruct(f"++/-- on {kids[0].kind.name}")


_TUPLE_CONSTRUCTORS = frozenset({"tuple", "pair", "make_pair", "make_tuple"})

_LIST_CONSTRUCTORS = frozenset({"vector", "array", "deque", "list"})

_OVERLOAD_BINOPS = frozenset(
    {
        "operator+",
        "operator-",
        "operator*",
        "operator/",
        "operator%",
        "operator==",
        "operator!=",
        "operator<",
        "operator>",
        "operator<=",
        "operator>=",
        "operator&&",
        "operator||",
    }
)

_OVERLOAD_AUGOPS = {
    "operator+=": "+",
    "operator-=": "-",
    "operator*=": "*",
    "operator/=": "/",
    "operator%=": "%",
}


def _lhs_as_subscript_or_name(lhs: ci.Cursor) -> hir.HirNode:
    """Convert an assignment LHS cursor to an expression for use in `return lhs`."""
    lhs = _strip_unexposed(lhs)
    if lhs.kind == CursorKind.ARRAY_SUBSCRIPT_EXPR:
        lk = list(lhs.get_children())
        if len(lk) == 2:
            return hir.HirSubscript(
                value=_convert_expr(lk[0]), index=_convert_expr(lk[1])
            )
    if lhs.kind == CursorKind.CALL_EXPR:
        lk = list(lhs.get_children())
        args = [
            c
            for c in lk
            if c.kind not in (CursorKind.TYPE_REF, CursorKind.NAMESPACE_REF)
        ]
        meaningful = [
            a
            for a in args
            if not (
                (a.spelling or "").startswith("operator")
                and a.kind != CursorKind.CALL_EXPR
            )
        ]
        if len(meaningful) >= 2:
            return hir.HirSubscript(
                value=_convert_expr(meaningful[0]), index=_convert_expr(meaningful[-1])
            )
    if lhs.kind == CursorKind.MEMBER_REF_EXPR:
        lk = list(lhs.get_children())
        obj = _convert_expr(lk[0]) if lk else hir.HirName(name="self")
        return hir.HirFieldAccess(value=obj, field=lhs.spelling)
    return _convert_expr(lhs)


def _assign_to(target: hir.HirNode, value: hir.HirNode) -> hir.HirNode:
    """Build the right *Assign statement for a target expression shape
    produced by `_lhs_as_subscript_or_name` (subscript / field / plain
    name), for `_convert_std_swap_stmt`'s manual swap desugaring."""
    if isinstance(target, hir.HirSubscript):
        return hir.HirSubscriptAssign(obj=target.value, index=target.index, value=value)
    if isinstance(target, hir.HirFieldAccess):
        return hir.HirFieldAssign(obj=target.value, field=target.field, value=value)
    if isinstance(target, hir.HirName):
        return hir.HirAssign(target=target.name, value=value, annotation=None)
    raise UnsupportedConstruct(f"swap target shape {type(target).__name__}")


def _convert_std_swap_stmt(cursor: ci.Cursor) -> list[hir.HirNode] | None:
    """`std::swap(a, b);` as a statement -> `tmp = a; a = b; b = tmp;`.

    Not just a style choice: Mojo's own `swap()` builtin rejects two
    arguments that alias the same underlying container ("argument ...
    allows writing a memory location previously writable through another
    aliased argument") -- exactly OCCT's `gp_Mat::Transpose` idiom,
    `std::swap(myMat[0][1], myMat[1][0])`, two elements of the *same*
    matrix. A manual temp-variable swap sidesteps that aliasing-exclusivity
    restriction entirely (no two arguments passed to any single call), and
    is correct universally -- not a Mojo-specific workaround.

    Returns None (not applicable) for anything that isn't a genuine
    `std::swap(a, b)` two-argument call, so the caller falls back to
    ordinary call-expression handling.
    """
    if cursor.spelling != "swap":
        return None
    ref = cursor.referenced
    if (
        ref is None
        or ref.semantic_parent is None
        or ref.semantic_parent.spelling != "std"
    ):
        return None
    kids = [
        k
        for k in cursor.get_children()
        if k.kind
        not in (CursorKind.NAMESPACE_REF, CursorKind.TYPE_REF, CursorKind.TEMPLATE_REF)
        and (k.spelling or "") != "swap"
    ]
    if len(kids) != 2:
        return None
    a = _lhs_as_subscript_or_name(kids[0])
    b = _lhs_as_subscript_or_name(kids[1])
    tmp = "__swap_tmp"
    return [
        hir.HirAssign(target=tmp, value=a, annotation=None),
        _assign_to(a, b),
        _assign_to(b, hir.HirName(name=tmp)),
    ]


def _iter_index(node: "hir.HirNode"):
    """Interpret a vector iterator expr as (container, index): c.begin() -> (c,0),
    c.end() -> (c, len(c)), c.begin()+k -> (c, k). Returns None otherwise."""
    if (
        isinstance(node, hir.HirMethodCall)
        and node.method in ("begin", "end")
        and not node.args
    ):
        idx = (
            hir.HirIntLiteral(value=0)
            if node.method == "begin"
            else hir.HirCall(func="len", args=[node.receiver])
        )
        return (node.receiver, idx)
    if (
        isinstance(node, hir.HirBinOp)
        and node.op == "+"
        and isinstance(node.left, hir.HirMethodCall)
        and node.left.method == "begin"
    ):
        return (node.left.receiver, node.right)
    return None


def _convert_call(cursor: ci.Cursor) -> hir.HirNode:
    kids = list(cursor.get_children())

    if cursor.spelling in _OVERLOAD_BINOPS:
        op = cursor.spelling[len("operator") :]
        operands = [k for k in kids if (k.spelling or "") != cursor.spelling]
        if len(operands) == 2:
            lhs = _convert_expr(operands[0])
            rhs = _convert_expr(operands[1])
            if op in ("==", "!=", "<", ">", "<=", ">="):
                return hir.HirCompare(op=op, left=lhs, right=rhs)
            if op in ("&&", "||"):
                return hir.HirBoolOp(
                    op="and" if op == "&&" else "or", left=lhs, right=rhs
                )
            return hir.HirBinOp(op=op, left=lhs, right=rhs)
        if len(operands) == 1 and op in ("+", "-"):
            return hir.HirUnaryOp(op=op, operand=_convert_expr(operands[0]))

    if cursor.spelling == "operator=" or cursor.spelling in _OVERLOAD_AUGOPS:
        operands = [k for k in kids if (k.spelling or "") != cursor.spelling]
        if len(operands) == 2:
            lhs, rhs = operands
            aug = _OVERLOAD_AUGOPS.get(cursor.spelling)
            if lhs.kind == CursorKind.MEMBER_REF_EXPR:
                lhs_kids = list(lhs.get_children())
                obj = (
                    _convert_expr(lhs_kids[0]) if lhs_kids else hir.HirName(name="self")
                )
                value = _convert_expr(rhs)
                if aug is not None:
                    value = hir.HirBinOp(
                        op=aug,
                        left=hir.HirFieldAccess(value=obj, field=lhs.spelling),
                        right=value,
                    )
                return hir.HirFieldAssign(obj=obj, field=lhs.spelling, value=value)
            target = _decl_name(lhs) or ("self" if _is_this_deref(lhs) else None)
            if target is not None:
                return hir.HirAssign(
                    target=target,
                    value=_convert_expr(rhs),
                    annotation=None,
                    augmented_op=aug,
                )

    if cursor.spelling in _KNOWN_STRUCT_NAMES:
        real = [c for c in kids if c.kind != CursorKind.TYPE_REF]
        if len(real) == 1:
            arg_ty = (
                (real[0].type.spelling or "").replace("const ", "").rstrip("&").strip()
            )
            if arg_ty == cursor.spelling:
                return _convert_expr(real[0])
        args = [_convert_expr(c) for c in real]
        return hir.HirStructInit(name=cursor.spelling, args=args)

    if cursor.spelling == "vector":
        real = [
            k
            for k in kids
            if k.kind
            not in (
                CursorKind.TYPE_REF,
                CursorKind.TEMPLATE_REF,
                CursorKind.NAMESPACE_REF,
            )
        ]
        if "{" in [t.spelling for t in cursor.get_tokens()]:
            if not real:
                return hir.HirCall(func="__cpp_overloaded_op__", args=[])
            return hir.HirList(elements=[_convert_expr(k) for k in real])
        if len(real) == 1 and "vector" in (real[0].type.spelling or ""):
            return _convert_expr(real[0])
        if (
            len(real) == 2
        ):
            a_hir, b_hir = _convert_expr(real[0]), _convert_expr(real[1])
            ia, ib = _iter_index(a_hir), _iter_index(b_hir)
            if ia and ib:
                return hir.HirCall(func="__vector_slice__", args=[ia[0], ia[1], ib[1]])
        if real:
            return hir.HirCall(
                func="__vector_fill__", args=[_convert_expr(k) for k in real]
            )

    if cursor.spelling in ("map", "unordered_map", "_mapbase", "set", "unordered_set"):
        real = [
            k
            for k in kids
            if k.kind
            not in (
                CursorKind.TYPE_REF,
                CursorKind.TEMPLATE_REF,
                CursorKind.NAMESPACE_REF,
            )
        ]
        if len(real) == 1 and any(
            s in (real[0].type.spelling or "") for s in ("map", "set")
        ):
            return _convert_expr(real[0])

    if cursor.spelling in ("string", "basic_string"):
        real = [
            k
            for k in kids
            if k.kind
            not in (
                CursorKind.TYPE_REF,
                CursorKind.TEMPLATE_REF,
                CursorKind.NAMESPACE_REF,
            )
        ]
        if len(real) == 1:
            return _convert_expr(real[0])

    if cursor.spelling == "operator[]" or any(
        k.kind == CursorKind.DECL_REF_EXPR and "operator[]" in (k.spelling or "")
        for k in kids
    ):
        meaningful = [
            c
            for c in kids
            if c.kind not in (CursorKind.TYPE_REF, CursorKind.NAMESPACE_REF)
            and not (
                (c.spelling or "").startswith("operator")
                and c.kind != CursorKind.CALL_EXPR
            )
        ]
        if len(meaningful) >= 2:
            return hir.HirSubscript(
                value=_convert_expr(meaningful[0]), index=_convert_expr(meaningful[-1])
            )

    if cursor.spelling == "operator()":
        op_ref = next(
            (
                k
                for k in kids
                if (k.spelling or "").startswith("operator")
                and k.kind != CursorKind.CALL_EXPR
            ),
            None,
        )
        referenced = op_ref.referenced if op_ref is not None else None
        if referenced is not None and referenced.result_type.kind in (
            ci.TypeKind.LVALUEREFERENCE,
            ci.TypeKind.RVALUEREFERENCE,
        ):
            meaningful = [
                c
                for c in kids
                if c.kind not in (CursorKind.TYPE_REF, CursorKind.NAMESPACE_REF)
                and not (
                    (c.spelling or "").startswith("operator")
                    and c.kind != CursorKind.CALL_EXPR
                )
            ]
            if len(meaningful) >= 3:
                return hir.HirMethodCall(
                    receiver=_convert_expr(meaningful[0]),
                    method="__getitem__",
                    args=[_convert_expr(a) for a in meaningful[1:]],
                )

    if cursor.spelling in _TUPLE_CONSTRUCTORS and kids:
        real = [
            k
            for k in kids
            if k.kind
            not in (
                CursorKind.TYPE_REF,
                CursorKind.TEMPLATE_REF,
                CursorKind.NAMESPACE_REF,
            )
        ]
        if "{" in [t.spelling for t in cursor.get_tokens()]:
            return hir.HirCall(
                func="tuple",
                args=[hir.HirList(elements=[_convert_expr(c) for c in real])],
            )
        first = _strip_unexposed(kids[0])
        if first.kind not in (CursorKind.DECL_REF_EXPR, CursorKind.MEMBER_REF_EXPR):
            elements = [_convert_expr(c) for c in kids]
            return hir.HirCall(func="tuple", args=[hir.HirList(elements=elements)])

    if cursor.spelling in _LIST_CONSTRUCTORS and kids:
        first = _strip_unexposed(kids[0])
        if first.kind not in (CursorKind.DECL_REF_EXPR, CursorKind.MEMBER_REF_EXPR):
            elements = [_convert_expr(c) for c in kids]
            return hir.HirList(elements=elements)

    if not kids:
        return hir.HirCall(func="__cpp_overloaded_op__", args=[])
    callee = kids[0]
    if callee.kind == CursorKind.MEMBER_REF_EXPR:
        callee_kids = list(callee.get_children())
        receiver = (
            _convert_expr(callee_kids[0]) if callee_kids else hir.HirName(name="self")
        )
        args = [_convert_expr(a) for a in kids[1:]]
        return hir.HirMethodCall(receiver=receiver, method=callee.spelling, args=args)
    while callee.kind == CursorKind.UNEXPOSED_EXPR:
        inner = list(callee.get_children())
        if not inner:
            break
        callee = inner[0]
    name = _decl_name(callee) or callee.spelling
    if not name:
        return hir.HirCall(
            func="__cpp_overloaded_op__", args=[_convert_expr(a) for a in kids[1:]]
        )
    args = [_convert_expr(a) for a in kids[1:]]
    referenced = callee.referenced
    qualified = any(t.spelling == "::" for t in callee.get_tokens())
    if (
        referenced is not None
        and referenced.kind == CursorKind.CXX_METHOD
        and not qualified
    ):
        return hir.HirMethodCall(
            receiver=hir.HirName(name="self"), method=name, args=args
        )
    if (
        referenced is not None
        and referenced.kind == CursorKind.CXX_METHOD
        and qualified
        and referenced.is_static_method()
        and referenced.semantic_parent is not None
    ):
        struct_name = referenced.semantic_parent.spelling
        return hir.HirMethodCall(
            receiver=hir.HirName(name=struct_name), method=name, args=args
        )
    lifted = _lift_simd_intrinsic(name, args)
    if lifted is not None:
        return lifted
    return hir.HirCall(func=name, args=args)
