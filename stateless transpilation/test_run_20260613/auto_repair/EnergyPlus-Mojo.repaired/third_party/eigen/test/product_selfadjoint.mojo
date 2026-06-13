from main import *
from internal import random as internal_random
from numext import conj as numext_conj

def product_selfadjoint[MatrixType: AnyType](m: MatrixType):
    alias Scalar = MatrixType.Scalar
    alias VectorType = Matrix[Scalar, MatrixType.RowsAtCompileTime, 1]
    alias RowVectorType = Matrix[Scalar, 1, MatrixType.RowsAtCompileTime]
    alias RhsMatrixType = Matrix[Scalar, MatrixType.RowsAtCompileTime, Dynamic, RowMajor]
    var rows = m.rows()
    var cols = m.cols()
    var m1 = MatrixType.Random(rows, cols)
    var m2 = MatrixType.Random(rows, cols)
    var m3: MatrixType
    var v1 = VectorType.Random(rows)
    var v2 = VectorType.Random(rows)
    var v3 = VectorType(rows)
    var r1 = RowVectorType.Random(rows)
    var r2 = RowVectorType.Random(rows)
    var m4 = RhsMatrixType.Random(rows, 10)
    var s1 = internal_random[Scalar]()
    var s2 = internal_random[Scalar]()
    var s3 = internal_random[Scalar]()
    m1 = (m1.adjoint() + m1).eval()
    m2 = m1.template triangularView[Lower]()
    m2.template selfadjointView[Lower]().rankUpdate(v1, v2)
    VERIFY_IS_APPROX(m2, (m1 + v1 * v2.adjoint() + v2 * v1.adjoint()).template triangularView[Lower]().toDenseMatrix())
    m2 = m1.template triangularView[Upper]()
    m2.template selfadjointView[Upper]().rankUpdate(-v1, s2 * v2, s3)
    VERIFY_IS_APPROX(m2, (m1 + (s3 * (-v1) * (s2 * v2).adjoint() + numext_conj(s3) * (s2 * v2) * (-v1).adjoint())).template triangularView[Upper]().toDenseMatrix())
    m2 = m1.template triangularView[Upper]()
    m2.template selfadjointView[Upper]().rankUpdate(-s2 * r1.adjoint(), r2.adjoint() * s3, s1)
    VERIFY_IS_APPROX(m2, (m1 + s1 * (-s2 * r1.adjoint()) * (r2.adjoint() * s3).adjoint() + numext_conj(s1) * (r2.adjoint() * s3) * (-s2 * r1.adjoint()).adjoint()).template triangularView[Upper]().toDenseMatrix())
    if rows > 1:
        m2 = m1.template triangularView[Lower]()
        m2.block(1, 1, rows - 1, cols - 1).template selfadjointView[Lower]().rankUpdate(v1.tail(rows - 1), v2.head(cols - 1))
        m3 = m1
        m3.block(1, 1, rows - 1, cols - 1) += v1.tail(rows - 1) * v2.head(cols - 1).adjoint() + v2.head(cols - 1) * v1.tail(rows - 1).adjoint()
        VERIFY_IS_APPROX(m2, m3.template triangularView[Lower]().toDenseMatrix())

def test_product_selfadjoint():
    var s = 0
    for i in range(g_repeat):
        CALL_SUBTEST_1(product_selfadjoint[Matrix[float32, 1, 1]]())
        CALL_SUBTEST_2(product_selfadjoint[Matrix[float32, 2, 2]]())
        CALL_SUBTEST_3(product_selfadjoint[Matrix3d]())
        s = internal_random[int](1, EIGEN_TEST_MAX_SIZE / 2)
        CALL_SUBTEST_4(product_selfadjoint[MatrixXcf(s, s)]())
        TEST_SET_BUT_UNUSED_VARIABLE(s)
        s = internal_random[int](1, EIGEN_TEST_MAX_SIZE / 2)
        CALL_SUBTEST_5(product_selfadjoint[MatrixXcd(s, s)]())
        TEST_SET_BUT_UNUSED_VARIABLE(s)
        s = internal_random[int](1, EIGEN_TEST_MAX_SIZE)
        CALL_SUBTEST_6(product_selfadjoint[MatrixXd(s, s)]())
        TEST_SET_BUT_UNUSED_VARIABLE(s)
        s = internal_random[int](1, EIGEN_TEST_MAX_SIZE)
        CALL_SUBTEST_7(product_selfadjoint[Matrix[float32, Dynamic, Dynamic, RowMajor](s, s)]())
        TEST_SET_BUT_UNUSED_VARIABLE(s)