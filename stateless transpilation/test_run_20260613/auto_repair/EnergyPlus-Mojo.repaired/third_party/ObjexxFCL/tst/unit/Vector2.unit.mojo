from math import acos, asin, cos, sin
from testing import assert_equal, assert_approx_equal  # Using Mojo's testing module
from ObjexxFCL import Vector2
from ObjexxFCL import Array1D
from ObjexxFCL.unit import *  # Assumes .mojo equivalent

# Helper to mimic gtest macros
def EXPECT_EQ[T: EqualityComparable](actual: T, expected: T):
    assert_equal(actual, expected)

def EXPECT_FLOAT_EQ(actual: Float, expected: Float):
    assert_approx_equal(actual, expected, rel_tol=1e-6)

def EXPECT_DOUBLE_EQ(actual: Float64, expected: Float64):
    assert_approx_equal(actual, expected, rel_tol=1e-15)

def EXPECT_TRUE(cond: Bool):
    assert_equal(cond, True)

def EXPECT_FALSE(cond: Bool):
    assert_equal(cond, False)

# Main test functions (replace TEST macros)
struct Vector2Test:
    def Basic() raises:
        var v = Vector2[Float32](15.0)  # Uniform value construction
        EXPECT_EQ(15.0, v.x)
        EXPECT_EQ(15.0, v.y)
        v.normalize()
        EXPECT_FLOAT_EQ(1.0, v.length())
        v.normalize(5.0)
        EXPECT_FLOAT_EQ(5.0, v.length())
        v.zero()
        EXPECT_EQ(0.0, v.x)
        EXPECT_EQ(0.0, v.y)
        EXPECT_EQ(0.0, v.length())
        v.normalize_zero()
        EXPECT_EQ(0.0, v.x)
        EXPECT_EQ(0.0, v.y)
        v.zero()
        v.normalize_x()
        EXPECT_EQ(1.0, v.x)
        EXPECT_EQ(0.0, v.y)
        v.zero()
        v.normalize_y()
        EXPECT_EQ(0.0, v.x)
        EXPECT_EQ(1.0, v.y)
        v.zero()
        v.normalize_uniform()
        EXPECT_EQ(v.x, v.y)
        EXPECT_FLOAT_EQ(1.0, v.length())

    def InitializerList() raises:
        var v = Vector2[Int32]([33, 52])
        EXPECT_EQ(33, v.x)
        EXPECT_EQ(52, v.y)
        EXPECT_EQ(33, v.x1())
        EXPECT_EQ(52, v.x2())
        EXPECT_EQ(33, v[0])
        EXPECT_EQ(52, v[1])
        EXPECT_EQ(33, v(0))  # Note: 1-based→0-based
        EXPECT_EQ(52, v(1))
        v = [44, 55]
        EXPECT_EQ(44, v.x)
        EXPECT_EQ(55, v.y)
        v += 10
        EXPECT_EQ(54, v.x)
        EXPECT_EQ(65, v.y)
        v -= 10
        EXPECT_EQ(44, v.x)
        EXPECT_EQ(55, v.y)
        v *= 2
        EXPECT_EQ(88, v.x)
        EXPECT_EQ(110, v.y)
        v /= 2.0
        EXPECT_EQ(44, v.x)
        EXPECT_EQ(55, v.y)
        v.negate()
        EXPECT_EQ(-44, v.x)
        EXPECT_EQ(-55, v.y)

    def StdArray() raises:
        var arr = List[Int32](33, 52)  # Simulate array
        var v = Vector2[Int32](arr)
        EXPECT_EQ(33, v.x)
        EXPECT_EQ(52, v.y)
        arr = List[Int32](133, 152)
        v = arr
        EXPECT_EQ(133, v.x)
        EXPECT_EQ(152, v.y)
        v += arr
        EXPECT_EQ(266, v.x)
        EXPECT_EQ(304, v.y)
        v -= arr
        EXPECT_EQ(133, v.x)
        EXPECT_EQ(152, v.y)
        arr = List[Int32](3, 2)
        v *= arr
        EXPECT_EQ(399, v.x)
        EXPECT_EQ(304, v.y)
        v /= arr
        EXPECT_EQ(133, v.x)
        EXPECT_EQ(152, v.y)

    def StdVector() raises:
        var vec = List[Int32](33, 52)
        var v = Vector2[Int32](vec)
        EXPECT_EQ(33, v.x)
        EXPECT_EQ(52, v.y)
        vec = List[Int32](133, 152)
        v = vec
        EXPECT_EQ(133, v.x)
        EXPECT_EQ(152, v.y)
        v += vec
        EXPECT_EQ(266, v.x)
        EXPECT_EQ(304, v.y)
        v -= vec
        EXPECT_EQ(133, v.x)
        EXPECT_EQ(152, v.y)
        vec = List[Int32](3, 2)
        v *= vec
        EXPECT_EQ(399, v.x)
        EXPECT_EQ(304, v.y)
        v /= vec
        EXPECT_EQ(133, v.x)
        EXPECT_EQ(152, v.y)

    def Array() raises:
        var a = Array1D[Int32](2, [33, 52])
        var v = Vector2[Int32](a)
        EXPECT_EQ(33, v.x)
        EXPECT_EQ(52, v.y)
        a = [133, 152]
        v = a
        EXPECT_EQ(133, v.x)
        EXPECT_EQ(152, v.y)
        v += a
        EXPECT_EQ(266, v.x)
        EXPECT_EQ(304, v.y)
        v -= a
        EXPECT_EQ(133, v.x)
        EXPECT_EQ(152, v.y)
        a = [3, 2]
        v *= a
        EXPECT_EQ(399, v.x)
        EXPECT_EQ(304, v.y)
        v /= a
        EXPECT_EQ(133, v.x)
        EXPECT_EQ(152, v.y)

    def MinMax() raises:
        var v = Vector2[Float64](1.0, 5.0)
        var w = Vector2[Float64](3.0, 2.0)
        var min_vw = min(v, w)
        var max_vw = max(v, w)
        EXPECT_EQ(1.0, min_vw.x)
        EXPECT_EQ(2.0, min_vw.y)
        EXPECT_EQ(3.0, max_vw.x)
        EXPECT_EQ(5.0, max_vw.y)
        v.max(w)
        EXPECT_EQ(3.0, v.x)
        EXPECT_EQ(5.0, v.y)
        w.max(v)
        EXPECT_EQ(v, w)

    def Comparisons() raises:
        var v = Vector2[Float64](1.0, 2.0)
        var w = Vector2[Float64](1.0, 2.0)
        EXPECT_EQ(v, w)
        v -= 0.5
        EXPECT_TRUE(v != w)
        EXPECT_TRUE(not (v == w))
        EXPECT_TRUE(v < w)
        EXPECT_TRUE(v <= w)
        v += 1.0
        EXPECT_TRUE(v != w)
        EXPECT_TRUE(not (v == w))
        EXPECT_TRUE(v > w)
        EXPECT_TRUE(v >= w)
        v.x = 0.0
        EXPECT_TRUE(v != w)
        EXPECT_TRUE(not (v == w))
        EXPECT_TRUE(not lt(v, w))
        EXPECT_TRUE(not le(v, w))
        EXPECT_TRUE(not gt(v, w))
        EXPECT_TRUE(not ge(v, w))
        EXPECT_TRUE(not equal_length(v, w))
        EXPECT_TRUE(not_equal_length(v, w))

    def Generators() raises:
        var v = Vector2[Float64](1.0, 12.0)
        var w = Vector2[Float64](2.0, 6.0)
        EXPECT_EQ(Vector2[Float64](3.0, 18.0), v + w)
        EXPECT_EQ(Vector2[Float64](-1.0, 6.0), v - w)
        EXPECT_EQ(Vector2[Float64](2.0, 72.0), v * w)
        EXPECT_EQ(Vector2[Float64](0.5, 2.0), v / w)

    def Distance() raises:
        var v = Vector2[Float64](3.0, 3.0)
        var w = Vector2[Float64](3.0, 2.0)
        EXPECT_DOUBLE_EQ(1.0, distance(v, w))
        EXPECT_DOUBLE_EQ(1.0, distance_squared(v, w))

    def Dot() raises:
        var x = Vector2[Float64](3.0, 0.0)
        var y = Vector2[Float64](0.0, 2.0)
        EXPECT_EQ(0.0, dot(x, y))

    def Cross() raises:
        var x = Vector2[Float64](3.0, 0.0)
        var y = Vector2[Float64](0.0, 2.0)
        EXPECT_EQ(6.0, cross(x, y))

    def Center() raises:
        var x = Vector2[Float64](4.0, 0.0)
        var y = Vector2[Float64](0.0, 4.0)
        EXPECT_EQ(Vector2[Float64](2.0, 2.0), cen(x, y))

    def Angle() raises:
        var Pi = acos(-1.0)
        var Pi_2 = asin(1.0)
        # First block
        var a = Vector2[Float64](4.0, 0.0)
        var b = Vector2[Float64](0.0, 4.0)
        EXPECT_DOUBLE_EQ(Pi_2, angle(a, b))
        EXPECT_DOUBLE_EQ(0.0, cos(a, b))
        EXPECT_DOUBLE_EQ(1.0, sin(a, b))
        EXPECT_DOUBLE_EQ(Pi_2, dir_angle(a, b))
        EXPECT_DOUBLE_EQ(0.0, dir_cos(a, b))
        EXPECT_DOUBLE_EQ(1.0, dir_sin(a, b))
        # Second block
        a = Vector2[Float64](4.0, 0.0)
        b = Vector2[Float64](0.0, -4.0)
        EXPECT_DOUBLE_EQ(Pi_2, angle(a, b))
        EXPECT_DOUBLE_EQ(0.0, cos(a, b))
        EXPECT_DOUBLE_EQ(1.0, sin(a, b))
        EXPECT_DOUBLE_EQ(3.0 * Pi_2, dir_angle(a, b))
        EXPECT_DOUBLE_EQ(0.0, dir_cos(a, b))
        EXPECT_DOUBLE_EQ(-1.0, dir_sin(a, b))
        # Third block
        a = Vector2[Float64](4.0, 0.0)
        b = Vector2[Float64](-1.0, 0.0)
        EXPECT_DOUBLE_EQ(Pi, angle(a, b))
        EXPECT_DOUBLE_EQ(-1.0, cos(a, b))
        EXPECT_DOUBLE_EQ(0.0, sin(a, b))
        EXPECT_DOUBLE_EQ(Pi, dir_angle(a, b))
        EXPECT_DOUBLE_EQ(-1.0, dir_cos(a, b))
        EXPECT_DOUBLE_EQ(0.0, dir_sin(a, b))

    def BinaryOperations() raises:
        var v = Vector2[Float64](1.0, 2.0)
        var w = Vector2[Float64](1.0, 2.0)
        var original = v
        EXPECT_DOUBLE_EQ(v.length_squared(), dot(v, w)) # v == w here
        v += 1.0
        w -= 1.0
        var midpoint = mid(v, w)
        EXPECT_DOUBLE_EQ(original.x, midpoint.x)
        EXPECT_DOUBLE_EQ(original.y, midpoint.y)

    def String() raises:
        var X = "X"
        var v = Vector2[String](X)
        EXPECT_EQ(X, v.x)
        EXPECT_EQ(X, v.y)
        var w = Vector2[String]()
        w = v
        EXPECT_EQ(X, w.x)
        EXPECT_EQ(X, w.y)

def main() raises:
    Vector2Test.Basic()
    Vector2Test.InitializerList()
    Vector2Test.StdArray()
    Vector2Test.StdVector()
    Vector2Test.Array()
    Vector2Test.MinMax()
    Vector2Test.Comparisons()
    Vector2Test.Generators()
    Vector2Test.Distance()
    Vector2Test.Dot()
    Vector2Test.Cross()
    Vector2Test.Center()
    Vector2Test.Angle()
    Vector2Test.BinaryOperations()
    Vector2Test.String()