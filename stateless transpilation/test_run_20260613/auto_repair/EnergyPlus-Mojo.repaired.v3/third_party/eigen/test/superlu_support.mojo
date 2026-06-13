// #define EIGEN_NO_DEBUG_SMALL_PRODUCT_BLOCKS
from sparse_solver import check_sparse_square_solving, check_sparse_square_determinant
from Eigen.SparseMatrix import SparseMatrix
from Eigen.SuperLUSupport import SuperLU

def CALL_SUBTEST_1[T](val: T) -> T:
    return val

def CALL_SUBTEST_2[T](val: T) -> T:
    return val

def test_superlu_support():
    let superlu_double_colmajor = SuperLU[SparseMatrix[Float64]]()
    let superlu_cplxdouble_colmajor = SuperLU[SparseMatrix[Complex[Float64]]]()
    CALL_SUBTEST_1(check_sparse_square_solving(superlu_double_colmajor))
    CALL_SUBTEST_2(check_sparse_square_solving(superlu_cplxdouble_colmajor))
    CALL_SUBTEST_1(check_sparse_square_determinant(superlu_double_colmajor))
    CALL_SUBTEST_2(check_sparse_square_determinant(superlu_cplxdouble_colmajor))