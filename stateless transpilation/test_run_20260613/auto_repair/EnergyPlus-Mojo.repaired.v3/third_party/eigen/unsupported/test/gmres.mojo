from ......test.sparse_solver import check_sparse_square_solving
from Eigen.IterativeSolvers import GMRES, SparseMatrix, DiagonalPreconditioner, IdentityPreconditioner, IncompleteLUT

def test_gmres_T[type T]():
    var gmres_colmajor_diag: GMRES[SparseMatrix[T], DiagonalPreconditioner[T]]
    var gmres_colmajor_I: GMRES[SparseMatrix[T], IdentityPreconditioner]
    var gmres_colmajor_ilut: GMRES[SparseMatrix[T], IncompleteLUT[T]]
    check_sparse_square_solving(gmres_colmajor_diag)
    check_sparse_square_solving(gmres_colmajor_ilut)

def test_gmres():
    test_gmres_T[Float64]()
    test_gmres_T[ComplexFloat64]()