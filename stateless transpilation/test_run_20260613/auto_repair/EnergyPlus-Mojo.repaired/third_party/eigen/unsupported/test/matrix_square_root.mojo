from matrix_functions import (
    Matrix3cf,
    MatrixXcd,
    Matrix4f,
    Matrix,
    Dynamic,
    RowMajor,
    generateTestMatrix,
    VERIFY_IS_APPROX,
    g_repeat,
    ComplexFloat,
)

def testMatrixSqrt[MatrixType: AnyType](m: MatrixType):
    var A: MatrixType
    generateTestMatrix[MatrixType].run(A, m.rows())
    var sqrtA: MatrixType = A.sqrt()
    VERIFY_IS_APPROX(sqrtA * sqrtA, A)

def test_matrix_square_root():
    for i in range(g_repeat):
        testMatrixSqrt[Matrix3cf](Matrix3cf())
        testMatrixSqrt[MatrixXcd](MatrixXcd(12, 12))
        testMatrixSqrt[Matrix4f](Matrix4f())
        testMatrixSqrt[Matrix[float64, Dynamic, Dynamic, RowMajor]](Matrix[float64, Dynamic, Dynamic, RowMajor](9, 9))
        testMatrixSqrt[Matrix[float32, 1, 1]](Matrix[float32, 1, 1]())
        testMatrixSqrt[Matrix[ComplexFloat, 1, 1]](Matrix[ComplexFloat, 1, 1]())