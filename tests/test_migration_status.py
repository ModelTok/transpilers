"""Tests for scripts/migration_status.py.

No test needs WSL, the network or the EnergyPlus repos: LOC and symbol counting
run on small inline fixtures, test running uses a throw-away pytest project, and
the baseline-revision test builds a temporary git repository with two commits.
"""

from __future__ import annotations

import importlib.util
import json
import os
import shutil
import subprocess
import sys
import tempfile
import textwrap
from pathlib import Path

import pytest

SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "migration_status.py"
_spec = importlib.util.spec_from_file_location("migration_status", SCRIPT)
ms = importlib.util.module_from_spec(_spec)
sys.modules["migration_status"] = ms
_spec.loader.exec_module(ms)


def _t(src: str) -> str:
    return textwrap.dedent(src).lstrip("\n")


def _scan(src: str, filename: str):
    spec = ms.lang_for(filename)
    return ms.scan_text(_t(src), spec, Path(filename).suffix.lower() in ms.FIXED_FORM_EXTS)


# ---------------------------------------------------------------------------
# LOC counting per language
# ---------------------------------------------------------------------------


def test_python_loc_code_comment_blank_and_docstrings():
    res = _scan(
        '''
        """Module docstring
        over two lines."""
        # a comment
        import os

        def f(x):
            """One-line docstring."""
            y = """not
        a docstring
        # nor a comment"""
            return x  # trailing comment is code
        ''',
        "a.py",
    )
    assert (res.code, res.comment, res.blank) == (6, 4, 1)


def test_mojo_extensions_share_hash_rules_including_fire_emoji():
    src = "# c\nfn main():\n    pass\n"
    for name in ("a.mojo", "a.\U0001F525"):
        res = _scan(src, name)
        assert (res.code, res.comment, res.blank) == (2, 1, 0)


def test_cpp_block_line_and_mixed_comments():
    res = _scan(
        """
        // header comment
        /* block start
           still comment

           end */
        int x = 1; // trailing
        /* inline */ int y = 2;
        int z = 3; /* a */ /* b */

        int w;
        """,
        "a.cc",
    )
    # code: x, y, z, w ; comment: line, 3 block lines (blank line inside is blank) ; blank: 2
    assert (res.code, res.comment, res.blank) == (4, 4, 2)


def test_cpp_comment_markers_inside_strings_are_code():
    res = _scan(
        r"""
        const char* url = "http://example.com";
        const char* q = "a /* not a comment";
        char c = '"';
        int after = 1; // real comment
        """,
        "a.cpp",
    )
    assert (res.code, res.comment, res.blank) == (4, 0, 0)
    assert "real comment" not in "\n".join(res.code_lines)


def test_cpp_code_lines_drop_comments():
    res = _scan("int a; // x { }\n/* { */ int b;\n", "a.h")
    assert [ln.strip() for ln in res.code_lines] == ["int a;", "int b;"]


def test_rust_nested_block_comments():
    res = _scan(
        """
        /* outer /* inner */ still outer */
        fn main() {}
        // line
        """,
        "a.rs",
    )
    assert (res.code, res.comment, res.blank) == (1, 2, 0)


def test_fortran_free_and_fixed_form_comments():
    free = _scan("! comment\nprogram p\n  x = 1 ! trailing\nend program\n", "a.f90")
    assert (free.code, free.comment, free.blank) == (3, 1, 0)
    fixed = _scan("C old style comment\n      X = 1\n* another\n! bang\n", "a.f")
    assert (fixed.code, fixed.comment) == (1, 3)


def test_crlf_and_form_feed_do_not_change_line_counts():
    res = ms.scan_text("int a;\r\n\x0c\r\nint b;\r\n", ms.lang_for("a.c"))
    assert (res.code, res.comment, res.blank) == (2, 0, 1)


def test_unknown_extension_has_no_language():
    assert ms.lang_for("README.md") is None
    assert ms.lang_for("Foo.CC").key == "c_cpp"


# ---------------------------------------------------------------------------
# test / production split
# ---------------------------------------------------------------------------


