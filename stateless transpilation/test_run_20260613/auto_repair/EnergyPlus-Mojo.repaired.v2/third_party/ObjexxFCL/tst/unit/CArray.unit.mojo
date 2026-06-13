from testing import *
from ObjexxFCL.CArray import CArray
from ObjexxFCL.unit import *
from math import sqrt

def test_Construction():
    # Copy constructor and assignment
    var v = CArray[Int](10, 22)
    var w = CArray[Int](v)
    assert_equal(v, w)
    assert_equal(w, v)
    w += 1
    v = w
    assert_equal(v, w)
    assert_equal(w, v)
    assert_true(v == w)
    assert_true(v <= w)
    assert_true(v >= w)
    assert_false(v < w)
    assert_false(v > w)
    var s = CArray[Int](v + w)
    assert_equal(v.size(), s.size())
    assert_true(s == 46)

    # Copy constructor and assignment template
    var v2 = CArray[Int](10, 22)
    var f = CArray[Float32](v2)
    assert_equal(CArray[Float32](10, 22.0), f)
    v2 += 1
    assert_equal(CArray[Int](10, 23), v2)
    f = v2
    assert_equal(CArray[Float32](10, 23.0), f)

    # Size constructor
    var v3 = CArray[Int](10)  # Uninitialized
    assert_equal(10, v3.size())

    # Size + value constructor
    var v4 = CArray[Int](10, 22)
    assert_equal(10, v4.size())
    assert_equal(22, v4[0])
    assert_equal(22, v4[9])

def test_Assignment():
    var v = CArray[Int](10, 22)
    v += 2
    assert_equal(CArray[Int](10, 24), v)
    v -= 2
    assert_equal(CArray[Int](10, 22), v)
    v *= 2
    assert_equal(CArray[Int](10, 44), v)
    v /= 2
    assert_equal(CArray[Int](10, 22), v)
    v = CArray[Int](20, 33)
    assert_equal(CArray[Int](20, 33), v)
    v += v
    assert_equal(CArray[Int](20, 66), v)
    v -= v
    assert_equal(CArray[Int](20, 0), v)
    v = 55
    assert_equal(CArray[Int](20, 55), v)

def test_Subscripting():
    var v = CArray[Int](10, 22)
    v[3] = 33
    assert_equal(22, v[0])
    assert_equal(33, v[3])
    assert_equal(22, v[9])
    assert_equal(33, v(4))
    v(5) = 44
    assert_equal(44, v(5))

def test_Functions():
    var u = CArray[Int](1, 2, 3)
    var v = CArray[Int](2, 3, 4)
    assert_equal(14, magnitude_squared(u))
    assert_equal(3, distance_squared(u, v))
    assert_equal(20, dot(u, v))

def test_Swap():
    var a = CArray[Int](10, 22)
    var A = CArray[Int](a)
    var b = CArray[Int](8, 33)
    var B = CArray[Int](b)
    a.swap(b)
    assert_equal(B, a)
    assert_equal(A, b)
    b.swap(a)
    assert_equal(A, a)
    assert_equal(B, b)
    swap(a, b)
    assert_equal(B, a)
    assert_equal(A, b)