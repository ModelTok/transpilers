from sparse_solver import check_sparse_square_solving, check_sparse_leastsquare_solving, CALL_SUBTEST, CALL_SUBTEST_1, CALL_SUBTEST_2
from Eigen import SparseMatrix, LeastSquaresConjugateGradient, IdentityPreconditioner, RowMajor

def test_lscg_T[T: AnyType]():
  var lscg_colmajor_diag = LeastSquaresConjugateGradient[SparseMatrix[T]]()
  var lscg_colmajor_I = LeastSquaresConjugateGradient[SparseMatrix[T], IdentityPreconditioner]()
  var lscg_rowmajor_diag = LeastSquaresConjugateGradient[SparseMatrix[T, RowMajor]]()
  var lscg_rowmajor_I = LeastSquaresConjugateGradient[SparseMatrix[T, RowMajor], IdentityPreconditioner]()
  CALL_SUBTEST( check_sparse_square_solving(lscg_colmajor_diag)  )
  CALL_SUBTEST( check_sparse_square_solving(lscg_colmajor_I)     )
  CALL_SUBTEST( check_sparse_leastsquare_solving(lscg_colmajor_diag)  )
  CALL_SUBTEST( check_sparse_leastsquare_solving(lscg_colmajor_I)     )
  CALL_SUBTEST( check_sparse_square_solving(lscg_rowmajor_diag)  )
  CALL_SUBTEST( check_sparse_square_solving(lscg_rowmajor_I)     )
  CALL_SUBTEST( check_sparse_leastsquare_solving(lscg_rowmajor_diag)  )
  CALL_SUBTEST( check_sparse_leastsquare_solving(lscg_rowmajor_I)     )

def test_lscg():
  CALL_SUBTEST_1(test_lscg_T[Float64]())
  CALL_SUBTEST_2(test_lscg_T[Complex[Float64]]())