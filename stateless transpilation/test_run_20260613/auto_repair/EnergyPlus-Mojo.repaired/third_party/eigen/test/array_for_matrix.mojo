from Eigen import Matrix, Array, MatrixWrapper, ArrayWrapper, NumTraits, internal, numext

alias Index = Int
alias Dynamic = -1

# Test infrastructure (simplified)
var g_repeat: Int = 1
var EIGEN_TEST_MAX_SIZE: Int = 50

def VERIFY(cond: Bool) raises:
    if not cond:
        raise Error("VERIFY failed")

def VERIFY_IS_APPROX(a: AnyType, b: AnyType):
    # approximate comparison (simplified)
    # In actual Eigen, this is a macro; we approximate as equality
    # For brevity, we use a simple check assuming scalars
    if abs(a - b) > 1e-6:
        raise Error("VERIFY_IS_APPROX failed")

def VERIFY_IS_MUCH_SMALLER_THAN(a: AnyType, b: AnyType):

def CALL_SUBTEST_1(body_fn: fn() raises) raises:
    body_fn()

def CALL_SUBTEST_2(body_fn: fn() raises) raises:
    body_fn()

def CALL_SUBTEST_3(body_fn: fn() raises) raises:
    body_fn()

def CALL_SUBTEST_4(body_fn: fn() raises) raises:
    body_fn()

def CALL_SUBTEST_5(body_fn: fn() raises) raises:
    body_fn()

def CALL_SUBTEST_6(body_fn: fn() raises) raises:
    body_fn()

def CALL_SUBTEST_7(body_fn: fn() raises) raises:
    body_fn()

def CALL_SUBTEST_8(body_fn: fn() raises) raises:
    body_fn()

# Template function array_for_matrix
def array_for_matrix[MatrixType: AnyType](m: MatrixType) raises:
    alias Scalar = MatrixType.Scalar
    alias ColVectorType = Matrix[Scalar, MatrixType.RowsAtCompileTime, 1]
    alias RowVectorType = Matrix[Scalar, 1, MatrixType.ColsAtCompileTime]
    var rows: Index = m.rows()
    var cols: Index = m.cols()
    var m1: MatrixType = MatrixType.Random(rows, cols)
    var m2: MatrixType = MatrixType.Random(rows, cols)
    var m3: MatrixType = MatrixType(rows, cols)
    var cv1: ColVectorType = ColVectorType.Random(rows)
    var rv1: RowVectorType = RowVectorType.Random(cols)
    var s1: Scalar = internal.random[Scalar]()
    var s2: Scalar = internal.random[Scalar]()
    VERIFY_IS_APPROX(m1.array() + s1, s1 + m1.array())
    VERIFY_IS_APPROX((m1.array() + s1).matrix(), MatrixType.Constant(rows, cols, s1) + m1)
    VERIFY_IS_APPROX(((m1 * Scalar(2)).array() - s2).matrix(), (m1 + m1) - MatrixType.Constant(rows, cols, s2))
    m3 = m1
    m3.array() += s2
    VERIFY_IS_APPROX(m3, (m1.array() + s2).matrix())
    m3 = m1
    m3.array() -= s1
    VERIFY_IS_APPROX(m3, (m1.array() - s1).matrix())
    VERIFY_IS_MUCH_SMALLER_THAN(m1.colwise().sum().sum() - m1.sum(), m1.squaredNorm())
    VERIFY_IS_MUCH_SMALLER_THAN(m1.rowwise().sum().sum() - m1.sum(), m1.squaredNorm())
    VERIFY_IS_MUCH_SMALLER_THAN(m1.colwise().sum() + m2.colwise().sum() - (m1 + m2).colwise().sum(), (m1 + m2).squaredNorm())
    VERIFY_IS_MUCH_SMALLER_THAN(m1.rowwise().sum() - m2.rowwise().sum() - (m1 - m2).rowwise().sum(), (m1 - m2).squaredNorm())
    VERIFY_IS_APPROX(m1.colwise().sum(), m1.colwise().redux(internal.scalar_sum_op[Scalar, Scalar]()))
    m3 = m1
    VERIFY_IS_APPROX(m3.colwise() += cv1, m1.colwise() + cv1)
    m3 = m1
    VERIFY_IS_APPROX(m3.colwise() -= cv1, m1.colwise() - cv1)
    m3 = m1
    VERIFY_IS_APPROX(m3.rowwise() += rv1, m1.rowwise() + rv1)
    m3 = m1
    VERIFY_IS_APPROX(m3.rowwise() -= rv1, m1.rowwise() - rv1)
    VERIFY_IS_APPROX(m1.block(0, 0, 0, cols).colwise().sum(), RowVectorType.Zero(cols))
    VERIFY_IS_APPROX(m1.block(0, 0, rows, 0).rowwise().prod(), ColVectorType.Ones(rows))
    var ref_m1: Scalar& = m.matrix().array().coeffRef(0)
    var ref_m2: Scalar& = m.matrix().array().coeffRef(0, 0)
    var ref_a1: Scalar& = m.array().matrix().coeffRef(0)
    var ref_a2: Scalar& = m.array().matrix().coeffRef(0, 0)
    VERIFY(&ref_a1 == &ref_m1)
    VERIFY(&ref_a2 == &ref_m2)
    m1.array().coeffRef(0, 0) = 1
    VERIFY_IS_APPROX(m1(0, 0), Scalar(1))
    m1.array()(0, 0) = 2
    VERIFY_IS_APPROX(m1(0, 0), Scalar(2))
    m1.array().matrix().coeffRef(0, 0) = 3
    VERIFY_IS_APPROX(m1(0, 0), Scalar(3))
    m1.array().matrix()(0, 0) = 4
    VERIFY_IS_APPROX(m1(0, 0), Scalar(4))