@pytest.mark.parametrize(
    "rel,expected",
    [
        ("tests/unit/test_a.py", True),
        ("src/pkg/test_helpers.py", True),
        ("src/pkg/widget_test.cc", True),
        ("src/pkg/widget.test.ts", True),
        ("tst/EnergyPlus/unit/Foo.unit.cc", True),
        ("conftest.py", True),
        ("src/FooTest.java", True),
        ("src/pkg/widget.py", False),
        ("src/EnergyPlus/Foo.cc", False),
        ("src/latest/model.py", False),
        ("src/contest/solver.rs", False),
    ],
)
def test_is_test_path(rel, expected):
    assert ms.is_test_path(rel) is expected


# ---------------------------------------------------------------------------
# function / class counting
# ---------------------------------------------------------------------------


def test_python_symbols_via_ast_and_declared_tests():
    src = _t(
        """
        import pytest

        def helper(): pass

        def test_one(): pass

        async def test_two(): pass

        class TestGroup:
            def test_a(self): pass
            def helper(self): pass

        class Plain:
            def test_not_collected(self): pass
        """
    )
    sym = ms.count_python(src, want_tests=True)
    assert (sym.functions, sym.classes, sym.declared_tests, sym.parse_error) == (6, 2, 3, False)


def test_python_syntax_error_falls_back_to_regex():
    sym = ms.count_python("def a(:\n    pass\ndef b(): pass\nclass C: pass\n", want_tests=False)
    assert sym.parse_error and sym.functions == 2 and sym.classes == 1


def test_mojo_symbols():
    code = _t(
        """
        struct Point:
            var x: Int
            fn __init__(out self, x: Int):
                self.x = x

        trait Shape:
            fn area(self) -> Float64: ...

        @export
        fn main():
            pass

        def test_main():
            pass
        """
    )
    sym = ms.count_mojo(code, want_tests=True)
    assert (sym.functions, sym.classes, sym.declared_tests) == (4, 2, 1)


CPP_SAMPLE = _t(
    """
    #include <vector>
    #define MACRO(x) { x; }
    namespace Demo {
    constexpr int table[] = {1, 2, 3};
    struct Widget : Base {
        Widget(int a) : a_{a}, b_(a) { init(); }
        int get() const { return a_; }
        void set(int v);
        struct Inner { int q; };
        enum class Kind { A, B };
        int a_;
    };
    void Widget::set(int v)
    {
        auto f = [&](int x) { return x + v; };
        if (v > 0) { a_ = f(1); }
        for (int i = 0; i < 3; ++i) { a_ += i; }
    }
    template <typename T = int>
    T twice(T x) { return x * 2; }
    bool operator==(const Widget& a, const Widget& b) { return a.get() == b.get(); }
    #ifdef FEATURE
    void guarded() { if (true) { } }
    #else
    void guarded() { }
    #endif
    }
    TEST_F(Fixture, Works) { EXPECT_TRUE(true); }
    """
)


def test_cpp_function_and_class_counts():
    sym = ms.count_cpp(CPP_SAMPLE, want_tests=True)
    # functions: Widget(), get(), set(), twice(), operator==, guarded() once, TEST_F
    assert sym.functions == 7
    # classes: Widget, Inner (enum class and the table initialiser are not classes)
    assert sym.classes == 2
    assert sym.declared_tests == 1


def test_cpp_if_zero_branch_is_dropped():
    src = "#if 0\nvoid dead() { }\n#else\nvoid live() { }\n#endif\n"
    assert ms.count_cpp(src, want_tests=False).functions == 1


def test_rust_and_fortran_symbols():
    rs = ms.count_rust("pub struct A;\nenum B {}\nfn a() {}\nimpl A { pub fn b(&self) {} }\n#[test]\nfn t() {}\n", True)
    assert (rs.functions, rs.classes, rs.declared_tests) == (3, 2, 1)
    f90 = ms.count_fortran("subroutine a()\nend subroutine a\npure function f(x)\nend function f\n")
    assert f90.functions == 2


def test_analyse_file_ties_scan_and_symbols_together():
    fm = ms.analyse_file("tests/test_x.py", "def test_a():\n    assert 1\n")
    assert fm.is_test and fm.lang == "python" and fm.code == 2
    assert fm.symbols.declared_tests == 1


# ---------------------------------------------------------------------------
# file discovery
# ---------------------------------------------------------------------------


def _write(path: Path, text: str = "x = 1\n") -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")
    return path


