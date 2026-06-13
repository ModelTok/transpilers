from sparse import initSparse, ForceNonZeroDiag
from Eigen import SparseMatrix, Matrix, DenseVector, SparseQR, COLAMDOrdering, internal, eigen_assert
from Eigen.Core import VERIFY_IS_EQUAL, VERIFY_IS_APPROX, ColPivHouseholderQR, Success, Dynamic
from stdlib import Random, max, exit

def generate_sparse_rectangular_problem[MatrixType: AnyType, DenseMat: AnyType](A: MatrixType, dA: DenseMat, maxRows: Int = 300, maxCols: Int = 150) -> Int:
    eigen_assert(maxRows >= maxCols)
    alias Scalar = MatrixType.Scalar
    var rows = internal.random[Int](1, maxRows)
    var cols = internal.random[Int](1, maxCols)
    var density = (max)(8.0 / (rows * cols), 0.01)
    A.resize(rows, cols)
    dA.resize(rows, cols)
    initSparse[Scalar](density, dA, A, ForceNonZeroDiag)
    A.makeCompressed()
    var nop = internal.random[Int](0, internal.random[Float64](0.0, 1.0) > 0.5 ? cols // 2 : 0)
    for k in range(nop):
        var j0 = internal.random[Int](0, cols - 1)
        var j1 = internal.random[Int](0, cols - 1)
        var s = internal.random[Scalar]()
        A.col(j0) = s * A.col(j1)
        dA.col(j0) = s * dA.col(j1)
    return rows

def test_sparseqr_scalar[Scalar: AnyType]():
    alias MatrixType = SparseMatrix[Scalar, ColMajor]
    alias DenseMat = Matrix[Scalar, Dynamic, Dynamic]
    alias DenseVector = Matrix[Scalar, Dynamic, 1]
    var A: MatrixType
    var dA: DenseMat
    var refX: DenseVector
    var x: DenseVector
    var b: DenseVector
    var solver: SparseQR[MatrixType, COLAMDOrdering[Int]]
    generate_sparse_rectangular_problem[MatrixType, DenseMat](A, dA)
    b = dA * DenseVector.Random(A.cols())
    solver.compute(A)
    VERIFY_IS_EQUAL(solver.matrixQ().rows(), A.rows())
    VERIFY_IS_EQUAL(solver.matrixQ().cols(), A.rows())
    VERIFY_IS_EQUAL(solver.matrixR().rows(), A.rows())
    VERIFY_IS_EQUAL(solver.matrixR().cols(), A.cols())
    var recoveredA: DenseMat = solver.matrixQ() * DenseMat(solver.matrixR().template triangularView[Upper]()) * solver.colsPermutation().transpose()
    VERIFY_IS_EQUAL(recoveredA.rows(), A.rows())
    VERIFY_IS_EQUAL(recoveredA.cols(), A.cols())
    if solver.rank() == A.cols():
        VERIFY_IS_APPROX(A, recoveredA)
    if internal.random[Float32](0.0, 1.0) > 0.5:
        solver.factorize(A)  # this checks that calling analyzePattern is not needed if the pattern do not change.
    if solver.info() != Success:
        std.cerr.print("sparse QR factorization failed")
        exit(0)
        return
    x = solver.solve(b)
    if solver.info() != Success:
        std.cerr.print("sparse QR factorization failed")
        exit(0)
        return
    VERIFY_IS_APPROX(A * x, b)
    var dqr: ColPivHouseholderQR[DenseMat](dA)
    refX = dqr.solve(b)
    VERIFY_IS_EQUAL(dqr.rank(), solver.rank())
    if solver.rank() == A.cols():  # full rank
        VERIFY_IS_APPROX(x, refX)
    var Q: MatrixType
    var QtQ: MatrixType
    var idM: MatrixType
    Q = solver.matrixQ()
    QtQ = Q * Q.adjoint()
    idM.resize(Q.rows(), Q.rows())
    idM.setIdentity()
    VERIFY(idM.isApprox(QtQ))
    var dQ: DenseMat
    dQ = solver.matrixQ()
    VERIFY_IS_APPROX(Q, dQ)

def test_sparseqr():
    for i in range(g_repeat):
        CALL_SUBTEST_1(test_sparseqr_scalar[Float64]())
        CALL_SUBTEST_2(test_sparseqr_scalar[Complex[Float64]]())