from matrix_functions import *
from math import cos, sin, cosh, sinh, pow, ldexp, abs as fabs
from internal import random as internal_random
from NumTraits import NumTraits

def test2dRotation[T: AnyRegType](tol: T):
    var A: Matrix[2, 2, T]
    var B: Matrix[2, 2, T]
    var C: Matrix[2, 2, T]
    var angle: T
    var c: T
    var s: T
    A = Matrix[2, 2, T](0, 1, -1, 0)
    var Apow = MatrixPower[Matrix[2, 2, T]](A)
    for i in range(0, 21):
        angle = pow(T(10), (i - 10) / T(5.))
        c = cos(angle)
        s = sin(angle)
        B = Matrix[2, 2, T](c, s, -s, c)
        C = Apow(ldexp(angle, 1) / T(math.pi))
        print("test2dRotation: i = " + str(i) + "   error powerm = " + str(relerr(C, B)))
        VERIFY(C.isApprox(B, tol))
    end
end

def test2dHyperbolicRotation[T: AnyRegType](tol: T):
    var A: Matrix[2, 2, complex[T]]
    var B: Matrix[2, 2, complex[T]]
    var C: Matrix[2, 2, complex[T]]
    var angle: T
    var ch: T = cosh(T(1))
    var ish: complex[T] = complex[T](0, sinh(T(1)))
    A = Matrix[2, 2, complex[T]](ch, ish, -ish, ch)
    var Apow = MatrixPower[Matrix[2, 2, complex[T]]](A)
    for i in range(0, 21):
        angle = ldexp(static_cast[T](i - 10), -1)
        ch = cosh(angle)
        ish = complex[T](0, sinh(angle))
        B = Matrix[2, 2, complex[T]](ch, ish, -ish, ch)
        C = Apow(angle)
        print("test2dHyperbolicRotation: i = " + str(i) + "   error powerm = " + str(relerr(C, B)))
        VERIFY(C.isApprox(B, tol))
    end
end

def test3dRotation[T: AnyRegType](tol: T):
    var v: Matrix[3, 1, T]
    var angle: T
    for i in range(0, 21):
        v = Matrix[3, 1, T].Random()
        v.normalize()
        angle = pow(T(10), (i - 10) / T(5.))
        VERIFY(AngleAxis[T](angle, v).matrix().isApprox(AngleAxis[T](1, v).matrix().pow(angle), tol))
    end
end

def testGeneral[MatrixType: AnyRegType](m: MatrixType, tol: MatrixType.RealScalar):
    alias RealScalar = MatrixType.RealScalar
    var m1: MatrixType
    var m2: MatrixType
    var m3: MatrixType
    var m4: MatrixType
    var m5: MatrixType
    var x: RealScalar
    var y: RealScalar
    for i in range(0, g_repeat):
        generateTestMatrix[MatrixType].run(m1, m.rows())
        var mpow = MatrixPower[MatrixType](m1)
        x = internal_random[RealScalar]()
        y = internal_random[RealScalar]()
        m2 = mpow(x)
        m3 = mpow(y)
        m4 = mpow(x + y)
        m5.noalias() = m2 * m3
        VERIFY(m4.isApprox(m5, tol))
        m4 = mpow(x * y)
        m5 = m2.pow(y)
        VERIFY(m4.isApprox(m5, tol))
        m4 = (fabs(x) * m1).pow(y)
        m5 = pow(fabs(x), y) * m3
        VERIFY(m4.isApprox(m5, tol))
    end
end

def testSingular[MatrixType: AnyRegType](m_const: MatrixType, tol: MatrixType.RealScalar):
    var m: MatrixType = m_const
    alias IsComplex = NumTraits[internal.traits[MatrixType].Scalar].IsComplex
    alias TriangularType = internal.conditional[IsComplex, TriangularView[MatrixType, Upper], const MatrixType&].type
    var schur: internal.conditional[IsComplex, ComplexSchur[MatrixType], RealSchur[MatrixType]].type
    var T: MatrixType
    for i in range(0, g_repeat):
        m.setRandom()
        m.col(0).fill(0)
        schur.compute(m)
        T = schur.matrixT()
        var U: MatrixType = schur.matrixU()
        processTriangularMatrix[MatrixType].run(m, T, U)
        var mpow = MatrixPower[MatrixType](m)
        T = T.sqrt()
        VERIFY(mpow(0.5).isApprox(U * (TriangularType(T) * U.adjoint()), tol))
        T = T.sqrt()
        VERIFY(mpow(0.25).isApprox(U * (TriangularType(T) * U.adjoint()), tol))
        T = T.sqrt()
        VERIFY(mpow(0.125).isApprox(U * (TriangularType(T) * U.adjoint()), tol))
    end
end

def testLogThenExp[MatrixType: AnyRegType](m_const: MatrixType, tol: MatrixType.RealScalar):
    var m: MatrixType = m_const
    alias Scalar = MatrixType.Scalar
    var x: Scalar
    for i in range(0, g_repeat):
        generateTestMatrix[MatrixType].run(m, m.rows())
        x = internal_random[Scalar]()
        VERIFY(m.pow(x).isApprox((x * m.log()).exp(), tol))
    end