def test_walk_applies_excludes_includes_and_skips(tmp_path):
    _write(tmp_path / "src" / "a.py")
    _write(tmp_path / "src" / "vendored" / "b.py")
    _write(tmp_path / "node_modules" / "c.js")
    _write(tmp_path / "other" / "d.py")
    _write(tmp_path / "src" / "notes.md", "# not code\n")
    (tmp_path / "src" / "blob.py").write_bytes(b"x = 1\x00\x01")
    _write(tmp_path / "src" / "huge.py", "y = 2\n" * 100)
    skips = ms.SkipCounts()
    found = ms.walk_files(tmp_path, ["src"], [*ms.DEFAULT_EXCLUDES, "src/vendored"], None, skips)
    assert [rel for rel, _ in found] == ["src/a.py", "src/blob.py", "src/huge.py"]
    assert ms.read_text(tmp_path / "src" / "blob.py", 10_000, skips) is None
    assert ms.read_text(tmp_path / "src" / "huge.py", 50, skips) is None
    assert (skips.binary, skips.too_large) == (1, 1)


def test_symlinked_files_and_directories_are_not_followed(tmp_path):
    _write(tmp_path / "real" / "a.py")
    try:
        (tmp_path / "link.py").symlink_to(tmp_path / "real" / "a.py")
        (tmp_path / "real" / "loop").symlink_to(tmp_path, target_is_directory=True)
    except (OSError, NotImplementedError):
        pytest.skip("symlinks not available")
    skips = ms.SkipCounts()
    found = ms.walk_files(tmp_path, [], [], None, skips)
    assert [rel for rel, _ in found] == ["real/a.py"]
    assert skips.symlink == 1


def test_collect_static_splits_languages_and_parts(tmp_path):
    _write(tmp_path / "src" / "a.py", "# c\ndef f():\n    return 1\n")
    _write(tmp_path / "src" / "b.cc", "int main() { return 0; }\n")
    _write(tmp_path / "tests" / "test_a.py", "def test_f():\n    assert 1\n")
    body, _ = ms.collect_static(tmp_path, includes=[], excludes=[], tracked=None, max_bytes=10_000)
    assert body["loc"]["production"]["files"] == 2
    assert body["loc"]["production"]["code"] == 3
    assert body["loc"]["test"]["code"] == 2
    assert body["declared_tests"] == 1
    assert body["languages"]["c_cpp"]["production"]["code"] == 1
    assert body["symbols"]["production"]["functions"] == 2  # f() and main()
    assert body["symbols"]["approximate"]["production"] is True


# ---------------------------------------------------------------------------
# migration map
# ---------------------------------------------------------------------------

MAP_SAMPLE = _t(
    """
    # Map

    ## Core

    | Upstream File | Status | Target Module(s) | Mojo Kernel(s) | Notes |
    |---|---|---|---|---|
    | `Alpha.cc` | COMPLETE | `alpha.py` | `alpha.mojo` | done |
    | `Beta.cc` | PARTIAL | `beta.py` | — | has a `a|b` pipe in notes |
    | `Gamma.cc` | **NOT_STARTED** | — | — | |
    | `Gamma.cc` | PARTIAL | `gamma.py` | — | duplicate row, higher status wins |
    | `Delta.cc` | WIP | `d.py` | — | unknown status -> malformed |
    | `Broken.cc` |
    | `ExpandObjects (epfilter.f90)` | PARTIAL | `x.py` | — | stem from first word |

    ## Data

    | Upstream File | Status | Target Module(s) | Notes |
    |---|---|---|---|
    | `Zeta.hh` | complete | `z.py` | lower-case status |

    ## Summary Statistics

    | Category | Count | Percentage |
    |----------|-------|-----------|
    | **COMPLETE** (kernel) | 49 | ~29% |
    """
)


def test_parse_migration_map_tolerates_extra_columns_and_flags_malformed_rows():
    data = ms.parse_migration_map(MAP_SAMPLE)
    keys = [(r.key, r.status) for r in data.rows]
    assert ("Alpha", "COMPLETE") in keys and ("Zeta", "COMPLETE") in keys
    assert ("Gamma", "NOT_STARTED") in keys and ("ExpandObjects", "PARTIAL") in keys
    assert len(data.malformed) == 2  # Delta (WIP) and Broken (one cell)
    assert any("Delta" in m for m in data.malformed) and any("Broken" in m for m in data.malformed)
    assert data.non_data_rows >= 4  # headers, separators, summary row


