"""Opt-in, source-aware prompt guidance for the per-file C++ -> Mojo driver.

Two families of C++ files defeat the generic prompt (issues #96 and #97):

* GoogleTest unit tests (``tst/EnergyPlus/*.unit.cc``), where ``TEST_F`` and
  ``EXPECT_*`` macros lead the model to drop the ``<<<FILE>>>`` block.
* Eigen-heavy code (``third_party/ssc``), where ``MatrixXd``/``.block()``
  idioms have a weak Eigen -> Mojo training signal.

A third domain targets the EnergyPlusMojo repository's kernel conventions
(bit-exact ``@export`` batch kernels checked against a g++ oracle); it is
selected by a ``.upstream.inc`` source path, the name EnergyPlusMojo's
``extract_fn.py`` gives verbatim upstream text.

``detect_domains`` inspects a source path and text; ``domain_guidance`` renders
the matching rules.  Nothing here runs unless the caller opts in.
"""

from __future__ import annotations

import re

GTEST = "gtest"
EIGEN = "eigen"
EPMOJO = "epmojo"

_GTEST_INCLUDE = re.compile(r'#\s*include\s*[<"]gtest/[^>"]+[>"]')
_GTEST_MACRO = re.compile(
    r"^\s*(?:TEST|TEST_F|TEST_P|TYPED_TEST)\s*\(\s*\w+\s*,\s*\w+\s*\)", re.MULTILINE
)
_EIGEN_INCLUDE = re.compile(r'#\s*include\s*[<"]Eigen/[^>"]+[>"]')
_EIGEN_TYPE = re.compile(r"\bEigen::\w+|\b(?:Matrix|Vector|Array)(?:X|[234])[dfi]\b")


def detect_domains(source_text: str, source_path: str = "") -> list[str]:
    """Return the domains (``gtest``, ``eigen``, ``epmojo``) evident in a source file."""
    domains: list[str] = []
    if _GTEST_INCLUDE.search(source_text) or _GTEST_MACRO.search(source_text):
        domains.append(GTEST)
    if _EIGEN_INCLUDE.search(source_text) or _EIGEN_TYPE.search(source_text):
        domains.append(EIGEN)
    # SSC is Eigen/SAM-idiom heavy even where a file has no direct Eigen use.
    norm = source_path.replace("\\", "/")
    if EIGEN not in domains and "third_party/ssc/" in norm:
        domains.append(EIGEN)
    if norm.endswith(".upstream.inc"):
        domains.append(EPMOJO)
    return domains


GTEST_GUIDANCE = """\
GOOGLETEST RULES (this file is a gtest unit test):
- The output is STILL exactly one <<<FILE ...>>> block. Never answer with prose
  or refuse because the file only contains tests.
- `TEST(Suite, Name) { ... }` -> `fn test_Suite_Name() raises:`
  `TEST_F(Fixture, Name)` -> `fn test_Fixture_Name() raises:` on a fresh
  `var fixture = Fixture()`; call `fixture.SetUp()` first and
  `fixture.TearDown()` last (use `try/finally` if the body can raise).
- Fixture classes (`class X : public testing::Test`) -> `struct X` with
  `fn SetUp(mut self)` and `fn TearDown(mut self)`; members become fields.
- `EXPECT_EQ(a, b)` / `ASSERT_EQ` -> `assert_equal(a, b)`;
  `EXPECT_NE` -> `assert_not_equal`; `EXPECT_TRUE(x)` -> `assert_true(x)`;
  `EXPECT_FALSE(x)` -> `assert_false(x)`;
  `EXPECT_NEAR(a, b, tol)` -> `assert_almost_equal(a, b, atol=tol)`;
  `EXPECT_DOUBLE_EQ` / `EXPECT_FLOAT_EQ` -> `assert_almost_equal` with a tight
  tolerance; `EXPECT_LT/LE/GT/GE(a, b)` -> `assert_true(a < b)` etc.
- `from testing import assert_equal, assert_true, assert_false,
  assert_not_equal, assert_almost_equal` for whatever the file uses.
- Streamed messages (`EXPECT_TRUE(x) << "msg"`) -> pass `msg="..."`.
- Every test function is preserved, in order, with its name unchanged after the
  `test_` prefix. Do not merge, skip or comment out tests.

WORKED EXAMPLE
C++:
    TEST_F(EnergyPlusFixture, Foo_Calc) {
        Real64 r = Foo::calc(2.0);
        EXPECT_NEAR(4.0, r, 0.001);
        ASSERT_TRUE(r > 0.0);
    }
Mojo:
    fn test_EnergyPlusFixture_Foo_Calc() raises:
        var fixture = EnergyPlusFixture()
        fixture.SetUp()
        var r: Float64 = calc(2.0)
        assert_almost_equal(4.0, r, atol=0.001)
        assert_true(r > 0.0)
        fixture.TearDown()
"""

