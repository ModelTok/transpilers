from main import g_repeat, CALL_SUBTEST, VERIFY_IS_APPROX, VERIFY_IS_MUCH_SMALLER_THAN, EIGEN_TEST_MAX_SIZE
from Eigen.QR import HouseholderQR, HouseholderSequence, OnTheRight
from Eigen.Core import Matrix, NumTraits, internal, numext, Dynamic, StrictlyLower, HouseholderSequence

var even: Bool = True

def householder[MatrixType: AnyType](m: MatrixType):
    even = not even
    # this test covers the following files:
    # Householder.h
    var rows: Int = m.rows()
    var cols: Int = m.cols()
    alias Scalar = MatrixType.Scalar
    alias RealScalar = NumTraits[Scalar].Real
    alias VectorType = Matrix[Scalar, MatrixType.RowsAtCompileTime, 1]
    alias EssentialVectorType = Matrix[Scalar, internal.decrement_size[MatrixType.RowsAtCompileTime].ret, 1]
    alias SquareMatrixType = Matrix[Scalar, MatrixType.RowsAtCompileTime, MatrixType.RowsAtCompileTime]
    alias HBlockMatrixType = Matrix[Scalar, Dynamic, MatrixType.ColsAtCompileTime]
    alias HCoeffsVectorType = Matrix[Scalar, Dynamic, 1]
    alias TMatrixType = Matrix[Scalar, MatrixType.ColsAtCompileTime, MatrixType.RowsAtCompileTime]
    var _tmp: Matrix[Scalar, EIGEN_SIZE_MAX(MatrixType.RowsAtCompileTime, MatrixType.ColsAtCompileTime), 1] = Matrix[Scalar, EIGEN_SIZE_MAX(MatrixType.RowsAtCompileTime, MatrixType.ColsAtCompileTime), 1](max(rows, cols))
    var tmp: Scalar* = _tmp.coeffRef(0, 0)
    var beta: Scalar
    var alpha: RealScalar
    var essential: EssentialVectorType
    var v1: VectorType = VectorType.Random(rows)
    var v2: VectorType
    v2 = v1
    v1.makeHouseholder(essential, beta, alpha)
    v1.applyHouseholderOnTheLeft(essential, beta, tmp)
    VERIFY_IS_APPROX(v1.norm(), v2.norm())
    if rows >= 2:
        VERIFY_IS_MUCH_SMALLER_THAN(v1.tail(rows - 1).norm(), v1.norm())
    v1 = VectorType.Random(rows)
    v2 = v1
    v1.applyHouseholderOnTheLeft(essential, beta, tmp)
    VERIFY_IS_APPROX(v1.norm(), v2.norm())
    var m1: MatrixType = MatrixType(rows, cols)
    var m2: MatrixType = MatrixType(rows, cols)
    v1 = VectorType.Random(rows)
    if even:
        v1.tail(rows - 1).setZero()
    m1.colwise() = v1
    m2 = m1
    m1.col(0).makeHouseholder(essential, beta, alpha)
    m1.applyHouseholderOnTheLeft(essential, beta, tmp)
    VERIFY_IS_APPROX(m1.norm(), m2.norm())
    if rows >= 2:
        VERIFY_IS_MUCH_SMALLER_THAN(m1.block(1, 0, rows - 1, cols).norm(), m1.norm())
    VERIFY_IS_MUCH_SMALLER_THAN(numext.imag(m1(0, 0)), numext.real(m1(0, 0)))
    VERIFY_IS_APPROX(numext.real(m1(0, 0)), alpha)
    v1 = VectorType.Random(rows)
    if even:
        v1.tail(rows - 1).setZero()
    var m3: SquareMatrixType = SquareMatrixType(rows, rows)
    var m4: SquareMatrixType = SquareMatrixType(rows, rows)
    m3.rowwise() = v1.transpose()
    m4 = m3
    m3.row(0).makeHouseholder(essential, beta, alpha)
    m3.applyHouseholderOnTheRight(essential, beta, tmp)
    VERIFY_IS_APPROX(m3.norm(), m4.norm())
    if rows >= 2:
        VERIFY_IS_MUCH_SMALLER_THAN(m3.block(0, 1, rows, rows - 1).norm(), m3.norm())
    VERIFY_IS_MUCH_SMALLER_THAN(numext.imag(m3(0, 0)), numext.real(m3(0, 0)))
    VERIFY_IS_APPROX(numext.real(m3(0, 0)), alpha)
    var shift: Int = internal.random[Int](0, max[Int](rows - 2, 0))
    var brows: Int = rows - shift
    m1.setRandom(rows, cols)
    var hbm: HBlockMatrixType = m1.block(shift, 0, brows, cols)
    var qr: HouseholderQR[HBlockMatrixType] = HouseholderQR[HBlockMatrixType](hbm)
    m2 = m1
    m2.block(shift, 0, brows, cols) = qr.matrixQR()
    var hc: HCoeffsVectorType = qr.hCoeffs().conjugate()
    var hseq: HouseholderSequence[MatrixType, HCoeffsVectorType] = HouseholderSequence[MatrixType, HCoeffsVectorType](m2, hc)
    hseq.setLength(hc.size()).setShift(shift)
    VERIFY(hseq.length() == hc.size())
    VERIFY(hseq.shift() == shift)
    var m5: MatrixType = m2
    m5.block(shift, 0, brows, cols).triangularView[StrictlyLower]().setZero()
    VERIFY_IS_APPROX(hseq * m5, m1)  # test applying hseq directly
    m3 = hseq
    VERIFY_IS_APPROX(m3 * m5, m1)  # test evaluating hseq to a dense matrix, then applying
    var hseq_mat: SquareMatrixType = hseq
    var hseq_mat_conj: SquareMatrixType = hseq.conjugate()
    var hseq_mat_adj: SquareMatrixType = hseq.adjoint()
    var hseq_mat_trans: SquareMatrixType = hseq.transpose()
    var m6: SquareMatrixType = SquareMatrixType.Random(rows, rows)
    VERIFY_IS_APPROX(hseq_mat.adjoint(), hseq_mat_adj)
    VERIFY_IS_APPROX(hseq_mat.conjugate(), hseq_mat_conj)
    VERIFY_IS_APPROX(hseq_mat.transpose(), hseq_mat_trans)
    VERIFY_IS_APPROX(hseq_mat * m6, hseq_mat * m6)
    VERIFY_IS_APPROX(hseq_mat.adjoint() * m6, hseq_mat_adj * m6)
    VERIFY_IS_APPROX(hseq_mat.conjugate() * m6, hseq_mat_conj * m6)
    VERIFY_IS_APPROX(hseq_mat.transpose() * m6, hseq_mat_trans * m6)
    VERIFY_IS_APPROX(m6 * hseq_mat, m6 * hseq_mat)
    VERIFY_IS_APPROX(m6 * hseq_mat.adjoint(), m6 * hseq_mat_adj)
    VERIFY_IS_APPROX(m6 * hseq_mat.conjugate(), m6 * hseq_mat_conj)
    VERIFY_IS_APPROX(m6 * hseq_mat.transpose(), m6 * hseq_mat_trans)
    var tm2: TMatrixType = m2.transpose()
    var rhseq: HouseholderSequence[TMatrixType, HCoeffsVectorType, OnTheRight] = HouseholderSequence[TMatrixType, HCoeffsVectorType, OnTheRight](tm2, hc)
    rhseq.setLength(hc.size()).setShift(shift)
    VERIFY_IS_APPROX(rhseq * m5, m1)  # test applying rhseq directly
    m3 = rhseq
    VERIFY_IS_APPROX(m3 * m5, m1)  # test evaluating rhseq to a dense matrix, then applying