def test_map_summary_counts_unique_modules_with_highest_status():
    summary = ms.map_summary(ms.parse_migration_map(MAP_SAMPLE), "MAP.md")
    assert summary["status_counts"] == {"COMPLETE": 2, "PARTIAL": 3, "NOT_STARTED": 0}
    assert summary["duplicate_rows"] == 1
    assert summary["malformed_row_count"] == 2


def test_join_map_to_files_by_stem_reports_unmapped_honestly():
    data = ms.parse_migration_map(MAP_SAMPLE)
    files = [
        {"path": "src/Alpha.cc", "code": 100, "is_test": False},
        {"path": "src/Alpha.hh", "code": 20, "is_test": False},  # header joins by stem
        {"path": "src/Beta.cc", "code": 50, "is_test": False},
        {"path": "src/sub/Beta.cc", "code": 30, "is_test": False},  # ambiguous stem
        {"path": "src/Orphan.cc", "code": 800, "is_test": False},
        {"path": "tst/Alpha.unit.cc", "code": 999, "is_test": True},  # ignored
    ]
    join = ms.join_map_to_files(data, files)
    by = join["by_status"]
    assert (by["COMPLETE"]["files"], by["COMPLETE"]["code"]) == (2, 120)
    assert (by["PARTIAL"]["files"], by["PARTIAL"]["code"]) == (2, 80)
    assert (by["UNMAPPED"]["files"], by["UNMAPPED"]["code"]) == (1, 800)
    assert join["upstream_code"] == 1000
    assert sum(b["code_share"] for b in by.values()) == pytest.approx(1.0)
    assert join["ambiguous_stems"] == 1
    assert "Gamma" in join["map_keys_without_upstream_file"]
    assert join["largest_unmapped"][0]["path"] == "src/Orphan.cc"


# ---------------------------------------------------------------------------
# pytest output parsing
# ---------------------------------------------------------------------------

SUMMARY_MIXED = """\
..F.s.x.E                                                                [100%]
=================================== FAILURES ===================================
___________________________________ test_b ____________________________________

    def test_b():
>       assert 1 == 2
E       assert 1 == 2

tests/test_x.py:4: AssertionError
=========================== short test summary info ============================
FAILED tests/test_x.py::test_b - assert 1 == 2
ERROR tests/test_x.py::test_e - RuntimeError: boom
============ 1 failed, 5 passed, 1 skipped, 1 xfailed, 1 error, 2 warnings in 12.34s ============
"""


def test_parse_pytest_summary_mixed():
    parsed = ms.parse_pytest_summary(SUMMARY_MIXED)
    assert parsed["counts"] == {"failed": 1, "passed": 5, "skipped": 1, "xfailed": 1, "errors": 1, "warnings": 2}
    assert parsed["duration_s"] == 12.34


def test_parse_pytest_summary_quiet_form_with_hms_duration():
    out = "........\n8201 passed, 3 skipped in 120.34s (0:02:00)\n"
    parsed = ms.parse_pytest_summary(out)
    assert parsed["counts"] == {"passed": 8201, "skipped": 3}
    assert parsed["duration_s"] == 120.34


def test_parse_pytest_summary_no_tests_ran():
    parsed = ms.parse_pytest_summary("============================ no tests ran in 0.01s =============================\n")
    assert parsed is not None and parsed["counts"] == {}


def test_parse_pytest_summary_collection_errors():
    out = (
        "==================================== ERRORS ====================================\n"
        "_____________________ ERROR collecting tests/test_a.py _____________________\n"
        "ImportError: No module named foo\n"
        "!!!!!!!!!!!!!!!!!!! Interrupted: 2 errors during collection !!!!!!!!!!!!!!!!!!!!\n"
        "=============================== 2 errors in 0.45s ===============================\n"
    )
    assert ms.parse_pytest_summary(out)["counts"] == {"errors": 2}


def test_parse_pytest_summary_absent_for_crash_or_truncated_output():
    assert ms.parse_pytest_summary("Traceback (most recent call last):\n  ...\nKeyError: 1\n") is None
    assert ms.parse_pytest_summary("..........F.....\n") is None
    # a test-output line that merely contains "in 3s" must not be mistaken for a summary
    assert ms.parse_pytest_summary("slept 3 times in 3s\n") is None


