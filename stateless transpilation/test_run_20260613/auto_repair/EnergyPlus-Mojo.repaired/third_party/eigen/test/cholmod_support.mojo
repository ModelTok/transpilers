#define EIGEN_NO_DEBUG_SMALL_PRODUCT_BLOCKS
#include "sparse_solver.h"
#include <Eigen/CholmodSupport>
template<T> def test_cholmod_T()
{
  CholmodDecomposition[SparseMatrix[T], Lower] g_chol_colmajor_lower; g_chol_colmajor_lower.setMode(CholmodSupernodalLLt);
  CholmodDecomposition[SparseMatrix[T], Upper] g_chol_colmajor_upper; g_chol_colmajor_upper.setMode(CholmodSupernodalLLt);
  CholmodDecomposition[SparseMatrix[T], Lower] g_llt_colmajor_lower;  g_llt_colmajor_lower.setMode(CholmodSimplicialLLt);
  CholmodDecomposition[SparseMatrix[T], Upper] g_llt_colmajor_upper;  g_llt_colmajor_upper.setMode(CholmodSimplicialLLt);
  CholmodDecomposition[SparseMatrix[T], Lower] g_ldlt_colmajor_lower; g_ldlt_colmajor_lower.setMode(CholmodLDLt);
  CholmodDecomposition[SparseMatrix[T], Upper] g_ldlt_colmajor_upper; g_ldlt_colmajor_upper.setMode(CholmodLDLt);
  CholmodSupernodalLLT[SparseMatrix[T], Lower] chol_colmajor_lower;
  CholmodSupernodalLLT[SparseMatrix[T], Upper] chol_colmajor_upper;
  CholmodSimplicialLLT[SparseMatrix[T], Lower] llt_colmajor_lower;
  CholmodSimplicialLLT[SparseMatrix[T], Upper] llt_colmajor_upper;
  CholmodSimplicialLDLT[SparseMatrix[T], Lower] ldlt_colmajor_lower;
  CholmodSimplicialLDLT[SparseMatrix[T], Upper] ldlt_colmajor_upper;
  check_sparse_spd_solving(g_chol_colmajor_lower);
  check_sparse_spd_solving(g_chol_colmajor_upper);
  check_sparse_spd_solving(g_llt_colmajor_lower);
  check_sparse_spd_solving(g_llt_colmajor_upper);
  check_sparse_spd_solving(g_ldlt_colmajor_lower);
  check_sparse_spd_solving(g_ldlt_colmajor_upper);
  check_sparse_spd_solving(chol_colmajor_lower);
  check_sparse_spd_solving(chol_colmajor_upper);
  check_sparse_spd_solving(llt_colmajor_lower);
  check_sparse_spd_solving(llt_colmajor_upper);
  check_sparse_spd_solving(ldlt_colmajor_lower);
  check_sparse_spd_solving(ldlt_colmajor_upper);
  check_sparse_spd_determinant(chol_colmajor_lower);
  check_sparse_spd_determinant(chol_colmajor_upper);
  check_sparse_spd_determinant(llt_colmajor_lower);
  check_sparse_spd_determinant(llt_colmajor_upper);
  check_sparse_spd_determinant(ldlt_colmajor_lower);
  check_sparse_spd_determinant(ldlt_colmajor_upper);
}
def test_cholmod_support()
{
  CALL_SUBTEST_1(test_cholmod_T[Float64]());
  CALL_SUBTEST_2(test_cholmod_T[ComplexFloat64]());
}