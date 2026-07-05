"""C++ frontend tests. Validates the third source language flows through the
shared MIR pipeline. Initial C++ subset is deliberately C-like (no classes,
templates, references, namespaces) — those are real C++ features the IR
doesn't model yet."""

from __future__ import annotations

import shutil
import textwrap

import pytest

from transpilers.cli.main import (
    transpile_cpp_to_c,
    transpile_cpp_to_mojo,
    transpile_cpp_to_rust,
    transpile_cpp_to_zig,
)
from transpilers.verify import c_compiles, mojo_compiles, rust_compiles, zig_compiles


def _rust(src: str) -> str:
    return transpile_cpp_to_rust(textwrap.dedent(src).lstrip())


def _zig(src: str) -> str:
    return transpile_cpp_to_zig(textwrap.dedent(src).lstrip())


def _c(src: str) -> str:
    return transpile_cpp_to_c(textwrap.dedent(src).lstrip())


def _mojo(src: str) -> str:
    return transpile_cpp_to_mojo(textwrap.dedent(src).lstrip())


def _has(name: str) -> bool:
    return shutil.which(name) is not None


# ---------- shape ----------

def test_cpp_add_to_rust():
    out = _rust("int add(int a, int b) { return a + b; }")
    assert "fn add(a: i64, b: i64) -> i64" in out


def test_cpp_to_mojo_shape():
    out = _mojo("int add(int a, int b) { return a + b; }")
    assert "def add(a: Int, b: Int) -> Int:" in out
    assert "return a + b" in out


def test_cpp_enum_inlines_to_int_constants():
    # `enum {...}` was previously refused (top-level ENUM_DECL). Each
    # enumerator now becomes a module-level int constant that inlines at use
    # sites, so the construct flows through to every backend.
    src = """
        enum SurfaceClass { Wall = 0, Floor = 1, Roof = 2 };

        int classify(int x) {
            if (x == Wall) return 100;
            if (x == Roof) return 300;
            return 0;
        }
    """
    out = _mojo(src)
    assert "def classify(x: Int) -> Int:" in out
    assert "if x == 0:" in out      # Wall -> 0, inlined
    assert "if x == 2:" in out      # Roof -> 2, inlined
    # same C++ enum flows to other targets from one HIR
    assert "fn classify(x: i64) -> i64" in _rust(src)


def test_cpp_namespace_flattens_to_module_scope():
    # `namespace foo { ... }` members used to be skipped wholesale; they now
    # flatten to module scope and emit.
    out = _mojo(
        """
        namespace hb {
        int classify(int x) { return x + 1; }
        }
        """
    )
    assert "def classify(x: Int) -> Int:" in out


def test_cpp_typedef_and_using_resolve():
    out = _mojo(
        """
        typedef double Real64;
        using Int32 = int;
        Real64 add(Real64 a, Real64 b) { return a + b; }
        Int32 doubled(Int32 n) { return n * 2; }
        """
    )
    assert "def add(a: Float64, b: Float64) -> Float64:" in out
    assert "def doubled(n: Int) -> Int:" in out


def test_cpp_constructor_to_init():
    out = _mojo(
        """
        struct Vec2 {
            double x;
            double y;
            Vec2(double a, double b) : x(a), y(b) {}
            double norm2() const { return x*x + y*y; }
        };
        """
    )
    assert "def __init__(out self, a: Float64, b: Float64):" in out
    assert "self.x = a" in out
    assert "self.y = b" in out
    # explicit constructor replaces the synthesized fieldwise one
    assert "@fieldwise_init" not in out


def test_cpp_bool_handled():
    out = _rust("bool is_positive(int x) { return x > 0; }")
    assert "fn is_positive(x: i64) -> bool" in out


def test_cpp_for_loop_desugars():
    out = _rust(
        """
        int sum_to(int n) {
            int total = 0;
            for (int i = 0; i < n; i++) {
                total = total + i;
            }
            return total;
        }
        """
    )
    assert "while i < n {" in out
    assert "i += 1;" in out


def test_cpp_std_list_range_for_to_mojo():
    # std::list<T> is a plain opaque shim in the parser preamble (unlike
    # std::vector<T>, which has a full iterator surface) -- so a real-world
    # function range-iterating a std::list (found testing against
    # github.com/wassimj/Topologic) previously failed to even parse with
    # "invalid range expression ... no viable 'begin' function available".
    out = _mojo(
        """
        int sum(const std::list<int>& xs) {
            int total = 0;
            for (const int x : xs) { total = total + x; }
            return total;
        }
        """
    )
    assert "def sum(xs: List[Int]) -> Int:" in out


