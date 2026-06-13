from testing import *
from ObjexxFCL.Vector3 import Vector3
from ObjexxFCL.Array1D import Array1D
from ObjexxFCL.unit import *
from memory import Pointer
from math import *
from utils import *
from sys import *

def test_Vector3Test_Basic() raises:
    var v = Vector3[float32](15.0)
    assert_equal(15.0, v.x)
    assert_equal(15.0, v.y)
    assert_equal(15.0, v.z)
    v.normalize()
    assert_almost_equal(1.0, v.length())
    v.normalize(5.0)
    assert_almost_equal(5.0, v.length())
    v.zero()
    assert_equal(0.0, v.x)
    assert_equal(0.0, v.y)
    assert_equal(0.0, v.z)
    assert_equal(0.0, v.length())
    v.normalize_zero()
    assert_equal(0.0, v.x)
    assert_equal(0.0, v.y)
    assert_equal(0.0, v.z)
    v.zero()
    v.normalize_x()
    assert_equal(1.0, v.x)
    assert_equal(0.0, v.y)
    assert_equal(0.0, v.z)
    v.zero()
    v.normalize_y()
    assert_equal(0.0, v.x)
    assert_equal(1.0, v.y)
    assert_equal(0.0, v.z)
    v.zero()
    v.normalize_z()
    assert_equal(0.0, v.x)
    assert_equal(0.0, v.y)
    assert_equal(1.0, v.z)
    v.zero()
    v.normalize_uniform()
    assert_equal(v.x, v.y)
    assert_equal(v.x, v.z)
    assert_almost_equal(1.0, v.length())

def test_Vector3Test_InitializerList() raises:
    var v = Vector3[Int32](33, 52, 17)
    assert_equal(33, v.x)
    assert_equal(52, v.y)
    assert_equal(17, v.z)
    assert_equal(33, v.x1())
    assert_equal(52, v.x2())
    assert_equal(17, v.x3())
    assert_equal(33, v[0])
    assert_equal(52, v[1])
    assert_equal(17, v[2])
    assert_equal(33, v(1))
    assert_equal(52, v(2))
    assert_equal(17, v(3))
    v = Vector3[Int32](44, 55, 66)
    assert_equal(44, v.x)
    assert_equal(55, v.y)
    assert_equal(66, v.z)
    v += 10
    assert_equal(54, v.x)
    assert_equal(65, v.y)
    assert_equal(76, v.z)
    v -= 10
    assert_equal(44, v.x)
    assert_equal(55, v.y)
    assert_equal(66, v.z)
    v *= 2
    assert_equal(88, v.x)
    assert_equal(110, v.y)
    assert_equal(132, v.z)
    v /= 2.0
    assert_equal(44, v.x)
    assert_equal(55, v.y)
    assert_equal(66, v.z)
    v.negate()
    assert_equal(-44, v.x)
    assert_equal(-55, v.y)
    assert_equal(-66, v.z)

def test_Vector3Test_StdArray() raises:
    var arr = Pointer[Int32].alloc(3)
    arr[0] = 33
    arr[1] = 52
    arr[2] = 17
    var v = Vector3[Int32](arr)
    assert_equal(33, v.x)
    assert_equal(52, v.y)
    assert_equal(17, v.z)
    arr[0] = 133
    arr[1] = 152
    arr[2] = 117
    v = Vector3[Int32](arr)
    assert_equal(133, v.x)
    assert_equal(152, v.y)
    assert_equal(117, v.z)
    v += Vector3[Int32](arr)
    assert_equal(266, v.x)
    assert_equal(304, v.y)
    assert_equal(234, v.z)
    v -= Vector3[Int32](arr)
    assert_equal(133, v.x)
    assert_equal(152, v.y)
    assert_equal(117, v.z)
    arr[0] = 3
    arr[1] = 2
    arr[2] = 2
    v *= Vector3[Int32](arr)
    assert_equal(399, v.x)
    assert_equal(304, v.y)
    assert_equal(234, v.z)
    v /= Vector3[Int32](arr)
    assert_equal(133, v.x)
    assert_equal(152, v.y)
    assert_equal(117, v.z)
    arr.free()

def test_Vector3Test_StdVector() raises:
    var vec = List[Int32](33, 52, 17)
    var v = Vector3[Int32](vec)
    assert_equal(33, v.x)
    assert_equal(52, v.y)
    assert_equal(17, v.z)
    vec = List[Int32](133, 152, 117)
    v = Vector3[Int32](vec)
    assert_equal(133, v.x)
    assert_equal(152, v.y)
    assert_equal(117, v.z)
    v += Vector3[Int32](vec)
    assert_equal(266, v.x)
    assert_equal(304, v.y)
    assert_equal(234, v.z)
    v -= Vector3[Int32](vec)
    assert_equal(133, v.x)
    assert_equal(152, v.y)
    assert_equal(117, v.z)
    vec = List[Int32](3, 2, 2)
    v *= Vector3[Int32](vec)
    assert_equal(399, v.x)
    assert_equal(304, v.y)
    assert_equal(234, v.z)
    v /= Vector3[Int32](vec)
    assert_equal(133, v.x)
    assert_equal(152, v.y)
    assert_equal(117, v.z)

