from ObjexxFCL import Array1D, Array2D, MArray1
from testing import expect_equal

struct C:
    var m: Int
    var x: Float32

    def __init__(inout self, m_: Int = 0, x_: Float32 = 0.0):
        self.m = m_
        self.x = x_

@test
def MArrayTest_Basic1D():
    var a = Array1D[C](5)
    for i in range(a.l(), a.u() + 1):
        a[i].m = i
    var ma = MArray1[Array1D[C], Int](a, &C.m)
    expect_equal(a[1].m, ma[1])
    expect_equal(a[2].m, ma[2])
    expect_equal(a[3].m, ma[3])
    expect_equal(a[4].m, ma[4])
    expect_equal(a[5].m, ma[5])
    expect_equal(1, ma[1])
    expect_equal(2, ma[2])
    expect_equal(3, ma[3])
    expect_equal(4, ma[4])
    expect_equal(5, ma[5])
    expect_equal(2, ma[1])
    expect_equal(3, ma[2])
    expect_equal(4, ma[3])
    expect_equal(5, ma[4])
    expect_equal(6, ma[5])

@test
def MArrayTest_Range1D():
    var a = Array1D[C](Array1D[C].IR(-3, 3))
    for i in range(a.l(), a.u() + 1):
        a[i].m = i
    var ma = MArray1[Array1D[C], Int](a, &C.m)
    expect_equal(1, ma.l())
    expect_equal(1, ma.l1())
    expect_equal(1, ma.l(1))
    expect_equal(7, ma.u())
    expect_equal(7, ma.u1())
    expect_equal(7, ma.u(1))
    expect_equal(a[-3].m, ma[1])
    expect_equal(a[-2].m, ma[2])
    expect_equal(a[-1].m, ma[3])
    expect_equal(a[0].m, ma[4])
    expect_equal(a[1].m, ma[5])
    expect_equal(a[2].m, ma[6])
    expect_equal(a[3].m, ma[7])
    expect_equal(-3, ma[1])
    expect_equal(-2, ma[2])
    expect_equal(-1, ma[3])
    expect_equal(0, ma[4])
    expect_equal(1, ma[5])
    expect_equal(2, ma[6])
    expect_equal(3, ma[7])

@test
def MArrayTest_MakerMethod1D():
    var a = Array1D[C](5)
    for i in range(1, a.u() + 1):
        a[i].m = i
    var ma = a.ma(&C.m)
    expect_equal(a[1].m, ma[1])
    expect_equal(a[2].m, ma[2])
    expect_equal(a[3].m, ma[3])
    expect_equal(a[4].m, ma[4])
    expect_equal(a[5].m, ma[5])