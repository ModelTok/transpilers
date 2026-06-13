/* 
   Intel Copyright (C) ....
*/
from sparse_solver import *
from Eigen.PardisoSupport import *

def test_pardiso_T[T: AnyType]():
    var pardiso_llt_lower = PardisoLLT[SparseMatrix[T, RowMajor], Lower]()
    var pardiso_llt_upper = PardisoLLT[SparseMatrix[T, RowMajor], Upper]()
    var pardiso_ldlt_lower = PardisoLDLT[SparseMatrix[T, RowMajor], Lower]()
    var pardiso_ldlt_upper = PardisoLDLT[SparseMatrix[T, RowMajor], Upper]()
    var pardiso_lu = PardisoLU[SparseMatrix[T, RowMajor]]()
    check_sparse_spd_solving(pardiso_llt_lower)
    check_sparse_spd_solving(pardiso_llt_upper)
    check_sparse_spd_solving(pardiso_ldlt_lower)
    check_sparse_spd_solving(pardiso_ldlt_upper)
    check_sparse_square_solving(pardiso_lu)

def test_pardiso_support():
    CALL_SUBTEST_1(test_pardiso_T[float32]())
    CALL_SUBTEST_2(test_pardiso_T[float64]())
    CALL_SUBTEST_3(test_pardiso_T[complex[float32]]())
    CALL_SUBTEST_4(test_pardiso_T[complex[float64]]())