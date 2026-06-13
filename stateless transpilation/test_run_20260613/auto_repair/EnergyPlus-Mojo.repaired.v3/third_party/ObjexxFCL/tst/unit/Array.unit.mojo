from testing import *
from ObjexxFCL.Array.all import *
from ObjexxFCL.unit import *
from Array import array

alias IR = IndexRange
def test_DefaultConstruction():
    var A = Array2D_int()
    var B = Array2D_int()
    assert_equal(0, A.size())
def test_Construction2DIndexRangeInitializerList():
    var r = Array2D_int(IR(-1, 1), IR(-1, 1), [1, 2, 3, 4, 5, 6, 7, 8, 9])
    assert_equal(-1, r.l1())
    assert_equal(-1, lbound(r, 1))
    assert_equal(1, r.u1())
    assert_equal(1, ubound(r, 1))
    assert_equal(-1, r.l2())
    assert_equal(-1, lbound(r, 2))
    assert_equal(1, r.u2())
    assert_equal(1, ubound(r, 2))
    assert_true(eq(Array1D_int(2, [-1, -1]), lbound(r)))
    assert_true(eq(Array1D_int(2, [1, 1]), ubound(r)))
    var k = 1
    for i in range(-1, 2):
        for j in range(-1, 2):
            assert_equal(k, r[i, j])
            k += 1
    var v = 0
    for e in r:
        v += 1
        assert_equal(v, e)
    v = 10
    for e in r:
        v += 1
        e = v
        assert_equal(v, e)
def test_Construction2DDifferentValueType():
    var A = Array2D_int(3, 3, 33)
    var B = Array2D_double(A)
    assert_true(eq(Array2D_double(3, 3, 33.0), B))
def test_Assignment2D():
    var A = Array2D_int(3, 3, 33)
    var B = Array2D_int(IR(0, 4), IR(0, 4), 44)
    A = B
    assert_true(eq(B, A))
def test_Assignment2DRedimensionDifferentValueType():
    var A = Array2D_int(3, 3, 33)
    var B = Array2D_double(IR(0, 4), IR(0, 4), 4.4)
    A = B
    assert_true(eq(Array2D_int(IR(0, 4), IR(0, 4), 4), A))
def test_Assignment2DNoOverlapProxy():
    var A = Array2D_int(3, 3, 33)
    var B = Array2A_int(A[2, 2], 2, 2)
    B = 44
    var C = Array2A_int(A[1, 1], 2, 2)
    C = 55
    assert_true(A.overlap(B))
    assert_true(A.overlap(C))
    assert_true(B.overlap(A))
    assert_true(C.overlap(A))
    assert_false(B.overlap(C))
    assert_false(C.overlap(B))
    B = C
    assert_true(eq(C, B))
    var D = Array2A_int(A[3, 3], 1, 1)
    assert_false(C.overlap(D))
    assert_false(D.overlap(C))
    assert_false(B.overlap(D))
    assert_false(D.overlap(B))
    assert_equal(55, A[1, 1])
    assert_equal(55, A[1, 2])
    assert_equal(55, A[1, 3])
    assert_equal(55, A[2, 1])
    assert_equal(55, A[2, 2])
    assert_equal(55, A[2, 3])
    assert_equal(55, A[3, 1])
    assert_equal(55, A[3, 2])
    assert_equal(33, A[3, 3])
def test_Assignment2DOverlapProxy():
    var A = Array2D_int(3, 3, 33)
    var B = Array2A_int(A[1, 1], 2, 3)
    B = 44
    assert_equal(44, A[1, 1])
    assert_equal(44, A[1, 2])
    assert_equal(44, A[1, 3])
    assert_equal(44, A[2, 1])
    assert_equal(44, A[2, 2])
    assert_equal(44, A[2, 3])
    assert_equal(33, A[3, 1])
    assert_equal(33, A[3, 2])
    assert_equal(33, A[3, 3])
    var C = Array2A_int(A[2, 1], 2, 3)
    C = 55
    assert_true(A.overlap(B))
    assert_true(A.overlap(C))
    assert_true(B.overlap(A))
    assert_true(C.overlap(A))
    assert_true(B.overlap(C))
    assert_true(C.overlap(B))
    B = C
    assert_true(eq(C, B))
    assert_true(eq(55, A))
def test_Assignment2DOverlapProxyVarying():
    var A = Array2D_int(2, 2, 1)
    var B = Array1A_int(A[1, 1], 3)
    B[1] = 1
    B[2] = 2
    B[3] = 3
    assert_equal(1, A[1, 1])
    assert_equal(2, A[1, 2])
    assert_equal(3, A[2, 1])
    assert_equal(1, A[2, 2])
    var C = Array1A_int(A[1, 2], 3)
    assert_true(A.overlap(B))
    assert_true(A.overlap(C))
    assert_true(B.overlap(A))
    assert_true(C.overlap(A))
    assert_true(B.overlap(C))
    assert_true(C.overlap(B))
    C = B
    assert_false(eq(C, B))
    assert_false(eq(B, C))
    assert_equal(1, A[1, 1])
    assert_equal(1, A[1, 2])
    assert_equal(2, A[2, 1])
    assert_equal(3, A[2, 2])
