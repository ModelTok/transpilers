from math import sqrt
from ......test.sparse_solver import check_sparse_spd_solving
from Eigen.IterativeSolvers import MINRES, SparseMatrix, Lower, Upper, IdentityPreconditioner, DiagonalPreconditioner

def test_minres_T[T: AnyType]():
    var minres_colmajor_lower_I: MINRES[SparseMatrix[T], Lower, IdentityPreconditioner]
    var minres_colmajor_upper_I: MINRES[SparseMatrix[T], Upper, IdentityPreconditioner]
    var minres_colmajor_lower_diag: MINRES[SparseMatrix[T], Lower, DiagonalPreconditioner[T]]
    var minres_colmajor_upper_diag: MINRES[SparseMatrix[T], Upper, DiagonalPreconditioner[T]]
    var minres_colmajor_uplo_diag: MINRES[SparseMatrix[T], Lower | Upper, DiagonalPreconditioner[T]]
    CALL_SUBTEST(check_sparse_spd_solving(minres_colmajor_lower_I))
    CALL_SUBTEST(check_sparse_spd_solving(minres_colmajor_upper_I))
    CALL_SUBTEST(check_sparse_spd_solving(minres_colmajor_lower_diag))
    CALL_SUBTEST(check_sparse_spd_solving(minres_colmajor_upper_diag))
    CALL_SUBTEST(check_sparse_spd_solving(minres_colmajor_uplo_diag))

def test_minres():
    CALL_SUBTEST_1(test_minres_T[Float64]())