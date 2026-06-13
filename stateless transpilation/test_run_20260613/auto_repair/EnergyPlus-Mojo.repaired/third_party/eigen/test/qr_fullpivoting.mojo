from Eigen import Matrix, FullPivHouseholderQR, NumTraits
from internal import random, is_same
from numext import maxi, mini
from math import log, abs
from random import Random

# Constants
let EIGEN_TEST_MAX_SIZE = 50  # Approximate
let g_repeat = 10             # Default value

def qr[MatrixType: AnyType]() raises:
    var max_size: Int = EIGEN_TEST_MAX_SIZE
    var min_size: Int = numext.maxi(1, EIGEN_TEST_MAX_SIZE // 10)
    var rows: Int = internal.random[Index](min_size, max_size)
    var cols: Int = internal.random[Index](min_size, max_size)
    var cols2: Int = internal.random[Index](min_size, max_size)
    var rank: Int = internal.random[Index](1, min(rows, cols) - 1)
    alias Scalar = MatrixType.Scalar
    alias MatrixQType = Matrix[Scalar, MatrixType.RowsAtCompileTime, MatrixType.RowsAtCompileTime]
    var m1: MatrixType
    createRandomPIMatrixOfRank(rank, rows, cols, m1)
    var qr_val: FullPivHouseholderQR[MatrixType] = FullPivHouseholderQR[MatrixType](m1)
    VERIFY_IS_EQUAL(rank, qr_val.rank())
    VERIFY_IS_EQUAL(cols - qr_val.rank(), qr_val.dimensionOfKernel())
    VERIFY(!qr_val.isInjective())
    VERIFY(!qr_val.isInvertible())
    VERIFY(!qr_val.isSurjective())
    var r: MatrixType = qr_val.matrixQR()
    var q: MatrixQType = qr_val.matrixQ()
    VERIFY_IS_UNITARY(q)
    for i in range(rows):
        for j in range(cols):
            if i > j:
                r[i, j] = Scalar(0)
    var c: MatrixType = qr_val.matrixQ() * r * qr_val.colsPermutation().inverse()
    VERIFY_IS_APPROX(m1, c)
    var tmp: MatrixType
    VERIFY_IS_APPROX(tmp.noalias() = qr_val.matrixQ() * r, (qr_val.matrixQ() * r).eval())
    var m2: MatrixType = MatrixType.Random(cols, cols2)
    var m3: MatrixType = m1 * m2
    m2 = MatrixType.Random(cols, cols2)
    m2 = qr_val.solve(m3)
    VERIFY_IS_APPROX(m3, m1 * m2)
    do:
        var size: Int = rows
        while True:
            m1 = MatrixType.Random(size, size)
            qr_val.compute(m1)
            if qr_val.isInvertible():
                break
        var m1_inv: MatrixType = qr_val.inverse()
        m3 = m1 * MatrixType.Random(size, cols2)
        m2 = qr_val.solve(m3)
        VERIFY_IS_APPROX(m2, m1_inv * m3)

def qr_invertible[MatrixType: AnyType]() raises:
    using std.log = log
    using std.abs = abs
    alias RealScalar = NumTraits[MatrixType.Scalar].Real
    alias Scalar = MatrixType.Scalar
    var max_size: Int = numext.mini(50, EIGEN_TEST_MAX_SIZE)
    var min_size: Int = numext.maxi(1, EIGEN_TEST_MAX_SIZE // 10)
    var size: Int = internal.random[Index](min_size, max_size)
    var m1: MatrixType = MatrixType(size, size)
    var m2: MatrixType = MatrixType(size, size)
    var m3: MatrixType = MatrixType(size, size)
    m1 = MatrixType.Random(size, size)
    if internal.is_same[RealScalar, float]():
        var a: MatrixType = MatrixType.Random(size, size * 2)
        m1 += a * a.adjoint()
    var qr_val: FullPivHouseholderQR[MatrixType] = FullPivHouseholderQR[MatrixType](m1)
    VERIFY(qr_val.isInjective())
    VERIFY(qr_val.isInvertible())
    VERIFY(qr_val.isSurjective())
    m3 = MatrixType.Random(size, size)
    m2 = qr_val.solve(m3)
    VERIFY_IS_APPROX(m3, m1 * m2)
    m1.setZero()
    for i in range(size):
        m1[i, i] = internal.random[Scalar]()
    var absdet: RealScalar = abs(m1.diagonal().prod())
    m3 = qr_val.matrixQ()
    m1 = m3 * m1 * m3
    qr_val.compute(m1)
    VERIFY_IS_APPROX(absdet, qr_val.absDeterminant())
    VERIFY_IS_APPROX(log(absdet), qr_val.logAbsDeterminant())

def qr_verify_assert[MatrixType: AnyType]() raises:
    var tmp: MatrixType
    var qr_val: FullPivHouseholderQR[MatrixType] = FullPivHouseholderQR[MatrixType]()
    VERIFY_RAISES_ASSERT(qr_val.matrixQR())
    VERIFY_RAISES_ASSERT(qr_val.solve(tmp))
    VERIFY_RAISES_ASSERT(qr_val.matrixQ())
    VERIFY_RAISES_ASSERT(qr_val.dimensionOfKernel())
    VERIFY_RAISES_ASSERT(qr_val.isInjective())
    VERIFY_RAISES_ASSERT(qr_val.isSurjective())
    VERIFY_RAISES_ASSERT(qr_val.isInvertible())
    VERIFY_RAISES_ASSERT(qr_val.inverse())
    VERIFY_RAISES_ASSERT(qr_val.absDeterminant())
    VERIFY_RAISES_ASSERT(qr_val.logAbsDeterminant())

def test_qr_fullpivoting() raises:
    for i in range(1):
        CALL_SUBTEST_1(qr[MatrixXf]())
        CALL_SUBTEST_2(qr[MatrixXd]())
        CALL_SUBTEST_3(qr[MatrixXcd]())
    for i in range(g_repeat):
        CALL_SUBTEST_1(qr_invertible[MatrixXf]())
        CALL_SUBTEST_2(qr_invertible[MatrixXd]())
        CALL_SUBTEST_4(qr_invertible[MatrixXcf]())
        CALL_SUBTEST_3(qr_invertible[MatrixXcd]())
    CALL_SUBTEST_5(qr_verify_assert[Matrix3f]())
    CALL_SUBTEST_6(qr_verify_assert[Matrix3d]())
    CALL_SUBTEST_1(qr_verify_assert[MatrixXf]())
    CALL_SUBTEST_2(qr_verify_assert[MatrixXd]())
    CALL_SUBTEST_4(qr_verify_assert[MatrixXcf]())
    CALL_SUBTEST_3(qr_verify_assert[MatrixXcd]())
    CALL_SUBTEST_7(FullPivHouseholderQR[MatrixXf](10, 20))
    CALL_SUBTEST_7(FullPivHouseholderQR[Matrix[float, 10, 20]](10, 20))
    CALL_SUBTEST_7(FullPivHouseholderQR[Matrix[float, 10, 20]](Matrix[float, 10, 20].Random()))
    CALL_SUBTEST_7(FullPivHouseholderQR[Matrix[float, 20, 10]](20, 10))
    CALL_SUBTEST_7(FullPivHouseholderQR[Matrix[float, 20, 10]](Matrix[float, 20, 10].Random()))