def test_Operators2D():
    var A = Array2D_int(3, 3, 33)
    var B = Array2A_int(A)
    A += B
    assert_true(eq(Array2D_int(3, 3, 66), A))
    assert_true(eq(Array2D_int(3, 3, 66), B))
    A += 1
    assert_true(eq(Array2D_int(3, 3, 67), A))
    assert_true(eq(Array2D_int(3, 3, 67), B))
def test_Swap3D():
    var A = Array3D_int(4, 4, 4, 44)
    var temp = Array3D_int(5, 5, 5, 55)
    temp.swap(A)
    assert_equal(IR(1, 5), A.I1())
    assert_equal(IR(1, 5), A.I2())
    assert_equal(IR(1, 5), A.I3())
    assert_equal(5, A.size1())
    assert_equal(5, A.size2())
    assert_equal(5, A.size3())
    assert_equal(5 * 5 * 5, A.size())
    for i in range(A.size()):
        assert_equal(55, A[i])
def test_Pow2D():
    var A = Array2D_int(3, 3, 12)
    var B = pow(A, 2)
    var S = Array2D_int(3, 3, 144)
    assert_true(eq(S, B))
def test_Generation2DValueMinusArray():
    var A = Array2D_int(3, 3, 33)
    var B = 44 - A
    assert_true(eq(Array2D_int(3, 3, 11), B))
def test_Cross1D():
    var A = Array1D_int(3, 33)
    var B = 44 - A
    assert_true(eq(cross(A, B), cross_product(A, B)))
def test_LogicalNegation():
    var F = Array2D_bool(2, 2, False)
    assert_false(F[1, 1])
    assert_false(F[1, 2])
    assert_false(F[2, 1])
    assert_false(F[2, 2])
    var T = !F
    assert_true(T[1, 1])
    assert_true(T[1, 2])
    assert_true(T[2, 1])
    assert_true(T[2, 2])
def test_UboundOfUnbounded():
    var r = Array2D_int([-1, 1], [-1, 1], [1, 2, 3, 4, 5, 6, 7, 8, 9])
    var u = Array2A_int(r[-1, -1])
    u.dim(_, 3)
    assert_equal(1, lbound(u, 1))
    assert_equal(1, lbound(u, 2))
    assert_equal(3, ubound(u, 2))
    # Can't take ubound of unbounded dimension
    # EXPECT_DEBUG_DEATH( ubound( u, 1 ), ".*Assertion.*" )
def test_EmptyComparisonPredicate():
    var a = Array1D_int(0)
    var b = Array1D_int(0)
    assert_equal(0, a.size())
    assert_equal(0, b.size())
    assert_equal(1, lbound(a, 1))
    assert_equal(0, ubound(a, 1))
    assert_true(eq(a, b))
def test_EmptyComparisonElemental():
    var a = Array1D_int(0)
    var b = Array1D_int(0)
    assert_equal(0, a.size())
    assert_equal(0, b.size())
    assert_equal(1, lbound(a, 1))
    assert_equal(0, ubound(a, 1))
    assert_equal(0, (a == b).size())
    assert_equal(0, (a > b).size())
def test_Unallocated():
    var a = Array1D_int()
    assert_false(a.allocated())
    assert_false(allocated(a))
    # EXPECT_DEBUG_DEATH( a( 1 ), ".*Assertion.*" )
def test_AnyOp2D():
    var A = Array2D_int(3, 3, [1, 2, 3, 4, 5, 6, 7, 8, 9])
    assert_true(any_eq(A, 6))
    assert_false(any_eq(A, 22))
    assert_true(any_ne(A, 6))
    assert_true(any_lt(A, 2))
    assert_true(any_ge(A, 9))
    assert_false(any_lt(A, 1))
    assert_false(any_gt(A, 9))
def test_AllOp2D():
    var A = Array2D_int(3, 3, [1, 2, 3, 4, 5, 6, 7, 8, 9])
    assert_true(all_ne(A, 22))
    assert_false(all_ne(A, 2))
def test_CountOp2D():
    var A = Array2D_int(3, 3, [1, 2, 2, 3, 3, 3, 7, 8, 9])
    assert_equal(0, count_eq(A, 0))
    assert_equal(1, count_eq(A, 1))
    assert_equal(2, count_eq(A, 2))
    assert_equal(3, count_eq(A, 3))
    assert_equal(6, count_lt(A, 7))
    assert_equal(1, count_ge(A, 9))
    assert_equal(9, count_lt(A, 11))
    assert_equal(3, count_gt(A, 3))
def test_Functions1D():
    var u = Array1D_int([1, 2, 3])
    var v = Array1D_int([2, 3, 4])
    assert_equal(14, magnitude_squared(u))
    assert_equal(3, distance_squared(u, v))
    assert_equal(20, dot(u, v))