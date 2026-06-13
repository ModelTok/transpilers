from main import *
from Eigen import *

def triangular_square[MatrixType: AnyType](m: MatrixType):
    alias Scalar = MatrixType.Scalar
    alias RealScalar = NumTraits[Scalar].Real
    alias VectorType = Matrix[Scalar, MatrixType.RowsAtCompileTime, 1]
    var largerEps: RealScalar = 10 * test_precision[RealScalar]()
    var rows = m.rows()
    var cols = m.cols()
    var m1 = MatrixType.Random(rows, cols)
    var m2 = MatrixType.Random(rows, cols)
    var m3 = MatrixType(rows, cols)
    var m4 = MatrixType(rows, cols)
    var r1 = MatrixType(rows, cols)
    var r2 = MatrixType(rows, cols)
    var v2 = VectorType.Random(rows)
    var m1up = m1.triangularView[Upper]()
    var m2up = m2.triangularView[Upper]()
    if rows * cols > 1:
        VERIFY(m1up.isUpperTriangular())
        VERIFY(m2up.transpose().isLowerTriangular())
        VERIFY(!m2.isLowerTriangular())
    r1.setZero()
    r2.setZero()
    r1.triangularView[Upper]() += m1
    r2 += m1up
    VERIFY_IS_APPROX(r1, r2)
    m1.setZero()
    m1.triangularView[Upper]() = m2.transpose() + m2
    m3 = m2.transpose() + m2
    VERIFY_IS_APPROX(m3.triangularView[Lower]().transpose().toDenseMatrix(), m1)
    m1.setZero()
    m1.triangularView[Lower]() = m2.transpose() + m2
    VERIFY_IS_APPROX(m3.triangularView[Lower]().toDenseMatrix(), m1)
    VERIFY_IS_APPROX(m3.triangularView[Lower]().conjugate().toDenseMatrix(),
                     m3.conjugate().triangularView[Lower]().toDenseMatrix())
    m1 = MatrixType.Random(rows, cols)
    for i in range(0, rows):
        while numext.abs2(m1[i, i]) < RealScalar(1e-1):
            m1[i, i] = internal.random[Scalar]()
    var trm4 = Transpose[MatrixType](m4)
    m3 = m1.triangularView[Upper]()
    VERIFY(v2.isApprox(m3.adjoint() * (m1.adjoint().triangularView[Lower]().solve(v2)), largerEps))
    m3 = m1.triangularView[Lower]()
    VERIFY(v2.isApprox(m3.transpose() * (m1.transpose().triangularView[Upper]().solve(v2)), largerEps))
    m3 = m1.triangularView[Upper]()
    VERIFY(v2.isApprox(m3 * (m1.triangularView[Upper]().solve(v2)), largerEps))
    m3 = m1.triangularView[Lower]()
    VERIFY(v2.isApprox(m3.conjugate() * (m1.conjugate().triangularView[Lower]().solve(v2)), largerEps))
    m3 = m1.triangularView[Upper]()
    VERIFY(m2.isApprox(m3.adjoint() * (m1.adjoint().triangularView[Lower]().solve(m2)), largerEps))
    m3 = m1.triangularView[Lower]()
    VERIFY(m2.isApprox(m3.transpose() * (m1.transpose().triangularView[Upper]().solve(m2)), largerEps))
    m3 = m1.triangularView[Upper]()
    VERIFY(m2.isApprox(m3 * (m1.triangularView[Upper]().solve(m2)), largerEps))
    m3 = m1.triangularView[Lower]()
    VERIFY(m2.isApprox(m3.conjugate() * (m1.conjugate().triangularView[Lower]().solve(m2)), largerEps))
    m4 = m3
    m1.transpose().triangularView[Eigen.Upper]().solveInPlace(trm4)
    VERIFY_IS_APPROX(m4 * m1.triangularView[Eigen.Lower](), m3)
    m3 = m1.triangularView[Upper]()
    m4 = m3
    m3.transpose().triangularView[Eigen.Lower]().solveInPlace(trm4)
    VERIFY_IS_APPROX(m4 * m1.triangularView[Eigen.Upper](), m3)
    m3 = m1.triangularView[UnitUpper]()
    VERIFY(m2.isApprox(m3 * (m1.triangularView[UnitUpper]().solve(m2)), largerEps))
    m1.setOnes()
    m2.setZero()
    m2.triangularView[Upper]().swap(m1)
    m3.setZero()
    m3.triangularView[Upper]().setOnes()
    VERIFY_IS_APPROX(m2, m3)
    m1.setRandom()
    m3 = m1.triangularView[Upper]()
    var m5 = Matrix[Scalar, MatrixType.ColsAtCompileTime, Dynamic](cols, internal.random[int](1, 20))
    m5.setRandom()
    var m6 = Matrix[Scalar, Dynamic, MatrixType.RowsAtCompileTime](internal.random[int](1, 20), rows)
    m6.setRandom()
    VERIFY_IS_APPROX(m1.triangularView[Upper]() * m5, m3 * m5)
    VERIFY_IS_APPROX(m6 * m1.triangularView[Upper](), m6 * m3)
    m1up = m1.triangularView[Upper]()
    VERIFY_IS_APPROX(m1.selfadjointView[Upper]().triangularView[Upper]().toDenseMatrix(), m1up)
    VERIFY_IS_APPROX(m1up.selfadjointView[Upper]().triangularView[Upper]().toDenseMatrix(), m1up)
    VERIFY_IS_APPROX(m1.selfadjointView[Upper]().triangularView[Lower]().toDenseMatrix(), m1up.adjoint())
    VERIFY_IS_APPROX(m1up.selfadjointView[Upper]().triangularView[Lower]().toDenseMatrix(), m1up.adjoint())
    VERIFY_IS_APPROX(m1.selfadjointView[Upper]().diagonal(), m1.diagonal())

