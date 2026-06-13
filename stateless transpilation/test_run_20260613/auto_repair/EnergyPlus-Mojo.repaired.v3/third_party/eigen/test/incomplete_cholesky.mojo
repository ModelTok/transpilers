from sparse_solver import *
from Eigen.IterativeLinearSolvers import *
from unsupported.Eigen.IterativeSolvers import *

def test_incomplete_cholesky_T[T: AnyType, I: AnyType]():
    alias SparseMatrixType = SparseMatrix[T, 0, I]
    var cg_illt_lower_amd: ConjugateGradient[SparseMatrixType, Lower, IncompleteCholesky[T, Lower, AMDOrdering[I]]]
    var cg_illt_lower_nat: ConjugateGradient[SparseMatrixType, Lower, IncompleteCholesky[T, Lower, NaturalOrdering[I]]]
    var cg_illt_upper_amd: ConjugateGradient[SparseMatrixType, Upper, IncompleteCholesky[T, Upper, AMDOrdering[I]]]
    var cg_illt_upper_nat: ConjugateGradient[SparseMatrixType, Upper, IncompleteCholesky[T, Upper, NaturalOrdering[I]]]
    var cg_illt_uplo_amd: ConjugateGradient[SparseMatrixType, Upper|Lower, IncompleteCholesky[T, Lower, AMDOrdering[I]]]
    CALL_SUBTEST(check_sparse_spd_solving(cg_illt_lower_amd))
    CALL_SUBTEST(check_sparse_spd_solving(cg_illt_lower_nat))
    CALL_SUBTEST(check_sparse_spd_solving(cg_illt_upper_amd))
    CALL_SUBTEST(check_sparse_spd_solving(cg_illt_upper_nat))
    CALL_SUBTEST(check_sparse_spd_solving(cg_illt_uplo_amd))

def test_incomplete_cholesky():
    CALL_SUBTEST_1(test_incomplete_cholesky_T[float64, int]())
    CALL_SUBTEST_2(test_incomplete_cholesky_T[complex[float64], int]())
    CALL_SUBTEST_3(test_incomplete_cholesky_T[float64, long int]())
    #ifdef EIGEN_TEST_PART_1
    for N in range(1, 20):
        var b: Eigen.MatrixXd = Eigen.MatrixXd(N, N)
        b.setOnes()
        var m: Eigen.SparseMatrix[float64] = Eigen.SparseMatrix[float64](N, N)
        m.reserve(Eigen.VectorXi.Constant(N, 4))
        for i in range(N):
            m.insert(i, i) = 1
            m.coeffRef(i, i / 2) = 2
            m.coeffRef(i, i / 3) = 2
            m.coeffRef(i, i / 4) = 2
        var A: Eigen.SparseMatrix[float64]
        A = m * m.transpose()
        var solver: Eigen.ConjugateGradient[Eigen.SparseMatrix[float64], Eigen.Lower | Eigen.Upper, Eigen.IncompleteCholesky[float64]](A)
        VERIFY(solver.preconditioner().info() == Eigen.Success)
        VERIFY(solver.info() == Eigen.Success)
    #endif