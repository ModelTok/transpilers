from main import *
from Eigen.SVD import *

def upperbidiag[MatrixType: AnyType](m: MatrixType):
    let rows: MatrixType.Index = m.rows()
    let cols: MatrixType.Index = m.cols()
    type RealMatrixType = Matrix[MatrixType.RealScalar, MatrixType.RowsAtCompileTime, MatrixType.ColsAtCompileTime]
    type TransposeMatrixType = Matrix[MatrixType.Scalar, MatrixType.ColsAtCompileTime, MatrixType.RowsAtCompileTime]
    var a: MatrixType = MatrixType.Random(rows, cols)
    var ubd: internal.UpperBidiagonalization[MatrixType] = internal.UpperBidiagonalization[MatrixType](a)
    var b: RealMatrixType = RealMatrixType(rows, cols)
    b.setZero()
    b.block(0, 0, cols, cols) = ubd.bidiagonal()
    var c: MatrixType = ubd.householderU() * b * ubd.householderV().adjoint()
    VERIFY_IS_APPROX(a, c)
    var d: TransposeMatrixType = ubd.householderV() * b.adjoint() * ubd.householderU().adjoint()
    VERIFY_IS_APPROX(a.adjoint(), d)

def test_upperbidiagonalization():
    for i in range(g_repeat):
        CALL_SUBTEST_1(lambda: upperbidiag[MatrixXf](MatrixXf(3, 3)))
        CALL_SUBTEST_2(lambda: upperbidiag[MatrixXd](MatrixXd(17, 12)))
        CALL_SUBTEST_3(lambda: upperbidiag[MatrixXcf](MatrixXcf(20, 20)))
        CALL_SUBTEST_4(lambda: upperbidiag[Matrix[complex[float64], Dynamic, Dynamic, RowMajor]](Matrix[complex[float64], Dynamic, Dynamic, RowMajor](16, 15)))
        CALL_SUBTEST_5(lambda: upperbidiag[Matrix[float32, 6, 4]](Matrix[float32, 6, 4]()))
        CALL_SUBTEST_6(lambda: upperbidiag[Matrix[float32, 5, 5]](Matrix[float32, 5, 5]()))
        CALL_SUBTEST_7(lambda: upperbidiag[Matrix[float64, 4, 3]](Matrix[float64, 4, 3]()))