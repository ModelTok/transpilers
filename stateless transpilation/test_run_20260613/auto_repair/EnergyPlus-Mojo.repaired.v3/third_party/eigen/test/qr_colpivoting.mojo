// Mojo translation of third_party/eigen/test/qr_colpivoting.cpp

from main import (
    internal,
    VERIFY,
    VERIFY_IS_APPROX,
    VERIFY_IS_EQUAL,
    VERIFY_IS_UNITARY,
    VERIFY_IS_APPROX_OR_LESS_THAN,
    VERIFY_RAISES_ASSERT,
    test_isApproxOrLessThan,
    createRandomPIMatrixOfRank,
    g_repeat,
    CALL_SUBTEST_1,
    CALL_SUBTEST_2,
    CALL_SUBTEST_3,
    CALL_SUBTEST_4,
    CALL_SUBTEST_5,
    CALL_SUBTEST_6,
    CALL_SUBTEST_7,
    CALL_SUBTEST_8,
    CALL_SUBTEST_9,
    EIGEN_TEST_MAX_SIZE,
)
from Eigen.QR import (
    ColPivHouseholderQR,
    CompleteOrthogonalDecomposition,
)
from Eigen.SVD import (
    JacobiSVD,
    ComputeThinU,
    ComputeThinV,
    ComputeFullU,
    ComputeFullV,
)
from Eigen.Core import (
    Matrix,
    NumTraits,
    numext,
)
from math import (
    sqrt,
    pow,
    abs as math_abs,   // to avoid conflict with numext.abs
    log,
)

def cod[MatrixType: type]() -> void:
    let rows: Int = internal.random[Int](2, EIGEN_TEST_MAX_SIZE)
    let cols: Int = internal.random[Int](2, EIGEN_TEST_MAX_SIZE)
    let cols2: Int = internal.random[Int](2, EIGEN_TEST_MAX_SIZE)
    let rank: Int = internal.random[Int](1, min(rows, cols) - 1)
    alias Scalar = MatrixType.Scalar
    alias MatrixQType = Matrix[Scalar, MatrixType.RowsAtCompileTime, MatrixType.RowsAtCompileTime]
    var matrix: MatrixType
    createRandomPIMatrixOfRank(rank, rows, cols, matrix)
    let cod: CompleteOrthogonalDecomposition[MatrixType] = CompleteOrthogonalDecomposition[MatrixType](matrix)
    VERIFY(rank == cod.rank())
    VERIFY(cols - cod.rank() == cod.dimensionOfKernel())
    VERIFY(!cod.isInjective())
    VERIFY(!cod.isInvertible())
    VERIFY(!cod.isSurjective())
    let q: MatrixQType = cod.householderQ()
    VERIFY_IS_UNITARY(q)
    let z: MatrixType = cod.matrixZ()
    VERIFY_IS_UNITARY(z)
    var t: MatrixType
    t.setZero(rows, cols)
    t.topLeftCorner(rank, rank) = cod.matrixT().topLeftCorner(rank, rank).template triangularView[Upper]()
    let c: MatrixType = q * t * z * cod.colsPermutation().inverse()
    VERIFY_IS_APPROX(matrix, c)
    let exact_solution: MatrixType = MatrixType.Random(cols, cols2)
    let rhs: MatrixType = matrix * exact_solution
    let cod_solution: MatrixType = cod.solve(rhs)
    VERIFY_IS_APPROX(rhs, matrix * cod_solution)
    let svd: JacobiSVD[MatrixType] = JacobiSVD[MatrixType](matrix, ComputeThinU | ComputeThinV)
    let svd_solution: MatrixType = svd.solve(rhs)
    VERIFY_IS_APPROX(cod_solution, svd_solution)
    let pinv: MatrixType = cod.pseudoInverse()
    VERIFY_IS_APPROX(cod_solution, pinv * rhs)