_EIGEN_SEMANTICS = """\
- Eigen views vs copies: `m.block(...)`, `m.col(j)`, `m.row(i)`, `v.head(n)`,
  `v.segment(i, n)`, `m.diagonal()` and `Eigen::Map<...>` are WRITABLE VIEWS of
  the parent, not copies. When one is assigned to (`m.col(j) = v`,
  `m.block(i, j, r, c) += x`, `m.diagonal().setOnes()`), write the elements
  into the parent matrix. A view bound with `auto`/`Block<...>` that is later
  assigned through must also write through. Only read-only uses may copy.
- Aliasing: Eigen evaluates a matrix product into a temporary before
  assigning, so `a = b * a` reads the OLD `a` throughout. Compute the whole
  product into a fresh matrix, then assign. The same applies after `.eval()`.
- Comma initialiser `m << a, b, c, d;` fills row by row (row-major reading
  order) into `m`'s existing size; `Matrix<double, 3, 3>` fixed sizes are the
  same as dynamic ones with that size.
- Reductions: `.sum()`, `.prod()`, `.maxCoeff()`, `.minCoeff()`,
  `.squaredNorm()`, `.cwiseAbs()`, `.array() * x`, `.array().abs()` are
  element-wise; translate to explicit loops or helpers, keeping the
  accumulation order of a left-to-right loop.
"""

_SAM_RULES = """\
- SAM idioms: keep `sscapi_t`, `ssc_data_t`, `cmod_*` compute-module classes and
  `var_info` tables with the same names and field order. A `compute()`
  function is translated in place; `ssc_module_exec`-style calls stay calls.
- TCS (`tcstype`) state machines: keep the `init` / `call` / `converged`
  callbacks as separate methods and preserve the `switch (ncall)` / mode
  branches and parameter/input/output index enums verbatim.
"""

EIGEN_GUIDANCE = """\
EIGEN / SAM RULES (this file uses Eigen or System Advisor Model idioms):
- Output is exactly one <<<FILE ...>>> block. Do not drop an operation because
  it looks like linear algebra; translate it or keep a named helper call.
- Eigen -> Mojo table (use `Matrix`/`Vector` helpers with row-major
  `List[Float64]` storage; declare any helper you need in the same file):
    MatrixXd(r, c) / VectorXd(n)   -> Matrix(r, c) / Vector(n), zero-filled
    m(i, j), v(i)                   -> m[i, j], v[i]  (0-based, as in C++)
    m.rows() / m.cols() / v.size()  -> m.rows / m.cols / v.size
    m.setZero() / setIdentity()     -> m.set_zero() / m.set_identity()
    m.transpose()                   -> m.transpose()
    a * b (matrix product)          -> matmul(a, b)
    a.cwiseProduct(b)               -> elementwise_mul(a, b)
    m.block(i, j, r, c) (read)      -> m.block(i, j, r, c)  (copy is fine)
    m.block(i, j, r, c) = x (write) -> m.set_block(i, j, x)
    m.col(j) / m.row(i) (read)      -> m.col(j) / m.row(i)
    m.col(j) = v / m.row(i) = v     -> m.set_col(j, v) / m.set_row(i, v)
    v.dot(w) / v.norm()             -> dot(v, w) / norm(v)
    A.llt().solve(b)                -> cholesky_solve(A, b)
    A.lu().solve(b) / A.inverse()   -> lu_solve(A, b) / inverse(A)
- Keep the order of floating-point operations exactly as written.
""" + _EIGEN_SEMANTICS + _SAM_RULES + """
WORKED EXAMPLE
C++:
    MatrixXd A(3, 3);
    A.setZero();
    A.col(1) = VectorXd::Ones(3);
    A.block(0, 0, 2, 2) += B;
    VectorXd x = A.lu().solve(b);
Mojo:
    var A = Matrix(3, 3)
    A.set_zero()
    A.set_col(1, ones(3))
    A.set_block(0, 0, A.block(0, 0, 2, 2) + B)
    var x = lu_solve(A, b)
"""