# Template function comparisons
def comparisons[MatrixType: AnyType](m: MatrixType) raises:
    using abs = internal.abs
    alias Scalar = MatrixType.Scalar
    alias RealScalar = NumTraits[Scalar].Real
    var rows: Index = m.rows()
    var cols: Index = m.cols()
    var r: Index = internal.random[Index](0, rows - 1)
    var c: Index = internal.random[Index](0, cols - 1)
    var m1: MatrixType = MatrixType.Random(rows, cols)
    var m2: MatrixType = MatrixType.Random(rows, cols)
    var m3: MatrixType = MatrixType(rows, cols)
    VERIFY(((m1.array() + Scalar(1)) > m1.array()).all())
    VERIFY(((m1.array() - Scalar(1)) < m1.array()).all())
    if rows * cols > 1:
        m3 = m1
        m3(r, c) += 1
        VERIFY(!(m1.array() < m3.array()).all())
        VERIFY(!(m1.array() > m3.array()).all())
    VERIFY((m1.array() != (m1(r, c) + 1)).any())
    VERIFY((m1.array() > (m1(r, c) - 1)).any())
    VERIFY((m1.array() < (m1(r, c) + 1)).any())
    VERIFY((m1.array() == m1(r, c)).any())
    VERIFY(m1.cwiseEqual(m1(r, c)).any())
    VERIFY_IS_APPROX((m1.array() < m2.array()).select(m1, m2), m1.cwiseMin(m2))
    VERIFY_IS_APPROX((m1.array() > m2.array()).select(m1, m2), m1.cwiseMax(m2))
    var mid: Scalar = (m1.cwiseAbs().minCoeff() + m1.cwiseAbs().maxCoeff()) / Scalar(2)
    for j in range(cols):
        for i in range(rows):
            m3(i, j) = abs(m1(i, j)) < mid ? 0 : m1(i, j)
    VERIFY_IS_APPROX((m1.array().abs() < MatrixType.Constant(rows, cols, mid).array()).select(MatrixType.Zero(rows, cols), m1), m3)
    VERIFY_IS_APPROX((m1.array().abs() < MatrixType.Constant(rows, cols, mid).array()).select(0, m1), m3)
    VERIFY_IS_APPROX((m1.array().abs() >= MatrixType.Constant(rows, cols, mid).array()).select(m1, 0), m3)
    VERIFY_IS_APPROX((m1.array().abs() < mid).select(0, m1), m3)
    VERIFY(((m1.array().abs() + 1) > RealScalar(0.1)).count() == rows * cols)
    VERIFY(((m1.array() < RealScalar(0)).matrix() and (m1.array() > RealScalar(0)).matrix()).count() == 0)
    VERIFY(((m1.array() < RealScalar(0)).matrix() or (m1.array() >= RealScalar(0)).matrix()).count() == rows * cols)
    var a: RealScalar = m1.cwiseAbs().mean()
    VERIFY(((m1.array() < -a).matrix() or (m1.array() > a).matrix()).count() == (m1.cwiseAbs().array() > a).count())
    alias VectorOfIndices = Matrix[MatrixType.Index, Dynamic, 1]
    VERIFY_IS_APPROX(((m1.array().abs() + 1) > RealScalar(0.1)).matrix().colwise().count(), VectorOfIndices.Constant(cols, rows).transpose())
    VERIFY_IS_APPROX(((m1.array().abs() + 1) > RealScalar(0.1)).matrix().rowwise().count(), VectorOfIndices.Constant(rows, cols))