def cod_fixedsize[MatrixType: type, Cols2: Int]() -> void:
    alias Rows = MatrixType.RowsAtCompileTime
    alias Cols = MatrixType.ColsAtCompileTime
    alias Scalar = MatrixType.Scalar
    let rank: Int = internal.random[Int](1, min(Rows, Cols) - 1)
    var matrix: Matrix[Scalar, Rows, Cols]
    createRandomPIMatrixOfRank(rank, Rows, Cols, matrix)
    let cod: CompleteOrthogonalDecomposition[Matrix[Scalar, Rows, Cols]] = CompleteOrthogonalDecomposition[Matrix[Scalar, Rows, Cols]](matrix)
    VERIFY(rank == cod.rank())
    VERIFY(Cols - cod.rank() == cod.dimensionOfKernel())
    VERIFY(cod.isInjective() == (rank == Rows))
    VERIFY(cod.isSurjective() == (rank == Cols))
    VERIFY(cod.isInvertible() == (cod.isInjective() and cod.isSurjective()))
    var exact_solution: Matrix[Scalar, Cols, Cols2]
    exact_solution.setRandom(Cols, Cols2)
    let rhs: Matrix[Scalar, Rows, Cols2] = matrix * exact_solution
    let cod_solution: Matrix[Scalar, Cols, Cols2] = cod.solve(rhs)
    VERIFY_IS_APPROX(rhs, matrix * cod_solution)
    let svd: JacobiSVD[MatrixType] = JacobiSVD[MatrixType](matrix, ComputeFullU | ComputeFullV)
    let svd_solution: Matrix[Scalar, Cols, Cols2] = svd.solve(rhs)
    VERIFY_IS_APPROX(cod_solution, svd_solution)

def qr[MatrixType: type]() -> void:
    using std: "{sqrt = sqrt, abs = math_abs}" // just for clarity, but we use non-using
    let rows: Int = internal.random[Int](2, EIGEN_TEST_MAX_SIZE)
    let cols: Int = internal.random[Int](2, EIGEN_TEST_MAX_SIZE)
    let cols2: Int = internal.random[Int](2, EIGEN_TEST_MAX_SIZE)
    let rank: Int = internal.random[Int](1, min(rows, cols) - 1)
    alias Scalar = MatrixType.Scalar
    alias RealScalar = MatrixType.RealScalar
    alias MatrixQType = Matrix[Scalar, MatrixType.RowsAtCompileTime, MatrixType.RowsAtCompileTime]
    var m1: MatrixType
    createRandomPIMatrixOfRank(rank, rows, cols, m1)
    let qr: ColPivHouseholderQR[MatrixType] = ColPivHouseholderQR[MatrixType](m1)
    VERIFY_IS_EQUAL(rank, qr.rank())
    VERIFY_IS_EQUAL(cols - qr.rank(), qr.dimensionOfKernel())
    VERIFY(!qr.isInjective())
    VERIFY(!qr.isInvertible())
    VERIFY(!qr.isSurjective())
    let q: MatrixQType = qr.householderQ()
    VERIFY_IS_UNITARY(q)
    let r: MatrixType = qr.matrixQR().template triangularView[Upper]()
    let c: MatrixType = q * r * qr.colsPermutation().inverse()
    VERIFY_IS_APPROX(m1, c)
    let threshold: RealScalar = sqrt(RealScalar(rows)) * numext.abs(r(0, 0)) * NumTraits[Scalar].epsilon()
    for i in range(0, min(rows, cols) - 1):
        let x: RealScalar = numext.abs(r(i, i))
        let y: RealScalar = numext.abs(r(i + 1, i + 1))
        if x < threshold and y < threshold:
            continue
        if not test_isApproxOrLessThan(y, x):
            for j in range(0, min(rows, cols)):
                print("i = " + str(j) + ", |r_ii| = " + str(numext.abs(r(j, j))))
            print("Failure at i=" + str(i) + ", rank=" + str(rank) + ", threshold=" + str(threshold))
        VERIFY_IS_APPROX_OR_LESS_THAN(y, x)
    var m2: MatrixType = MatrixType.Random(cols, cols2)
    var m3: MatrixType = m1 * m2
    m2 = MatrixType.Random(cols, cols2)
    m2 = qr.solve(m3)
    VERIFY_IS_APPROX(m3, m1 * m2)
    do:
        var size: Int = rows
        repeat:
            m1 = MatrixType.Random(size, size)
            qr.compute(m1)
        while not qr.isInvertible()
        let m1_inv: MatrixType = qr.inverse()
        m3 = m1 * MatrixType.Random(size, cols2)
        m2 = qr.solve(m3)
        VERIFY_IS_APPROX(m2, m1_inv * m3)

