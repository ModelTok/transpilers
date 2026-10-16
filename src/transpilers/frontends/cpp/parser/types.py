"""C++ type spelling -> HIR type-text mapping (leaf utility)."""

from __future__ import annotations

import clang.cindex as ci

from .errors import UnsupportedConstruct


class _TypeShim:
    __slots__ = ("spelling",)

    def __init__(self, spelling: str) -> None:
        self.spelling = spelling


CPP_TYPE_ALIASES: dict[str, str] = {
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
    "float": "float",
    "double": "float",
    "long double": "float",
    "bool": "bool",
    "_Bool": "bool",
    "void": "None",
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

SIMD_TYPE_ALIASES: dict[str, str] = {
    "__m256d": "simd[float, 4]",
    "__m256": "simd[float, 8]",
    "__m256i": "simd[int, 8]",
    "__m128d": "simd[float, 2]",
    "__m128": "simd[float, 4]",
    "__m128i": "simd[int, 4]",
    "__m512d": "simd[float, 8]",
    "__m512": "simd[float, 16]",
    "__m512i": "simd[int, 16]",
}

_VECTOR_ELEM_ALIASES = {
    "int": "int",
    "long": "int",
    "long long": "int",
    "short": "int",
    "unsigned": "int",
    "unsigned int": "int",
    "unsigned long": "int",
    "char": "int",
    "unsigned char": "int",
    "signed char": "int",
    "size_t": "int",
    "ptrdiff_t": "int",
    "float": "float",
    "double": "float",
    "long double": "float",
    "bool": "bool",
    "string": "str",
    "std::string": "str",
}


def _type_text(t: ci.Type) -> str:
    spelling = t.spelling
    cleaned = spelling.replace("const ", "").replace("volatile ", "").strip()
    if cleaned in CPP_TYPE_ALIASES:
        return CPP_TYPE_ALIASES[cleaned]
    if cleaned in SIMD_TYPE_ALIASES:
        return SIMD_TYPE_ALIASES[cleaned]
    if cleaned in ("string", "std::string", "std::basic_string<char>"):
        return "str"
    if cleaned.startswith(("vector<", "std::vector<")) and cleaned.endswith(">"):
        inner = cleaned.split("<", 1)[1][:-1].strip()
        if inner.startswith(("vector<", "std::vector<")) and inner.endswith(">"):
            inner = _type_text(
                _TypeShim(spelling=inner)
            )
        else:
            inner = _VECTOR_ELEM_ALIASES.get(inner, inner)
        return f"list[{inner}]"
    for _pre in (
        "list<",
        "std::list<",
        "stack<",
        "std::stack<",
        "queue<",
        "std::queue<",
    ):
        if cleaned.startswith(_pre) and cleaned.endswith(">"):
            inner = cleaned.split("<", 1)[1][:-1].strip()
            return f"list[{_VECTOR_ELEM_ALIASES.get(inner, inner)}]"
    for _pre in ("tuple<", "std::tuple<", "pair<", "std::pair<"):
        if cleaned.startswith(_pre) and cleaned.endswith(">"):
            inner = cleaned.split("<", 1)[1][:-1].strip()
            parts, depth, last = [], 0, 0
            for i, ch in enumerate(inner):
                if ch in "[<":
                    depth += 1
                elif ch in "]>":
                    depth -= 1
                elif ch == "," and depth == 0:
                    parts.append(inner[last:i].strip())
                    last = i + 1
            parts.append(inner[last:].strip())
            parts = [_VECTOR_ELEM_ALIASES.get(p, p) for p in parts]
            return f"tuple[{', '.join(parts)}]"
    for _pre in ("unordered_map<", "std::unordered_map<", "map<", "std::map<"):
        if cleaned.startswith(_pre) and cleaned.endswith(">"):
            inner = cleaned.split("<", 1)[1][:-1].strip()
            depth = 0
            for i, ch in enumerate(inner):
                if ch in "[<":
                    depth += 1
                elif ch in "]>":
                    depth -= 1
                elif ch == "," and depth == 0:
                    k = _VECTOR_ELEM_ALIASES.get(inner[:i].strip(), inner[:i].strip())
                    v = _VECTOR_ELEM_ALIASES.get(
                        inner[i + 1 :].strip(), inner[i + 1 :].strip()
                    )
                    return f"dict[{k}, {v}]"
            break
    if "[" in cleaned and cleaned.endswith("]"):
        head = cleaned[: cleaned.index("[")].strip()
        if head in _VECTOR_ELEM_ALIASES:
            result = _VECTOR_ELEM_ALIASES[head]
            for _ in range(cleaned.count("[")):
                result = f"list[{result}]"
            return result
    if t.kind in (
        ci.TypeKind.CONSTANTARRAY,
        ci.TypeKind.INCOMPLETEARRAY,
        ci.TypeKind.VARIABLEARRAY,
    ):
        try:
            return f"list[{_type_text(t.element_type)}]"
        except UnsupportedConstruct:
            return "list[int]"
    kind = t.kind
    INTEGER_KINDS = {
        ci.TypeKind.INT,
        ci.TypeKind.LONG,
        ci.TypeKind.LONGLONG,
        ci.TypeKind.SHORT,
        ci.TypeKind.SCHAR,
        ci.TypeKind.UCHAR,
        ci.TypeKind.CHAR_S,
        ci.TypeKind.CHAR_U,
        ci.TypeKind.UINT,
        ci.TypeKind.ULONG,
        ci.TypeKind.ULONGLONG,
        ci.TypeKind.USHORT,
    }
    if kind in INTEGER_KINDS:
        return "int"
    if kind in (ci.TypeKind.FLOAT, ci.TypeKind.DOUBLE, ci.TypeKind.LONGDOUBLE):
        return "float"
    if kind == ci.TypeKind.BOOL:
        return "bool"
    if kind == ci.TypeKind.VOID:
        return "None"
    if kind == ci.TypeKind.RECORD:
        if cleaned.startswith(("vector<", "std::vector<")) and cleaned.endswith(">"):
            inner = cleaned.split("<", 1)[1][:-1].strip()
            return f"list[{_VECTOR_ELEM_ALIASES.get(inner, inner)}]"
        if "::" in cleaned:
            return cleaned.rsplit("::", 1)[1]
        return cleaned
    if kind == ci.TypeKind.POINTER:
        try:
            return f"list[{_type_text(t.get_pointee())}]"
        except UnsupportedConstruct:
            return "list[int]"
    if kind in (ci.TypeKind.LVALUEREFERENCE, ci.TypeKind.RVALUEREFERENCE):
        try:
            return _type_text(t.get_pointee())
        except UnsupportedConstruct:
            return "int"
    if kind == ci.TypeKind.TYPEDEF:
        canonical = t.get_canonical()
        if canonical.kind != kind:
            try:
                return _type_text(canonical)
            except UnsupportedConstruct:
                pass
        return "int"
    if kind in (ci.TypeKind.AUTO, ci.TypeKind.ELABORATED, ci.TypeKind.UNEXPOSED):
        canonical = t.get_canonical()
        if canonical.kind != kind:
            try:
                return _type_text(canonical)
            except UnsupportedConstruct:
                pass
        return "int"
    raise UnsupportedConstruct(f"C++ type {spelling!r} (kind={kind.name})")


__all__ = [
    "CPP_TYPE_ALIASES",
    "SIMD_TYPE_ALIASES",
    "_VECTOR_ELEM_ALIASES",
    "_type_text",
]
