from sparse_solver import check_sparse_spd_solving, CALL_SUBTEST, CALL_SUBTEST_1, CALL_SUBTEST_2, CALL_SUBTEST_3
from Eigen.IterativeLinearSolvers import ConjugateGradient, SparseMatrix, Lower, Upper, IdentityPreconditioner

def test_conjugate_gradient_T[T: AnyType, I: AnyType]():
    alias SparseMatrixType = SparseMatrix[T, 0, I]
    var cg_colmajor_lower_diag = ConjugateGradient[SparseMatrixType, Lower]()
    var cg_colmajor_upper_diag = ConjugateGradient[SparseMatrixType, Upper]()
    var cg_colmajor_loup_diag = ConjugateGradient[SparseMatrixType, Lower | Upper]()
    var cg_colmajor_lower_I = ConjugateGradient[SparseMatrixType, Lower, IdentityPreconditioner]()
    var cg_colmajor_upper_I = ConjugateGradient[SparseMatrixType, Upper, IdentityPreconditioner]()
    CALL_SUBTEST(check_sparse_spd_solving(cg_colmajor_lower_diag))
    CALL_SUBTEST(check_sparse_spd_solving(cg_colmajor_upper_diag))
    CALL_SUBTEST(check_sparse_spd_solving(cg_colmajor_loup_diag))
    CALL_SUBTEST(check_sparse_spd_solving(cg_colmajor_lower_I))
    CALL_SUBTEST(check_sparse_spd_solving(cg_colmajor_upper_I))

def test_conjugate_gradient():
    CALL_SUBTEST_1(test_conjugate_gradient_T[Float64, Int32]())
    CALL_SUBTEST_2(test_conjugate_gradient_T[Complex[Float64], Int32]())
    CALL_SUBTEST_3(test_conjugate_gradient_T[Float64, Int64]())