def test_parse_collect_output_variants():
    assert ms.parse_collect_output("a.py::t1\n\n10562 tests collected in 14.28s\n")["collected"] == 10562
    assert ms.parse_collect_output("=== 3/5 tests collected (2 deselected) in 0.1s ===")["collected"] == 3
    assert ms.parse_collect_output("1 test collected in 0.01s")["collected"] == 1
    assert ms.parse_collect_output("no tests collected in 0.00s")["collected"] == 0
    err = ms.parse_collect_output("120 tests collected, 2 errors in 1.5s")
    assert (err["collected"], err["errors"]) == (120, 2)
    assert ms.parse_collect_output("Traceback...\n") is None


def test_parse_junit_sums_suites_and_derives_passed():
    xml = _t(
        """
        <?xml version="1.0" encoding="utf-8"?>
        <testsuites>
          <testsuite name="pytest" errors="1" failures="2" skipped="3" tests="20"/>
          <testsuite name="other" errors="0" failures="0" skipped="0" tests="5"/>
        </testsuites>
        """
    ).strip()
    got = ms.parse_junit(xml)
    assert got == {"collected": 25, "passed": 19, "failed": 2, "errors": 1, "skipped": 3}
    assert ms.parse_junit("<not xml") is None
    single = '<testsuite errors="0" failures="0" skipped="0" tests="4"/>'
    assert ms.parse_junit(single)["passed"] == 4


def test_extract_failure_excerpt_prefers_short_summary_lines():
    lines = ms.extract_failure_excerpt(SUMMARY_MIXED)
    assert lines[0].startswith("FAILED tests/test_x.py::test_b")
    assert len(lines) == 2


def test_classify_run_timeout_never_reports_counts():
    verdict = ms._classify_run(None, True, None, None, False, "....", 5.0)
    assert verdict["status"] == "timeout" and verdict["counts"] == {}
    assert "unknown" in verdict["reason"]


def test_classify_run_without_summary_is_unknown_not_zero():
    verdict = ms._classify_run(1, False, None, None, False, "Traceback", 5.0)
    assert verdict["status"] == "error" and verdict["counts"] == {}


def test_classify_run_junit_wins_and_flags_mismatch():
    junit = {"collected": 10, "passed": 8, "failed": 1, "errors": 0, "skipped": 1}
    summary = {"counts": {"passed": 7, "failed": 1, "skipped": 1}, "line": "x", "duration_s": 1.0}
    verdict = ms._classify_run(1, False, summary, junit, False, "", 5.0)
    assert verdict["counts"]["passed"] == 8 and verdict["counts_source"] == "junit"
    assert verdict["status"] == "failed" and "disagree" in verdict["reason"]


def test_to_wsl_path():
    assert ms.to_wsl_path("C:\\Github\\repo") == "/mnt/c/Github/repo"
    assert ms.to_wsl_path("d:/data") == "/mnt/d/data"
    assert ms.to_wsl_path("\\\\wsl$\\Ubuntu\\root\\epm") == "/root/epm"
    assert ms.to_wsl_path("\\\\wsl.localhost\\Ubuntu\\root\\epm") == "/root/epm"
    assert ms.to_wsl_path("/root/epm") == "/root/epm"
    spec = ms.WslSpec.parse("Ubuntu:root")
    assert (spec.distro, spec.user) == ("Ubuntu", "root")
    argv = spec.argv("C:\\x", "echo hi")
    assert argv[:5] == ["wsl.exe", "-d", "Ubuntu", "-u", "root"] and "/mnt/c/x" in argv


def test_parse_test_specs_names_bare_commands():
    assert ms.parse_test_specs(["unit=pytest tests/unit -q", "pytest x"]) == [
        ("unit", "pytest tests/unit -q"),
        ("tests2", "pytest x"),
    ]


# ---------------------------------------------------------------------------
# running commands (real subprocesses, local only)
# ---------------------------------------------------------------------------


@pytest.fixture
def mini_project(tmp_path):
    _write(
        tmp_path / "tests" / "test_mini.py",
        _t(
            """
            import pytest

            def test_ok_1(): pass
            def test_ok_2(): pass
            def test_bad(): assert 1 == 2

            @pytest.mark.skip(reason="demo")
            def test_skipped(): pass

            @pytest.mark.parametrize("n", [1, 2, 3])
            def test_param(n): pass
            """
        ),
    )
    return tmp_path


def _run(project: Path, command: str, **kw):
    kw.setdefault("collect_only", False)
    kw.setdefault("timeout", 120.0)
    return ms.run_test_spec("mini", command, cwd=project, wsl=None, revision="WORKTREE", **kw)


