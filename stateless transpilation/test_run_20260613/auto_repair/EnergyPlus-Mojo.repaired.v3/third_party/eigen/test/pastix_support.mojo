#define EIGEN_NO_DEBUG_SMALL_PRODUCT_BLOCKS
#include "sparse_solver.h"
#include <Eigen/PaStiXSupport>
#include <unsupported/Eigen/SparseExtra>
template<T> def test_pastix_T()
{
  PastixLLT< SparseMatrix<T, ColMajor>, Eigen::Lower > pastix_llt_lower;
  PastixLDLT< SparseMatrix<T, ColMajor>, Eigen::Lower > pastix_ldlt_lower;
  PastixLLT< SparseMatrix<T, ColMajor>, Eigen::Upper > pastix_llt_upper;
  PastixLDLT< SparseMatrix<T, ColMajor>, Eigen::Upper > pastix_ldlt_upper;
  PastixLU< SparseMatrix<T, ColMajor> > pastix_lu;
  check_sparse_spd_solving(pastix_llt_lower);
  check_sparse_spd_solving(pastix_ldlt_lower);
  check_sparse_spd_solving(pastix_llt_upper);
  check_sparse_spd_solving(pastix_ldlt_upper);
  check_sparse_square_solving(pastix_lu);
  pastix_llt_lower.iparm();
  pastix_llt_lower.dparm();
  pastix_ldlt_lower.iparm();
  pastix_ldlt_lower.dparm();
  pastix_lu.iparm();
  pastix_lu.dparm();
}
template<T> def test_pastix_T_LU()
{
  PastixLU< SparseMatrix<T, ColMajor> > pastix_lu;
  check_sparse_square_solving(pastix_lu);
}
def test_pastix_support()
{
  CALL_SUBTEST_1(test_pastix_T[float]());
  CALL_SUBTEST_2(test_pastix_T[double]());
  CALL_SUBTEST_3( (test_pastix_T_LU[complex[float]]()) );
  CALL_SUBTEST_4(test_pastix_T_LU[complex[double]]());
}