def test_cpp_std_string_from_char_literal():
    # `std::string("literal")` (a functional-style cast, the common way to
    # construct a std::string from a string literal) previously failed to
    # parse: the preamble's std::string shim declared only a default
    # constructor, so libclang rejected the conversion.
    out = _mojo('std::string greet() { return std::string("hi"); }')
    assert 'return "hi"' in out


def test_cpp_logical_ops_to_mojo():
    out = _mojo("bool both(bool a, bool b) { return a && b; }")
    assert "return a and b" in out


def test_cpp_long_collapses_to_int():
    out = _rust("long sum(long a, long b) { return a + b; }")
    assert "fn sum(a: i64, b: i64) -> i64" in out


def test_cpp_operator_overloads_become_dunders():
    # Member `operator+` / `operator==` / `operator<` rename to the matching
    # Python/Mojo dunder; the backends already emit these as ordinary methods.
    src = """
        struct Vec {
            int x;
            int y;
            Vec(int a, int b) : x(a), y(b) {}
            Vec operator+(Vec o) const { return Vec(x + o.x, y + o.y); }
            bool operator==(Vec o) const { return x == o.x && y == o.y; }
            bool operator<(Vec o) const { return x < o.x; }
        };
    """
    out = _mojo(src)
    assert "def __add__(self, o: Vec) -> Vec:" in out
    assert "def __eq__(self, o: Vec) -> Bool:" in out
    assert "def __lt__(self, o: Vec) -> Bool:" in out
    # same rename flows to other targets from one HIR
    rust = _rust(src)
    assert "fn __add__(&self, o: Vec) -> Vec" in rust


def test_cpp_call_operator_becomes_dunder_call():
    # `operator()` (functor call operator, e.g. a std::sort comparator) was
    # missing from the operator->dunder table, so it fell through to the raw
    # spelling `operator()` -- not a valid Mojo/Python identifier, breaking
    # the emitted struct.
    src = """
        struct Comparator {
            bool operator()(int a, int b) const { return a < b; }
        };
    """
    out = _mojo(src)
    assert "def __call__(self, a: Int, b: Int) -> Bool:" in out
    assert "operator()" not in out


def test_cpp_auto_var_type_inferred():
    # `auto x = expr;` carries no forced annotation, so the IR's own type
    # inference recovers x's type from the RHS: int from int+int, float from
    # the float mix.
    out = _mojo(
        """
        int compute(int a, int b) {
            auto s = a + b;
            auto f = a + 1.5;
            return s;
        }
        """
    )
    assert "var s: Int = a + b" in out
    assert "var f: Float64 = a + 1.5" in out


# ---------- C++ → Mojo compile checks ----------

@pytest.mark.skipif(not _has("mojo"), reason="mojo not installed")
@pytest.mark.parametrize(
    "src",
    [
        "int add(int a, int b) { return a + b; }",
        """
        int max2(int a, int b) {
            if (a > b) return a;
            else return b;
        }
        """,
        """
        int factorial(int n) {
            int result = 1;
            int i = 1;
            while (i <= n) {
                result = result * i;
                i = i + 1;
            }
            return result;
        }
        """,
        """
        int sum_to(int n) {
            int total = 0;
            for (int i = 0; i < n; i++) {
                total = total + i;
            }
            return total;
        }
        """,
        """
        bool in_range(int x, int lo, int hi) {
            return x >= lo && x <= hi;
        }
        """,
    ],
)
def test_cpp_to_mojo_compiles(src: str):
    out = _mojo(src)
    result = mojo_compiles(out)
    assert result.ok, f"mojo rejected:\n{out}\n\nstderr:\n{result.stderr}"


# ---------- C++ → Rust compile check ----------

@pytest.mark.skipif(not _has("rustc"), reason="rustc not installed")
def test_cpp_to_rust_compiles():
    out = _rust(
        """
        int factorial(int n) {
            int result = 1;
            int i = 1;
            while (i <= n) {
                result = result * i;
                i = i + 1;
            }
            return result;
        }
        """
    )
    result = rust_compiles(out)
    assert result.ok, result.stderr


# ---------- C++ → Zig compile check ----------

@pytest.mark.skipif(not _has("zig"), reason="zig not installed")
def test_cpp_to_zig_compiles():
    out = _zig("int add(int a, int b) { return a + b; }")
    result = zig_compiles(out)
    assert result.ok, result.stderr


# ---------- C++ → C compile check ----------

