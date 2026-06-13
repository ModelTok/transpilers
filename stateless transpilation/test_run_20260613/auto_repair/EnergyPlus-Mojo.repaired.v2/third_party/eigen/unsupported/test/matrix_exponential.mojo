from matrix_functions import *
from math import exp, cos, sin, cosh, sinh, pow
from complex import Complex
from memory import Pointer
from sys import print as std_cout

def binom(n: Int, k: Int) -> Float64:
    var res: Float64 = 1.0
    for i in range(0, k):
        res = res * Float64(n - k + i + 1) / Float64(i + 1)
    return res

def expfn[T: AnyType](x: T, arg: Int) -> T:
    return exp(x)

def test2dRotation[T: AnyType](tol: Float64):
    var A: Matrix[T, 2, 2]
    var B: Matrix[T, 2, 2]
    var C: Matrix[T, 2, 2]
    var angle: T
    A = Matrix[T, 2, 2](0, 1, -1, 0)
    for i in range(0, 21):
        angle = T(pow(10.0, Float64(i) / 5.0 - 2.0))
        B = Matrix[T, 2, 2](cos(angle), sin(angle), -sin(angle), cos(angle))
        C = (angle * A).matrixFunction(expfn)
        std_cout("test2dRotation: i = ", i, "   error funm = ", relerr(C, B))
        VERIFY(C.isApprox(B, T(tol)))
        C = (angle * A).exp()
        std_cout("   error expm = ", relerr(C, B), "\n")
        VERIFY(C.isApprox(B, T(tol)))

def test2dHyperbolicRotation[T: AnyType](tol: Float64):
    var A: Matrix[Complex[T], 2, 2]
    var B: Matrix[Complex[T], 2, 2]
    var C: Matrix[Complex[T], 2, 2]
    var imagUnit: Complex[T] = Complex[T](0, 1)
    var angle: T
    var ch: T
    var sh: T
    for i in range(0, 21):
        angle = T((Float64(i) - 10.0) / 2.0)
        ch = cosh(angle)
        sh = sinh(angle)
        A = Matrix[Complex[T], 2, 2](0, angle * imagUnit, -angle * imagUnit, 0)
        B = Matrix[Complex[T], 2, 2](ch, sh * imagUnit, -sh * imagUnit, ch)
        C = A.matrixFunction(expfn)
        std_cout("test2dHyperbolicRotation: i = ", i, "   error funm = ", relerr(C, B))
        VERIFY(C.isApprox(B, T(tol)))
        C = A.exp()
        std_cout("   error expm = ", relerr(C, B), "\n")
        VERIFY(C.isApprox(B, T(tol)))

def testPascal[T: AnyType](tol: Float64):
    for size in range(1, 20):
        var A: Matrix[T, Dynamic, Dynamic] = Matrix[T, Dynamic, Dynamic](size, size)
        var B: Matrix[T, Dynamic, Dynamic] = Matrix[T, Dynamic, Dynamic](size, size)
        var C: Matrix[T, Dynamic, Dynamic] = Matrix[T, Dynamic, Dynamic](size, size)
        A.setZero()
        for i in range(0, size - 1):
            A(i + 1, i) = T(i + 1)
        B.setZero()
        for i in range(0, size):
            for j in range(0, i + 1):
                B(i, j) = T(binom(i, j))
        C = A.matrixFunction(expfn)
        std_cout("testPascal: size = ", size, "   error funm = ", relerr(C, B))
        VERIFY(C.isApprox(B, T(tol)))
        C = A.exp()
        std_cout("   error expm = ", relerr(C, B), "\n")
        VERIFY(C.isApprox(B, T(tol)))

def randomTest[MatrixType: AnyType](m: MatrixType, tol: Float64):
    """ this test covers the following files:
     Inverse.h
  """
    var rows: Int = m.rows()
    var cols: Int = m.cols()
    var m1: MatrixType = MatrixType(rows, cols)
    var m2: MatrixType = MatrixType(rows, cols)
    var identity: MatrixType = MatrixType.Identity(rows, cols)
    alias RealScalar = NumTraits[internal.traits[MatrixType].Scalar].Real
    for i in range(0, g_repeat):
        m1 = MatrixType.Random(rows, cols)
        m2 = m1.matrixFunction(expfn) * (-m1).matrixFunction(expfn)
        std_cout("randomTest: error funm = ", relerr(identity, m2))
        VERIFY(identity.isApprox(m2, RealScalar(tol)))
        m2 = m1.exp() * (-m1).exp()
        std_cout("   error expm = ", relerr(identity, m2), "\n")
        VERIFY(identity.isApprox(m2, RealScalar(tol)))

def test_matrix_exponential():
    CALL_SUBTEST_2(test2dRotation[Float64](1e-13))
    CALL_SUBTEST_1(test2dRotation[Float32](2e-5))
    CALL_SUBTEST_8(test2dRotation[Float64](1e-13))
    CALL_SUBTEST_2(test2dHyperbolicRotation[Float64](1e-14))
    CALL_SUBTEST_1(test2dHyperbolicRotation[Float32](1e-5))
    CALL_SUBTEST_8(test2dHyperbolicRotation[Float64](1e-14))
    CALL_SUBTEST_6(testPascal[Float32](1e-6))
    CALL_SUBTEST_5(testPascal[Float64](1e-15))
    CALL_SUBTEST_2(randomTest[Matrix2d](Matrix2d(), 1e-13))
    CALL_SUBTEST_7(randomTest[Matrix[Float64, 3, 3, RowMajor]](Matrix[Float64, 3, 3, RowMajor](), 1e-13))
    CALL_SUBTEST_3(randomTest[Matrix4cd](Matrix4cd(), 1e-13))
    CALL_SUBTEST_4(randomTest[MatrixXd](MatrixXd(8, 8), 1e-13))
    CALL_SUBTEST_1(randomTest[Matrix2f](Matrix2f(), 1e-4))
    CALL_SUBTEST_5(randomTest[Matrix3cf](Matrix3cf(), 1e-4))
    CALL_SUBTEST_1(randomTest[Matrix4f](Matrix4f(), 1e-4))
    CALL_SUBTEST_6(randomTest[MatrixXf](MatrixXf(8, 8), 1e-4))
    CALL_SUBTEST_9(randomTest[Matrix[Float64, Dynamic, Dynamic]](Matrix[Float64, Dynamic, Dynamic](7, 7), 1e-13))