from ..Array3 import Array3D_int, Array3D
from ..Array.functions import conformable, equal_dimensions, eq
from ObjexxFCL.unit import *
from testing import *

@test
def test_Array3Test_ConstructDefault():
    var A = Array3D_int()
    assert_eq(0, A.size())
    assert_eq(0, A.size1())
    assert_eq(0, A.size2())
    assert_eq(0, A.size3())
    assert_eq(1, A.l1())
    assert_eq(1, A.l2())
    assert_eq(1, A.l3())
    assert_eq(0, A.u1())
    assert_eq(0, A.u2())
    assert_eq(0, A.u3())
    assert_eq(Array3D_int.IR(), A.I1())
    assert_eq(Array3D_int.IR(), A.I2())
    assert_eq(Array3D_int.IR(), A.I3())

@test
def test_Array3Test_ConstructCopy():
    var A = Array3D_int()
    var B = Array3D_int(A)
    assert_eq(A.size(), B.size())
    assert_eq(A.size1(), B.size1())
    assert_eq(A.size2(), B.size2())
    assert_eq(A.size3(), B.size3())
    assert_eq(A.l1(), B.l1())
    assert_eq(A.l2(), B.l2())
    assert_eq(A.l3(), B.l3())
    assert_eq(A.u1(), B.u1())
    assert_eq(A.u2(), B.u2())
    assert_eq(A.u3(), B.u3())
    assert_eq(A.I1(), B.I1())
    assert_eq(A.I2(), B.I2())
    assert_eq(A.I3(), B.I3())
    assert_true(conformable(A, B))
    assert_true(equal_dimensions(A, B))
    assert_true(eq(A, B))

@test
def test_Array3Test_ConstructOtherData():
    var A = Array3D[Float64](2, 2, 2)
    for i1 in range(A.l1(), A.u1() + 1):
        for i2 in range(A.l2(), A.u2() + 1):
            for i3 in range(A.l3(), A.u3() + 1):
                A(i1, i2, i3) = i1 + i2 + i3
    var B = Array3D_int(A)
    assert_eq(A.I1(), B.I1())
    assert_eq(A.I2(), B.I2())
    assert_eq(A.I3(), B.I3())
    assert_true(conformable(A, B))
    assert_true(equal_dimensions(A, B))
    for i1 in range(A.l1(), A.u1() + 1):
        for i2 in range(A.l2(), A.u2() + 1):
            for i3 in range(A.l3(), A.u3() + 1):
                assert_eq(Int(A(i1, i2, i3)), B(i1, i2, i3))
                assert_almost_eq(A(i1, i2, i3), Float64(B(i1, i2, i3)))

@test
def test_Array3Test_ConstructIndexes():
    var A = Array3D_int(3, 3, 3)
    assert_eq(27, A.size())
    assert_eq(3, A.size1())
    assert_eq(3, A.size2())
    assert_eq(3, A.size3())
    assert_eq(1, A.l1())
    assert_eq(1, A.l2())
    assert_eq(1, A.l3())
    assert_eq(3, A.u1())
    assert_eq(3, A.u2())
    assert_eq(3, A.u3())
    assert_eq(Array3D_int.IR(1, 3), A.I1())
    assert_eq(Array3D_int.IR(1, 3), A.I2())
    assert_eq(Array3D_int.IR(1, 3), A.I3())

@test
def test_Array3Test_RangeBasedFor():
    var A = Array3D_int(2, 2, 2, 1, 2, 3, 4, 5, 6, 7, 8)
    var v = 0
    for e in A:
        v += 1
        assert_eq(v, e)

@test
def test_Array3Test_Subscript():
    var A = Array3D_int(2, 2, 2,
        111,
        112,
        121,
        122,
        211,
        212,
        221,
        222)
    assert_eq(8, A.size())
    assert_eq(111, A[0])
    assert_eq(112, A[1])
    assert_eq(121, A[2])
    assert_eq(122, A[3])
    assert_eq(211, A[4])
    assert_eq(212, A[5])
    assert_eq(221, A[6])
    assert_eq(222, A[7])
    assert_eq(111, A(1, 1, 1))
    assert_eq(112, A(1, 1, 2))
    assert_eq(121, A(1, 2, 1))
    assert_eq(122, A(1, 2, 2))
    assert_eq(211, A(2, 1, 1))
    assert_eq(212, A(2, 1, 2))
    assert_eq(221, A(2, 2, 1))
    assert_eq(222, A(2, 2, 2))

@test
def test_Array3Test_Predicates():
    var A1 = Array3D_int()
    assert_false(A1.active())
    assert_false(A1.allocated())
    assert_true(A1.empty())
    assert_true(A1.size_bounded())
    assert_true(A1.owner())
    assert_false(A1.proxy())
    var A2 = Array3D_int(2, 3, 2)
    assert_true(A2.active())
    assert_true(A2.allocated())
    assert_false(A2.empty())
    assert_true(A2.owner())
    assert_false(A2.proxy())
    var A3 = Array3D_int(2, 3, 2, 31459)
    assert_true(A3.active())
    assert_true(A3.allocated())
    assert_false(A3.empty())
    assert_true(A3.owner())
    assert_false(A3.proxy())
    var A4 = Array3D_int(2, 2, 2, 111, 112, 121, 122, 211, 212, 221, 222)
    assert_true(A4.active())
    assert_true(A4.allocated())
    assert_false(A4.empty())
    assert_true(A4.owner())
    assert_false(A4.proxy())

@test
def test_Array3Test_PredicateComparisonsValues():
    var A1 = Array3D_int()
    assert_true(eq(A1, 0) and eq(0, A1))
    var A2 = Array3D_int(2, 3, 2, 31459)
    assert_true(eq(A2, 31459) and eq(31459, A1))
    var A3 = Array3D_int(2, 2, 2, 111, 112, 121, 122, 211, 212, 221, 222)
    assert_false(eq(A3, 11) or eq(23, A3))