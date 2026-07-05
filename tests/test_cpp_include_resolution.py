"""Multi-file C++ support: resolving local `#include` headers.

The strict frontend is built around single self-contained translation units
(`preprocess.py` strips every #include unconditionally). Real C++ projects
split declarations (.h) from definitions (.cpp) across files, so feeding
just the .cpp means the class its out-of-line methods belong to is never
declared. `resolve_local_includes` closes that gap by transitively inlining
local headers found on a search path before the file ever reaches the
parser; the CLI's `--include-dir`/`-I` flag is opt-in only (an invocation
with no -I is byte-for-byte the old behavior).
"""

from __future__ import annotations

import textwrap

import pytest

from transpilers.cli.main import main
from transpilers.frontends.cpp.parser.includes import resolve_local_includes


def _write(tmp_path, name, content):
    p = tmp_path / name
    p.write_text(textwrap.dedent(content).lstrip())
    return p


def test_resolve_local_includes_inlines_transitively(tmp_path):
    _write(tmp_path, "base.h", """
        class Base { public: int tag() { return 1; } };
    """)
    _write(tmp_path, "derived.h", """
        #include "base.h"
        class Derived : public Base {};
    """)
    entry = _write(tmp_path, "derived.cpp", """
        #include "derived.h"
        int use() { return 0; }
    """)

    out = resolve_local_includes(entry)
    # base.h's declaration comes before derived.h's, which comes before the
    # entry file's own body -- dependencies before dependents.
    assert out.index("class Base") < out.index("class Derived")
    assert out.index("class Derived") < out.index("int use()")


def test_resolve_local_includes_matches_angle_bracket_form(tmp_path):
    # Real projects (e.g. Topologic) use #include <Local.h> for their own
    # headers when their build system puts the project's own include dir on
    # the search path -- angle vs quote is a search-order hint, not a
    # local/system classification.
    _write(tmp_path, "widget.h", """
        class Widget { public: int id() { return 7; } };
    """)
    entry = _write(tmp_path, "widget.cpp", """
        #include <widget.h>
        int use() { return 0; }
    """)

    out = resolve_local_includes(entry, include_dirs=[tmp_path])
    assert "class Widget" in out


def test_resolve_local_includes_leaves_unresolvable_include_alone(tmp_path):
    entry = _write(tmp_path, "uses_vendor.cpp", """
        #include <SomeVendorLib.hxx>
        int f() { return 1; }
    """)
    out = resolve_local_includes(entry)
    # Nothing to inline -- the file is returned effectively unchanged
    # (still containing the now-unresolvable directive, which the existing
    # preprocess.py stripping removes later exactly as before).
    assert "#include <SomeVendorLib.hxx>" in out
    assert "int f()" in out


def test_cli_transpiles_multi_file_class_with_include_dir(tmp_path, capsys):
    _write(tmp_path, "mathutil.h", """
        class MathUtil {
        public:
            static int square(int x);
        };
    """)
    entry = _write(tmp_path, "mathutil.cpp", """
        #include <mathutil.h>
        int MathUtil::square(int x) { return x * x; }
    """)

    ret = main([str(entry), "--source", "cpp", "--target", "mojo",
                "--include-dir", str(tmp_path)])
    assert ret is None or ret == 0
    out = capsys.readouterr().out
    assert "struct MathUtil" in out
    assert "def square(self, x: Int) -> Int:" in out


def test_cli_without_include_dir_still_fails_the_old_way(tmp_path):
    """No -I given -> behavior is unchanged from before this feature:
    the out-of-line method's enclosing class is never declared."""
    _write(tmp_path, "mathutil.h", """
        class MathUtil {
        public:
            static int square(int x);
        };
    """)
    entry = _write(tmp_path, "mathutil.cpp", """
        #include <mathutil.h>
        int MathUtil::square(int x) { return x * x; }
    """)

    from transpilers.frontends.errors import UnsupportedConstruct
    with pytest.raises(UnsupportedConstruct, match="undeclared identifier"):
        main([str(entry), "--source", "cpp", "--target", "mojo"])