EIGEN_DUAL_GUIDANCE = """\
EIGEN / SAM RULES (this file uses Eigen or System Advisor Model idioms):
- Output is both <<<FILE ...>>> blocks (Python and Mojo), complete. Do not
  drop an operation because it looks like linear algebra; translate it or keep
  a named helper call.
- Eigen -> Python (numpy, 0-based like C++; `import numpy as np`):
    MatrixXd(r, c) / VectorXd(n)   -> np.zeros((r, c)) / np.zeros(n)
    m(i, j), v(i)                   -> m[i, j], v[i]
    m.rows() / m.cols() / v.size()  -> m.shape[0] / m.shape[1] / v.size
    m.setZero() / setIdentity()     -> m[:] = 0.0 / m[:] = np.eye(*m.shape)
    m.transpose()                   -> m.T
    a * b (matrix product)          -> a @ b
    a.cwiseProduct(b)               -> a * b
    m.block(i, j, r, c)             -> m[i:i + r, j:j + c]  (a numpy view: assign
                                       through it to write the parent)
    m.col(j) / m.row(i)             -> m[:, j] / m[i, :]
    v.dot(w) / v.norm()             -> np.dot(v, w) / np.linalg.norm(v)
    A.llt().solve(b)                -> np.linalg.solve(A, b)
    A.lu().solve(b) / A.inverse()   -> np.linalg.solve(A, b) / np.linalg.inv(A)
- Eigen -> Mojo table (use `Matrix`/`Vector` helpers with row-major
  `List[Float64]` storage; declare any helper you need in the same file):
    MatrixXd(r, c) / VectorXd(n)   -> Matrix(r, c) / Vector(n), zero-filled
    m(i, j), v(i)                   -> m[i, j], v[i]  (0-based, as in C++)
    m.rows() / m.cols() / v.size()  -> m.rows / m.cols / v.size
    m.setZero() / setIdentity()     -> m.set_zero() / m.set_identity()
    m.transpose()                   -> m.transpose()
    a * b (matrix product)          -> matmul(a, b)
    a.cwiseProduct(b)               -> elementwise_mul(a, b)
    m.block(i, j, r, c) (read)      -> m.block(i, j, r, c)  (copy is fine)
    m.block(i, j, r, c) = x (write) -> m.set_block(i, j, x)
    m.col(j) / m.row(i) (read)      -> m.col(j) / m.row(i)
    m.col(j) = v / m.row(i) = v     -> m.set_col(j, v) / m.set_row(i, v)
    v.dot(w) / v.norm()             -> dot(v, w) / norm(v)
    A.llt().solve(b)                -> cholesky_solve(A, b)
    A.lu().solve(b) / A.inverse()   -> lu_solve(A, b) / inverse(A)
- Keep the order of floating-point operations exactly as written in scalar
  code. Solves and products may use the library routine above.
""" + _EIGEN_SEMANTICS + _SAM_RULES + """
WORKED EXAMPLE
C++:
    MatrixXd A(3, 3);
    A.setZero();
    A.col(1) = VectorXd::Ones(3);
    A.block(0, 0, 2, 2) += B;
    VectorXd x = A.lu().solve(b);
Python:
    A = np.zeros((3, 3))
    A[:, 1] = np.ones(3)
    A[0:2, 0:2] += B
    x = np.linalg.solve(A, b)
Mojo:
    var A = Matrix(3, 3)
    A.set_zero()
    A.set_col(1, ones(3))
    A.set_block(0, 0, A.block(0, 0, 2, 2) + B)
    var x = lu_solve(A, b)
"""

