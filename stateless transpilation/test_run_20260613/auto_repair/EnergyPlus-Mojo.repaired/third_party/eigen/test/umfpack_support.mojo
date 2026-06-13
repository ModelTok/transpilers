// #define EIGEN_NO_DEBUG_SMALL_PRODUCT_BLOCKS
from ...Eigen.UmfPackSupport import UmfPackLU, SparseMatrix, ColMajor, RowMajor
from ..sparse_solver import check_sparse_square_solving, check_sparse_square_determinant, CALL_SUBTEST_1, CALL_SUBTEST_2

def test_umfpack_support_T[type T]():
    let umfpack_colmajor = UmfPackLU[SparseMatrix[T, ColMajor]]()
    let umfpack_rowmajor = UmfPackLU[SparseMatrix[T, RowMajor]]()
    check_sparse_square_solving(umfpack_colmajor)
    check_sparse_square_solving(umfpack_rowmajor)
    check_sparse_square_determinant(umfpack_colmajor)
    check_sparse_square_determinant(umfpack_rowmajor)

def test_umfpack_support():
    CALL_SUBTEST_1(test_umfpack_support_T[Float64]())
    CALL_SUBTEST_2(test_umfpack_support_T[ComplexFloat64]())