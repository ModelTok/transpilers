from testing import expect_equal, expect_true, expect_false
from ..Array4D import Array4D_int
from ..ObjexxFCL.unit import conformable, equal_dimensions, eq

@test
def test_Array4Test_ConstructDefault():
    var A = Array4D_int()
    expect_equal(0, A.size())
    expect_equal(0, A.size1())
    expect_equal(0, A.size2())
    expect_equal(0, A.size3())
    expect_equal(0, A.size4())
    expect_equal(1, A.l1())
    expect_equal(1, A.l2())
    expect_equal(1, A.l3())
    expect_equal(1, A.l4())
    expect_equal(0, A.u1())
    expect_equal(0, A.u2())
    expect_equal(0, A.u3())
    expect_equal(0, A.u4())
    expect_equal(Array4D_int.IR(), A.I1())
    expect_equal(Array4D_int.IR(), A.I2())
    expect_equal(Array4D_int.IR(), A.I3())
    expect_equal(Array4D_int.IR(), A.I4())

@test
def test_Array4Test_ConstructCopy():
    var A = Array4D_int()
    var B = Array4D_int(A)
    expect_equal(A.size(), B.size())
    expect_equal(A.size1(), B.size1())
    expect_equal(A.size2(), B.size2())
    expect_equal(A.size3(), B.size3())
    expect_equal(A.size4(), B.size4())
    expect_equal(A.l1(), B.l1())
    expect_equal(A.l2(), B.l2())
    expect_equal(A.l3(), B.l3())
    expect_equal(A.l4(), B.l4())
    expect_equal(A.u1(), B.u1())
    expect_equal(A.u2(), B.u2())
    expect_equal(A.u3(), B.u3())
    expect_equal(A.u4(), B.u4())
    expect_equal(A.I1(), B.I1())
    expect_equal(A.I2(), B.I2())
    expect_equal(A.I3(), B.I3())
    expect_equal(A.I4(), B.I4())
    expect_true(conformable(A, B))
    expect_true(equal_dimensions(A, B))
    expect_true(eq(A, B))

@test
def test_Array4Test_RangeBasedFor():
    var A = Array4D_int(2, 2, 2, 2, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16])
    var v = 0
    for e in A:
        v += 1
        expect_equal(v, e)

@test
def test_Array4Test_Subscript():
    var A = Array4D_int(2, 2, 2, 2, [
        1111,
        1112,
        1121,
        1122,
        1211,
        1212,
        1221,
        1222,
        2111,
        2112,
        2121,
        2122,
        2211,
        2212,
        2221,
        2222
    ])
    expect_equal(16, A.size())
    expect_equal(1111, A[0])
    expect_equal(1112, A[1])
    expect_equal(1121, A[2])
    expect_equal(1122, A[3])
    expect_equal(1211, A[4])
    expect_equal(1212, A[5])
    expect_equal(1221, A[6])
    expect_equal(1222, A[7])
    expect_equal(2111, A[8])
    expect_equal(2112, A[9])
    expect_equal(2121, A[10])
    expect_equal(2122, A[11])
    expect_equal(2211, A[12])
    expect_equal(2212, A[13])
    expect_equal(2221, A[14])
    expect_equal(2222, A[15])
    # 1-based to 0-based conversion
    expect_equal(1111, A[0, 0, 0, 0])
    expect_equal(1112, A[0, 0, 0, 1])
    expect_equal(1121, A[0, 0, 1, 0])
    expect_equal(1122, A[0, 0, 1, 1])
    expect_equal(1211, A[0, 1, 0, 0])
    expect_equal(1212, A[0, 1, 0, 1])
    expect_equal(1221, A[0, 1, 1, 0])
    expect_equal(1222, A[0, 1, 1, 1])
    expect_equal(2111, A[1, 0, 0, 0])
    expect_equal(2112, A[1, 0, 0, 1])
    expect_equal(2121, A[1, 0, 1, 0])
    expect_equal(2122, A[1, 0, 1, 1])
    expect_equal(2211, A[1, 1, 0, 0])
    expect_equal(2212, A[1, 1, 0, 1])
    expect_equal(2221, A[1, 1, 1, 0])
    expect_equal(2222, A[1, 1, 1, 1])

@test
def test_Array4Test_Predicates():
    var A1 = Array4D_int()
    expect_false(A1.active())
    expect_false(A1.allocated())
    expect_true(A1.empty())
    expect_true(A1.size_bounded())
    expect_true(A1.owner())
    expect_false(A1.proxy())
    var A3 = Array4D_int(2, 3, 2, 2, 31459)
    expect_true(A3.active())
    expect_true(A3.allocated())
    expect_false(A3.empty())
    expect_true(A3.owner())
    expect_false(A3.proxy())
    var A4 = Array4D_int(2, 2, 2, 2, [
        1111,
        1112,
        1121,
        1122,
        1211,
        1212,
        1221,
        1222,
        2111,
        2112,
        2121,
        2122,
        2211,
        2212,
        2221,
        2222
    ])
    expect_true(A4.active())
    expect_true(A4.allocated())
    expect_false(A4.empty())
    expect_true(A4.owner())
    expect_false(A4.proxy())

@test
def test_Array4Test_PredicateComparisonsValues():
    var A1 = Array4D_int()
    expect_true(eq(A1, 0) and eq(0, A1))  # Empty array is considered to equal any scalar (no values don't equal the scalar)
    var A2 = Array4D_int(2, 3, 2, 2, 31459)
    expect_true(eq(A2, 31459) and eq(31459, A1))
    var A3 = Array4D_int(2, 2, 2, 2, [
        1111,
        1112,
        1121,
        1122,
        1211,
        1212,
        1221,
        1222,
        2111,
        2112,
        2121,
        2122,
        2211,
        2212,
        2221,
        2222
    ])
    expect_false(eq(A3, 11) or eq(23, A3))