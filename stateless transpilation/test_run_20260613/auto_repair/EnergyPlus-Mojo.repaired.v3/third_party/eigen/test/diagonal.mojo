from ...Eigen import (
    Matrix, MatrixXf, MatrixXi, MatrixXcf, MatrixXcd, Matrix4d,
    internal_random, VERIFY_IS_APPROX, VERIFY_RAISES_ASSERT,
    CALL_SUBTEST_1, CALL_SUBTEST_2, Dynamic, g_repeat, EIGEN_TEST_MAX_SIZE
)

def diagonal[MatrixType: AnyType](m: MatrixType):
    let Scalar = MatrixType.Scalar
    let rows = m.rows()
    let cols = m.cols()
    var m1 = MatrixType.Random(rows, cols)
    var m2 = MatrixType.Random(rows, cols)
    let s1 = internal_random[Scalar]()
    VERIFY_IS_APPROX(m1.diagonal(), m1.transpose().diagonal())
    m2.diagonal() = 2 * m1.diagonal()
    m2.diagonal()[0] *= 3
    if rows > 2:
        let N1: Int = 2 if MatrixType.RowsAtCompileTime > 2 else 0
        let N2: Int = -1 if MatrixType.RowsAtCompileTime > 1 else 0
        if MatrixType.SizeAtCompileTime != Dynamic:
            VERIFY(m1.template diagonal[N1]().RowsAtCompileTime == m1.diagonal(N1).size())
            VERIFY(m1.template diagonal[N2]().RowsAtCompileTime == m1.diagonal(N2).size())
        m2.template diagonal[N1]() = 2 * m1.template diagonal[N1]()
        VERIFY_IS_APPROX(m2.template diagonal[N1](), static_cast[Scalar](2) * m1.diagonal(N1))
        m2.template diagonal[N1]()[0] *= 3
        VERIFY_IS_APPROX(m2.template diagonal[N1]()[0], static_cast[Scalar](6) * m1.template diagonal[N1]()[0])
        m2.template diagonal[N2]() = 2 * m1.template diagonal[N2]()
        m2.template diagonal[N2]()[0] *= 3
        VERIFY_IS_APPROX(m2.template diagonal[N2]()[0], static_cast[Scalar](6) * m1.template diagonal[N2]()[0])
        m2.diagonal(N1) = 2 * m1.diagonal(N1)
        VERIFY_IS_APPROX(m2.template diagonal[N1](), static_cast[Scalar](2) * m1.diagonal(N1))
        m2.diagonal(N1)[0] *= 3
        VERIFY_IS_APPROX(m2.diagonal(N1)[0], static_cast[Scalar](6) * m1.diagonal(N1)[0])
        m2.diagonal(N2) = 2 * m1.diagonal(N2)
        VERIFY_IS_APPROX(m2.template diagonal[N2](), static_cast[Scalar](2) * m1.diagonal(N2))
        m2.diagonal(N2)[0] *= 3
        VERIFY_IS_APPROX(m2.diagonal(N2)[0], static_cast[Scalar](6) * m1.diagonal(N2)[0])
        m2.diagonal(N2).x() = s1
        VERIFY_IS_APPROX(m2.diagonal(N2).x(), s1)
        m2.diagonal(N2).coeffRef(0) = Scalar(2) * s1
        VERIFY_IS_APPROX(m2.diagonal(N2).coeff(0), Scalar(2) * s1)
    VERIFY(m1.diagonal(cols).size() == 0)
    VERIFY(m1.diagonal(-rows).size() == 0)

def diagonal_assert[MatrixType: AnyType](m: MatrixType):
    let rows = m.rows()
    let cols = m.cols()
    var m1 = MatrixType.Random(rows, cols)
    if rows >= 2 and cols >= 2:
        VERIFY_RAISES_ASSERT(m1 += m1.diagonal())
        VERIFY_RAISES_ASSERT(m1 -= m1.diagonal())
        VERIFY_RAISES_ASSERT(m1.array() *= m1.diagonal().array())
        VERIFY_RAISES_ASSERT(m1.array() /= m1.diagonal().array())
    VERIFY_RAISES_ASSERT(m1.diagonal(cols + 1))
    VERIFY_RAISES_ASSERT(m1.diagonal(-(rows + 1)))

def test_diagonal():
    for i in range(g_repeat):
        CALL_SUBTEST_1(diagonal[Matrix[float32, 1, 1]]())
        CALL_SUBTEST_1(diagonal[Matrix[float32, 4, 9]]())
        CALL_SUBTEST_1(diagonal[Matrix[float32, 7, 3]]())
        CALL_SUBTEST_2(diagonal[Matrix4d]())
        CALL_SUBTEST_2(diagonal[MatrixXcf(internal_random[int](1, EIGEN_TEST_MAX_SIZE), internal_random[int](1, EIGEN_TEST_MAX_SIZE))]())
        CALL_SUBTEST_2(diagonal[MatrixXi(internal_random[int](1, EIGEN_TEST_MAX_SIZE), internal_random[int](1, EIGEN_TEST_MAX_SIZE))]())
        CALL_SUBTEST_2(diagonal[MatrixXcd(internal_random[int](1, EIGEN_TEST_MAX_SIZE), internal_random[int](1, EIGEN_TEST_MAX_SIZE))]())
        CALL_SUBTEST_1(diagonal[MatrixXf(internal_random[int](1, EIGEN_TEST_MAX_SIZE), internal_random[int](1, EIGEN_TEST_MAX_SIZE))]())
        CALL_SUBTEST_1(diagonal[Matrix[float32, Dynamic, 4](3, 4)]())
        CALL_SUBTEST_1(diagonal_assert[MatrixXf(internal_random[int](1, EIGEN_TEST_MAX_SIZE), internal_random[int](1, EIGEN_TEST_MAX_SIZE))]())