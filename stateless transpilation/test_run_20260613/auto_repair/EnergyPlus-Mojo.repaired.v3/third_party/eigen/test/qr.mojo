from main import main, g_repeat, CALL_SUBTEST_1, CALL_SUBTEST_2, CALL_SUBTEST_3, CALL_SUBTEST_4, CALL_SUBTEST_5, CALL_SUBTEST_6, CALL_SUBTEST_7, CALL_SUBTEST_8, CALL_SUBTEST_9, CALL_SUBTEST_10, CALL_SUBTEST_11, CALL_SUBTEST_12
from Eigen.QR import HouseholderQR
from Eigen.Core import Matrix, MatrixXf, MatrixXcd, MatrixXd, MatrixXcf, Matrix3f, Matrix3d, MatrixXcd
from Eigen.Core import internal, NumTraits, VERIFY_IS_UNITARY, VERIFY_IS_APPROX, VERIFY_IS_MUCH_SMALLER_THAN, VERIFY_RAISES_ASSERT, numext

def qr[MatrixType: AnyType](m: MatrixType) raises:
    var rows = m.rows()
    var cols = m.cols()
    alias Scalar = MatrixType.Scalar
    alias MatrixQType = Matrix[Scalar, MatrixType.RowsAtCompileTime, MatrixType.RowsAtCompileTime]
    var a = MatrixType.Random(rows, cols)
    var qrOfA = HouseholderQR[MatrixType](a)
    var q = qrOfA.householderQ()
    VERIFY_IS_UNITARY(q)
    var r = qrOfA.matrixQR().template triangularView[Upper]()
    VERIFY_IS_APPROX(a, qrOfA.householderQ() * r)

def qr_fixedsize[MatrixType: AnyType, Cols2: Int]() raises:
    alias Rows = MatrixType.RowsAtCompileTime
    alias Cols = MatrixType.ColsAtCompileTime
    alias Scalar = MatrixType.Scalar
    var m1 = Matrix[Scalar, Rows, Cols].Random()
    var qr = HouseholderQR[Matrix[Scalar, Rows, Cols]](m1)
    var r = qr.matrixQR()
    for i in range(Rows):
        for j in range(Cols):
            if i > j:
                r[i, j] = Scalar(0)
    VERIFY_IS_APPROX(m1, qr.householderQ() * r)
    var m2 = Matrix[Scalar, Cols, Cols2].Random(Cols, Cols2)
    var m3 = m1 * m2
    m2 = Matrix[Scalar, Cols, Cols2].Random(Cols, Cols2)
    m2 = qr.solve(m3)
    VERIFY_IS_APPROX(m3, m1 * m2)

def qr_invertible[MatrixType: AnyType]() raises:
    using std.log
    using std.abs
    using std.pow
    using std.max
    alias RealScalar = NumTraits[MatrixType.Scalar].Real
    alias Scalar = MatrixType.Scalar
    var size = internal.random[Int](10, 50)
    var m1 = MatrixType(size, size)
    var m2 = MatrixType(size, size)
    var m3 = MatrixType(size, size)
    m1 = MatrixType.Random(size, size)
    if internal.is_same[RealScalar, float]():
        var a = MatrixType.Random(size, size * 4)
        m1 += a * a.adjoint()
    var qr = HouseholderQR[MatrixType](m1)
    m3 = MatrixType.Random(size, size)
    m2 = qr.solve(m3)
    VERIFY_IS_APPROX(m3, m1 * m2)
    m1.setZero()
    for i in range(size):
        m1[i, i] = internal.random[Scalar]()
    var absdet = abs(m1.diagonal().prod())
    m3 = qr.householderQ()
    m1 = m3 * m1 * m3
    qr.compute(m1)
    VERIFY_IS_APPROX(log(absdet), qr.logAbsDeterminant())
    VERIFY_IS_MUCH_SMALLER_THAN(abs(absdet - qr.absDeterminant()), numext.maxi[RealScalar](RealScalar(pow(0.5, size)), numext.maxi[RealScalar](abs(absdet), abs(qr.absDeterminant()))))

def qr_verify_assert[MatrixType: AnyType]() raises:
    var tmp = MatrixType()
    var qr = HouseholderQR[MatrixType]()
    VERIFY_RAISES_ASSERT(qr.matrixQR())
    VERIFY_RAISES_ASSERT(qr.solve(tmp))
    VERIFY_RAISES_ASSERT(qr.householderQ())
    VERIFY_RAISES_ASSERT(qr.absDeterminant())
    VERIFY_RAISES_ASSERT(qr.logAbsDeterminant())

def test_qr() raises:
    for i in range(g_repeat):
        CALL_SUBTEST_1(qr(MatrixXf(internal.random[Int](1, EIGEN_TEST_MAX_SIZE), internal.random[Int](1, EIGEN_TEST_MAX_SIZE))))
        CALL_SUBTEST_2(qr(MatrixXcd(internal.random[Int](1, EIGEN_TEST_MAX_SIZE / 2), internal.random[Int](1, EIGEN_TEST_MAX_SIZE / 2))))
        CALL_SUBTEST_3((qr_fixedsize[Matrix[float32, 3, 4], 2]()))
        CALL_SUBTEST_4((qr_fixedsize[Matrix[float64, 6, 2], 4]()))
        CALL_SUBTEST_5((qr_fixedsize[Matrix[float64, 2, 5], 7]()))
        CALL_SUBTEST_11(qr(Matrix[float32, 1, 1]()))
    for i in range(g_repeat):
        CALL_SUBTEST_1(qr_invertible[MatrixXf]())
        CALL_SUBTEST_6(qr_invertible[MatrixXd]())
        CALL_SUBTEST_7(qr_invertible[MatrixXcf]())
        CALL_SUBTEST_8(qr_invertible[MatrixXcd]())
    CALL_SUBTEST_9(qr_verify_assert[Matrix3f]())
    CALL_SUBTEST_10(qr_verify_assert[Matrix3d]())
    CALL_SUBTEST_1(qr_verify_assert[MatrixXf]())
    CALL_SUBTEST_6(qr_verify_assert[MatrixXd]())
    CALL_SUBTEST_7(qr_verify_assert[MatrixXcf]())
    CALL_SUBTEST_8(qr_verify_assert[MatrixXcd]())
    CALL_SUBTEST_12(HouseholderQR[MatrixXf](10, 20))