def qr_fixedsize[MatrixType: type, Cols2: Int]() -> void:
    alias Rows = MatrixType.RowsAtCompileTime
    alias Cols = MatrixType.ColsAtCompileTime
    alias Scalar = MatrixType.Scalar
    alias RealScalar = MatrixType.RealScalar
    let rank: Int = internal.random[Int](1, min(Rows, Cols) - 1)
    var m1: Matrix[Scalar, Rows, Cols]
    createRandomPIMatrixOfRank(rank, Rows, Cols, m1)
    let qr: ColPivHouseholderQR[Matrix[Scalar, Rows, Cols]] = ColPivHouseholderQR[Matrix[Scalar, Rows, Cols]](m1)
    VERIFY_IS_EQUAL(rank, qr.rank())
    VERIFY_IS_EQUAL(Cols - qr.rank(), qr.dimensionOfKernel())
    VERIFY_IS_EQUAL(qr.isInjective(), (rank == Rows))
    VERIFY_IS_EQUAL(qr.isSurjective(), (rank == Cols))
    VERIFY_IS_EQUAL(qr.isInvertible(), (qr.isInjective() and qr.isSurjective()))
    let r: Matrix[Scalar, Rows, Cols] = qr.matrixQR().template triangularView[Upper]()
    let c: Matrix[Scalar, Rows, Cols] = qr.householderQ() * r * qr.colsPermutation().inverse()
    VERIFY_IS_APPROX(m1, c)
    var m2: Matrix[Scalar, Cols, Cols2] = Matrix[Scalar, Cols, Cols2].Random(Cols, Cols2)
    var m3: Matrix[Scalar, Rows, Cols2] = m1 * m2
    m2 = Matrix[Scalar, Cols, Cols2].Random(Cols, Cols2)
    m2 = qr.solve(m3)
    VERIFY_IS_APPROX(m3, m1 * m2)
    let threshold: RealScalar = sqrt(RealScalar(Rows)) * math_abs(r(0, 0)) * NumTraits[Scalar].epsilon()
    for i in range(0, min(Rows, Cols) - 1):
        let x: RealScalar = numext.abs(r(i, i))
        let y: RealScalar = numext.abs(r(i + 1, i + 1))
        if x < threshold and y < threshold:
            continue
        if not test_isApproxOrLessThan(y, x):
            for j in range(0, min(Rows, Cols)):
                print("i = " + str(j) + ", |r_ii| = " + str(numext.abs(r(j, j))))
            print("Failure at i=" + str(i) + ", rank=" + str(rank) + ", threshold=" + str(threshold))
        VERIFY_IS_APPROX_OR_LESS_THAN(y, x)

def qr_kahan_matrix[MatrixType: type]() -> void:
    using std: "{sqrt = sqrt, abs = math_abs}"
    alias Scalar = MatrixType.Scalar
    alias RealScalar = MatrixType.RealScalar
    let rows: Int = 300
    let cols: Int = rows
    var m1: MatrixType
    m1.setZero(rows, cols)
    let s: RealScalar = pow(NumTraits[RealScalar].epsilon(), 1.0 / rows)
    let c: RealScalar = sqrt(1 - s * s)
    var pow_s_i: RealScalar = 1.0
    for i in range(0, rows):
        m1(i, i) = pow_s_i
        m1.row(i).tail(rows - i - 1) = -pow_s_i * c * MatrixType.Ones(1, rows - i - 1)
        pow_s_i *= s
    m1 = (m1 + m1.transpose()).eval()
    let qr: ColPivHouseholderQR[MatrixType] = ColPivHouseholderQR[MatrixType](m1)
    let r: MatrixType = qr.matrixQR().template triangularView[Upper]()
    let threshold: RealScalar = sqrt(RealScalar(rows)) * numext.abs(r(0, 0)) * NumTraits[Scalar].epsilon()
    for i in range(0, min(rows, cols) - 1):
        let x: RealScalar = numext.abs(r(i, i))
        let y: RealScalar = numext.abs(r(i + 1, i + 1))
        if x < threshold and y < threshold:
            continue
        if not test_isApproxOrLessThan(y, x):
            for j in range(0, min(rows, cols)):
                print("i = " + str(j) + ", |r_ii| = " + str(numext.abs(r(j, j))))
            print("Failure at i=" + str(i) + ", rank=" + str(qr.rank()) + ", threshold=" + str(threshold))
        VERIFY_IS_APPROX_OR_LESS_THAN(y, x)

