from main import VERIFY_IS_APPROX, VERIFY_IS_MUCH_SMALLER_THAN, VERIFY, VERIFY_IS_NOT_APPROX, CALL_SUBTEST_1, CALL_SUBTEST_2, CALL_SUBTEST_3, CALL_SUBTEST_4, CALL_SUBTEST_5, CALL_SUBTEST_6, g_repeat, test_precision
from internal import random, scalar_sum_op, global_math_functions_filtering_base, is_same
from numext import real, imag, abs2
from math import acos, sqrt, exp, log, log10, log1p, sin, cos, tan, asin, acos, atan, sinh, cosh, tanh, round, floor, ceil, isnan, isinf, isfinite, pow, sign, inverse, square, cube, rsqrt, abs, arg
from sys import float_info

def array[ArrayType: AnyType](m: ArrayType):
    type Scalar = ArrayType.element_type
    type RealScalar = ArrayType.real_element_type
    type ColVectorType = Array[Scalar, ArrayType.rows_at_compile_time, 1]
    type RowVectorType = Array[Scalar, 1, ArrayType.cols_at_compile_time]
    var rows = m.rows()
    var cols = m.cols()
    var m1 = ArrayType.random(rows, cols)
    var m2 = ArrayType.random(rows, cols)
    var m3 = ArrayType(rows, cols)
    var m4 = m1  # copy constructor
    VERIFY_IS_APPROX(m1, m4)
    var cv1 = ColVectorType.random(rows)
    var rv1 = RowVectorType.random(cols)
    var s1 = random[Scalar]()
    var s2 = random[Scalar]()
    VERIFY_IS_APPROX(m1 + s1, s1 + m1)
    VERIFY_IS_APPROX(m1 + s1, ArrayType.constant(rows, cols, s1) + m1)
    VERIFY_IS_APPROX(s1 - m1, (-m1) + s1)
    VERIFY_IS_APPROX(m1 - s1, m1 - ArrayType.constant(rows, cols, s1))
    VERIFY_IS_APPROX(s1 - m1, ArrayType.constant(rows, cols, s1) - m1)
    VERIFY_IS_APPROX((m1 * Scalar(2)) - s2, (m1 + m1) - ArrayType.constant(rows, cols, s2))
    m3 = m1
    m3 += s2
    VERIFY_IS_APPROX(m3, m1 + s2)
    m3 = m1
    m3 -= s1
    VERIFY_IS_APPROX(m3, m1 - s1)
    m3 = m1
    ArrayType.map(m1.data(), m1.rows(), m1.cols()) -= ArrayType.map(m2.data(), m2.rows(), m2.cols())
    VERIFY_IS_APPROX(m1, m3 - m2)
    m3 = m1
    ArrayType.map(m1.data(), m1.rows(), m1.cols()) += ArrayType.map(m2.data(), m2.rows(), m2.cols())
    VERIFY_IS_APPROX(m1, m3 + m2)
    m3 = m1
    ArrayType.map(m1.data(), m1.rows(), m1.cols()) *= ArrayType.map(m2.data(), m2.rows(), m2.cols())
    VERIFY_IS_APPROX(m1, m3 * m2)
    m3 = m1
    m2 = ArrayType.random(rows, cols)
    m2 = (m2 == 0).select(1, m2)
    ArrayType.map(m1.data(), m1.rows(), m1.cols()) /= ArrayType.map(m2.data(), m2.rows(), m2.cols())
    VERIFY_IS_APPROX(m1, m3 / m2)
    VERIFY_IS_APPROX(m1.abs().colwise().sum().sum(), m1.abs().sum())
    VERIFY_IS_APPROX(m1.abs().rowwise().sum().sum(), m1.abs().sum())
    using std.abs
    VERIFY_IS_MUCH_SMALLER_THAN(abs(m1.colwise().sum().sum() - m1.sum()), m1.abs().sum())
    VERIFY_IS_MUCH_SMALLER_THAN(abs(m1.rowwise().sum().sum() - m1.sum()), m1.abs().sum())
    if not isMuchSmallerThan(abs(m1.sum() - (m1 + m2).sum()), m1.abs().sum(), test_precision[Scalar]()):
        VERIFY_IS_NOT_APPROX(((m1 + m2).rowwise().sum()).sum(), m1.sum())
    VERIFY_IS_APPROX(m1.colwise().sum(), m1.colwise().redux(scalar_sum_op[Scalar, Scalar]()))
    m3 = m1
    VERIFY_IS_APPROX(m3.colwise() += cv1, m1.colwise() + cv1)
    m3 = m1
    VERIFY_IS_APPROX(m3.colwise() -= cv1, m1.colwise() - cv1)
    m3 = m1
    VERIFY_IS_APPROX(m3.rowwise() += rv1, m1.rowwise() + rv1)
    m3 = m1
    VERIFY_IS_APPROX(m3.rowwise() -= rv1, m1.rowwise() - rv1)
    VERIFY_IS_APPROX((m3 = s1), ArrayType.constant(rows, cols, s1))
    VERIFY_IS_APPROX((m3 = 1), ArrayType.constant(rows, cols, 1))
    VERIFY_IS_APPROX((m3.topLeftCorner(rows, cols) = 1), ArrayType.constant(rows, cols, 1))
    type FixedArrayType = Array[Scalar,
                                ArrayType.rows_at_compile_time if ArrayType.rows_at_compile_time != -1 else 2,
                                ArrayType.cols_at_compile_time if ArrayType.cols_at_compile_time != -1 else 2,
                                ArrayType.options]
    var f1 = FixedArrayType(s1)
    VERIFY_IS_APPROX(f1, FixedArrayType.constant(s1))
    var f2 = FixedArrayType(real(s1))
    VERIFY_IS_APPROX(f2, FixedArrayType.constant(real(s1)))
    var f3 = FixedArrayType(int(100) * real(s1))
    VERIFY_IS_APPROX(f3, FixedArrayType.constant(int(100) * real(s1)))
    f1.setRandom()
    var f4 = FixedArrayType(f1.data())
    VERIFY_IS_APPROX(f4, f1)
    VERIFY_IS_APPROX(m1.pow(2), m1.square())
    VERIFY_IS_APPROX(pow(m1, 2), m1.square())
    VERIFY_IS_APPROX(m1.pow(3), m1.cube())
    VERIFY_IS_APPROX(pow(m1, 3), m1.cube())
    VERIFY_IS_APPROX((-m1).pow(3), -m1.cube())
    VERIFY_IS_APPROX(pow(2 * m1, 3), 8 * m1.cube())
    var exponents = ArrayType.constant(rows, cols, RealScalar(2))
    VERIFY_IS_APPROX(pow(m1, exponents), m1.square())
    VERIFY_IS_APPROX(m1.pow(exponents), m1.square())
    VERIFY_IS_APPROX(pow(2 * m1, exponents), 4 * m1.square())
    VERIFY_IS_APPROX((2 * m1).pow(exponents), 4 * m1.square())
    VERIFY_IS_APPROX(pow(m1, 2 * exponents), m1.square().square())
    VERIFY_IS_APPROX(m1.pow(2 * exponents), m1.square().square())
    VERIFY_IS_APPROX(pow(m1(0, 0), exponents), ArrayType.constant(rows, cols, m1(0, 0) * m1(0, 0)))
    type OneDArrayType = Array[Scalar, -1, 1]
    var o1 = OneDArrayType(rows)
    VERIFY(o1.size() == rows)
    var o4 = OneDArrayType(int(rows))
    VERIFY(o4.size() == rows)

