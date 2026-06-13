from ...Eigen import (
    Matrix, Matrix3d, Matrix3cf, MatrixXcd, Dynamic,
    Scalar, Index, internal, selfadjointView, triangularView,
    adjoint, real, cast, diagonal, Random, rows, cols,
    VERIFY_IS_APPROX, VERIFY_RAISES_STATIC_ASSERT, CALL_SUBTEST_1,
    CALL_SUBTEST_2, CALL_SUBTEST_3, CALL_SUBTEST_4, CALL_SUBTEST_5,
    EIGEN_UNUSED_VARIABLE, g_repeat, EIGEN_TEST_MAX_SIZE,
    TEST_SET_BUT_UNUSED_VARIABLE,
)

def selfadjoint[MatrixType: ConcreteType](m: MatrixType):
    alias Scalar = MatrixType.Scalar
    let rows = m.rows()
    let cols = m.cols()
    var m1 = MatrixType.Random(rows, cols)
    var m2 = MatrixType.Random(rows, cols)
    var m3 = MatrixType(rows, cols)
    var m4 = MatrixType(rows, cols)
    m1.diagonal() = m1.diagonal().real().cast[Scalar]()
    m3 = m1.selfadjointView[Upper]()
    VERIFY_IS_APPROX(MatrixType(m3.triangularView[Upper]()), MatrixType(m1.triangularView[Upper]()))
    VERIFY_IS_APPROX(m3, m3.adjoint())
    m3 = m1.selfadjointView[Lower]()
    VERIFY_IS_APPROX(MatrixType(m3.triangularView[Lower]()), MatrixType(m1.triangularView[Lower]()))
    VERIFY_IS_APPROX(m3, m3.adjoint())
    m3 = m1.selfadjointView[Upper]()
    m4 = m2
    m4 += m1.selfadjointView[Upper]()
    VERIFY_IS_APPROX(m4, m2 + m3)
    m3 = m1.selfadjointView[Lower]()
    m4 = m2
    m4 -= m1.selfadjointView[Lower]()
    VERIFY_IS_APPROX(m4, m2 - m3)
    VERIFY_RAISES_STATIC_ASSERT(m2.selfadjointView[StrictlyUpper]())
    VERIFY_RAISES_STATIC_ASSERT(m2.selfadjointView[UnitLower]())

def bug_159():
    let m = Matrix3d.Random().selfadjointView[Lower]()
    EIGEN_UNUSED_VARIABLE(m)

def test_selfadjoint():
    for i in range(g_repeat):
        let s = internal.random[Int](1, EIGEN_TEST_MAX_SIZE)
        CALL_SUBTEST_1(selfadjoint[Matrix[Float32, 1, 1]]())
        CALL_SUBTEST_2(selfadjoint[Matrix[Float32, 2, 2]]())
        CALL_SUBTEST_3(selfadjoint[Matrix3cf]())
        CALL_SUBTEST_4(selfadjoint[MatrixXcd(s, s)]())
        CALL_SUBTEST_5(selfadjoint[Matrix[Float32, Dynamic, Dynamic, RowMajor](s, s)]())
        TEST_SET_BUT_UNUSED_VARIABLE(s)
    CALL_SUBTEST_1(bug_159())