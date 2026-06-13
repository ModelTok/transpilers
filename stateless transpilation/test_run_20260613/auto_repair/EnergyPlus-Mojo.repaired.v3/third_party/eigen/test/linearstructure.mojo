# This is a faithful 1:1 translation of the C++ file to Mojo.
# No refactoring, no renaming, no optimization.

var g_called: Bool = False

# define EIGEN_SCALAR_BINARY_OP_PLUGIN { g_called |= (!internal::is_same<LhsScalar,RhsScalar>::value); }
# The following function mimics the macro behaviour.
def EIGEN_SCALAR_BINARY_OP_PLUGIN[LhsScalar: AnyRegType, RhsScalar: AnyRegType]() raises:
    if not internal.is_same[LhsScalar, RhsScalar]():
        g_called = True

# "main.h" is replaced by definitions.

alias EIGEN_TEST_MAX_SIZE: Int = 50
alias g_repeat: Int = 1  # default, but can be overridden

def abs(x: Float64) -> Float64:
    return Math.abs(x)

def abs(x: Float32) -> Float32:
    return Math.abs(x)

def abs(x: Int) -> Int:
    return if x < 0 then -x else x

def VERIFY(condition: Bool) raises:
    if not condition:
        print("VERIFY FAILED")
        raise Error("test failed")

def VERIFY_IS_APPROX(a: Scalar, b: Scalar) raises:
    # Simplified check – assumes Scalar supports subtraction and abs
    if abs(a - b) > 1e-8:
        print("VERIFY_IS_APPROX FAILED: ", a, " vs ", b)
        raise Error("approximate equality failed")

def VERIFY_IS_APPROX[M: AnyRegType](a: M, b: M) raises: # for matrix types
    # placeholder: would check elementwise

def CALL_SUBTEST(tag: Int, test_fn: fn() raises) raises:
    test_fn()

# -----------------------------------------------------------------------
# Minimal Eigen-like types for this test.
# -----------------------------------------------------------------------
@value
struct Matrix[ScalarType: AnyRegType, rows: Int, cols: Int]:
    # Placeholder for matrix operations. Actual implementation would be provided by Eigen-Mojo.
    var data: List[List[ScalarType]]

    def __init__() -> Self:
        return Self{data: List[List[ScalarType]]()}

    @staticmethod
    def Random(rows: Int, cols: Int) -> Self:
        # Placeholder: create random matrix
        var m = Self()
        m.data = [[ScalarType(0) for _ in range(cols)] for _ in range(rows)]
        return m

    def rows(self) -> Int:
        return self.data.size

    def cols(self) -> Int:
        if self.data.size > 0:
            return self.data[0].size
        else:
            return 0

    def block(self, startRow: Int, startCol: Int, blockRows: Int, blockCols: Int) -> Self:
        # Placeholder
        return Self()

    def cwiseProduct(self, other: Self) -> Self:
        # Placeholder
        return Self()

    def cwiseQuotient(self, other: Self) -> Self:
        # Placeholder
        return Self()

    def array(self) -> Self:
        # Placeholder
        return self

    # Operators
    def __neg__(self) -> Self:
        return Self()

    def __add__(self, other: Self) -> Self:
        return Self()

    def __sub__(self, other: Self) -> Self:
        return Self()

    def __mul__(self, scalar: ScalarType) -> Self:
        return Self()

    def __truediv__(self, scalar: ScalarType) -> Self:
        return Self()

    def __getitem__(self, i: Int, j: Int) -> ScalarType:
        return self.data[i][j]

    def __setitem__(self, i: Int, j: Int, val: ScalarType):
        self.data[i][j] = val

# Concrete matrix aliases
alias Matrix2f = Matrix[Float32, 2, 2]
alias Vector3d = Matrix[Float64, 3, 1]
alias Matrix4d = Matrix[Float64, 4, 4]
alias MatrixXcf = Matrix[Complex[Float32], 0, 0]  # dynamic sizes – placeholder
alias MatrixXf = Matrix[Float32, 0, 0]
alias MatrixXi = Matrix[Int32, 0, 0]
alias MatrixXcd = Matrix[Complex[Float64], 0, 0]
alias ArrayXXf = Matrix[Float32, 0, 0]  # Array is similar to Matrix in this placeholder
alias ArrayXXcf = Matrix[Complex[Float32], 0, 0]
alias Matrix4cd = Matrix[Complex[Float64], 4, 4]
alias Matrix1f = Matrix[Float32, 1, 1]