def comparisons[ArrayType: AnyType](m: ArrayType):
    using std.abs
    type Scalar = ArrayType.element_type
    type RealScalar = NumTraits[Scalar].Real
    var rows = m.rows()
    var cols = m.cols()
    var r = random[Index](0, rows - 1)
    var c = random[Index](0, cols - 1)
    var m1 = ArrayType.random(rows, cols)
    var m2 = ArrayType.random(rows, cols)
    var m3 = ArrayType(rows, cols)
    var m4 = m1
    m4 = (m4.abs() == Scalar(0)).select(1, m4)
    VERIFY(((m1 + Scalar(1)) > m1).all())
    VERIFY(((m1 - Scalar(1)) < m1).all())
    if rows * cols > 1:
        m3 = m1
        m3(r, c) += 1
        VERIFY(not (m1 < m3).all())
        VERIFY(not (m1 > m3).all())
    VERIFY(not (m1 > m2 and m1 < m2).any())
    VERIFY((m1 <= m2 or m1 >= m2).all())
    VERIFY((m1 != (m1(r, c) + 1)).any())
    VERIFY((m1 > (m1(r, c) - 1)).any())
    VERIFY((m1 < (m1(r, c) + 1)).any())
    VERIFY((m1 == m1(r, c)).any())
    VERIFY(((m1(r, c) + 1) != m1).any())
    VERIFY(((m1(r, c) - 1) < m1).any())
    VERIFY(((m1(r, c) + 1) > m1).any())
    VERIFY((m1(r, c) == m1).any())
    VERIFY_IS_APPROX((m1 < m2).select(m1, m2), m1.cwiseMin(m2))
    VERIFY_IS_APPROX((m1 > m2).select(m1, m2), m1.cwiseMax(m2))
    var mid = (m1.cwiseAbs().minCoeff() + m1.cwiseAbs().maxCoeff()) / Scalar(2)
    for j in range(cols):
        for i in range(rows):
            m3(i, j) = 0 if abs(m1(i, j)) < mid else m1(i, j)
    VERIFY_IS_APPROX((m1.abs() < ArrayType.constant(rows, cols, mid))
                        .select(ArrayType.zero(rows, cols), m1), m3)
    VERIFY_IS_APPROX((m1.abs() < ArrayType.constant(rows, cols, mid))
                        .select(0, m1), m3)
    VERIFY_IS_APPROX((m1.abs() >= ArrayType.constant(rows, cols, mid))
                        .select(m1, 0), m3)
    VERIFY_IS_APPROX((m1.abs() < mid).select(0, m1), m3)
    VERIFY(((m1.abs() + 1) > RealScalar(0.1)).count() == rows * cols)
    VERIFY((m1 < RealScalar(0) and m1 > RealScalar(0)).count() == 0)
    VERIFY((m1 < RealScalar(0) or m1 >= RealScalar(0)).count() == rows * cols)
    var a = m1.abs().mean()
    VERIFY((m1 < -a or m1 > a).count() == (m1.abs() > a).count())
    type ArrayOfIndices = Array[ArrayType.Index, -1, 1]
    VERIFY_IS_APPROX(((m1.abs() + 1) > RealScalar(0.1)).colwise().count(), ArrayOfIndices.constant(cols, rows).transpose())
    VERIFY_IS_APPROX(((m1.abs() + 1) > RealScalar(0.1)).rowwise().count(), ArrayOfIndices.constant(rows, cols))