@pytest.mark.skipif(not _has("cc") and not _has("gcc") and not _has("clang"), reason="no C compiler")
def test_cpp_to_c_compiles():
    """C++ -> C via the shared MIR — the IR is language-agnostic enough that
    this works for the C-compatible subset."""
    out = _c("int add(int a, int b) { return a + b; }")
    assert "int64_t add(int64_t a, int64_t b)" in out
    result = c_compiles(out)
    assert result.ok, result.stderr


# ---------- classes ----------

def test_cpp_class_to_rust_struct_impl():
    out = _rust(
        """
        class Point {
        public:
            int x;
            int y;

            int sum() {
                return this->x + this->y;
            }
        };
        """
    )
    assert "struct Point {" in out
    assert "x: i64," in out
    assert "y: i64," in out
    assert "impl Point {" in out
    assert "fn sum(&self) -> i64" in out
    assert "self.x + self.y" in out


def test_cpp_class_to_mojo_struct():
    out = _mojo(
        """
        class Point {
        public:
            int x;
            int y;

            int sum() {
                return this->x + this->y;
            }
        };
        """
    )
    assert "@fieldwise_init" in out
    assert "struct Point(Copyable, Movable):" in out
    assert "var x: Int" in out
    assert "var y: Int" in out
    assert "def sum(self) -> Int:" in out


def test_cpp_unqualified_sibling_method_call_gets_self():
    # `cube()` calls `square(x)` with no `this->`/qualifier -- valid C++ via
    # implicit member lookup (works even for a *static* sibling method, as
    # here). Every backend's struct methods aren't free functions, so the
    # call must be qualified with `self.` or the emitted target can't reach
    # the method at all (Mojo: "cannot access method directly").
    src = """
        class MathUtil {
        public:
            static int square(int x) { return x * x; }
            static int cube(int x) { return x * square(x); }
        };
    """
    out = _mojo(src)
    assert "self.square(x)" in out
    rust = _rust(src)
    assert "self.square(x)" in rust


_CLASS_SRC = """
class Point {
public:
    int x;
    int y;
    int sum() { return this->x + this->y; }
};
"""


def _to(target: str) -> str:
    from transpilers.cli.main import transpile
    return transpile(textwrap.dedent(_CLASS_SRC).lstrip(), source_lang="cpp", target=target)


def test_cpp_class_to_c_struct():
    out = _to("c")
    assert "typedef struct {" in out
    assert "int64_t x;" in out
    assert "} Point;" in out
    assert "int64_t Point_sum(Point *self)" in out
    assert "self->x + self->y" in out


def test_cpp_class_to_zig_struct():
    out = _to("zig")
    assert "const Point = struct {" in out
    assert "x: i64," in out
    assert "fn sum(self: Point) i64" in out
    assert "self.x + self.y" in out


def test_cpp_class_to_go_struct():
    out = _to("go")
    assert "type Point struct {" in out
    assert "func (self *Point) sum() int64" in out
    assert "self.x + self.y" in out


def test_cpp_class_to_python_class():
    out = _to("python")
    assert "class Point:" in out
    assert "x: int" in out
    assert "def sum(self) -> int:" in out


def test_cpp_class_to_fortran_type():
    out = _to("fortran")
    assert "type :: Point" in out
    assert "integer :: x" in out
    assert "function Point_sum(self) result(result_)" in out
    assert "self%x + self%y" in out


@pytest.mark.skipif(not _has("rustc"), reason="rustc not installed")
def test_cpp_class_compiles_as_rust():
    out = _rust(
        """
        class Point {
        public:
            int x;
            int y;
            int sum() { return this->x + this->y; }
            int scale(int factor) { return this->x * factor + this->y * factor; }
        };
        """
    )
    result = rust_compiles(out)
    assert result.ok, result.stderr


# ---------- refusals ----------

def test_cpp_template_preserved_as_raw_hole():
    # Issue #50: templates are now preserved as HirRaw holes (with a
    # TODO[port] stub emitted by every backend), and the *signature*
    # is recorded in the ground truth so callers can pick up the
    # parameter / return types via the AST. We don't refuse the
    # construct outright anymore -- templates are real C++ and the
    # engine should emit *something* rather than aborting.
    out = _mojo("template<typename T> T add(T a, T b) { return a + b; }")
    # The mojo backend should emit a TODO stub for the function body.
    assert "TODO[port]" in out


def test_cpp_class_inheritance_refused():
    with pytest.raises(Exception):
        _rust("class Base { public: int x; }; class D : public Base { public: int y; };")
