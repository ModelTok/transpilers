from Fmath import (
    min, max, abs as fmath_abs, FLOOR, CEILING, signum, sign,
    nint, nsint, nlint, nint64, nearest, nearest_size, nearest_ssize, nearest_int,
    mod, modulo, dim, gcd, REAL, make_complex,
    pi, pi_over_2, pi__2, degrees, deg, radians, rad,
    cot, acot, sind, cosd, tand, cotd, asind, acosd, atand, acotd, atan2d,
    erfcx, square, cube, quad, pow_2, pow_3, pow_4, pow_5, pow_6, pow_7, pow_8, pow_9,
    root_4, root_8,
    eq_tol, lt_tol, le_tol, gt_tol, ge_tol
)
from math import sqrt, atan, abs as std_abs, infinity
from complex import ComplexFloat64, ComplexFloat32

alias ushort = UInt16

struct S:
    var x: Int
    def __init__(inout self, x: Int = 11):
        self.x = x
    def __mul__(self, other: S) -> S:
        return S(self.x * other.x)

def EXPECT_EQ[T: Comparable](a: T, b: T):
    if a != b:
        print("FAIL: EXPECT_EQ", a, "!=", b)
        exit(1)

def EXPECT_DOUBLE_EQ(a: Float64, b: Float64):
    if a != b:
        print("FAIL: EXPECT_DOUBLE_EQ", a, "!=", b)
        exit(1)

def EXPECT_FLOAT_EQ(a: Float32, b: Float32):
    if a != b:
        print("FAIL: EXPECT_FLOAT_EQ", a, "!=", b)
        exit(1)

def EXPECT_NEAR(a: Float64, b: Float64, tol: Float64):
    if std_abs(a - b) > tol:
        print("FAIL: EXPECT_NEAR", a, "!=", b, "tol", tol)
        exit(1)

def EXPECT_TRUE(cond: Bool):
    if not cond:
        print("FAIL: EXPECT_TRUE")
        exit(1)

def EXPECT_FALSE(cond: Bool):
    if cond:
        print("FAIL: EXPECT_FALSE")
        exit(1)