def array_real[ArrayType: AnyType](m: ArrayType):
    using std.abs
    using std.sqrt
    type Scalar = ArrayType.element_type
    type RealScalar = NumTraits[Scalar].Real
    var rows = m.rows()
    var cols = m.cols()
    var m1 = ArrayType.random(rows, cols)
    var m2 = ArrayType.random(rows, cols)
    var m3 = ArrayType(rows, cols)
    var m4 = m1
    m4 = (m4.abs() == Scalar(0)).select(1, m4)
    var s1 = random[Scalar]()
    VERIFY_IS_APPROX(m1.sin(), sin(m1))
    VERIFY_IS_APPROX(m1.cos(), cos(m1))
    VERIFY_IS_APPROX(m1.tan(), tan(m1))
    VERIFY_IS_APPROX(m1.asin(), asin(m1))
    VERIFY_IS_APPROX(m1.acos(), acos(m1))
    VERIFY_IS_APPROX(m1.atan(), atan(m1))
    VERIFY_IS_APPROX(m1.sinh(), sinh(m1))
    VERIFY_IS_APPROX(m1.cosh(), cosh(m1))
    VERIFY_IS_APPROX(m1.tanh(), tanh(m1))
    VERIFY_IS_APPROX(m1.arg(), arg(m1))
    VERIFY_IS_APPROX(m1.round(), round(m1))
    VERIFY_IS_APPROX(m1.floor(), floor(m1))
    VERIFY_IS_APPROX(m1.ceil(), ceil(m1))
    VERIFY((m1.isNaN() == isnan(m1)).all())
    VERIFY((m1.isInf() == isinf(m1)).all())
    VERIFY((m1.isFinite() == isfinite(m1)).all())
    VERIFY_IS_APPROX(m1.inverse(), inverse(m1))
    VERIFY_IS_APPROX(m1.abs(), abs(m1))
    VERIFY_IS_APPROX(m1.abs2(), abs2(m1))
    VERIFY_IS_APPROX(m1.square(), square(m1))
    VERIFY_IS_APPROX(m1.cube(), cube(m1))
    VERIFY_IS_APPROX(cos(m1 + RealScalar(3) * m2), cos((m1 + RealScalar(3) * m2).eval()))
    VERIFY_IS_APPROX(m1.sign(), sign(m1))
    m3 = m1.abs()
    VERIFY_IS_APPROX(m3.sqrt(), sqrt(abs(m1)))
    VERIFY_IS_APPROX(m3.rsqrt(), Scalar(1) / sqrt(abs(m1)))
    VERIFY_IS_APPROX(rsqrt(m3), Scalar(1) / sqrt(abs(m1)))
    VERIFY_IS_APPROX(m3.log(), log(m3))
    VERIFY_IS_APPROX(m3.log1p(), log1p(m3))
    VERIFY_IS_APPROX(m3.log10(), log10(m3))
    VERIFY((not (m1 > m2) == (m1 <= m2)).all())
    VERIFY_IS_APPROX(sin(m1.asin()), m1)
    VERIFY_IS_APPROX(cos(m1.acos()), m1)
    VERIFY_IS_APPROX(tan(m1.atan()), m1)
    VERIFY_IS_APPROX(sinh(m1), 0.5 * (exp(m1) - exp(-m1)))
    VERIFY_IS_APPROX(cosh(m1), 0.5 * (exp(m1) + exp(-m1)))
    VERIFY_IS_APPROX(tanh(m1), (0.5 * (exp(m1) - exp(-m1))) / (0.5 * (exp(m1) + exp(-m1))))
    VERIFY_IS_APPROX(arg(m1), ((m1 < 0).template cast[Scalar]()) * acos(-1.0))
    VERIFY((round(m1) <= ceil(m1) and round(m1) >= floor(m1)).all())
    VERIFY(isnan((m1 * 0.0) / 0.0).all())
    VERIFY(isinf(m4 / 0.0).all())
    VERIFY((isfinite(m1) and (not isfinite(m1 * 0.0 / 0.0)) and (not isfinite(m4 / 0.0))).all())
    VERIFY_IS_APPROX(inverse(inverse(m1)), m1)
    VERIFY((abs(m1) == m1 or abs(m1) == -m1).all())
    VERIFY_IS_APPROX(m3, sqrt(abs2(m1)))
    VERIFY_IS_APPROX(m1.sign(), -(-m1).sign())
    VERIFY_IS_APPROX(m1 * m1.sign(), m1.abs())
    VERIFY_IS_APPROX(m1.sign() * m1.abs(), m1)
    VERIFY_IS_APPROX(abs2(real(m1)) + abs2(imag(m1)), abs2(m1))
    VERIFY_IS_APPROX(abs2(real(m1)) + abs2(imag(m1)), abs2(m1))
    if not NumTraits[Scalar].IsComplex:
        VERIFY_IS_APPROX(real(m1), m1)
    var smallNumber = NumTraits[Scalar].dummy_precision()
    VERIFY_IS_APPROX((m3 + smallNumber).log(), log(abs(m1) + smallNumber))
    VERIFY_IS_APPROX((m3 + smallNumber + 1).log(), log1p(abs(m1) + smallNumber))
    VERIFY_IS_APPROX(m1.exp() * m2.exp(), exp(m1 + m2))
    VERIFY_IS_APPROX(m1.exp(), exp(m1))
    VERIFY_IS_APPROX(m1.exp() / m2.exp(), (m1 - m2).exp())
    VERIFY_IS_APPROX(m3.pow(RealScalar(0.5)), m3.sqrt())
    VERIFY_IS_APPROX(pow(m3, RealScalar(0.5)), m3.sqrt())
    VERIFY_IS_APPROX(m3.pow(RealScalar(-0.5)), m3.rsqrt())
    VERIFY_IS_APPROX(pow(m3, RealScalar(-0.5)), m3.rsqrt())
    VERIFY_IS_APPROX(log10(m3), log(m3) / log(10))
    var tiny = sqrt(float_info[RealScalar].epsilon)
    s1 += Scalar(tiny)
    m1 += ArrayType.constant(rows, cols, Scalar(tiny))
    VERIFY_IS_APPROX(s1 / m1, s1 * m1.inverse())
    m3 = m1
    m3.transposeInPlace()
    VERIFY_IS_APPROX(m3, m1.transpose())
    m3.transposeInPlace()
    VERIFY_IS_APPROX(m3, m1)