def test_run_test_spec_counts_pass_fail_skip_via_junit(mini_project):
    cmd = f'"{sys.executable}" -m pytest tests -q'
    rec = _run(mini_project, cmd)
    assert rec["status"] == "failed" and rec["counts_source"] == "junit"
    assert rec["counts"]["collected"] == 7
    assert (rec["counts"]["passed"], rec["counts"]["failed"], rec["counts"]["skipped"]) == (5, 1, 1)
    assert rec["exit_code"] == 1 and not rec["timed_out"]
    assert any("test_bad" in ln for ln in rec["failure_excerpt"])
    assert not (mini_project / ".pytest_cache").exists()  # cache provider disabled


def test_run_test_spec_collect_only_executes_nothing(mini_project):
    marker = mini_project / "ran.txt"
    _write(mini_project / "tests" / "test_side_effect.py", f"open({str(marker)!r}, 'w').close()\n")
    cmd = f'"{sys.executable}" -m pytest tests -q'
    rec = _run(mini_project, cmd, collect_only=True)
    assert rec["mode"] == "collect-only" and rec["counts_source"] == "collect-only"
    assert rec["counts"]["collected"] == 7 and "passed" not in rec["counts"]
    assert rec["status"] in ("ok", "collection_error")


def test_run_test_spec_timeout_reports_unknown(tmp_path):
    cmd = f'"{sys.executable}" -c "import time; time.sleep(60)"'
    rec = _run(tmp_path, cmd, timeout=1.0)
    assert rec["status"] == "timeout" and rec["timed_out"] and rec["counts"] == {}
    assert rec["duration_s"] < 30


def test_run_test_spec_non_pytest_command_is_error_not_pass(tmp_path):
    rec = _run(tmp_path, f'"{sys.executable}" -c "import sys; sys.exit(3)"')
    assert rec["status"] == "error" and rec["counts"] == {}
    assert rec["exit_code"] == 3


def test_run_test_spec_exports_root_variable(tmp_path):
    rec = _run(tmp_path, f'"{sys.executable}" -c "import os; print(os.environ[\'MIGRATION_STATUS_ROOT\'])"')
    assert str(tmp_path) in "\n".join(rec["output_tail"])


# ---------------------------------------------------------------------------
# rendering
# ---------------------------------------------------------------------------


def _snapshot(root: Path, label: str, role: str = "target", **kw):
    opts = ms.SideOptions(root=root, label=label, role=role, **kw)
    snap, _ = ms.build_snapshot(opts)
    return snap


def _fake_run(name, collected, passed, failed=0, skipped=0, mode="run", status="ok"):
    counts = {"collected": collected}
    if mode == "run":
        counts.update(passed=passed, failed=failed, skipped=skipped, errors=0)
    return {
        "name": name, "command": "pytest", "mode": mode, "cwd": ".", "wrapper": None,
        "revision": "WORKTREE", "measured_at": "2026-01-01T00:00:00+00:00", "timeout_s": 1,
        "exit_code": 0, "duration_s": 1.0, "timed_out": False, "status": status, "counts": counts,
        "counts_source": "junit", "summary_line": None, "reason": "", "failure_excerpt": [],
        "output_tail": [],
    }


def test_report_headline_ratio_map_and_caveats(tmp_path):
    src_root, tgt_root = tmp_path / "up", tmp_path / "port"
    _write(src_root / "Alpha.cc", "int a;\n" * 100)
    _write(src_root / "Orphan.cc", "int o;\n" * 100)
    _write(tgt_root / "alpha.py", "a = 1\n" * 50)
    map_file = _write(tmp_path / "MAP.md", MAP_SAMPLE)
    source = _snapshot(src_root, "UP", "source", per_file=True)
    target = _snapshot(
        tgt_root, "PORT", map_path=map_file, join_files=source["files"],
    )
    target["tests"] = {"runs": [_fake_run("unit", 10, 8, 1, 1), _fake_run("kern", 5, 0, mode="collect-only")]}
    source.pop("files")
    md = ms.render_report(source=source, target=target)
    assert "| Production LOC - code | 200 | 50 |" in md
    assert "0.25x" in md  # 50 / 200
    assert "| Tests passed | not measured | 8 |" in md
    assert "| Tests collected | not measured | 15 |" in md
    assert "88.88%" in md  # 8 / (8 + 1 + 0), floored
    assert "UNMAPPED" in md and "50.0%" in md  # Orphan.cc is half of upstream LOC
    assert "## Caveats" in md and "collected only (no execution)" in md
    assert "Source test results: not measured" in md


