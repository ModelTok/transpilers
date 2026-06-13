from .. import *
from main import *  // #include "main.h"

def miscMatrices[MatrixType: AnyType](m: MatrixType):
  /* this test covers the following files:
     DiagonalMatrix.h Ones.h
  */
  alias Scalar = MatrixType.Scalar
  alias VectorType = Matrix[Scalar, MatrixType.RowsAtCompileTime, 1]
  var rows: Index = m.rows()
  var cols: Index = m.cols()
  var r: Index = internal.random[Index](0, rows - 1)
  var r2: Index = internal.random[Index](0, rows - 1)
  var c: Index = internal.random[Index](0, cols - 1)

  VERIFY_IS_APPROX(MatrixType.Ones(rows, cols)(r, c), Scalar(1))
  var m1: MatrixType = MatrixType.Ones(rows, cols)
  VERIFY_IS_APPROX(m1(r, c), Scalar(1))
  var v1: VectorType = VectorType.Random(rows)
  v1[0]
  var square: Matrix[Scalar, MatrixType.RowsAtCompileTime, MatrixType.RowsAtCompileTime] = v1.asDiagonal()
  if r == r2:
    VERIFY_IS_APPROX(square(r, r2), v1[r])
  else:
    VERIFY_IS_MUCH_SMALLER_THAN(square(r, r2), Scalar(1))
  square = MatrixType.Zero(rows, rows)
  square.diagonal() = VectorType.Ones(rows)
  VERIFY_IS_APPROX(square, MatrixType.Identity(rows, rows))

def test_miscmatrices():
  for i in range(g_repeat):
    CALL_SUBTEST_1(lambda: miscMatrices[Matrix[Float32, 1, 1]]())
    CALL_SUBTEST_2(lambda: miscMatrices[Matrix[Float64, 4, 4]]())
    CALL_SUBTEST_3(lambda: miscMatrices[MatrixXcf(3, 3)]())
    CALL_SUBTEST_4(lambda: miscMatrices[MatrixXi(8, 12)]())
    CALL_SUBTEST_5(lambda: miscMatrices[MatrixXcd(20, 20)]())