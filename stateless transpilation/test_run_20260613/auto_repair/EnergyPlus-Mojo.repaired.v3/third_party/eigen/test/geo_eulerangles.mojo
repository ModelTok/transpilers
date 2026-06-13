# Derived from third_party/eigen/test/geo_eulerangles.cpp
# Faithful 1:1 translation to Mojo (with necessary syntactic adjustments)

from Eigen import *
from math import pi as EIGEN_PI
from math import abs

# We assume that the Eigen test infrastructure (e.g., internal, VERIFY_IS_APPROX, etc.) 
# is also available in the Mojo translation.

def verify_euler[Scalar: DType](ea: Matrix[Scalar, 3, 1], i: Int, j: Int, k: Int):
    Matrix3 = Matrix[Scalar, 3, 3]
    Vector3 = Matrix[Scalar, 3, 1]
    AngleAxisx = AngleAxis[Scalar]

    var m: Matrix3 = Matrix3(
        AngleAxisx(ea[0], Vector3.Unit(i)) *
        AngleAxisx(ea[1], Vector3.Unit(j)) *
        AngleAxisx(ea[2], Vector3.Unit(k))
    )
    var eabis: Vector3 = m.eulerAngles(i, j, k)
    var mbis: Matrix3 = Matrix3(
        AngleAxisx(eabis[0], Vector3.Unit(i)) *
        AngleAxisx(eabis[1], Vector3.Unit(j)) *
        AngleAxisx(eabis[2], Vector3.Unit(k))
    )
    VERIFY_IS_APPROX(m, mbis)

    # If I==K, and ea[1]==0, then there no unique solution.
    # The remark apply in the case where I!=K, and |ea[1]| is close to pi/2.
    if (i != k or ea[1] != 0) and (i == k or not internal.isApprox(abs(ea[1]), Scalar(EIGEN_PI / 2), test_precision[Scalar]())):
        VERIFY((ea - eabis).norm() <= test_precision[Scalar]())
    VERIFY(0 < eabis[0] or test_isMuchSmallerThan(eabis[0], Scalar(1)))
    VERIFY_IS_APPROX_OR_LESS_THAN(eabis[0], Scalar(EIGEN_PI))
    VERIFY_IS_APPROX_OR_LESS_THAN(-Scalar(EIGEN_PI), eabis[1])
    VERIFY_IS_APPROX_OR_LESS_THAN(eabis[1], Scalar(EIGEN_PI))
    VERIFY_IS_APPROX_OR_LESS_THAN(-Scalar(EIGEN_PI), eabis[2])
    VERIFY_IS_APPROX_OR_LESS_THAN(eabis[2], Scalar(EIGEN_PI))

def check_all_var[Scalar: DType](ea: Matrix[Scalar, 3, 1]):
    verify_euler[Scalar](ea, 0, 1, 2)
    verify_euler[Scalar](ea, 0, 1, 0)
    verify_euler[Scalar](ea, 0, 2, 1)
    verify_euler[Scalar](ea, 0, 2, 0)
    verify_euler[Scalar](ea, 1, 2, 0)
    verify_euler[Scalar](ea, 1, 2, 1)
    verify_euler[Scalar](ea, 1, 0, 2)
    verify_euler[Scalar](ea, 1, 0, 1)
    verify_euler[Scalar](ea, 2, 0, 1)
    verify_euler[Scalar](ea, 2, 0, 2)
    verify_euler[Scalar](ea, 2, 1, 0)
    verify_euler[Scalar](ea, 2, 1, 2)

def eulerangles[Scalar: DType]():
    Matrix3 = Matrix[Scalar, 3, 3]
    Vector3 = Matrix[Scalar, 3, 1]
    Array3 = Array[Scalar, 3, 1]
    Quaternionx = Quaternion[Scalar]
    AngleAxisx = AngleAxis[Scalar]

    var a: Scalar = internal.random[Scalar](-Scalar(EIGEN_PI), Scalar(EIGEN_PI))
    var q1: Quaternionx = Quaternionx()
    q1 = AngleAxisx(a, Vector3.Random().normalized())
    var m: Matrix3 = Matrix3()
    m = q1
    var ea: Vector3 = m.eulerAngles(0, 1, 2)
    check_all_var[Scalar](ea)
    ea = m.eulerAngles(0, 1, 0)
    check_all_var[Scalar](ea)
    q1.coeffs() = Quaternionx.Coefficients.Random().normalized()
    m = q1
    ea = m.eulerAngles(0, 1, 2)
    check_all_var[Scalar](ea)
    ea = m.eulerAngles(0, 1, 0)
    check_all_var[Scalar](ea)
    ea = (Array3.Random() + Array3(1, 0, 0)) * Scalar(EIGEN_PI) * Array3(0.5, 1, 1)
    check_all_var[Scalar](ea)
    ea[2] = ea[0] = internal.random[Scalar](0, Scalar(EIGEN_PI))
    check_all_var[Scalar](ea)
    ea[0] = ea[1] = internal.random[Scalar](0, Scalar(EIGEN_PI))
    check_all_var[Scalar](ea)
    ea[1] = 0
    check_all_var[Scalar](ea)
    ea.head(2).setZero()
    check_all_var[Scalar](ea)
    ea.setZero()
    check_all_var[Scalar](ea)

def test_geo_eulerangles():
    for i in range(g_repeat):
        CALL_SUBTEST_1(eulerangles[Float32]())
        CALL_SUBTEST_2(eulerangles[Float64]())