def test_report_marks_unknown_suites_as_partial_and_never_zero(tmp_path):
    _write(tmp_path / "a.py", "x = 1\n")
    snap = _snapshot(tmp_path, "T")
    timed_out = _fake_run("slow", 0, 0, status="timeout")
    timed_out["counts"] = {}
    timed_out["reason"] = "timed out after 1s before a final summary; no counts reported (pass count unknown)"
    snap["tests"] = {"runs": [_fake_run("fast", 4, 4), timed_out]}
    md = ms.render_report(target=snap)
    assert "| Tests passed | 4* |" in md
    assert "timed out after 1s" in md and "exclude suite `slow`" in md


def test_report_pair_with_deltas(tmp_path):
    root = tmp_path / "repo"
    _write(root / "a.py", "x = 1\n" * 10)
    before = _snapshot(root, "R")
    before["tests"] = {"runs": [_fake_run("unit", 10, 9, 1)]}
    _write(root / "b.py", "y = 2\n" * 5)
    after = _snapshot(root, "R")
    after["tests"] = {"runs": [_fake_run("unit", 12, 12)]}
    md = ms.render_report(before=before, after=after)
    assert "| Production LOC - code | 10 | 15 | +5 (+50.0%) |" in md
    assert "| Tests passed | 9 | 12 | +3 (+33.3%) |" in md
    assert "| Pass rate | 90.00% | 100.00% | +10.0 pp |" in md


def test_json_snapshot_is_versioned_and_stable(tmp_path):
    _write(tmp_path / "a.py", "x = 1\n")
    out1, out2 = tmp_path / "s1.json", tmp_path / "s2.json"
    for out in (out1, out2):
        assert ms.main(["snapshot", "--root", str(tmp_path), "--exclude", "*.json", "--out", str(out)]) == 0
    one, two = json.loads(out1.read_text()), json.loads(out2.read_text())
    assert one["schema_version"] == ms.SCHEMA_VERSION == 1
    for snap in (one, two):
        snap.pop("generated_at")
    assert one == two
    assert {"loc", "languages", "symbols", "scope", "tests", "migration_map", "label"} <= set(one)
    out_md = tmp_path / "r.md"
    assert ms.main(["report", "--snapshot", str(out1), "--out", str(out_md)]) == 0
    assert "## Headline" in out_md.read_text(encoding="utf-8")


def test_report_rejects_unknown_schema_version(tmp_path):
    bad = tmp_path / "bad.json"
    bad.write_text(json.dumps({"schema_version": 99}))
    with pytest.raises(SystemExit):
        ms.main(["report", "--snapshot", str(bad)])


# ---------------------------------------------------------------------------
# baseline revision (temporary git repository, two commits)
# ---------------------------------------------------------------------------

needs_git = pytest.mark.skipif(shutil.which("git") is None, reason="git not installed")


def _git(repo: Path, *args: str, date: str | None = None) -> str:
    env = {
        "GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@example.invalid",
        "GIT_COMMITTER_NAME": "t", "GIT_COMMITTER_EMAIL": "t@example.invalid",
        "GIT_CONFIG_GLOBAL": str(repo.parent / "gitconfig-empty"),
        "GIT_CONFIG_SYSTEM": str(repo.parent / "gitconfig-empty"),
    }
    if date:
        env.update(GIT_AUTHOR_DATE=date, GIT_COMMITTER_DATE=date)
    proc = subprocess.run(["git", "-C", str(repo), *args], capture_output=True, text=True,
                          env={**os.environ, **env})
    assert proc.returncode == 0, proc.stderr
    return proc.stdout


