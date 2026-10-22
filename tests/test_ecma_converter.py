"""JavaScript and TypeScript share one converter; pin what still differs between them."""

from __future__ import annotations

import pytest

from transpilers.frontends._ecma import EcmaConverter
from transpilers.frontends.errors import UnsupportedConstruct
from transpilers.frontends.javascript import parse_javascript
from transpilers.frontends.typescript import parse_typescript
from transpilers.frontends.javascript.parser import _JavaScript
from transpilers.frontends.typescript.parser import _TypeScript


def test_both_frontends_use_the_shared_converter():
    assert issubclass(_JavaScript, EcmaConverter)
    assert issubclass(_TypeScript, EcmaConverter)


@pytest.mark.parametrize(
    ("parse", "prefix"), [(parse_javascript, "js"), (parse_typescript, "ts")]
)
def test_unsupported_messages_carry_the_language_prefix(parse, prefix):
    with pytest.raises(UnsupportedConstruct, match=rf"{prefix} binary '\*\*'"):
        parse("function f(a) { return a ** 2; }")
    with pytest.raises(UnsupportedConstruct, match=rf"{prefix} stmt break_statement"):
        parse("function f(a) { break; }")


def test_source_lang_is_set_per_frontend():
    assert parse_javascript("function f() { return 1; }").source_lang == "javascript"
    assert parse_typescript("function f() { return 1; }").source_lang == "typescript"


def test_only_typescript_reads_annotations():
    js = parse_javascript("function f(a) { let b = 1; return a; }").body[0]
    assert js.return_annotation is None
    assert [p.annotation for p in js.params] == [None]

    ts = parse_typescript("function f(a: number): boolean { let b: string = 'x'; return true; }").body[0]
    assert ts.return_annotation == "bool"
    assert [p.annotation for p in ts.params] == ["int"]
    assert ts.body[0].annotation == "str"


def test_typescript_skips_type_declarations_that_javascript_rejects():
    ts = parse_typescript("type T = number;\ninterface I { a: number }\nfunction f() { return 1; }")
    assert [f.name for f in ts.body] == ["f"]
    with pytest.raises(UnsupportedConstruct):
        parse_javascript("class A {}")
