# C++ source: third_party/eigen/unsupported/test/autodiff_scalar.cpp
# Faithful 1:1 translation to Mojo, no refactoring.
# Note: Eigen types (Matrix, AutoDiffScalar, internal) are assumed to be
# available from a hypothetical Mojo Eigen package. Imports below attempt
# to mirror the original include paths.

from third_party.eigen.Eigen import Matrix, AutoDiffScalar, internal
from third_party.eigen.unsupported.Eigen.AutoDiff import noop  # placeholder for AutoDiff header
from math import exp, sin, cos, sinh, cosh, tanh
from random import random as std_random  # for internal::random

# Simulate g_repeat and test macros from main.h (not provided in original)
alias g_repeat: Int = 1

def VERIFY_IS_APPROX(a: F64, b: F64) raises:
    # Simulates Eigen's approximate comparison
    let diff = a - b
    if diff > 1e-6 or diff < -1e-6:
        raise Error("VERIFY_IS_APPROX failed")

def CALL_SUBTEST_1[Scalar: DType](test_fn: fn() raises) raises:
    test_fn()

def CALL_SUBTEST_2[Scalar: DType](test_fn: fn() raises) raises:
    test_fn()

def CALL_SUBTEST_3[Scalar: DType](test_fn: fn() raises) raises:
    test_fn()

def CALL_SUBTEST_4[Scalar: DType](test_fn: fn() raises) raises:
    test_fn()

def CALL_SUBTEST_5[Scalar: DType](test_fn: fn() raises) raises:
    test_fn()

# Original template function check_atan2
def check_atan2[Scalar: DType]() raises:
    typedef Matrix[Scalar, 1, 1] = Deriv1
    typedef AutoDiffScalar[Deriv1] = AD
    var x = AD(internal.random[Scalar](-3.0, 3.0), Deriv1.UnitX())
    using exp  # dropped; use exp directly
    var r: Scalar = exp(internal.random[Scalar](-10, 10))
    var s = sin(x), c = cos(x)
    var res = atan2(r*s, r*c)
    VERIFY_IS_APPROX(res.value(), x.value())
    VERIFY_IS_APPROX(res.derivatives(), x.derivatives())
    res = atan2(r*s+0, r*c+0)
    VERIFY_IS_APPROX(res.value(), x.value())
    VERIFY_IS_APPROX(res.derivatives(), x.derivatives())

def check_hyperbolic_functions[Scalar: DType]() raises:
    using sinh  # dropped; use sinh
    using cosh  # dropped; use cosh
    using tanh  # dropped; use tanh
    typedef Matrix[Scalar, 1, 1] = Deriv1
    typedef AutoDiffScalar[Deriv1] = AD
    var p = Deriv1.Random()
    var val = AD(p.x(), Deriv1.UnitX())
    var cosh_px: Scalar = cosh(p.x())
    var res1 = tanh(val)
    VERIFY_IS_APPROX(res1.value(), tanh(p.x()))
    VERIFY_IS_APPROX(res1.derivatives().x(), Scalar(1.0) / (cosh_px * cosh_px))
    var res2 = sinh(val)
    VERIFY_IS_APPROX(res2.value(), sinh(p.x()))
    VERIFY_IS_APPROX(res2.derivatives().x(), cosh_px)
    var res3 = cosh(val)
    VERIFY_IS_APPROX(res3.value(), cosh_px)
    VERIFY_IS_APPROX(res3.derivatives().x(), sinh(p.x()))
    const sample_point: Scalar = Scalar(1) / Scalar(3)
    val = AD(sample_point, Deriv1.UnitX())
    res1 = tanh(val)
    VERIFY_IS_APPROX(res1.derivatives().x(), Scalar(0.896629559604914))
    res2 = sinh(val)
    VERIFY_IS_APPROX(res2.derivatives().x(), Scalar(1.056071867829939))
    res3 = cosh(val)
    VERIFY_IS_APPROX(res3.derivatives().x(), Scalar(0.339540557256150))

def check_limits_specialization[Scalar: DType]() raises:
    typedef Eigen.Matrix[Scalar, 1, 1] = Deriv
    typedef Eigen.AutoDiffScalar[Deriv] = AD
    typedef std.numeric_limits[AD] = A
    typedef std.numeric_limits[Scalar] = B
    VERIFY(!bool(internal.is_same[B, A].value))
    #if EIGEN_HAS_CXX11
    VERIFY(bool(std.is_base_of[B, A].value))
    #endif

def test_autodiff_scalar() raises:
    for i in range(g_repeat):
        CALL_SUBTEST_1[float](check_atan2[float])
        CALL_SUBTEST_2[double](check_atan2[double])
        CALL_SUBTEST_3[float](check_hyperbolic_functions[float])
        CALL_SUBTEST_4[double](check_hyperbolic_functions[double])
        CALL_SUBTEST_5[double](check_limits_specialization[double])