def array_complex[ArrayType: AnyType](m: ArrayType):
    type Scalar = ArrayType.element_type
    type RealScalar = NumTraits[Scalar].Real
    var rows = m.rows()
    var cols = m.cols()
    var m1 = ArrayType.random(rows, cols)
    var m2 = ArrayType(rows, cols)
    var m4 = m1
    m4.real() = (m4.real().abs() == RealScalar(0)).select(RealScalar(1), m4.real())
    m4.imag() = (m4.imag().abs() == RealScalar(0)).select(RealScalar(1), m4.imag())
    var m3 = Array[RealScalar, -1, -1](rows, cols)
    for i in range(m.rows()):
        for j in range(m.cols()):
            m2(i, j) = sqrt(m1(i, j))
    VERIFY_IS_APPROX(m1.sin(), sin(m1))
    VERIFY_IS_APPROX(m1.cos(), cos(m1))
    VERIFY_IS_APPROX(m1.tan(), tan(m1))
    VERIFY_IS_APPROX(m1.sinh(), sinh(m1))
    VERIFY_IS_APPROX(m1.cosh(), cosh(m1))
    VERIFY_IS_APPROX(m1.tanh(), tanh(m1))
    VERIFY_IS_APPROX(m1.arg(), arg(m1))
    VERIFY((m1.isNaN() == isnan(m1)).all())
    VERIFY((m1.isInf() == isinf(m1)).all())
    VERIFY((m1.isFinite() == isfinite(m1)).all())
    VERIFY_IS_APPROX(m1.inverse(), inverse(m1))
    VERIFY_IS_APPROX(m1.log(), log(m1))
    VERIFY_IS_APPROX(m1.log10(), log10(m1))
    VERIFY_IS_APPROX(m1.abs(), abs(m1))
    VERIFY_IS_APPROX(m1.abs2(), abs2(m1))
    VERIFY_IS_APPROX(m1.sqrt(), sqrt(m1))
    VERIFY_IS_APPROX(m1.square(), square(m1))
    VERIFY_IS_APPROX(m1.cube(), cube(m1))
    VERIFY_IS_APPROX(cos(m1 + RealScalar(3) * m2), cos((m1 + RealScalar(3) * m2).eval()))
    VERIFY_IS_APPROX(m1.sign(), sign(m1))
    VERIFY_IS_APPROX(m1.exp() * m2.exp(), exp(m1 + m2))
    VERIFY_IS_APPROX(m1.exp(), exp(m1))
    VERIFY_IS_APPROX(m1.exp() / m2.exp(), (m1 - m2).exp())
    VERIFY_IS_APPROX(sinh(m1), 0.5 * (exp(m1) - exp(-m1)))
    VERIFY_IS_APPROX(cosh(m1), 0.5 * (exp(m1) + exp(-m1)))
    VERIFY_IS_APPROX(tanh(m1), (0.5 * (exp(m1) - exp(-m1))) / (0.5 * (exp(m1) + exp(-m1))))
    for i in range(m.rows()):
        for j in range(m.cols()):
            m3(i, j) = atan2(imag(m1(i, j)), real(m1(i, j)))
    VERIFY_IS_APPROX(arg(m1), m3)
    var zero = Complex[RealScalar](0.0, 0.0)
    VERIFY(isnan(m1 * zero / zero).all())
    #if EIGEN_COMP_MSVC
    #  VERIFY(isinf(m4 / RealScalar(0)).all())
    #else
    #  if EIGEN_COMP_CLANG
    #    if isinf(m4(0,0) / RealScalar(0)):
    #  endif
    #    VERIFY(isinf(m4 / zero).all())
    #  if EIGEN_COMP_CLANG
    #    else:
    #      VERIFY(isinf(m4.real() / zero.real()).all())
    #  endif
    #endif
    # Simplified: assume not MSVC or Clang
    VERIFY(isinf(m4 / zero).all())
    VERIFY((isfinite(m1) and (not isfinite(m1 * zero / zero)) and (not isfinite(m1 / zero))).all())
    VERIFY_IS_APPROX(inverse(inverse(m1)), m1)
    VERIFY_IS_APPROX(conj(m1.conjugate()), m1)
    VERIFY_IS_APPROX(abs(m1), sqrt(square(real(m1)) + square(imag(m1))))
    VERIFY_IS_APPROX(abs(m1), sqrt(abs2(m1)))
    VERIFY_IS_APPROX(log10(m1), log(m1) / log(10))
    VERIFY_IS_APPROX(m1.sign(), -(-m1).sign())
    VERIFY_IS_APPROX(m1.sign() * m1.abs(), m1)
    var s1 = random[Scalar]()
    var tiny = sqrt(float_info[RealScalar].epsilon)
    s1 += Scalar(tiny)
    m1 += ArrayType.constant(rows, cols, Scalar(tiny))
    VERIFY_IS_APPROX(s1 / m1, s1 * m1.inverse())
    m2 = m1
    m2.transposeInPlace()
    VERIFY_IS_APPROX(m2, m1.transpose())
    m2.transposeInPlace()
    VERIFY_IS_APPROX(m2, m1)