# Template function lpNorm
def lpNorm[VectorType: AnyType](v: VectorType) raises:
    using sqrt = internal.sqrt
    alias RealScalar = VectorType.RealScalar
    var u: VectorType = VectorType.Random(v.size())
    if v.size() == 0:
        VERIFY_IS_APPROX(u.template lpNorm[0](), RealScalar(0))
        VERIFY_IS_APPROX(u.template lpNorm[1](), RealScalar(0))
        VERIFY_IS_APPROX(u.template lpNorm[2](), RealScalar(0))
        VERIFY_IS_APPROX(u.template lpNorm[5](), RealScalar(0))
    else:
        VERIFY_IS_APPROX(u.template lpNorm[0](), u.cwiseAbs().maxCoeff())
    VERIFY_IS_APPROX(u.template lpNorm[1](), u.cwiseAbs().sum())
    VERIFY_IS_APPROX(u.template lpNorm[2](), sqrt(u.array().abs().square().sum()))
    VERIFY_IS_APPROX(numext.pow(u.template lpNorm[5](), RealScalar(5)), u.array().abs().pow(5).sum())

# Template function cwise_min_max
def cwise_min_max[MatrixType: AnyType](m: MatrixType) raises:
    alias Scalar = MatrixType.Scalar
    var rows: Index = m.rows()
    var cols: Index = m.cols()
    var m1: MatrixType = MatrixType.Random(rows, cols)
    var maxM1: Scalar = m1.maxCoeff()
    var minM1: Scalar = m1.minCoeff()
    VERIFY_IS_APPROX(MatrixType.Constant(rows, cols, minM1), m1.cwiseMin(MatrixType.Constant(rows, cols, minM1)))
    VERIFY_IS_APPROX(m1, m1.cwiseMin(MatrixType.Constant(rows, cols, maxM1)))
    VERIFY_IS_APPROX(MatrixType.Constant(rows, cols, maxM1), m1.cwiseMax(MatrixType.Constant(rows, cols, maxM1)))
    VERIFY_IS_APPROX(m1, m1.cwiseMax(MatrixType.Constant(rows, cols, minM1)))
    VERIFY_IS_APPROX(MatrixType.Constant(rows, cols, minM1), m1.cwiseMin(minM1))
    VERIFY_IS_APPROX(m1, m1.cwiseMin(maxM1))
    VERIFY_IS_APPROX(-m1, (-m1).cwiseMin(-minM1))
    VERIFY_IS_APPROX(-m1.array(), ((-m1).array().min)(-minM1))
    VERIFY_IS_APPROX(MatrixType.Constant(rows, cols, maxM1), m1.cwiseMax(maxM1))
    VERIFY_IS_APPROX(m1, m1.cwiseMax(minM1))
    VERIFY_IS_APPROX(-m1, (-m1).cwiseMax(-maxM1))
    VERIFY_IS_APPROX(-m1.array(), ((-m1).array().max)(-maxM1))
    VERIFY_IS_APPROX(MatrixType.Constant(rows, cols, minM1).array(), (m1.array().min)(minM1))
    VERIFY_IS_APPROX(m1.array(), (m1.array().min)(maxM1))
    VERIFY_IS_APPROX(MatrixType.Constant(rows, cols, maxM1).array(), (m1.array().max)(maxM1))
    VERIFY_IS_APPROX(m1.array(), (m1.array().max)(minM1))