def test_Vector3Test_Array() raises:
    var a = Array1D_int(3, List[Int32](33, 52, 17))
    var v = Vector3[Int32](a)
    assert_equal(33, v.x)
    assert_equal(52, v.y)
    assert_equal(17, v.z)
    a = Array1D_int(3, List[Int32](133, 152, 117))
    v = Vector3[Int32](a)
    assert_equal(133, v.x)
    assert_equal(152, v.y)
    assert_equal(117, v.z)
    v += Vector3[Int32](a)
    assert_equal(266, v.x)
    assert_equal(304, v.y)
    assert_equal(234, v.z)
    v -= Vector3[Int32](a)
    assert_equal(133, v.x)
    assert_equal(152, v.y)
    assert_equal(117, v.z)
    a = Array1D_int(3, List[Int32](3, 2, 2))
    v *= Vector3[Int32](a)
    assert_equal(399, v.x)
    assert_equal(304, v.y)
    assert_equal(234, v.z)
    v /= Vector3[Int32](a)
    assert_equal(133, v.x)
    assert_equal(152, v.y)
    assert_equal(117, v.z)

def test_Vector3Test_MinMax() raises:
    var v = Vector3[Float64](1.0, 5.0, 3.0)
    var w = Vector3[Float64](3.0, 2.0, 7.0)
    var min_vw = min(v, w)
    var max_vw = max(v, w)
    assert_equal(1.0, min_vw.x)
    assert_equal(2.0, min_vw.y)
    assert_equal(3.0, min_vw.z)
    assert_equal(3.0, max_vw.x)
    assert_equal(5.0, max_vw.y)
    assert_equal(7.0, max_vw.z)
    v.max(w)
    assert_equal(3.0, v.x)
    assert_equal(5.0, v.y)
    assert_equal(7.0, v.z)
    w.max(v)
    assert_equal(v, w)

def test_Vector3Test_Comparisons() raises:
    var v = Vector3[Float64](1.0, 2.0, 3.0)
    var w = Vector3[Float64](1.0, 2.0, 3.0)
    assert_equal(v, w)
    v -= 0.5
    assert_true(v != w)
    assert_true(not (v == w))
    assert_true(v < w)
    assert_true(v <= w)
    v += 1.0
    assert_true(v != w)
    assert_true(not (v == w))
    assert_true(v > w)
    assert_true(v >= w)
    v.x = 0.0
    assert_true(v != w)
    assert_true(not (v == w))
    assert_true(not lt(v, w))
    assert_true(not le(v, w))
    assert_true(not gt(v, w))
    assert_true(not ge(v, w))
    assert_true(not equal_length(v, w))
    assert_true(not_equal_length(v, w))

def test_Vector3Test_Generators() raises:
    var v = Vector3[Float64](1.0, 12.0, 21.0)
    var w = Vector3[Float64](2.0, 6.0, 7.0)
    assert_equal(Vector3[Float64](3.0, 18.0, 28.0), v + w)
    assert_equal(Vector3[Float64](-1.0, 6.0, 14.0), v - w)
    assert_equal(Vector3[Float64](2.0, 72.0, 147.0), v * w)
    assert_equal(Vector3[Float64](0.5, 2.0, 3.0), v / w)

def test_Vector3Test_Distance() raises:
    var v = Vector3[Float64](3.0, 3.0, 0.0)
    var w = Vector3[Float64](3.0, 2.0, 0.0)
    assert_almost_equal(1.0, distance(v, w))
    assert_almost_equal(1.0, distance_squared(v, w))

def test_Vector3Test_Dot() raises:
    var x = Vector3[Float64](3.0, 0.0, 0.0)
    var y = Vector3[Float64](0.0, 2.0, 0.0)
    assert_equal(0.0, dot(x, y))

def test_Vector3Test_Cross() raises:
    var x = Vector3[Float64](3.0, 0.0, 0.0)
    var y = Vector3[Float64](0.0, 2.0, 0.0)
    assert_equal(Vector3[Float64](0.0, 0.0, 6.0), cross(x, y))

def test_Vector3Test_Center() raises:
    var x = Vector3[Float64](4.0, 0.0, 77.0)
    var y = Vector3[Float64](0.0, 4.0, 77.0)
    assert_equal(Vector3[Float64](2.0, 2.0, 77.0), cen(x, y))

def test_Vector3Test_Angle() raises:
    var Pi = acos(-1.0)
    var Pi_2 = asin(1.0)
    do:
        var a = Vector3[Float64](4.0, 0.0, 0.0)
        var b = Vector3[Float64](0.0, 4.0, 0.0)
        assert_almost_equal(Pi_2, angle(a, b))
        assert_almost_equal(0.0, cos(a, b))
        assert_almost_equal(1.0, sin(a, b))
    end
    do:
        var a = Vector3[Float64](4.0, 0.0, 0.0)
        var b = Vector3[Float64](0.0, 0.0, -4.0)
        assert_almost_equal(Pi_2, angle(a, b))
        assert_almost_equal(0.0, cos(a, b))
        assert_almost_equal(1.0, sin(a, b))
    end
    do:
        var a = Vector3[Float64](0.0, 4.0, 0.0)
        var b = Vector3[Float64](0.0, -1.0, 0.0)
        assert_almost_equal(Pi, angle(a, b))
        assert_almost_equal(-1.0, cos(a, b))
        assert_almost_equal(0.0, sin(a, b))
    end

def test_Vector3Test_BinaryOperations() raises:
    var v = Vector3[Float64](1.0, 2.0, 3.0)
    var w = Vector3[Float64](1.0, 2.0, 3.0)
    var original = v
    assert_almost_equal(v.length_squared(), dot(v, w))
    v += 1.0
    w -= 1.0
    var c = cross(v, w)
    assert_almost_equal(dot(c, v), 0.0)
    assert_almost_equal(dot(c, w), 0.0)
    var midpoint = mid(v, w)
    assert_almost_equal(original.x, midpoint.x)
    assert_almost_equal(original.y, midpoint.y)
    assert_almost_equal(original.z, midpoint.z)