@pytest.fixture
def two_commit_repo(tmp_path):
    repo = tmp_path / "port"
    repo.mkdir()
    _git(repo, "init", "-q")
    _write(repo / "src" / "a.py", "def a():\n    return 1\n")
    _write(repo / "tests" / "test_a.py", "def test_a():\n    assert True\n")
    _write(repo / "MIGRATION_MAP.md", "| Upstream File | Status |\n|---|---|\n| `Alpha.cc` | PARTIAL |\n")
    _git(repo, "add", "-A")
    _git(repo, "commit", "-q", "-m", "first", date="2020-01-01T12:00:00+00:00")
    first = _git(repo, "rev-parse", "HEAD").strip()
    _write(repo / "src" / "b.py", "def b():\n    return 2\n\ndef c():\n    return 3\n")
    _write(repo / "MIGRATION_MAP.md", "| Upstream File | Status |\n|---|---|\n| `Alpha.cc` | COMPLETE |\n")
    _git(repo, "add", "-A")
    _git(repo, "commit", "-q", "-m", "second", date="2021-01-01T12:00:00+00:00")
    return repo, first


def _leftover_exports() -> set[str]:
    return {p.name for p in Path(tempfile.gettempdir()).glob("migration_status_rev_*")}


@needs_git
def test_snapshot_at_revision_reads_old_tree_and_cleans_up(two_commit_repo):
    repo, first = two_commit_repo
    before_dirs = _leftover_exports()
    # leave an untracked, uncommitted file: it must not leak into the revision snapshot
    _write(repo / "src" / "untracked.py", "z = 1\n" * 40)
    opts = ms.SideOptions(root=repo, label="port", includes=["src", "tests"])
    old, _ = ms.build_snapshot(opts, rev=first)
    new, _ = ms.build_snapshot(opts)
    assert old["revision"] == first[:12] and old["git"]["commit"] == first
    assert old["loc"]["production"]["files"] == 1 and old["loc"]["production"]["code"] == 2
    assert new["loc"]["production"]["files"] == 3  # a, b, untracked
    assert old["migration_map"]["status_counts"]["PARTIAL"] == 1
    assert new["migration_map"]["status_counts"]["COMPLETE"] == 1
    assert _leftover_exports() == before_dirs
    # the real worktree was not touched: only the untracked file we made is reported
    assert _git(repo, "status", "--porcelain").split() == ["??", "src/untracked.py"]


@needs_git
def test_compare_with_baseline_rev_end_to_end(two_commit_repo, tmp_path):
    repo, first = two_commit_repo
    upstream = tmp_path / "upstream"
    _write(upstream / "Alpha.cc", "int a;\n" * 10)
    out = tmp_path / "report.md"
    save = tmp_path / "snaps"
    code = ms.main([
        "compare", "--source", str(upstream), "--target", str(repo), "--baseline-rev", first,
        "--target-include", "src", "--target-include", "tests",
        "--target-tests", f'unit="{sys.executable}" -c "print(1)"', "--save-snapshots", str(save),
        "--out", str(out),
    ])
    assert code == 0
    md = out.read_text(encoding="utf-8")
    assert "## Progress vs baseline" in md
    assert "| Production LOC - code | 10 |" in md
    # target now has a.py + b.py (2 files, 6 code lines); baseline had a.py only (2 code lines)
    assert "+4 (+200.0%)" in md  # code lines: 2 -> 6
    assert "+1 (+100.0%)" in md  # files: 1 -> 2
    assert "Baseline revision: static metrics only" in md
    assert "Test commands were NOT run at this revision" in md
    assert "% upstream LOC" in md  # map status moved PARTIAL -> COMPLETE with a join
    snaps = {p.name for p in save.iterdir()}
    assert snaps == {"source.json", "target.json", "target_baseline.json"}
    baseline = json.loads((save / "target_baseline.json").read_text())
    assert baseline["tests"]["runs"] == []


@needs_git
def test_baseline_before_date_selects_older_commit(two_commit_repo):
    repo, first = two_commit_repo
    head = _git(repo, "rev-parse", "HEAD").strip()
    assert ms.rev_before(repo, "2020-06-01") == first
    assert ms.rev_before(repo, "2022-01-01") == head
    with pytest.raises(RuntimeError):
        ms.rev_before(repo, "2019-01-01")


@needs_git
def test_export_revision_honours_root_relative_includes(two_commit_repo, tmp_path):
    repo, first = two_commit_repo
    dest = tmp_path / "export"
    dest.mkdir()
    written = ms.export_revision(repo, first, dest, ["src"], [], extra=["MIGRATION_MAP.md"])
    assert written == 2  # src/a.py and the map; not third_party/lib/src/z.py
    assert (dest / "MIGRATION_MAP.md").is_file() and not (dest / "src" / "b.py").exists()
    assert not (dest / "third_party").exists() and not (dest / "tests").exists()