struct FmathTest:
    def Min():
        EXPECT_EQ(Int16(4), min(Int16(4), Int16(9)))
        EXPECT_EQ(Int16(1), min(Int16(5), Int16(1), Int16(9)))
        EXPECT_EQ(Int16(-9), min(Int16(3), Int16(5), Int16(1), Int16(-9)))
        EXPECT_EQ(ushort(3), min(ushort(9), ushort(3)))
        EXPECT_EQ(ushort(3), min(ushort(4), ushort(9), ushort(3)))
        EXPECT_EQ(ushort(3), min(ushort(4), ushort(9), ushort(3), ushort(11)))
        EXPECT_EQ(4, min(4, 9))
        EXPECT_EQ(1, min(5, 1, 9))
        EXPECT_EQ(-9, min(3, 5, 1, -9))
        EXPECT_EQ(3u, min(9u, 3u))
        EXPECT_EQ(3u, min(4u, 9u, 3u, 11u))
        EXPECT_EQ(4l, min(4l, 9l))
        EXPECT_EQ(1l, min(5l, 1l, 9l))
        EXPECT_EQ(-9l, min(3l, 5l, 1l, -9l))
        EXPECT_EQ(3ul, min(9ul, 3ul))
        EXPECT_EQ(3ul, min(4ul, 9ul, 3ul, 11ul))
        EXPECT_EQ(4.0f, min(4.0f, 9.0f))
        EXPECT_EQ(1.0f, min(5.0f, 1.0f, 9.0f))
        EXPECT_EQ(-9.0f, min(3.0f, 5.0f, 1.0f, -9.0f))
        EXPECT_EQ(4.0, min(4.0, 9.0))
        EXPECT_EQ(1.0, min(5.0, 1.0, 9.0))
        EXPECT_EQ(-9.0, min(3.0, 5.0, 1.0, -9.0))
        EXPECT_EQ(4.0l, min(4.0l, 9.0l))
        EXPECT_EQ(1.0l, min(5.0l, 1.0l, 9.0l))
        EXPECT_EQ(-9.0l, min(3.0l, 5.0l, 1.0l, -9.0l))

    def Max():
        EXPECT_EQ(Int16(9), max(Int16(4), Int16(9)))
        EXPECT_EQ(Int16(9), max(Int16(3), Int16(5), Int16(1), Int16(9)))
        EXPECT_EQ(Int16(5), max(Int16(3), Int16(5), Int16(1), Int16(-9)))
        EXPECT_EQ(ushort(9), max(ushort(9), ushort(3)))
        EXPECT_EQ(ushort(11), max(ushort(4), ushort(9), ushort(3), ushort(11)))
        EXPECT_EQ(9, max(4, 9))
        EXPECT_EQ(9, max(5, 1, 9))
        EXPECT_EQ(5, max(3, 5, 1, -9))
        EXPECT_EQ(9u, max(9u, 3u))
        EXPECT_EQ(11u, max(4u, 9u, 3u, 11u))
        EXPECT_EQ(9l, max(4l, 9l))
        EXPECT_EQ(9l, max(5l, 1l, 9l))
        EXPECT_EQ(5l, max(3l, 5l, 1l, -9l))
        EXPECT_EQ(9ul, max(9ul, 3ul))
        EXPECT_EQ(11ul, max(4ul, 9ul, 3ul, 11ul))
        EXPECT_EQ(9.0f, max(4.0f, 9.0f))
        EXPECT_EQ(9.0f, max(3.0f, 5.0f, 1.0f, 9.0f))
        EXPECT_EQ(5.0f, max(3.0f, 5.0f, 1.0f, -9.0f))
        EXPECT_EQ(9.0, max(4.0, 9.0))
        EXPECT_EQ(9.0, max(3.0, 5.0, 1.0, 9.0))
        EXPECT_EQ(5.0, max(3.0, 5.0, 1.0, -9.0))
        EXPECT_EQ(9.0l, max(4.0l, 9.0l))
        EXPECT_EQ(9.0l, max(3.0l, 5.0l, 1.0l, 9.0l))
        EXPECT_EQ(5.0l, max(3.0l, 5.0l, 1.0l, -9.0l))

    def Abs():
        EXPECT_EQ(44, std_abs(-44))
        EXPECT_EQ(44l, std_abs(-44l))
        EXPECT_EQ(44.4f, std_abs(-44.4f))
        EXPECT_EQ(44.4, std_abs(-44.4))
        EXPECT_EQ(44.4l, std_abs(-44.4l))
        EXPECT_EQ(44, fmath_abs(-44))
        EXPECT_EQ(44l, fmath_abs(-44l))
        EXPECT_EQ(44.4f, fmath_abs(-44.4f))
        EXPECT_EQ(44.4, fmath_abs(-44.4))
        EXPECT_EQ(44.4l, fmath_abs(-44.4l))
        EXPECT_EQ(44, std_abs(-44))
        EXPECT_EQ(44l, std_abs(-44l))
        EXPECT_EQ(44.4f, std_abs(-44.4f))
        EXPECT_EQ(44.4, std_abs(-44.4))
        EXPECT_EQ(44.4l, std_abs(-44.4l))

    def Floor():
        EXPECT_EQ(42, FLOOR(42.0f))
        EXPECT_EQ(91, FLOOR(91.1f))
        EXPECT_EQ(-3, FLOOR(-2.3f))
        EXPECT_EQ(42, FLOOR(42.0))
        EXPECT_EQ(91, FLOOR(91.1))
        EXPECT_EQ(-3, FLOOR(-2.3))
        EXPECT_EQ(42, FLOOR(42.0l))
        EXPECT_EQ(91, FLOOR(91.1l))
        EXPECT_EQ(-3, FLOOR(-2.3l))

    def Ceiling():
        EXPECT_EQ(42, CEILING(42.0f))
        EXPECT_EQ(92, CEILING(91.1f))
        EXPECT_EQ(-2, CEILING(-2.3f))
        EXPECT_EQ(42, CEILING(42.0))
        EXPECT_EQ(92, CEILING(91.1))
        EXPECT_EQ(-2, CEILING(-2.3))
        EXPECT_EQ(42, CEILING(42.0l))
        EXPECT_EQ(92, CEILING(91.1l))
        EXPECT_EQ(-2, CEILING(-2.3l))

    def Signum():
        EXPECT_EQ(1, signum(11))
        EXPECT_EQ(0, signum(0))
        EXPECT_EQ(-1, signum(-11))

    def Sign():
        EXPECT_EQ(1, sign(11))
        EXPECT_EQ(1, sign(0))
        EXPECT_EQ(-1, sign(-11))
        EXPECT_EQ(53.3, sign(53.3, 11))
        EXPECT_EQ(53.3, sign(53.3, 0))
        EXPECT_EQ(-53.3, sign(53.3, -11))
        EXPECT_EQ(53.3, sign(-53.3, 11))
        EXPECT_EQ(53.3, sign(-53.3, 0))
        EXPECT_EQ(-53.3, sign(-53.3, -11))

    def Nint():
        EXPECT_EQ(3, nint(3.123))
        EXPECT_EQ(3, nint(3.4999))
        EXPECT_EQ(4, nint(3.5))
        EXPECT_EQ(3, nsint(3.123))
        EXPECT_EQ(3, nsint(3.4999))
        EXPECT_EQ(4, nsint(3.5))
        EXPECT_EQ(3, nlint(3.123))
        EXPECT_EQ(3, nlint(3.4999))
        EXPECT_EQ(4, nlint(3.5))
        EXPECT_EQ(3, nint64(3.123))
        EXPECT_EQ(3, nint64(3.4999))
        EXPECT_EQ(4, nint64(3.5))

    def Nearest():
        EXPECT_EQ(4, nearest[Int](3.5))
        EXPECT_EQ(3.5f, nearest[Float32](3.5))
        EXPECT_EQ(3.5, nearest[Float64](3.5))
        EXPECT_EQ(3, nearest[Int](3.4999))
        EXPECT_EQ(3.4999, nearest[Float64](3.4999))
        EXPECT_EQ(-4, nearest[Int](-3.5))
        EXPECT_EQ(-3.5f, nearest[Float32](-3.5))
        EXPECT_EQ(-3.5, nearest[Float64](-3.5))
        EXPECT_EQ(-3, nearest[Int](-3.4999))
        EXPECT_EQ(-3.4999, nearest[Float64](-3.4999))
        EXPECT_EQ(3u, nearest_size(3.123))
        EXPECT_EQ(3u, nearest_size(3.4999))
        EXPECT_EQ(4u, nearest_size(3.5))
        EXPECT_EQ(0u, nearest_size(-3.123))
        EXPECT_EQ(0u, nearest_size(-3.4999))
        EXPECT_EQ(0u, nearest_size(-3.5))
        EXPECT_EQ(3, nearest_ssize(3.123))
        EXPECT_EQ(3, nearest_ssize(3.4999))
        EXPECT_EQ(4, nearest_ssize(3.5))
        EXPECT_EQ(-3, nearest_ssize(-3.123))
        EXPECT_EQ(-3, nearest_ssize(-3.4999))
        EXPECT_EQ(-4, nearest_ssize(-3.5))
        EXPECT_EQ(3, nearest_int(3.123))
        EXPECT_EQ(3, nearest_int(3.4999))
        EXPECT_EQ(4, nearest_int(3.5))

    def Mod():
        EXPECT_EQ(Int16(3), mod(Int16(33), Int16(10)))
        EXPECT_EQ(ushort(3), mod(ushort(33), ushort(10)))
        EXPECT_EQ(3, mod(33, 10))
        EXPECT_EQ(3u, mod(33u, 10u))
        EXPECT_EQ(3l, mod(33l, 10l))
        EXPECT_EQ(3ul, mod(33ul, 10ul))
        EXPECT_EQ(UInt64(3u), mod(UInt64(33u), UInt64(10u)))
        EXPECT_EQ(3.0f, mod(33.0f, 10.0f))
        EXPECT_EQ(10.0f, mod(32.0f, 11.0f))
        EXPECT_EQ(3.0, mod(33.0, 10.0))
        EXPECT_EQ(10.0, mod(32.0l, 11.0l))
        EXPECT_EQ(3.0l, mod(33.0l, 10.0l))
        EXPECT_EQ(10.0l, mod(32.0l, 11.0l))

    def Modulo():
        EXPECT_EQ(Int16(3), modulo(Int16(33), Int16(10)))
        EXPECT_EQ(ushort(3), modulo(ushort(33), ushort(10)))
        EXPECT_EQ(3, modulo(33, 10))
        EXPECT_EQ(3u, modulo(33u, 10u))
        EXPECT_EQ(3l, modulo(33l, 10l))
        EXPECT_EQ(3ul, modulo(33ul, 10ul))
        EXPECT_EQ(UInt64(3u), modulo(UInt64(33u), UInt64(10u)))
        EXPECT_EQ(3.0f, modulo(33.0f, 10.0f))
        EXPECT_EQ(10.0f, modulo(32.0f, 11.0f))
        EXPECT_EQ(3.0, modulo(33.0, 10.0))
        EXPECT_EQ(10.0, modulo(32.0l, 11.0l))
        EXPECT_EQ(3.0l, modulo(33.0l, 10.0l))
        EXPECT_EQ(10.0l, modulo(32.0l, 11.0l))

    def Dim():
        EXPECT_EQ(0, dim(0, 0))
        EXPECT_EQ(11, dim(11, 0))
        EXPECT_EQ(0, dim(-11, 0))
        EXPECT_EQ(1, dim(22, 21))
        EXPECT_EQ(43, dim(22, -21))
        EXPECT_EQ(0, dim(-22, 21))
        EXPECT_EQ(0, dim(-22, -21))
        EXPECT_EQ(0, dim(31, 32))
        EXPECT_EQ(63, dim(31, -32))
        EXPECT_EQ(0, dim(-31, 32))
        EXPECT_EQ(1, dim(-31, -32))
        EXPECT_DOUBLE_EQ(0.42331, dim(3.14159, 2.71828))
        EXPECT_EQ(0.0, dim(2.71828, 3.14159))

    def Gcd():
        EXPECT_EQ(2, gcd(4, 6))
        EXPECT_EQ(3, gcd(6, 9))
        EXPECT_EQ(1, gcd(7, 11))
        EXPECT_EQ(7, gcd(0, 7))

    def REAL():
        EXPECT_DOUBLE_EQ(1.5, REAL(ComplexFloat64(1.5, 6.0)))
        EXPECT_DOUBLE_EQ(1.5f, REAL(1.5))

    def MakeComplex():
        EXPECT_EQ(ComplexFloat64(1.5, 6.0), make_complex(1.5, 6.0))
        EXPECT_EQ(ComplexFloat64(2.0, 6.0), make_complex(2, 6.0))
        EXPECT_EQ(ComplexFloat64(1.5, 6.0), make_complex(1.5, 6))
        EXPECT_EQ(ComplexFloat32(1.5f, 6.0f), make_complex(1.5f, 6))
        EXPECT_EQ(ComplexFloat32(2, 6), make_complex(2, 6))

    def Pi():
        EXPECT_DOUBLE_EQ(4.0 * atan(1.0), pi[Float64]())

    def PiOver2():
        EXPECT_DOUBLE_EQ(2.0 * atan(1.0), pi_over_2[Float64]())
        EXPECT_DOUBLE_EQ(2.0 * atan(1.0), pi__2[Float64]())

    def Degrees():
        EXPECT_DOUBLE_EQ(180.0, degrees(pi[Float64]()))
        EXPECT_DOUBLE_EQ(90.0, degrees(pi_over_2[Float64]()))
        EXPECT_DOUBLE_EQ(90.0, degrees(pi__2[Float64]()))

    def Deg():
        EXPECT_DOUBLE_EQ(180.0, deg(pi[Float64]()))
        EXPECT_DOUBLE_EQ(90.0, deg(pi_over_2[Float64]()))
        EXPECT_DOUBLE_EQ(90.0, deg(pi__2[Float64]()))

    def Radians():
        EXPECT_DOUBLE_EQ(pi[Float64](), radians(180.0))
        EXPECT_DOUBLE_EQ(pi_over_2[Float64](), radians(90.0))
        EXPECT_DOUBLE_EQ(pi__2[Float64](), radians(90.0))

    def Rad():
        EXPECT_DOUBLE_EQ(pi[Float64](), rad(180.0))
        EXPECT_DOUBLE_EQ(pi_over_2[Float64](), rad(90.0))
        EXPECT_DOUBLE_EQ(pi__2[Float64](), rad(90.0))

    def Cot():
        EXPECT_EQ(Float64.infinity, cot(0.0))
        EXPECT_DOUBLE_EQ(+1.0, cot(pi[Float64]() * 0.25))
        EXPECT_DOUBLE_EQ(+0.0, cot(pi[Float64]() * 0.50))
        EXPECT_DOUBLE_EQ(-1.0, cot(pi[Float64]() * 0.75))
        EXPECT_DOUBLE_EQ(+1.0, cot(pi[Float64]() * 2.25))

    def Acot():
        EXPECT_EQ(acot(Float64.infinity), 0.0)
        EXPECT_DOUBLE_EQ(acot(-Float64.infinity), pi[Float64]())
        EXPECT_DOUBLE_EQ(acot(+1.0), pi[Float64]() * 0.25)
        EXPECT_DOUBLE_EQ(acot(+0.0), pi[Float64]() * 0.50)
        EXPECT_DOUBLE_EQ(acot(-1.0), pi[Float64]() * 0.75)
        EXPECT_DOUBLE_EQ(acot(-1.0e99), pi[Float64]())

    def Sind():
        EXPECT_EQ(sind(0.0), 0.0)
        EXPECT_DOUBLE_EQ(sind(45.0), sqrt(0.5))
        EXPECT_DOUBLE_EQ(sind(90.0), 1.0)
        EXPECT_DOUBLE_EQ(sind(135.0), sqrt(0.5))
        EXPECT_NEAR(sind(180.0), 0.0, 1.0e-14)
        EXPECT_DOUBLE_EQ(sind(225.0), -sqrt(0.5))
        EXPECT_DOUBLE_EQ(sind(270.0), -1.0)
        EXPECT_DOUBLE_EQ(sind(315.0), -sqrt(0.5))
        EXPECT_NEAR(sind(360.0), 0.0, 1.0e-14)
        EXPECT_DOUBLE_EQ(sind(315.0 + 360.0), -sqrt(0.5))
        EXPECT_DOUBLE_EQ(sind(-45.0), -sqrt(0.5))

    def Cosd():
        EXPECT_EQ(cosd(0.0), 1.0)
        EXPECT_DOUBLE_EQ(cosd(45.0), sqrt(0.5))
        EXPECT_NEAR(cosd(90.0), 0.0, 1.0e-14)
        EXPECT_DOUBLE_EQ(cosd(135.0), -sqrt(0.5))
        EXPECT_DOUBLE_EQ(cosd(180.0), -1.0)
        EXPECT_DOUBLE_EQ(cosd(225.0), -sqrt(0.5))
        EXPECT_NEAR(cosd(270.0), 0.0, 1.0e-14)
        EXPECT_DOUBLE_EQ(cosd(315.0), sqrt(0.5))
        EXPECT_DOUBLE_EQ(cosd(360.0), 1.0)
        EXPECT_DOUBLE_EQ(cosd(315.0 + 360.0), sqrt(0.5))
        EXPECT_DOUBLE_EQ(cosd(-45.0), sqrt(0.5))

    def Tand():
        EXPECT_EQ(tand(0.0), 0.0)
        EXPECT_DOUBLE_EQ(tand(45.0), 1.0)
        EXPECT_DOUBLE_EQ(tand(135.0), -1.0)
        EXPECT_NEAR(tand(180.0), 0.0, 1.0e-14)
        EXPECT_DOUBLE_EQ(tand(225.0), 1.0)
        EXPECT_DOUBLE_EQ(tand(315.0), -1.0)
        EXPECT_NEAR(tand(360.0), 0.0, 1.0e-14)
        EXPECT_NEAR(tand(315.0 + 360.0), -1.0, 1.0e-14)
        EXPECT_DOUBLE_EQ(tand(-45.0), -1.0)

    def Cotd():
        EXPECT_DOUBLE_EQ(cotd(45.0), 1.0)
        EXPECT_NEAR(cotd(90.0), 0.0, 1.0e-14)
        EXPECT_DOUBLE_EQ(cotd(135.0), -1.0)
        EXPECT_DOUBLE_EQ(cotd(225.0), 1.0)
        EXPECT_NEAR(cotd(270.0), 0.0, 1.0e-14)
        EXPECT_DOUBLE_EQ(cotd(315.0), -1.0)
        EXPECT_DOUBLE_EQ(cotd(315.0 + 360.0), -1.0)
        EXPECT_DOUBLE_EQ(cotd(-45.0), -1.0)

    def Asind():
        EXPECT_EQ(asind(0.0), 0.0)
        EXPECT_DOUBLE_EQ(asind(sqrt(0.5)), 45.0)
        EXPECT_DOUBLE_EQ(asind(1.0), 90.0)
        EXPECT_DOUBLE_EQ(asind(-sqrt(0.5)), -45.0)
        EXPECT_DOUBLE_EQ(asind(-1.0), -90.0)

    def Acosd():
        EXPECT_EQ(acosd(1.0), 0.0)
        EXPECT_DOUBLE_EQ(acosd(sqrt(0.5)), 45.0)
        EXPECT_DOUBLE_EQ(acosd(0.0), 90.0)
        EXPECT_DOUBLE_EQ(acosd(-sqrt(0.5)), 135.0)
        EXPECT_DOUBLE_EQ(acosd(-1.0), 180.0)

    def Atand():
        EXPECT_EQ(atand(0.0), 0.0)
        EXPECT_EQ(atand(1.0), 45.0)
        EXPECT_EQ(atand(-1.0), -45.0)

    def Acotd():
        EXPECT_EQ(acotd(1.0), 45.0)
        EXPECT_EQ(acotd(0.0), 90.0)
        EXPECT_EQ(acotd(-1.0), 135.0)

    def Atan2d():
        EXPECT_EQ(atan2d(0.0, 1.0), 0.0)
        EXPECT_EQ(atan2d(1.0, 1.0), 45.0)
        EXPECT_EQ(atan2d(1.0, 0.0), 90.0)
        EXPECT_EQ(atan2d(1.0, -1.0), 135.0)
        EXPECT_EQ(atan2d(0.0, -1.0), 180.0)
        EXPECT_EQ(atan2d(-1.0, 1.0), -45.0)
        EXPECT_EQ(atan2d(-1.0, 0.0), -90.0)
        EXPECT_EQ(atan2d(-1.0, -1.0), -135.0)

    def Erfcx():
        EXPECT_FLOAT_EQ(erfcx(1.0f), 0.4275836f)
        EXPECT_NEAR(erfcx(20.0), 0.02817434874, 1.0e-11)

    def Square():
        EXPECT_EQ(Int16(11) * Int16(11), square(Int16(-11)))
        EXPECT_EQ(ushort(11) * ushort(11), square(ushort(11)))
        EXPECT_EQ(11 * 11, square(-11))
        EXPECT_EQ(11u * 11u, square(11u))
        EXPECT_EQ(11l * 11l, square(-11l))
        EXPECT_EQ(11ul * 11ul, square(11ul))
        EXPECT_EQ(11.0f * 11.0f, square(-11.0f))
        EXPECT_EQ(11.0 * 11.0, square(-11.0))
        EXPECT_EQ(11.0l * 11.0l, square(-11.0l))
        var s: S
        EXPECT_EQ(11 * 11, square(s).x)

    def Cube():
        EXPECT_EQ(-11*11*11, cube(-11))
        EXPECT_EQ(11u*11u*11u, cube(11u))
        EXPECT_EQ(-11l*11l*11l, cube(-11l))
        EXPECT_EQ(11ul*11ul*11ul, cube(11ul))
        EXPECT_EQ(-11.0f * 11.0f * 11.0f, cube(-11.0f))
        EXPECT_EQ(-11.0f * 11.0 * 11.0, cube(-11.0))
        EXPECT_EQ(-11.0l * 11.0l * 11.0l, cube(-11.0l))

    def Quad():
        EXPECT_EQ((-11) * (-11) * (-11) * (-11), quad(-11))
        EXPECT_EQ(11u * 11u * 11u * 11u, quad(11u))
        EXPECT_EQ((-11l) * (-11l) * (-11l) * (-11l), quad(-11l))
        EXPECT_EQ(11ul * 11ul * 11ul * 11ul, quad(11ul))
        EXPECT_EQ((-11.0f) * (-11.0f) * (-11.0f) * (-11.0f), quad(-11.0f))
        EXPECT_EQ((-11.0) * (-11.0) * (-11.0) * (-11.0), quad(-11.0))
        EXPECT_EQ((-11.0l) * (-11.0l) * (-11.0l) * (-11.0l), quad(-11.0l))

    def Pow():
        EXPECT_EQ(11*11, pow_2(-11))
        EXPECT_EQ(-11*11*11, pow_3(-11))
        EXPECT_EQ(11u*11u*11u, pow_3(11u))
        EXPECT_EQ(-11l*11l*11l, pow_3(-11l))
        EXPECT_EQ(11ul*11ul*11ul, pow_3(11ul))
        EXPECT_EQ(-11.0f * 11.0f * 11.0f, pow_3(-11.0f))
        EXPECT_EQ(-11.0f * 11.0 * 11.0, pow_3(-11.0))
        EXPECT_EQ(-11.0l * 11.0l * 11.0l, pow_3(-11.0l))
        EXPECT_EQ(16, pow_4(2.0))
        EXPECT_EQ(32, pow_5(2.0))
        EXPECT_EQ(64, pow_6(2.0))
        EXPECT_EQ(128, pow_7(2.0))
        EXPECT_EQ(256, pow_8(2.0))
        EXPECT_EQ(512, pow_9(2.0))

    def Root():
        EXPECT_EQ(3, root_4(81))
        EXPECT_EQ(3, root_8(6561))

    def Tolerance():
        EXPECT_TRUE(eq_tol(1.00, 1.01, 2.0))
        EXPECT_TRUE(eq_tol(1.00, 1.01, 0.2))
        EXPECT_TRUE(eq_tol(1.00, 1.01, 0.02))
        EXPECT_FALSE(eq_tol(1.00, 1.01, 0.002))
        EXPECT_TRUE(eq_tol(1.00, 1.01, 0.02, 2.0))
        EXPECT_TRUE(eq_tol(1.00, 1.01, 0.02, 0.2))
        EXPECT_TRUE(eq_tol(1.00, 1.01, 0.02, 0.02))
        EXPECT_TRUE(eq_tol(1.00, 1.01, 0.02, 0.002))
        EXPECT_TRUE(eq_tol(1.00, 1.01, 0.002, 2.0))
        EXPECT_TRUE(eq_tol(1.00, 1.01, 0.002, 0.2))
        EXPECT_TRUE(eq_tol(1.00, 1.01, 0.002, 0.02))
        EXPECT_FALSE(eq_tol(1.00, 1.01, 0.002, 0.002))
        EXPECT_TRUE(lt_tol(1.01, 1.00, 0.02, 2.0))
        EXPECT_TRUE(lt_tol(1.01, 1.00, 0.02, 0.2))
        EXPECT_TRUE(lt_tol(1.01, 1.00, 0.02, 0.02))
        EXPECT_TRUE(lt_tol(1.01, 1.00, 0.02, 0.002))
        EXPECT_TRUE(lt_tol(1.01, 1.00, 0.002, 2.0))
        EXPECT_TRUE(lt_tol(1.01, 1.00, 0.002, 0.2))
        EXPECT_TRUE(lt_tol(1.01, 1.00, 0.002, 0.02))
        EXPECT_FALSE(lt_tol(1.01, 1.00, 0.002, 0.002))
        EXPECT_TRUE(lt_tol(1.01, 1.00, 2.0, 0.002))
        EXPECT_TRUE(lt_tol(1.01, 1.00, 0.2, 0.002))
        EXPECT_TRUE(lt_tol(1.01, 1.00, 0.02, 0.002))
        EXPECT_FALSE(lt_tol(1.01, 1.00, 0.002, 0.002))
        EXPECT_TRUE(le_tol(1.01, 1.00, 0.02, 2.0))
        EXPECT_TRUE(le_tol(1.01, 1.00, 0.02, 0.2))
        EXPECT_TRUE(le_tol(1.01, 1.00, 0.02, 0.02))
        EXPECT_TRUE(le_tol(1.01, 1.00, 0.02, 0.002))
        EXPECT_TRUE(le_tol(1.01, 1.00, 0.002, 2.0))
        EXPECT_TRUE(le_tol(1.01, 1.00, 0.002, 0.2))
        EXPECT_TRUE(le_tol(1.01, 1.00, 0.002, 0.02))
        EXPECT_FALSE(le_tol(1.01, 1.00, 0.002, 0.002))
        EXPECT_TRUE(le_tol(1.01, 1.00, 2.0, 0.002))
        EXPECT_TRUE(le_tol(1.01, 1.00, 0.2, 0.002))
        EXPECT_TRUE(le_tol(1.01, 1.00, 0.02, 0.002))
        EXPECT_FALSE(le_tol(1.01, 1.00, 0.002, 0.002))
        EXPECT_TRUE(gt_tol(1.00, 1.01, 0.02, 2.0))
        EXPECT_TRUE(gt_tol(1.00, 1.01, 0.02, 0.2))
        EXPECT_TRUE(gt_tol(1.00, 1.01, 0.02, 0.02))
        EXPECT_TRUE(gt_tol(1.00, 1.01, 0.02, 0.002))
        EXPECT_TRUE(gt_tol(1.00, 1.01, 0.002, 2.0))
        EXPECT_TRUE(gt_tol(1.00, 1.01, 0.002, 0.2))
        EXPECT_TRUE(gt_tol(1.00, 1.01, 0.002, 0.02))
        EXPECT_FALSE(gt_tol(1.00, 1.01, 0.002, 0.002))
        EXPECT_TRUE(ge_tol(1.00, 1.01, 0.02, 2.0))
        EXPECT_TRUE(ge_tol(1.00, 1.01, 0.02, 0.2))
        EXPECT_TRUE(ge_tol(1.00, 1.01, 0.02, 0.02))
        EXPECT_TRUE(ge_tol(1.00, 1.01, 0.02, 0.002))
        EXPECT_TRUE(ge_tol(1.00, 1.01, 0.002, 2.0))
        EXPECT_TRUE(ge_tol(1.00, 1.01, 0.002, 0.2))
        EXPECT_TRUE(ge_tol(1.00, 1.01, 0.002, 0.02))
        EXPECT_FALSE(ge_tol(1.00, 1.01, 0.002, 0.002))

def main():
    FmathTest.Min()
    FmathTest.Max()
    FmathTest.Abs()
    FmathTest.Floor()
    FmathTest.Ceiling()
    FmathTest.Signum()
    FmathTest.Sign()
    FmathTest.Nint()
    FmathTest.Nearest()
    FmathTest.Mod()
    FmathTest.Modulo()
    FmathTest.Dim()
    FmathTest.Gcd()
    FmathTest.REAL()
    FmathTest.MakeComplex()
    FmathTest.Pi()
    FmathTest.PiOver2()
    FmathTest.Degrees()
    FmathTest.Deg()
    FmathTest.Radians()
    FmathTest.Rad()
    FmathTest.Cot()
    FmathTest.Acot()
    FmathTest.Sind()
    FmathTest.Cosd()
    FmathTest.Tand()
    FmathTest.Cotd()
    FmathTest.Asind()
    FmathTest.Acosd()
    FmathTest.Atand()
    FmathTest.Acotd()
    FmathTest.Atan2d()
    FmathTest.Erfcx()
    FmathTest.Square()
    FmathTest.Cube()
    FmathTest.Quad()
    FmathTest.Pow()
    FmathTest.Root()
    FmathTest.Tolerance()
    print("All tests passed.")