# Template function resize
def resize[MatrixTraits: AnyType](t: MatrixTraits) raises:
    alias Scalar = MatrixTraits.Scalar
    alias MatrixType = Matrix[Scalar, Dynamic, Dynamic]
    alias Array2DType = Array[Scalar, Dynamic, Dynamic]
    alias VectorType = Matrix[Scalar, Dynamic, 1]
    alias Array1DType = Array[Scalar, Dynamic, 1]
    var rows: Index = t.rows()
    var cols: Index = t.cols()
    var m: MatrixType = MatrixType(rows, cols)
    var v: VectorType = VectorType(rows)
    var a2: Array2DType = Array2DType(rows, cols)
    var a1: Array1DType = Array1DType(rows)
    m.array().resize(rows + 1, cols + 1)
    VERIFY(m.rows() == rows + 1 and m.cols() == cols + 1)
    a2.matrix().resize(rows + 1, cols + 1)
    VERIFY(a2.rows() == rows + 1 and a2.cols() == cols + 1)
    v.array().resize(cols)
    VERIFY(v.size() == cols)
    a1.matrix().resize(cols)
    VERIFY(a1.size() == cols)

# Template function regression_bug_654
def regression_bug_654[I: Int]() raises:
    var a: ArrayXf = RowVectorXf(3)
    var v: VectorXf = Array[float32, 1, Dynamic](3)

# Template function regrrssion_bug_1410
def regrrssion_bug_1410[I: Int]() raises:
    var M: Matrix4i
    var A: Array4i
    var MA: ArrayWrapper[const Matrix4i] = M.array()
    MA.row(0)
    var AM: MatrixWrapper[const Array4i] = A.matrix()
    AM.row(0)
    VERIFY((internal.traits[ArrayWrapper[const Matrix4i]].Flags & LvalueBit) == 0)
    VERIFY((internal.traits[MatrixWrapper[const Array4i]].Flags & LvalueBit) == 0)
    VERIFY((internal.traits[ArrayWrapper[Matrix4i]].Flags & LvalueBit) == LvalueBit)
    VERIFY((internal.traits[MatrixWrapper[Array4i]].Flags & LvalueBit) == LvalueBit)