end

alias Matrix3dRowMajor = Matrix[3, 3, double, RowMajor]
alias Matrix3e = Matrix[3, 3, long double]
alias MatrixXe = Matrix[Dynamic, Dynamic, long double]

def test_matrix_power():
    CALL_SUBTEST_2(test2dRotation[double](1e-13))
    CALL_SUBTEST_1(test2dRotation[float](2e-5))
    CALL_SUBTEST_9(test2dRotation[long double](1e-13))
    CALL_SUBTEST_2(test2dHyperbolicRotation[double](1e-14))
    CALL_SUBTEST_1(test2dHyperbolicRotation[float](1e-5))
    CALL_SUBTEST_9(test2dHyperbolicRotation[long double](1e-14))
    CALL_SUBTEST_10(test3dRotation[double](1e-13))
    CALL_SUBTEST_11(test3dRotation[float](1e-5))
    CALL_SUBTEST_12(test3dRotation[long double](1e-13))
    CALL_SUBTEST_2(testGeneral[Matrix2d](Matrix2d(), 1e-13))
    CALL_SUBTEST_7(testGeneral[Matrix3dRowMajor](Matrix3dRowMajor(), 1e-13))
    CALL_SUBTEST_3(testGeneral[Matrix4cd](Matrix4cd(), 1e-13))
    CALL_SUBTEST_4(testGeneral[MatrixXd(8,8)](MatrixXd(8,8), 2e-12))
    CALL_SUBTEST_1(testGeneral[Matrix2f](Matrix2f(), 1e-4))
    CALL_SUBTEST_5(testGeneral[Matrix3cf](Matrix3cf(), 1e-4))
    CALL_SUBTEST_8(testGeneral[Matrix4f](Matrix4f(), 1e-4))
    CALL_SUBTEST_6(testGeneral[MatrixXf(2,2)](MatrixXf(2,2), 1e-3))
    CALL_SUBTEST_9(testGeneral[MatrixXe(7,7)](MatrixXe(7,7), 1e-13))
    CALL_SUBTEST_10(testGeneral[Matrix3d](Matrix3d(), 1e-13))
    CALL_SUBTEST_11(testGeneral[Matrix3f](Matrix3f(), 1e-4))
    CALL_SUBTEST_12(testGeneral[Matrix3e](Matrix3e(), 1e-13))
    CALL_SUBTEST_2(testSingular[Matrix2d](Matrix2d(), 1e-13))
    CALL_SUBTEST_7(testSingular[Matrix3dRowMajor](Matrix3dRowMajor(), 1e-13))
    CALL_SUBTEST_3(testSingular[Matrix4cd](Matrix4cd(), 1e-13))
    CALL_SUBTEST_4(testSingular[MatrixXd(8,8)](MatrixXd(8,8), 2e-12))
    CALL_SUBTEST_1(testSingular[Matrix2f](Matrix2f(), 1e-4))
    CALL_SUBTEST_5(testSingular[Matrix3cf](Matrix3cf(), 1e-4))
    CALL_SUBTEST_8(testSingular[Matrix4f](Matrix4f(), 1e-4))
    CALL_SUBTEST_6(testSingular[MatrixXf(2,2)](MatrixXf(2,2), 1e-3))
    CALL_SUBTEST_9(testSingular[MatrixXe(7,7)](MatrixXe(7,7), 1e-13))
    CALL_SUBTEST_10(testSingular[Matrix3d](Matrix3d(), 1e-13))
    CALL_SUBTEST_11(testSingular[Matrix3f](Matrix3f(), 1e-4))
    CALL_SUBTEST_12(testSingular[Matrix3e](Matrix3e(), 1e-13))
    CALL_SUBTEST_2(testLogThenExp[Matrix2d](Matrix2d(), 1e-13))
    CALL_SUBTEST_7(testLogThenExp[Matrix3dRowMajor](Matrix3dRowMajor(), 1e-13))
    CALL_SUBTEST_3(testLogThenExp[Matrix4cd](Matrix4cd(), 1e-13))
    CALL_SUBTEST_4(testLogThenExp[MatrixXd(8,8)](MatrixXd(8,8), 2e-12))
    CALL_SUBTEST_1(testLogThenExp[Matrix2f](Matrix2f(), 1e-4))
    CALL_SUBTEST_5(testLogThenExp[Matrix3cf](Matrix3cf(), 1e-4))
    CALL_SUBTEST_8(testLogThenExp[Matrix4f](Matrix4f(), 1e-4))
    CALL_SUBTEST_6(testLogThenExp[MatrixXf(2,2)](MatrixXf(2,2), 1e-3))
    CALL_SUBTEST_9(testLogThenExp[MatrixXe(7,7)](MatrixXe(7,7), 1e-13))
    CALL_SUBTEST_10(testLogThenExp[Matrix3d](Matrix3d(), 1e-13))
    CALL_SUBTEST_11(testLogThenExp[Matrix3f](Matrix3f(), 1e-4))
    CALL_SUBTEST_12(testLogThenExp[Matrix3e](Matrix3e(), 1e-13))
end