def test_householder():
    for i in range(g_repeat):
        CALL_SUBTEST(1, householder[Matrix[Float64, 2, 2]]())
        CALL_SUBTEST(2, householder[Matrix[Float32, 2, 3]]())
        CALL_SUBTEST(3, householder[Matrix[Float64, 3, 5]]())
        CALL_SUBTEST(4, householder[Matrix[Float32, 4, 4]]())
        CALL_SUBTEST(5, householder[Matrix[Float64, Dynamic, Dynamic]](MatrixXd(internal.random[Int](1, EIGEN_TEST_MAX_SIZE), internal.random[Int](1, EIGEN_TEST_MAX_SIZE))))
        CALL_SUBTEST(6, householder[Matrix[Complex[Float32], Dynamic, Dynamic]](MatrixXcf(internal.random[Int](1, EIGEN_TEST_MAX_SIZE), internal.random[Int](1, EIGEN_TEST_MAX_SIZE))))
        CALL_SUBTEST(7, householder[Matrix[Float32, Dynamic, Dynamic]](MatrixXf(internal.random[Int](1, EIGEN_TEST_MAX_SIZE), internal.random[Int](1, EIGEN_TEST_MAX_SIZE))))
        CALL_SUBTEST(8, householder[Matrix[Float64, 1, 1]]())