EPMOJO_GUIDANCE = """\
ENERGYPLUSMOJO KERNEL RULES (this text is verbatim upstream EnergyPlus for a
kernel in the EnergyPlusMojo repository). Where these rules differ from the
generic rules above, these win.
- Output is exactly one <<<FILE ...>>> block: the kernel `src/kernels/<name>.mojo`.
  Write Mojo 1.0 syntax: `def` (not `fn`), `comptime` constants (not `alias`),
  stdlib imports as `from std.math import ...` / `from std.ffi import
  external_call`, and sibling modules by plain name (`from fp_strict import
  nc_mul`). Do NOT use the quoted-path import form `from "X" import` shown above.
- Port only the maths. If the routine reads `state.data*` values, take them as
  explicit Float64/Int arguments and edit only those accesses; a `ShowWarning*` /
  `ShowFatal*` call becomes a returned sentinel value. List every such edit in a
  comment above the function. Write no Python or NumPy twin and no extra files.
- Entry point: one `@export def <name>_batch(n: Int, <in>_ptr: Int, ...,
  out_ptr: Int) -> None`. Each `_ptr` is the integer address of a contiguous
  Float64[n] array (an array column of k values per row is ONE pointer to n*k
  row-major doubles, element j of row i at `v[k*i + j]`). Open each with
  `UnsafePointer[Float64, MutAnyOrigin](unsafe_from_address=ptr)`, loop `i` over
  `range(n)`, call the translated function and write `out[i]`. Keep the maths in
  ordinary helper functions that the batch entry calls.
- The kernel must match upstream compiled with g++ -ffp-contract=off BIT FOR BIT:
  * Mojo fuses `a*b + c` into a fused multiply-add; upstream does not. Wrap the
    product in `nc_mul` (`from fp_strict import nc_mul`) in every `a*b + c`,
    `c - a*b`, `a*b - c` and `acc += a*b`, e.g. `nc_mul(a, b) + c`. `a*b*c`,
    `a/b + c` and `a*(b+c)` need no guard. A `var` temporary, parentheses or an
    `@always_inline` helper do NOT prevent fusion. A helper whose result callers
    add to (ObjexxFCL `pow_2`, `pow_6`) must itself end with `return nc_mul(t, t)`.
  * Keep the C++ evaluation order and grouping and every literal exactly.
    ObjexxFCL `pow_2(x)` is `x*x`, `pow_3(x)` is `(x*x)*x`; never `x ** n`.
  * Call libm `pow`, `exp`, `log`, `sin`, `cos` through `external_call`, e.g.
    `external_call["pow", Float64, Float64, Float64](x, y)`; the `std.math`
    versions differ from glibc by up to about 1e-10 relative.
  * Absolute value: built-in `abs(x)` or `ep_abs(x)`; never `-x if x < 0.0 else x`
    (it keeps the sign of -0.0 and -NaN).
  * min/max: never the built-in `min`/`max` (they differ for NaN). Read how
    upstream spells it: an UNQUALIFIED `min(a, b)` / `max(a, b)` is ObjexxFCL's,
    so use `objexx_min` / `objexx_max`; `std::min` is `ep_min` and `std::max` is
    `ep_max`. All four come from `fp_strict`.

WORKED EXAMPLE
C++ (upstream, verbatim):
    Real64 CalcFoo(Real64 const dT, Real64 const L)
    {
        Real64 h = 1.23 * (dT * dT) + std::pow(L, 0.25);
        return std::max(h, 0.1);
    }
Mojo:
    from std.ffi import external_call
    from fp_strict import nc_mul, ep_max


    @always_inline
    def CalcFoo(dT: Float64, L: Float64) -> Float64:
        var h = nc_mul(1.23, dT * dT) + external_call["pow", Float64, Float64, Float64](L, 0.25)
        return ep_max(h, 0.1)


    @export
    def CalcFoo_batch(n: Int, dT_ptr: Int, L_ptr: Int, out_ptr: Int) -> None:
        var dT = UnsafePointer[Float64, MutAnyOrigin](unsafe_from_address=dT_ptr)
        var L = UnsafePointer[Float64, MutAnyOrigin](unsafe_from_address=L_ptr)
        var out = UnsafePointer[Float64, MutAnyOrigin](unsafe_from_address=out_ptr)
        for i in range(n):
            out[i] = CalcFoo(dT[i], L[i])
"""

