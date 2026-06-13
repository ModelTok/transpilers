from sparse_solver import *
from Eigen.IterativeLinearSolvers import *

def test_bicgstab_T[T: AnyType, I: AnyType]():
    var bicgstab_colmajor_diag: BiCGSTAB[SparseMatrix[T, 0, I], DiagonalPreconditioner[T]]
    var bicgstab_colmajor_I: BiCGSTAB[SparseMatrix[T, 0, I], IdentityPreconditioner]
    var bicgstab_colmajor_ilut: BiCGSTAB[SparseMatrix[T, 0, I], IncompleteLUT[T, I]]
    bicgstab_colmajor_diag.setTolerance(NumTraits[T].epsilon() * 4)
    bicgstab_colmajor_ilut.setTolerance(NumTraits[T].epsilon() * 4)
    CALL_SUBTEST(check_sparse_square_solving(bicgstab_colmajor_diag))
    CALL_SUBTEST(check_sparse_square_solving(bicgstab_colmajor_ilut))

def test_bicgstab():
    CALL_SUBTEST_1(test_bicgstab_T[float64, int]())
    CALL_SUBTEST_2(test_bicgstab_T[complex[float64], int]())
    CALL_SUBTEST_3(test_bicgstab_T[float64, long int]())