# Main test function
def test_array_for_matrix() raises:
    for i in range(g_repeat):
        CALL_SUBTEST_1(lambda: array_for_matrix(Matrix[float32, 1, 1]()))
        CALL_SUBTEST_2(lambda: array_for_matrix(Matrix2f()))
        CALL_SUBTEST_3(lambda: array_for_matrix(Matrix4d()))
        CALL_SUBTEST_4(lambda: array_for_matrix(MatrixXcf(internal.random[Index](1, EIGEN_TEST_MAX_SIZE), internal.random[Index](1, EIGEN_TEST_MAX_SIZE))))
        CALL_SUBTEST_5(lambda: array_for_matrix(MatrixXf(internal.random[Index](1, EIGEN_TEST_MAX_SIZE), internal.random[Index](1, EIGEN_TEST_MAX_SIZE))))
        CALL_SUBTEST_6(lambda: array_for_matrix(MatrixXi(internal.random[Index](1, EIGEN_TEST_MAX_SIZE), internal.random[Index](1, EIGEN_TEST_MAX_SIZE))))
    for i in range(g_repeat):
        CALL_SUBTEST_1(lambda: comparisons(Matrix[float32, 1, 1]()))
        CALL_SUBTEST_2(lambda: comparisons(Matrix2f()))
        CALL_SUBTEST_3(lambda: comparisons(Matrix4d()))
        CALL_SUBTEST_5(lambda: comparisons(MatrixXf(internal.random[Index](1, EIGEN_TEST_MAX_SIZE), internal.random[Index](1, EIGEN_TEST_MAX_SIZE))))
        CALL_SUBTEST_6(lambda: comparisons(MatrixXi(internal.random[Index](1, EIGEN_TEST_MAX_SIZE), internal.random[Index](1, EIGEN_TEST_MAX_SIZE))))
    for i in range(g_repeat):
        CALL_SUBTEST_1(lambda: cwise_min_max(Matrix[float32, 1, 1]()))
        CALL_SUBTEST_2(lambda: cwise_min_max(Matrix2f()))
        CALL_SUBTEST_3(lambda: cwise_min_max(Matrix4d()))
        CALL_SUBTEST_5(lambda: cwise_min_max(MatrixXf(internal.random[Index](1, EIGEN_TEST_MAX_SIZE), internal.random[Index](1, EIGEN_TEST_MAX_SIZE))))
        CALL_SUBTEST_6(lambda: cwise_min_max(MatrixXi(internal.random[Index](1, EIGEN_TEST_MAX_SIZE), internal.random[Index](1, EIGEN_TEST_MAX_SIZE))))
    for i in range(g_repeat):
        CALL_SUBTEST_1(lambda: lpNorm(Matrix[float32, 1, 1]()))
        CALL_SUBTEST_2(lambda: lpNorm(Vector2f()))
        CALL_SUBTEST_7(lambda: lpNorm(Vector3d()))
        CALL_SUBTEST_8(lambda: lpNorm(Vector4f()))
        CALL_SUBTEST_5(lambda: lpNorm(VectorXf(internal.random[Index](1, EIGEN_TEST_MAX_SIZE))))
        CALL_SUBTEST_4(lambda: lpNorm(VectorXcf(internal.random[Index](1, EIGEN_TEST_MAX_SIZE))))
    CALL_SUBTEST_5(lambda: lpNorm(VectorXf(0)))
    CALL_SUBTEST_4(lambda: lpNorm(VectorXcf(0)))
    for i in range(g_repeat):
        CALL_SUBTEST_4(lambda: resize(MatrixXcf(internal.random[Index](1, EIGEN_TEST_MAX_SIZE), internal.random[Index](1, EIGEN_TEST_MAX_SIZE))))
        CALL_SUBTEST_5(lambda: resize(MatrixXf(internal.random[Index](1, EIGEN_TEST_MAX_SIZE), internal.random[Index](1, EIGEN_TEST_MAX_SIZE))))
        CALL_SUBTEST_6(lambda: resize(MatrixXi(internal.random[Index](1, EIGEN_TEST_MAX_SIZE), internal.random[Index](1, EIGEN_TEST_MAX_SIZE))))
    CALL_SUBTEST_6(lambda: regression_bug_654[0]())
    CALL_SUBTEST_6(lambda: regrrssion_bug_1410[0]())

# Note: The following type aliases are assumed to be defined in the Eigen Mojo library:
# Matrix2f, Matrix4d, MatrixXf, MatrixXcf, MatrixXi, Vector2f, Vector3d, Vector4f, VectorXf, VectorXcf,
# ArrayXf, RowVectorXf, Matrix4i, Array4i, LvalueBit, etc.
# They are used as in the original C++.