def triangular_rect[MatrixType: AnyType](m: MatrixType):
    alias Scalar = MatrixType.Scalar
    alias RealScalar = NumTraits[Scalar].Real
    alias Rows = MatrixType.RowsAtCompileTime
    alias Cols = MatrixType.ColsAtCompileTime
    var rows = m.rows()
    var cols = m.cols()
    var m1 = MatrixType.Random(rows, cols)
    var m2 = MatrixType.Random(rows, cols)
    var m3 = MatrixType(rows, cols)
    var m4 = MatrixType(rows, cols)
    var r1 = MatrixType(rows, cols)
    var r2 = MatrixType(rows, cols)
    var m1up = m1.triangularView[Upper]()
    var m2up = m2.triangularView[Upper]()
    if rows > 1 and cols > 1:
        VERIFY(m1up.isUpperTriangular())
        VERIFY(m2up.transpose().isLowerTriangular())
        VERIFY(!m2.isLowerTriangular())
    r1.setZero()
    r2.setZero()
    r1.triangularView[Upper]() += m1
    r2 += m1up
    VERIFY_IS_APPROX(r1, r2)
    m1.setZero()
    m1.triangularView[Upper]() = 3 * m2
    m3 = 3 * m2
    VERIFY_IS_APPROX(m3.triangularView[Upper]().toDenseMatrix(), m1)
    m1.setZero()
    m1.triangularView[Lower]() = 3 * m2
    VERIFY_IS_APPROX(m3.triangularView[Lower]().toDenseMatrix(), m1)
    m1.setZero()
    m1.triangularView[StrictlyUpper]() = 3 * m2
    VERIFY_IS_APPROX(m3.triangularView[StrictlyUpper]().toDenseMatrix(), m1)
    m1.setZero()
    m1.triangularView[StrictlyLower]() = 3 * m2
    VERIFY_IS_APPROX(m3.triangularView[StrictlyLower]().toDenseMatrix(), m1)
    m1.setRandom()
    m2 = m1.triangularView[Upper]()
    VERIFY(m2.isUpperTriangular())
    VERIFY(!m2.isLowerTriangular())
    m2 = m1.triangularView[StrictlyUpper]()
    VERIFY(m2.isUpperTriangular())
    VERIFY(m2.diagonal().isMuchSmallerThan(RealScalar(1)))
    m2 = m1.triangularView[UnitUpper]()
    VERIFY(m2.isUpperTriangular())
    m2.diagonal().array() -= Scalar(1)
    VERIFY(m2.diagonal().isMuchSmallerThan(RealScalar(1)))
    m2 = m1.triangularView[Lower]()
    VERIFY(m2.isLowerTriangular())
    VERIFY(!m2.isUpperTriangular())
    m2 = m1.triangularView[StrictlyLower]()
    VERIFY(m2.isLowerTriangular())
    VERIFY(m2.diagonal().isMuchSmallerThan(RealScalar(1)))
    m2 = m1.triangularView[UnitLower]()
    VERIFY(m2.isLowerTriangular())
    m2.diagonal().array() -= Scalar(1)
    VERIFY(m2.diagonal().isMuchSmallerThan(RealScalar(1)))
    m1.setOnes()
    m2.setZero()
    m2.triangularView[Upper]().swap(m1)
    m3.setZero()
    m3.triangularView[Upper]().setOnes()
    VERIFY_IS_APPROX(m2, m3)

def bug_159():
    var m = Matrix3d.Random().triangularView[Lower]()
    EIGEN_UNUSED_VARIABLE(m)

def test_triangular():
    var maxsize = (std.min)(EIGEN_TEST_MAX_SIZE, 20)
    for i in range(0, g_repeat):
        var r = internal.random[int](2, maxsize)
        TEST_SET_BUT_UNUSED_VARIABLE(r)
        var c = internal.random[int](2, maxsize)
        TEST_SET_BUT_UNUSED_VARIABLE(c)
        CALL_SUBTEST_1(triangular_square[Matrix[float32, 1, 1]]())
        CALL_SUBTEST_2(triangular_square[Matrix[float32, 2, 2]]())
        CALL_SUBTEST_3(triangular_square[Matrix3d]())
        CALL_SUBTEST_4(triangular_square[Matrix[complex[float32], 8, 8]]())
        CALL_SUBTEST_5(triangular_square[MatrixXcd](r, r))
        CALL_SUBTEST_6(triangular_square[Matrix[float32, Dynamic, Dynamic, RowMajor]](r, r))
        CALL_SUBTEST_7(triangular_rect[Matrix[float32, 4, 5]]())
        CALL_SUBTEST_8(triangular_rect[Matrix[float64, 6, 2]]())
        CALL_SUBTEST_9(triangular_rect[MatrixXcf](r, c))
        CALL_SUBTEST_5(triangular_rect[MatrixXcd](r, c))
        CALL_SUBTEST_6(triangular_rect[Matrix[float32, Dynamic, Dynamic, RowMajor]](r, c))
    CALL_SUBTEST_1(bug_159())