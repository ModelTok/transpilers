from main import *
from Eigen import *

def verifySizeOf[MatrixType: AnyType](arg0: MatrixType):
    alias Scalar = MatrixType.Scalar
    if MatrixType.RowsAtCompileTime != Dynamic and MatrixType.ColsAtCompileTime != Dynamic:
        VERIFY_IS_EQUAL(ptrdiff_t(sizeof(MatrixType)), ptrdiff_t(sizeof(Scalar)) * ptrdiff_t(MatrixType.SizeAtCompileTime))
    else:
        VERIFY_IS_EQUAL(sizeof(MatrixType), sizeof(Scalar*) + 2 * sizeof(MatrixType.Index))

def test_sizeof():
    CALL_SUBTEST(verifySizeOf(Matrix[float32, 1, 1]()))
    CALL_SUBTEST(verifySizeOf(Array[float32, 2, 1]()))
    CALL_SUBTEST(verifySizeOf(Array[float32, 3, 1]()))
    CALL_SUBTEST(verifySizeOf(Array[float32, 4, 1]()))
    CALL_SUBTEST(verifySizeOf(Array[float32, 5, 1]()))
    CALL_SUBTEST(verifySizeOf(Array[float32, 6, 1]()))
    CALL_SUBTEST(verifySizeOf(Array[float32, 7, 1]()))
    CALL_SUBTEST(verifySizeOf(Array[float32, 8, 1]()))
    CALL_SUBTEST(verifySizeOf(Array[float32, 9, 1]()))
    CALL_SUBTEST(verifySizeOf(Array[float32, 10, 1]()))
    CALL_SUBTEST(verifySizeOf(Array[float32, 11, 1]()))
    CALL_SUBTEST(verifySizeOf(Array[float32, 12, 1]()))
    CALL_SUBTEST(verifySizeOf(Vector2d()))
    CALL_SUBTEST(verifySizeOf(Vector4f()))
    CALL_SUBTEST(verifySizeOf(Matrix4d()))
    CALL_SUBTEST(verifySizeOf(Matrix[float64, 4, 2]()))
    CALL_SUBTEST(verifySizeOf(Matrix[bool, 7, 5]()))
    CALL_SUBTEST(verifySizeOf(MatrixXcf(3, 3)))
    CALL_SUBTEST(verifySizeOf(MatrixXi(8, 12)))
    CALL_SUBTEST(verifySizeOf(MatrixXcd(20, 20)))
    CALL_SUBTEST(verifySizeOf(Matrix[float32, 100, 100]()))
    VERIFY(sizeof(Complex[float32]) == 2 * sizeof(float32))
    VERIFY(sizeof(Complex[float64]) == 2 * sizeof(float64))