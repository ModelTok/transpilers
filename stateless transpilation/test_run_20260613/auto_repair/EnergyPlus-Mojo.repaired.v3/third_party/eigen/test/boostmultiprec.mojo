from cholesky import cholesky
from lu import lu_non_invertible, lu_invertible
from qr import qr, qr_invertible
from qr_colpivoting import qr, cod
from qr_fullpivoting import qr, qr_invertible
from eigensolver_selfadjoint import selfadjointeigensolver
from eigensolver_generic import eigensolver
from eigensolver_generalized_real import generalized_eigensolver_real
from jacobisvd import jacobisvd
from bdcsvd import bdcsvd

from sys import int as cpp_int
from math import sqrt, abs, fabs, fmax, isfinite, isnan, isinf, copysign, hypot
from complex import complex
from io import StringIO
from eigen import *
from boost.multiprecision import cpp_dec_float, number, et_on
from boost.multiprecision.detail import expression
from boost.math import special_functions, complex as boost_math_complex

alias mp = boost.multiprecision
alias Real = mp.number[mp.cpp_dec_float[100], mp.et_on]

struct NumTraits_Real(GenericNumTraits[Real]):
    @staticmethod
    def dummy_precision() -> Real:
        return Real(1e-50)

struct NumTraits_expression[T1: AnyType, T2: AnyType, T3: AnyType, T4: AnyType, T5: AnyType](NumTraits_Real):

def test_precision[Real]() -> Real:
    return Real(1e-50)

struct cast_impl_Real_NewType[NewType: AnyType]:
    @staticmethod
    def run(x: Real) -> NewType:
        return x.convert_to[NewType]()

struct cast_impl_Real_complex_Real:
    @staticmethod
    def run(x: Real) -> complex[Real]:
        return complex[Real](x)

def fabs(a: Real) -> Real:
    return abs(a)

def fmax(a: Real, b: Real) -> Real:
    return max(a, b)

def test_isMuchSmallerThan(a: Real, b: Real) -> bool:
    return internal.isMuchSmallerThan(a, b, test_precision[Real]())

def test_isApprox(a: Real, b: Real) -> bool:
    return internal.isApprox(a, b, test_precision[Real]())

def test_isApproxOrLessThan(a: Real, b: Real) -> bool:
    return internal.isApproxOrLessThan(a, b, test_precision[Real]())

def get_test_precision(a: Real) -> Real:
    return test_precision[Real]()

def test_relative_error(a: Real, b: Real) -> Real:
    return sqrt(abs2[Real](a - b) / numext.mini[Real](abs2(a), abs2(b)))

def test_boostmultiprec():
    alias Mat = Matrix[Real, Dynamic, Dynamic]
    alias MatC = Matrix[complex[Real], Dynamic, Dynamic]
    print("NumTraits<Real>::epsilon()         = ", NumTraits_Real.epsilon())
    print("NumTraits<Real>::dummy_precision() = ", NumTraits_Real.dummy_precision())
    print("NumTraits<Real>::lowest()          = ", NumTraits_Real.lowest())
    print("NumTraits<Real>::highest()         = ", NumTraits_Real.highest())
    print("NumTraits<Real>::digits10()        = ", NumTraits_Real.digits10())
    {
        var A = Mat(10, 10)
        A.setRandom()
        var ss = StringIO()
        ss.write(str(A))
    }
    {
        var A = MatC(10, 10)
        A.setRandom()
        var ss = StringIO()
        ss.write(str(A))
    }
    for i in range(g_repeat):
        var s = internal.random[cpp_int](1, EIGEN_TEST_MAX_SIZE)
        CALL_SUBTEST_1(cholesky(Mat(s, s)))
        CALL_SUBTEST_2(lu_non_invertible[Mat]())
        CALL_SUBTEST_2(lu_invertible[Mat]())
        CALL_SUBTEST_2(lu_non_invertible[MatC]())
        CALL_SUBTEST_2(lu_invertible[MatC]())
        CALL_SUBTEST_3(qr(Mat(internal.random[cpp_int](1, EIGEN_TEST_MAX_SIZE), internal.random[cpp_int](1, EIGEN_TEST_MAX_SIZE))))
        CALL_SUBTEST_3(qr_invertible[Mat]())
        CALL_SUBTEST_4(qr[Mat]())
        CALL_SUBTEST_4(cod[Mat]())
        CALL_SUBTEST_4(qr_invertible[Mat]())
        CALL_SUBTEST_5(qr[Mat]())
        CALL_SUBTEST_5(qr_invertible[Mat]())
        CALL_SUBTEST_6(selfadjointeigensolver(Mat(s, s)))
        CALL_SUBTEST_7(eigensolver(Mat(s, s)))
        CALL_SUBTEST_8(generalized_eigensolver_real(Mat(s, s)))
        TEST_SET_BUT_UNUSED_VARIABLE(s)
    CALL_SUBTEST_9((jacobisvd(Mat(internal.random[cpp_int](EIGEN_TEST_MAX_SIZE / 4, EIGEN_TEST_MAX_SIZE), internal.random[cpp_int](EIGEN_TEST_MAX_SIZE / 4, EIGEN_TEST_MAX_SIZE / 2)))))
    CALL_SUBTEST_10((bdcsvd(Mat(internal.random[cpp_int](EIGEN_TEST_MAX_SIZE / 4, EIGEN_TEST_MAX_SIZE), internal.random[cpp_int](EIGEN_TEST_MAX_SIZE / 4, EIGEN_TEST_MAX_SIZE / 2)))))