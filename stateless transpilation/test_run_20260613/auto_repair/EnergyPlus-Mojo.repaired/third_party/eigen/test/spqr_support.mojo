# define EIGEN_NO_DEBUG_SMALL_PRODUCT_BLOCKS
from sparse import *
from SPQRSupport import SPQR, Success

def generate_sparse_rectangular_problem[MatrixType: AnyType, DenseMat: AnyType](A: MatrixType, dA: DenseMat, maxRows: Int = 300, maxCols: Int = 300) -> Int:
  eigen_assert(maxRows >= maxCols)
  type Scalar = MatrixType.Scalar
  let rows = internal.random[Int](1, maxRows)
  let cols = internal.random[Int](1, rows)
  let density = max(8./(rows*cols), 0.01)
  A.resize(rows, cols)
  dA.resize(rows, cols)
  initSparse[Scalar](density, dA, A, ForceNonZeroDiag)
  A.makeCompressed()
  return rows

def test_spqr_scalar[Scalar: AnyType]():
  type MatrixType = SparseMatrix[Scalar, ColMajor]
  var A: MatrixType
  var dA: Matrix[Scalar, Dynamic, Dynamic]
  type DenseVector = Matrix[Scalar, Dynamic, 1]
  var refX: DenseVector
  var x: DenseVector
  var b: DenseVector
  var solver: SPQR[MatrixType]
  generate_sparse_rectangular_problem[MatrixType, Matrix[Scalar, Dynamic, Dynamic]](A, dA)
  let m = A.rows()
  b = DenseVector.Random(m)
  solver.compute(A)
  if solver.info() != Success:
    cerr("sparse QR factorization failed\n")
    exit(0)
    return
  x = solver.solve(b)
  if solver.info() != Success:
    cerr("sparse QR factorization failed\n")
    exit(0)
    return
  refX = dA.colPivHouseholderQr().solve(b)
  VERIFY(x.isApprox(refX, test_precision[Scalar]()))

def test_spqr_support():
  CALL_SUBTEST_1(test_spqr_scalar[double]())
  CALL_SUBTEST_2(test_spqr_scalar[complex_double]())