def qr_invertible[MatrixType: type]() -> void:
    alias RealScalar = NumTraits[MatrixType.Scalar].Real
    alias Scalar = MatrixType.Scalar
    let size: Int = internal.random[Int](10, 50)
    var m1: MatrixType = MatrixType(size, size)
    var m2: MatrixType = MatrixType(size, size)
    var m3: MatrixType = MatrixType(size, size)
    m1 = MatrixType.Random(size, size)
    if internal.is_same[RealScalar, float]():
        let a: MatrixType = MatrixType.Random(size, size * 2)
        m1 += a * a.adjoint()
    let qr: ColPivHouseholderQR[MatrixType] = ColPivHouseholderQR[MatrixType](m1)
    m3 = MatrixType.Random(size, size)
    m2 = qr.solve(m3)
    m1.setZero()
    for i in range(0, size):
        m1(i, i) = internal.random[Scalar]()
    let absdet: RealScalar = math_abs(m1.diagonal().prod())
    m3 = qr.householderQ()
    m1 = m3 * m1 * m3
    qr.compute(m1)
    VERIFY_IS_APPROX(absdet, qr.absDeterminant())
    VERIFY_IS_APPROX(log(absdet), qr.logAbsDeterminant())

def qr_verify_assert[MatrixType: type]() -> void:
    var tmp: MatrixType
    let qr: ColPivHouseholderQR[MatrixType] = ColPivHouseholderQR[MatrixType]()
    VERIFY_RAISES_ASSERT(qr.matrixQR())
    VERIFY_RAISES_ASSERT(qr.solve(tmp))
    VERIFY_RAISES_ASSERT(qr.householderQ())
    VERIFY_RAISES_ASSERT(qr.dimensionOfKernel())
    VERIFY_RAISES_ASSERT(qr.isInjective())
    VERIFY_RAISES_ASSERT(qr.isSurjective())
    VERIFY_RAISES_ASSERT(qr.isInvertible())
    VERIFY_RAISES_ASSERT(qr.inverse())
    VERIFY_RAISES_ASSERT(qr.absDeterminant())
    VERIFY_RAISES_ASSERT(qr.logAbsDeterminant())

def test_qr_colpivoting() -> void:
    for i in range(0, g_repeat):
        CALL_SUBTEST_1(qr[MatrixXf]())
        CALL_SUBTEST_2(qr[MatrixXd]())
        CALL_SUBTEST_3(qr[MatrixXcd]())
        CALL_SUBTEST_4((qr_fixedsize[Matrix[float, 3, 5], 4]()))
        CALL_SUBTEST_5((qr_fixedsize[Matrix[double, 6, 2], 3]()))
        CALL_SUBTEST_5((qr_fixedsize[Matrix[double, 1, 1], 1]()))
    for i in range(0, g_repeat):
        CALL_SUBTEST_1(cod[MatrixXf]())
        CALL_SUBTEST_2(cod[MatrixXd]())
        CALL_SUBTEST_3(cod[MatrixXcd]())
        CALL_SUBTEST_4((cod_fixedsize[Matrix[float, 3, 5], 4]()))
        CALL_SUBTEST_5((cod_fixedsize[Matrix[double, 6, 2], 3]()))
        CALL_SUBTEST_5((cod_fixedsize[Matrix[double, 1, 1], 1]()))
    for i in range(0, g_repeat):
        CALL_SUBTEST_1(qr_invertible[MatrixXf]())
        CALL_SUBTEST_2(qr_invertible[MatrixXd]())
        CALL_SUBTEST_6(qr_invertible[MatrixXcf]())
        CALL_SUBTEST_3(qr_invertible[MatrixXcd]())
    CALL_SUBTEST_7(qr_verify_assert[Matrix3f]())
    CALL_SUBTEST_8(qr_verify_assert[Matrix3d]())
    CALL_SUBTEST_1(qr_verify_assert[MatrixXf]())
    CALL_SUBTEST_2(qr_verify_assert[MatrixXd]())
    CALL_SUBTEST_6(qr_verify_assert[MatrixXcf]())
    CALL_SUBTEST_3(qr_verify_assert[MatrixXcd]())
    CALL_SUBTEST_9(ColPivHouseholderQR[MatrixXf](10, 20))
    CALL_SUBTEST_1(qr_kahan_matrix[MatrixXf]())
    CALL_SUBTEST_2(qr_kahan_matrix[MatrixXd]())