def min_max[ArrayType: AnyType](m: ArrayType):
    type Scalar = ArrayType.element_type
    var rows = m.rows()
    var cols = m.cols()
    var m1 = ArrayType.random(rows, cols)
    var maxM1 = m1.maxCoeff()
    var minM1 = m1.minCoeff()
    VERIFY_IS_APPROX(ArrayType.constant(rows, cols, minM1), (m1.min)(ArrayType.constant(rows, cols, minM1)))
    VERIFY_IS_APPROX(m1, (m1.min)(ArrayType.constant(rows, cols, maxM1)))
    VERIFY_IS_APPROX(ArrayType.constant(rows, cols, maxM1), (m1.max)(ArrayType.constant(rows, cols, maxM1)))
    VERIFY_IS_APPROX(m1, (m1.max)(ArrayType.constant(rows, cols, minM1)))
    VERIFY_IS_APPROX(ArrayType.constant(rows, cols, minM1), (m1.min)(minM1))
    VERIFY_IS_APPROX(m1, (m1.min)(maxM1))
    VERIFY_IS_APPROX(ArrayType.constant(rows, cols, maxM1), (m1.max)(maxM1))
    VERIFY_IS_APPROX(m1, (m1.max)(minM1))

def test_array():
    for i in range(g_repeat):
        CALL_SUBTEST_1(array(Array[float32, 1, 1]()))
        CALL_SUBTEST_2(array(Array22f()))
        CALL_SUBTEST_3(array(Array44d()))
        CALL_SUBTEST_4(array(ArrayXXcf(random[int](1, EIGEN_TEST_MAX_SIZE), random[int](1, EIGEN_TEST_MAX_SIZE))))
        CALL_SUBTEST_5(array(ArrayXXf(random[int](1, EIGEN_TEST_MAX_SIZE), random[int](1, EIGEN_TEST_MAX_SIZE))))
        CALL_SUBTEST_6(array(ArrayXXi(random[int](1, EIGEN_TEST_MAX_SIZE), random[int](1, EIGEN_TEST_MAX_SIZE))))
    for i in range(g_repeat):
        CALL_SUBTEST_1(comparisons(Array[float32, 1, 1]()))
        CALL_SUBTEST_2(comparisons(Array22f()))
        CALL_SUBTEST_3(comparisons(Array44d()))
        CALL_SUBTEST_5(comparisons(ArrayXXf(random[int](1, EIGEN_TEST_MAX_SIZE), random[int](1, EIGEN_TEST_MAX_SIZE))))
        CALL_SUBTEST_6(comparisons(ArrayXXi(random[int](1, EIGEN_TEST_MAX_SIZE), random[int](1, EIGEN_TEST_MAX_SIZE))))
    for i in range(g_repeat):
        CALL_SUBTEST_1(min_max(Array[float32, 1, 1]()))
        CALL_SUBTEST_2(min_max(Array22f()))
        CALL_SUBTEST_3(min_max(Array44d()))
        CALL_SUBTEST_5(min_max(ArrayXXf(random[int](1, EIGEN_TEST_MAX_SIZE), random[int](1, EIGEN_TEST_MAX_SIZE))))
        CALL_SUBTEST_6(min_max(ArrayXXi(random[int](1, EIGEN_TEST_MAX_SIZE), random[int](1, EIGEN_TEST_MAX_SIZE))))
    for i in range(g_repeat):
        CALL_SUBTEST_1(array_real(Array[float32, 1, 1]()))
        CALL_SUBTEST_2(array_real(Array22f()))
        CALL_SUBTEST_3(array_real(Array44d()))
        CALL_SUBTEST_5(array_real(ArrayXXf(random[int](1, EIGEN_TEST_MAX_SIZE), random[int](1, EIGEN_TEST_MAX_SIZE))))
    for i in range(g_repeat):
        CALL_SUBTEST_4(array_complex(ArrayXXcf(random[int](1, EIGEN_TEST_MAX_SIZE), random[int](1, EIGEN_TEST_MAX_SIZE))))
    VERIFY((is_same[global_math_functions_filtering_base[int].type, int]()).value)
    VERIFY((is_same[global_math_functions_filtering_base[float32].type, float32]()).value)
    VERIFY((is_same[global_math_functions_filtering_base[Array2i].type, ArrayBase[Array2i]]()).value)
    type Xpr = CwiseUnaryOp[scalar_abs_op[float64], ArrayXd]
    VERIFY((is_same[global_math_functions_filtering_base[Xpr].type, ArrayBase[Xpr]]()).value)