from ......test.sparse_solver import *
from Eigen.src.IterativeSolvers.DGMRES import *

def test_dgmres_T[T: AnyType]():
    var dgmres_colmajor_diag: DGMRES[SparseMatrix[T], DiagonalPreconditioner[T]]
    var dgmres_colmajor_I: DGMRES[SparseMatrix[T], IdentityPreconditioner]
    var dgmres_colmajor_ilut: DGMRES[SparseMatrix[T], IncompleteLUT[T]]
    CALL_SUBTEST(check_sparse_square_solving(dgmres_colmajor_diag))
    CALL_SUBTEST(check_sparse_square_solving(dgmres_colmajor_ilut))

def test_dgmres():
    CALL_SUBTEST_1(test_dgmres_T[Float64]())
    CALL_SUBTEST_2(test_dgmres_T[ComplexFloat64]())