GTEST_DUAL_GUIDANCE = """\
GOOGLETEST RULES (this file is a gtest unit test; it overrides "do not write
tests" above: the tests ARE the source, so port every one of them):
- Still emit BOTH <<<FILE ...>>> blocks (Python and Mojo), complete. Never
  answer with prose or refuse because the file only contains tests.
- Every `TEST(Suite, Name)` / `TEST_F(Fixture, Name)` / `TEST_P` body is ported,
  in order, with its name kept. Do not merge, skip or comment out tests.
- Fixture classes (`class X : public testing::Test`) -> a class/struct `X` with
  `SetUp` and `TearDown` methods; members become fields. A `TEST_F` body builds
  a fresh fixture, calls `SetUp()` first and `TearDown()` last (`try/finally`
  if the body can raise).
- Python: `def test_Suite_Name():` with plain `assert` statements.
    EXPECT_EQ/ASSERT_EQ(a, b)   -> assert a == b
    EXPECT_NE(a, b)             -> assert a != b
    EXPECT_TRUE(x) / FALSE(x)   -> assert x / assert not x
    EXPECT_NEAR(a, b, tol)      -> assert abs(a - b) <= tol
    EXPECT_DOUBLE_EQ/FLOAT_EQ   -> assert a == pytest.approx(b, rel=1e-12)
    EXPECT_LT/LE/GT/GE(a, b)    -> assert a < b  (etc.)
- Mojo: `fn test_Suite_Name() raises:` using `from testing import
  assert_equal, assert_not_equal, assert_true, assert_false,
  assert_almost_equal` (`EXPECT_NEAR(a, b, tol)` -> `assert_almost_equal(a, b,
  atol=tol)`; comparisons -> `assert_true(a < b)`).
- Streamed messages (`EXPECT_TRUE(x) << "msg"`) -> keep `msg` as the assertion
  message in both ports.

WORKED EXAMPLE
C++:
    TEST_F(EnergyPlusFixture, Foo_Calc) {
        Real64 r = Foo::calc(2.0);
        EXPECT_NEAR(4.0, r, 0.001);
        ASSERT_TRUE(r > 0.0);
    }
Python:
    def test_EnergyPlusFixture_Foo_Calc():
        fixture = EnergyPlusFixture()
        fixture.SetUp()
        r = calc(2.0)
        assert abs(4.0 - r) <= 0.001
        assert r > 0.0
        fixture.TearDown()
Mojo:
    fn test_EnergyPlusFixture_Foo_Calc() raises:
        var fixture = EnergyPlusFixture()
        fixture.SetUp()
        var r: Float64 = calc(2.0)
        assert_almost_equal(4.0, r, atol=0.001)
        assert_true(r > 0.0)
        fixture.TearDown()
"""

_GUIDANCE = {GTEST: GTEST_GUIDANCE, EIGEN: EIGEN_GUIDANCE, EPMOJO: EPMOJO_GUIDANCE}
_DUAL_GUIDANCE = {GTEST: GTEST_DUAL_GUIDANCE, EIGEN: EIGEN_DUAL_GUIDANCE}
_OUTPUT_MARKERS = ("\nOUTPUT FORMAT:", "\n## Output format")


def domain_guidance(domains: list[str], dual_port: bool = False) -> str:
    """Render guidance for ``domains`` (empty string when none apply).

    ``dual_port`` selects the variant for drivers that ask for a Python and a
    Mojo file per source (the stateless runner) rather than Mojo alone. The
    ``epmojo`` domain has no dual-port variant (EnergyPlusMojo is Mojo only), so
    it adds nothing there.
    """
    parts = []
    for d in domains:
        text = (_DUAL_GUIDANCE if dual_port else _GUIDANCE).get(d)
        if text:
            parts.append(text)
    return "\n".join(parts)


def insert_guidance(prompt: str, guidance: str) -> str:
    """Insert ``guidance`` before the output-format section of ``prompt``.

    Appends it when no known output-format heading is present.
    """
    if not guidance:
        return prompt
    for marker in _OUTPUT_MARKERS:
        if marker in prompt:
            head, tail = prompt.split(marker, 1)
            return f"{head}\n{guidance}{marker}{tail}"
    return f"{prompt}\n\n{guidance}"


def apply_domain_guidance(
    prompt: str, source_text: str, source_path: str = "", dual_port: bool = False
) -> str:
    """Insert domain guidance before the OUTPUT FORMAT block of ``prompt``.

    Returns ``prompt`` unchanged when no domain is detected.
    """
    domains = detect_domains(source_text, source_path)
    return insert_guidance(prompt, domain_guidance(domains, dual_port))