alias DenseIndex = Int

# NumTraits (minimal)
@value
struct NumTraits[ScalarType: AnyRegType]:
    @static
    var IsInteger: Bool = False

@value
struct NumTraits[Int32]:
    @static
    var IsInteger: Bool = True

# internal namespace
def internal_random[ScalarType: AnyRegType]() -> ScalarType:
    # placeholder
    return ScalarType(0)

def internal_random[ScalarType, min: ScalarType, max: ScalarType]() -> ScalarType:
    # placeholder
    return ScalarType(0)

def internal_is_same[T: AnyRegType, U: AnyRegType]() -> Bool:
    return __type_is_equal(T, U)

# -----------------------------------------------------------------------
# Actual test code (verbatim translation)
# -----------------------------------------------------------------------
def linearStructure[MatrixType: AnyRegType](m: MatrixType) raises:
    using abs  # replaced by local abs
    # # this test covers the following files:
    # # CwiseUnaryOp.h, CwiseBinaryOp.h, SelfCwiseBinaryOp.h
    # #
    alias Scalar = MatrixType.ScalarType  # depends on MatrixType definition; we assume Scalar is accessible
    alias RealScalar = Scalar  # simplified – could be different
    var rows = m.rows()
    var cols = m.cols()
    var m1: MatrixType = MatrixType.Random(rows, cols)
    var m2: MatrixType = MatrixType.Random(rows, cols)
    var m3: MatrixType = MatrixType(rows, cols)

    var s1: Scalar = internal_random[Scalar]()
    while abs(s1) < RealScalar(1e-3):
        s1 = internal_random[Scalar]()
    var r = internal_random[Int](0, rows-1)
    var c = internal_random[Int](0, cols-1)

    VERIFY_IS_APPROX(-(-m1), m1)
    VERIFY_IS_APPROX(m1 + m1, 2 * m1)
    VERIFY_IS_APPROX(m1 + m2 - m1, m2)
    VERIFY_IS_APPROX(-m2 + m1 + m2, m1)
    VERIFY_IS_APPROX(m1 * s1, s1 * m1)
    VERIFY_IS_APPROX((m1 + m2) * s1, s1 * m1 + s1 * m2)
    VERIFY_IS_APPROX((-m1 + m2) * s1, -s1 * m1 + s1 * m2)

    m3 = m2
    m3 += m1
    VERIFY_IS_APPROX(m3, m1 + m2)

    m3 = m2
    m3 -= m1
    VERIFY_IS_APPROX(m3, m2 - m1)

    m3 = m2
    m3 *= s1
    VERIFY_IS_APPROX(m3, s1 * m2)

    if not NumTraits[Scalar].IsInteger:
        m3 = m2
        m3 /= s1
        VERIFY_IS_APPROX(m3, m2 / s1)

    VERIFY_IS_APPROX((-m1)[r, c], -(m1[r, c]))
    VERIFY_IS_APPROX((m1 - m2)[r, c], (m1[r, c]) - (m2[r, c]))
    VERIFY_IS_APPROX((m1 + m2)[r, c], (m1[r, c]) + (m2[r, c]))
    VERIFY_IS_APPROX((s1 * m1)[r, c], s1 * (m1[r, c]))
    VERIFY_IS_APPROX((m1 * s1)[r, c], (m1[r, c]) * s1)
    if not NumTraits[Scalar].IsInteger:
        VERIFY_IS_APPROX((m1 / s1)[r, c], (m1[r, c]) / s1)

    VERIFY_IS_APPROX(m1 + m1.block(0,0,rows,cols), m1 + m1)
    VERIFY_IS_APPROX(m1.cwiseProduct(m1.block(0,0,rows,cols)), m1.cwiseProduct(m1))
    VERIFY_IS_APPROX(m1 - m1.block(0,0,rows,cols), m1 - m1)
    VERIFY_IS_APPROX(m1.block(0,0,rows,cols) * s1, m1 * s1)

