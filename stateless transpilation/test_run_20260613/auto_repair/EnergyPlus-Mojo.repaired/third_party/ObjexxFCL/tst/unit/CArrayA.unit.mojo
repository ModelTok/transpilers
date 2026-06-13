from testing import assert_equal, assert_true, assert_false
from CArrayA import CArrayA
from ObjexxFCL import magnitude_squared, distance_squared, dot, swap

@test
def Construction():
    # Copy constructor and assignment
    v = CArrayA[Int](10, 22)
    w = CArrayA[Int](v)
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
    s = CArrayA[Int](v + w)
    assert_equal(v.size(), s.size())
    assert_true(s == 46)

    # Copy constructor and assignment template
    v = CArrayA[Int](10, 22)
    f = CArrayA[Float32](v)  # May cause conversion warning
    assert_equal(CArrayA[Float32](10, 22.0), f)
    v += 1
    assert_equal(CArrayA[Int](10, 23), v)
    f = v
    assert_equal(CArrayA[Float32](10, 23.0), f)

    # Size constructor
    v = CArrayA[Int](10)  # Uninitialized
    assert_equal(10, v.size())

    # Size + value constructor
    v = CArrayA[Int](10, 22)
    assert_equal(10, v.size())
    assert_equal(22, v[0])
    assert_equal(22, v[9])

@test
def Assignment():
    v = CArrayA[Int](10, 22)
    v += 2
    assert_equal(CArrayA[Int](10, 24), v)
    v -= 2
    assert_equal(CArrayA[Int](10, 22), v)
    v *= 2
    assert_equal(CArrayA[Int](10, 44), v)
    v /= 2
    assert_equal(CArrayA[Int](10, 22), v)
    v = CArrayA[Int](20, 33)
    assert_equal(CArrayA[Int](20, 33), v)
    v += v
    assert_equal(CArrayA[Int](20, 66), v)
    v -= v
    assert_equal(CArrayA[Int](20, 0), v)
    v = 55
    assert_equal(CArrayA[Int](20, 55), v)

@test
def Subscripting():
    v = CArrayA[Int](10, 22)
    v[3] = 33
    assert_equal(22, v[0])
    assert_equal(33, v[3])
    assert_equal(22, v[9])
    assert_equal(33, v[3])  # v(4) -> v[3] (1-based to 0-based)
    v[4] = 44  # v(5) -> v[4]
    assert_equal(44, v[4])

@test
def Functions():
    u = CArrayA[Int](1, 2, 3)
    v = CArrayA[Int](2, 3, 4)
    assert_equal(14, magnitude_squared(u))
    assert_equal(3, distance_squared(u, v))
    assert_equal(20, dot(u, v))

@test
def Swap():
    a = CArrayA[Int](10, 22)
    A = CArrayA[Int](a)
    b = CArrayA[Int](8, 33)
    B = CArrayA[Int](b)
    a.swap(b)
    assert_equal(B, a)
    assert_equal(A, b)
    b.swap(a)
    assert_equal(A, a)
    assert_equal(B, b)
    swap(a, b)
    assert_equal(B, a)
    assert_equal(A, b)