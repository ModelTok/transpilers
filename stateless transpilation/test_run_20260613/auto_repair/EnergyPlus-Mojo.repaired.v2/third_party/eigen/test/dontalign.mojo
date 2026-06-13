# if defined EIGEN_TEST_PART_1 || defined EIGEN_TEST_PART_2 || defined EIGEN_TEST_PART_3 || defined EIGEN_TEST_PART_4
# define EIGEN_DONT_ALIGN
# elif defined EIGEN_TEST_PART_5 || defined EIGEN_TEST_PART_6 || defined EIGEN_TEST_PART_7 || defined EIGEN_TEST_PART_8
# define EIGEN_DONT_ALIGN_STATICALLY
# endif
from main import *
from Eigen import *

def dontalign[MatrixType: AnyType](m: MatrixType):
    alias Scalar = MatrixType.Scalar
    alias VectorType = Matrix[Scalar, MatrixType.RowsAtCompileTime, 1]
    alias SquareMatrixType = Matrix[Scalar, MatrixType.RowsAtCompileTime, MatrixType.RowsAtCompileTime]
    var rows = m.rows()
    var cols = m.cols()
    var a = MatrixType.Random(rows, cols)
    var square = SquareMatrixType.Random(rows, rows)
    var v = VectorType.Random(rows)
    VERIFY_IS_APPROX(v, square * square.colPivHouseholderQr().solve(v))
    square = square.inverse().eval()
    a = square * a
    square = square * square
    v = square * v
    v = a.adjoint() * v
    VERIFY(square.determinant() != Scalar(0))
    var array = internal.aligned_new[Scalar](rows)
    v = VectorType.MapAligned(array, rows)
    internal.aligned_delete(array, rows)

def test_dontalign():
# if defined EIGEN_TEST_PART_1 || defined EIGEN_TEST_PART_5
    dontalign(Matrix3d())
    dontalign(Matrix4f())
# elif defined EIGEN_TEST_PART_2 || defined EIGEN_TEST_PART_6
    dontalign(Matrix3cd())
    dontalign(Matrix4cf())
# elif defined EIGEN_TEST_PART_3 || defined EIGEN_TEST_PART_7
    dontalign(Matrix[float32, 32, 32]())
    dontalign(Matrix[complex[float32], 32, 32]())
# elif defined EIGEN_TEST_PART_4 || defined EIGEN_TEST_PART_8
    dontalign(MatrixXd(32, 32))
    dontalign(MatrixXcf(32, 32))
# endif