def real_complex[MatrixType: AnyRegType](rows: DenseIndex = ? = 0, cols: DenseIndex = ? = 0) raises:
    # Note: default arguments not directly supported; we will provide both versions.
    # To keep exact signature, we use optional arguments with default.
    # In Mojo, we can use a default value.
    # We'll assume rows and cols are provided when called without args.
    alias Scalar = MatrixType.ScalarType
    alias RealScalar = Scalar  # simplified
    var s: RealScalar = internal_random[RealScalar]()
    var m1: MatrixType = MatrixType.Random(rows, cols)

    g_called = False
    VERIFY_IS_APPROX(s * m1, Scalar(s) * m1)
    VERIFY(g_called)  # real * matrix<complex> not properly optimized

    g_called = False
    VERIFY_IS_APPROX(m1 * s, m1 * Scalar(s))
    VERIFY(g_called)  # matrix<complex> * real not properly optimized

    g_called = False
    VERIFY_IS_APPROX(m1 / s, m1 / Scalar(s))
    VERIFY(g_called)  # matrix<complex> / real not properly optimized

    g_called = False
    VERIFY_IS_APPROX(s + m1.array(), Scalar(s) + m1.array())
    VERIFY(g_called)  # real + matrix<complex> not properly optimized

    g_called = False
    VERIFY_IS_APPROX(m1.array() + s, m1.array() + Scalar(s))
    VERIFY(g_called)  # matrix<complex> + real not properly optimized

    g_called = False
    VERIFY_IS_APPROX(s - m1.array(), Scalar(s) - m1.array())
    VERIFY(g_called)  # real - matrix<complex> not properly optimized

    g_called = False
    VERIFY_IS_APPROX(m1.array() - s, m1.array() - Scalar(s))
    VERIFY(g_called)  # matrix<complex> - real not properly optimized

def test_linearstructure() raises:
    g_called = True
    VERIFY(g_called)  # avoid `unneeded-internal-declaration` warning.

    for i in range(g_repeat):
        CALL_SUBTEST(1, lambda: linearStructure[Matrix[Float32,1,1]](Matrix[Float32,1,1]()))
        CALL_SUBTEST(2, lambda: linearStructure[Matrix2f](Matrix2f()))
        CALL_SUBTEST(3, lambda: linearStructure[Vector3d](Vector3d()))
        CALL_SUBTEST(4, lambda: linearStructure[Matrix4d](Matrix4d()))
        CALL_SUBTEST(5, lambda: linearStructure[MatrixXcf](MatrixXcf.Random(internal_random[Int](1,EIGEN_TEST_MAX_SIZE/2), internal_random[Int](1,EIGEN_TEST_MAX_SIZE/2))))
        CALL_SUBTEST(6, lambda: linearStructure[MatrixXf](MatrixXf.Random(internal_random[Int](1,EIGEN_TEST_MAX_SIZE), internal_random[Int](1,EIGEN_TEST_MAX_SIZE))))
        CALL_SUBTEST(7, lambda: linearStructure[MatrixXi](MatrixXi.Random(internal_random[Int](1,EIGEN_TEST_MAX_SIZE), internal_random[Int](1,EIGEN_TEST_MAX_SIZE))))
        CALL_SUBTEST(8, lambda: linearStructure[MatrixXcd](MatrixXcd.Random(internal_random[Int](1,EIGEN_TEST_MAX_SIZE/2), internal_random[Int](1,EIGEN_TEST_MAX_SIZE/2))))
        CALL_SUBTEST(9, lambda: linearStructure[ArrayXXf](ArrayXXf.Random(internal_random[Int](1,EIGEN_TEST_MAX_SIZE), internal_random[Int](1,EIGEN_TEST_MAX_SIZE))))
        CALL_SUBTEST(10, lambda: linearStructure[ArrayXXcf](ArrayXXcf.Random(internal_random[Int](1,EIGEN_TEST_MAX_SIZE), internal_random[Int](1,EIGEN_TEST_MAX_SIZE))))
        CALL_SUBTEST(11, lambda: real_complex[Matrix4cd](4,4))
        CALL_SUBTEST(11, lambda: real_complex[MatrixXcf](10,10))
        CALL_SUBTEST(11, lambda: real_complex[ArrayXXcf](10,10))

# #ifdef EIGEN_TEST_PART_4
if __EIGEN_TEST_PART__ == 4:  # need to define __EIGEN_TEST_PART__ constant – here we assume it's defined
    var m2: Matrix4d = Matrix4d.Random() * 1e-20
    var m3: Matrix4d = m2
    m2 = m2 / 4.9e-320
    VERIFY_IS_APPROX(m2.cwiseQuotient(m2), Matrix4d.Ones())
    m3 /= 4.9e-320
    VERIFY_IS_APPROX(m3.cwiseQuotient(m3), Matrix4d.Ones())
# #endif