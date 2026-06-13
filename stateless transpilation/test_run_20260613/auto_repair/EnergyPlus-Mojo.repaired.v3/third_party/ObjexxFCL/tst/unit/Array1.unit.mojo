from testing import assert_equal, assert_true, assert_false
from ObjexxFCL import (
    Array1D_int, Array1D_double, Array1D_string, Array1D_bool,
    Array1A_int,
    IndexRange as IR,
    Vector2, Vector3,
    eq, allocated, size, lbound, ubound,
    allocate, deallocate,
    all, any, abs, pow, sign, count, sum, minval, maxval, minloc,
    shape, isize, pack, eoshift,
    dot, cross, dot_product, cross_product,
    magnitude_squared, distance_squared,
    equal_dimensions
)
from ObjexxFCL.unit import *


@test
def construction_empty():
    var v = Array1D_int()
    assert_equal(0, v.size())
    assert_equal(0, v.size1())
    assert_equal(1, v.l())
    assert_equal(1, v.l1())
    assert_equal(0, v.u())
    assert_equal(0, v.u1())
    assert_equal(Array1D_int.IR(), v.I())
    assert_equal(Array1D_int.IR(), v.I1())


@test
def allocate_zero():
    var i = Array1D_int()
    assert_false(i.allocated())
    assert_false(allocated(i))
    i.allocate(0)
    assert_true(i.allocated())
    assert_true(allocated(i))
    assert_equal(0, i.size())
    assert_equal(0, size(i))


@test
def construction_copy_empty():
    var v = Array1D_int()
    var c = Array1D_int(v)
    assert_equal(v.size(), c.size())
    assert_equal(v.size1(), c.size1())
    assert_equal(v.l(), c.l())
    assert_equal(v.l1(), c.l1())
    assert_equal(v.u(), c.u())
    assert_equal(v.u1(), c.u1())
    assert_equal(v.I(), c.I())
    assert_equal(v.I1(), c.I1())


@test
def construction_uninitialized():
    var v = Array1D_int(22)
    assert_equal(22, v.size())
    assert_equal(1, v.l())
    assert_equal(1, lbound(v, 1))
    assert_equal(22, v.u())
    assert_equal(22, ubound(v, 1))


@test
def construction_value_initialized():
    var v = Array1D_int(22, 33)
    assert_equal(22, v.size())
    assert_equal(1, v.l())
    assert_equal(22, v.u())
    for i in range(1, 23):
        assert_equal(33, v[i - 1])


@test
def construction_initializer_list_index_range():
    var r = Array1D_double(1, 3)  # Calls the initializer_list constructor but special code in that treats it as an IndexRange
    assert_equal(1, r.l1())
    assert_equal(3, r.u1())


@test
def construction_initializer_list_only_int():
    var r = Array1D_double(1, 2, 3)
    assert_equal(1, r.l1())
    assert_equal(3, r.u1())
    assert_equal(1.0, r[0])
    assert_equal(2.0, r[1])
    assert_equal(3.0, r[2])
    var v: Int = 0
    for e in r:
        v += 1
        assert_equal(v, e)


@test
def construction_initializer_list_only_unsigned():
    var r = Array1D_double(1, 2, 3)
    assert_equal(1, r.l1())
    assert_equal(3, r.u1())
    assert_equal(1.0, r[0])
    assert_equal(2.0, r[1])
    assert_equal(3.0, r[2])


@test
def construction_initializer_list_only_double():
    var r = Array1D_double(1.0, 2.0, 3.0)
    assert_equal(1, r.l1())
    assert_equal(3, r.u1())
    assert_equal(1.0, r[0])
    assert_equal(2.0, r[1])
    assert_equal(3.0, r[2])


@test
def construction_initializer_list_only_string():
    var r = Array1D_string("Food", "Hat", "Eggs")
    assert_equal(1, r.l1())
    assert_equal(3, r.u1())
    assert_equal(4, r[0].length())
    assert_equal(3, r[1].length())
    assert_equal(4, r[2].length())
    assert_equal("Food", r[0])
    assert_equal("Hat", r[1])
    assert_equal("Eggs", r[2])


@test
def construction_std_array():
    var v = Array1D_int(std_array[Int, 3](11, 22, 33))
    assert_equal(3, v.size())
    assert_equal(3, v.size1())
    assert_equal(1, v.l())
    assert_equal(1, v.l1())
    assert_equal(3, v.u())
    assert_equal(3, v.u1())
    assert_equal(11, v[0])
    assert_equal(22, v[1])
    assert_equal(33, v[2])


@test
def construction_std_vector():
    var v = Array1D_int(std_vector[Int](11, 22, 33))
    assert_equal(3, v.size())
    assert_equal(3, v.size1())
    assert_equal(1, v.l())
    assert_equal(1, v.l1())
    assert_equal(3, v.u())
    assert_equal(3, v.u1())
    assert_equal(Array1D_int.IR(1, 3), v.I())
    assert_equal(Array1D_int.IR(1, 3), v.I1())
    assert_equal(11, v[0])
    assert_equal(22, v[1])
    assert_equal(33, v[2])


@test
def construction_vector2():
    var v = Array1D_int(Vector2[Int](11, 22))
    assert_equal(2, v.size())
    assert_equal(2, v.size1())
    assert_equal(1, v.l())
    assert_equal(1, v.l1())
    assert_equal(2, v.u())
    assert_equal(2, v.u1())
    assert_equal(11, v[0])
    assert_equal(22, v[1])


@test
def construction_vector3():
    var v = Array1D_int(Vector3[Int](11, 22, 33))
    assert_equal(3, v.size())
    assert_equal(3, v.size1())
    assert_equal(1, v.l())
    assert_equal(1, v.l1())
    assert_equal(3, v.u())
    assert_equal(3, v.u1())
    assert_equal(11, v[0])
    assert_equal(22, v[1])
    assert_equal(33, v[2])


@test
def construction_iterator():
    var v = std_vector[Int](11, 22, 33)
    var a = Array1D_int(v.begin(), v.end())
    assert_equal(3, a.size())
    assert_equal(3, a.size1())
    assert_equal(1, a.l())
    assert_equal(1, a.l1())
    assert_equal(3, a.u())
    assert_equal(3, a.u1())
    assert_equal(Array1D_int.IR(1, 3), a.I())
    assert_equal(Array1D_int.IR(1, 3), a.I1())
    assert_equal(11, a[0])
    assert_equal(22, a[1])
    assert_equal(33, a[2])


def initializer_function(inout a: Array1D_string):
    a[0] = "This"
    a[1] = "is"
    a[2] = "a"
    a[3] = "string"


def initializer_function_template[T](inout a: Array1D[T]):
    a[0] = T(1)
    a[1] = T(2)
    a[2] = T(3)
    a[3] = T(4)


@test
def construction_initializer_function():
    var r = Array1D_string(4, "This", "is", "a", "stub")
    initializer_function(r)
    assert_equal("This", r[0])
    assert_equal("is", r[1])
    assert_equal("a", r[2])
    assert_equal("string", r[3])
    var cr = Array1D_string(4, initializer_function)
    assert_equal("This", cr[0])
    assert_equal("is", cr[1])
    assert_equal("a", cr[2])
    assert_equal("string", cr[3])
    var tr = Array1D_double(4, initializer_function_template[Double])
    assert_equal(1.0, tr[0])
    assert_equal(2.0, tr[1])
    assert_equal(3.0, tr[2])
    assert_equal(4.0, tr[3])


@test
def construction_index_range():
    var r = Array1D_int(IR(1, 5), 33)
    assert_equal(1, r.l())
    assert_equal(5, r.u())
    for i in range(1, 6):
        assert_equal(33, r[i - 1])
        assert_equal(33, r[i - 1])
    var a = Array1A_int(r, IR(1, 3))
    assert_equal(1, a.l())
    assert_equal(3, a.u())
    assert_equal(33, a[0])
    assert_equal(33, a[2])


@test
def construction_index_range_list():
    var r = Array1D_int((1, 5), 33)
    assert_equal(1, r.l())
    assert_equal(5, r.u())
    for i in range(1, 6):
        assert_equal(33, r[i - 1])
        assert_equal(33, r[i - 1])


@test
def construction_string():
    var r = Array1D_string(3, String("   "))
    assert_equal(1, r.l1())
    assert_equal(3, r.u1())
    assert_equal("   ", r[0])


@test
def construction_string_initializer_list():
    var r = Array1D_string(3, "Food", "Hat", "Eggs")
    assert_equal(1, r.l1())
    assert_equal(3, r.u1())
    assert_equal(4, r[0].length())
    assert_equal(3, r[1].length())
    assert_equal(4, r[2].length())
    assert_equal("Food", r[0])
    assert_equal("Hat", r[1])
    assert_equal("Eggs", r[2])


@test
def construction_index_range_initializer_list():
    var r = Array1D_int(IR(-1, 1), 1, 2, 3)
    assert_equal(-1, r.l())
    assert_equal(1, r.u())
    for i in range(-1, 2):
        assert_equal(i + 2, r[i - -1])


@test
fun construction_index_range_initializer_array():
    var r = Array1D_int((-1, 1), Array1D_int(3, 33))
    assert_equal(-1, r.l())
    assert_equal(1, r.u())
    assert_equal(33, r[0])
    assert_equal(33, r[1])
    assert_equal(33, r[2])


@test
def construction_range():
    var c = Array1D_int(3)
    c[0] = 11
    c[1] = 22
    c[2] = 33
    var r1 = Array1D_int(Array1D_int.range(c))
    assert_equal(3, r1.size())
    assert_equal(3, r1.size1())
    assert_equal(1, r1.l())
    assert_equal(1, r1.l1())
    assert_equal(3, r1.u())
    assert_equal(3, r1.u1())
    var r2 = Array1D_int(Array1D_int.range(c, 17))
    assert_equal(3, r2.size())
    assert_equal(3, r2.size1())
    assert_equal(1, r2.l())
    assert_equal(1, r2.l1())
    assert_equal(3, r2.u())
    assert_equal(3, r2.u1())
    assert_equal(17, r2[0])
    assert_equal(17, r2[1])
    assert_equal(17, r2[2])


@test
def construction_shape():
    var c = Array1D_int(3)
    c[0] = 11
    c[1] = 22
    c[2] = 33
    var r1 = Array1D_int(Array1D_int.shape(c))
    assert_equal(3, r1.size())
    assert_equal(3, r1.size1())
    assert_equal(1, r1.l())
    assert_equal(1, r1.l1())
    assert_equal(3, r1.u())
    assert_equal(3, r1.u1())
    var r2 = Array1D_int(Array1D_int.shape(c, 17))
    assert_equal(3, r2.size())
    assert_equal(3, r2.size1())
    assert_equal(1, r2.l())
    assert_equal(1, r2.l1())
    assert_equal(3, r2.u())
    assert_equal(3, r2.u1())
    assert_equal(17, r2[0])
    assert_equal(17, r2[1])
    assert_equal(17, r2[2])


@test
def construction_one_based():
    var c = Array1D_int(3)
    c[0] = 11
    c[1] = 22
    c[2] = 33
    var r1 = Array1D_int(Array1D_int.one_based(c))
    assert_equal(3, r1.size())
    assert_equal(3, r1.size1())
    assert_equal(1, r1.l())
    assert_equal(1, r1.l1())
    assert_equal(3, r1.u())
    assert_equal(3, r1.u1())


@test
def construction_one_based_initializer_list():
    var c = Array1D_int(3)
    c[0] = 11
    c[1] = 22
    c[2] = 33
    var r = Array1D_int(Array1D_int.one_based((11, 22, 33)))
    assert_equal(3, r.size())
    assert_equal(3, r.size1())
    assert_equal(1, r.l())
    assert_equal(1, r.l1())
    assert_equal(3, r.u())
    assert_equal(3, r.u1())
    assert_equal(11, r[0])
    assert_equal(22, r[1])
    assert_equal(33, r[2])


@test
def assignment_copy():
    var v = Array1D_double(22, 55.5)
    var w = Array1D_double(13, 6.789)
    v = w
    assert_true(eq(w, v))
    v = 45.5
    assert_equal(13, v.size())
    assert_true(eq(v, 45.5))


@test
def assignment_move():
    var v = Array1D_double(22, 55.5)
    v = Array1D_double(13, 6.75)
    assert_equal(13, v.size())
    assert_true(eq(v, 6.75))
    var w = Array1D_double()
    w = v  # Move semantics not directly expressible, copy used
    assert_equal(0, v.size())
    assert_equal(13, w.size())
    assert_true(eq(w, 6.75))


@test
def arg_construct():
    var u = Array1D_int(10, 22)
    var a = Array1A_int(u)
    assert_equal(u.I(), a.I())
    assert_equal(u[2], a[2])
    assert_true(eq(Array1D_int(10, 22), a))
    a[2] += 1
    assert_equal(u[2], 23)
    assert_equal(u[2], a[2])


@test
def const_arg_construct():
    var u = Array1D_int(10, 22)
    var a = Array1A_int(u)
    assert_equal(u.I(), a.I())
    assert_equal(u[2], a[2])
    assert_true(eq(Array1D_int(10, 22), a))


@test
def operators():
    var A = Array1D_int(3, 33)
    var B = Array1A_int(A)
    var C = Array1D_int(A)
    A += B
    assert_true(eq(Array1D_int(3, 66), A))
    assert_true(eq(Array1D_int(3, 66), B))
    A += 1
    assert_true(eq(Array1D_int(3, 67), A))
    assert_true(eq(Array1D_int(3, 67), B))
    A -= 1
    assert_true(eq(Array1D_int(3, 66), A))
    assert_true(eq(Array1D_int(3, 66), B))
    A -= C
    assert_true(eq(Array1D_int(3, 33), A))
    assert_true(eq(Array1D_int(3, 33), B))
    A /= 3
    assert_true(eq(Array1D_int(3, 11), A))
    assert_true(eq(Array1D_int(3, 11), B))
    A *= 3
    assert_true(eq(Array1D_int(3, 33), A))
    assert_true(eq(Array1D_int(3, 33), B))


@test
def index():
    var A = Array1D_int(3, 6)
    var C = Array1D_int(3, 6)
    assert_equal(2, A.index(3))
    assert_equal(5, A.index(6))
    assert_equal(2, C.index(3))
    assert_equal(5, C.index(6))
    assert_equal(1, A.index(2))


@test
def operator_brackets():
    var A = Array1D_int(3)
    A[0] = 11
    A[1] = 22
    A[2] = 33
    assert_equal(11, A[0])
    assert_equal(22, A[1])
    assert_equal(33, A[2])
    var C = Array1D_int(3, 11, 22, 33)
    assert_equal(11, C[0])
    assert_equal(22, C[1])
    assert_equal(33, C[2])


@test
def contains():
    var A = Array1D_int(11, 22, 33)
    assert_true(A.contains(1) and A.contains(2) and A.contains(3))
    assert_false(not A.contains(11) and A.contains(22) and A.contains(33))
    assert_false(A.contains(4))
    assert_false(A.contains(-1))


@test
def allocate_deallocate():
    var A1 = Array1D_double()
    assert_equal(0, A1.size())
    assert_equal(1, A1.l())
    assert_equal(0, A1.u())
    assert_false(A1.allocated())
    A1.allocate(3)
    assert_equal(3, A1.size())
    assert_equal(1, A1.l())
    assert_equal(3, A1.u())
    assert_true(A1.allocated())
    A1.deallocate()
    assert_equal(0, A1.size())
    assert_equal(1, A1.l())
    assert_equal(0, A1.u())
    assert_false(allocated(A1))
    var A2 = Array1D_double(1.1, 2.2, 3.3)
    assert_equal(3, A2.size())
    assert_equal(1, A2.l())
    assert_equal(3, A2.u())
    assert_true(allocated(A2))
    deallocate(A2)
    assert_equal(0, A1.size())
    assert_equal(1, A1.l())
    assert_equal(0, A1.u())
    assert_false(allocated(A2))


def dimension_initializer_function(inout A: Array1D_int):
    for i in range(A.l(), A.u() + 1):
        A[i - A.l()] = i * 10 + i


@test
def dimension():
    {
        var A = Array1D_int()
        assert_equal(1, A.l())
        assert_equal(0, A.u())
        assert_equal(0, A.size())
        A.dimension(9)
        assert_equal(1, A.l())
        assert_equal(9, A.u())
        assert_equal(9, A.size())
    }
    {
        var A = Array1D_int(3)
        assert_equal(1, A.l())
        assert_equal(3, A.u())
        assert_equal(3, A.size())
        A.dimension((3, 7))
        assert_equal(3, A.l())
        assert_equal(7, A.u())
        assert_equal(5, A.size())
        A.dimension((2, 4), 17)
        assert_equal(2, A.l())
        assert_equal(4, A.u())
        assert_equal(3, A.size())
        assert_equal(17, A[2 - 2])
        assert_equal(17, A[3 - 2])
        assert_equal(17, A[4 - 2])
        A.dimension((1, 5), 42)
        assert_equal(1, A.l())
        assert_equal(5, A.u())
        assert_equal(5, A.size())
        assert_equal(42, A[0])
        assert_equal(42, A[1])
        assert_equal(42, A[2])
        assert_equal(42, A[3])
        assert_equal(42, A[4])
        A.dimension((4, 6), dimension_initializer_function)
        assert_equal(4, A.l())
        assert_equal(6, A.u())
        assert_equal(3, A.size())
        assert_equal(44, A[4 - 4])
        assert_equal(55, A[5 - 4])
        assert_equal(66, A[6 - 4])
        A.dimension(Array1D_int(3, 7))
        assert_equal(3, A.l())
        assert_equal(7, A.u())
        assert_equal(5, A.size())
        A.dimension(Array1D_int(2, 4), 17)
        assert_equal(2, A.l())
        assert_equal(4, A.u())
        assert_equal(3, A.size())
        assert_equal(17, A[2 - 2])
        assert_equal(17, A[3 - 2])
        assert_equal(17, A[4 - 2])
        A.dimension(Array1D_int(4, 6), dimension_initializer_function)
        assert_equal(4, A.l())
        assert_equal(6, A.u())
        assert_equal(3, A.size())
        assert_equal(44, A[4 - 4])
        assert_equal(55, A[5 - 4])
        assert_equal(66, A[6 - 4])
    }


@test
def redimension():
    var A = Array1D_int(5, 11, 22, 33, 44, 55)
    assert_equal(1, A.l())
    assert_equal(5, A.u())
    assert_equal(5, A.size())
    assert_equal(11, A[0])
    assert_equal(22, A[1])
    assert_equal(33, A[2])
    assert_equal(44, A[3])
    assert_equal(55, A[4])
    A.redimension((3, 7))
    assert_equal(3, A.l())
    assert_equal(7, A.u())
    assert_equal(5, A.size())
    assert_equal(33, A[3 - 3])
    assert_equal(44, A[4 - 3])
    assert_equal(55, A[5 - 3])
    A.redimension((0, 4), 17)
    assert_equal(0, A.l())
    assert_equal(4, A.u())
    assert_equal(5, A.size())
    assert_equal(17, A[0 - 0])
    assert_equal(17, A[1 - 0])
    assert_equal(17, A[2 - 0])
    assert_equal(33, A[3 - 0])
    assert_equal(44, A[4 - 0])
    var B = Array1D_int(5, 11, 22, 33, 44, 55)
    B.redimension(Array1D_int(3, 7))
    assert_equal(3, B.l())
    assert_equal(7, B.u())
    assert_equal(5, B.size())
    assert_equal(33, B[3 - 3])
    assert_equal(44, B[4 - 3])
    assert_equal(55, B[5 - 3])
    B.redimension(Array1D_int(0, 4), 17)
    assert_equal(0, B.l())
    assert_equal(4, B.u())
    assert_equal(5, B.size())
    assert_equal(17, B[0 - 0])
    assert_equal(17, B[1 - 0])
    assert_equal(17, B[2 - 0])
    assert_equal(33, B[3 - 0])
    assert_equal(44, B[4 - 0])
    {
        var A = Array1D_int(5, 1)
        A.redimension((1, 5), 2)
        assert_equal(1, A.l())
        assert_equal(5, A.u())
        assert_true(eq(A, 1))
    }
    {
        var A = Array1D_int(5, 1)
        A.redimension((2, 4), 2)
        assert_equal(2, A.l())
        assert_equal(4, A.u())
        assert_true(eq(A, 1))
    }
    {
        var A = Array1D_int(5, 1)
        A.redimension((-2, 0), 2)
        assert_equal(-2, A.l())
        assert_equal(0, A.u())
        assert_true(eq(A, 2))
    }
    {
        var A = Array1D_int(5, 1)
        A.redimension((7, 9), 2)
        assert_equal(7, A.l())
        assert_equal(9, A.u())
        assert_true(eq(A, 2))
    }
    {
        var A = Array1D_int(2, 1)
        A.redimension((-1, 4), 2)
        assert_equal(-1, A.l())
        assert_equal(4, A.u())
        assert_equal(2, A[-1 - -1])
        assert_equal(2, A[0 - -1])
        assert_equal(1, A[1 - -1])
        assert_equal(1, A[2 - -1])
        assert_equal(2, A[3 - -1])
        assert_equal(2, A[4 - -1])
    }
    {
        var A = Array1D_int(2, 1)
        A.redimension((-1, 2), 2)
        assert_equal(-1, A.l())
        assert_equal(2, A.u())
        assert_equal(2, A[-1 - -1])
        assert_equal(2, A[0 - -1])
        assert_equal(1, A[1 - -1])
        assert_equal(1, A[2 - -1])
    }
    {
        var A = Array1D_int(2, 1)
        A.redimension((-1, 1), 2)
        assert_equal(-1, A.l())
        assert_equal(1, A.u())
        assert_equal(2, A[-1 - -1])
        assert_equal(2, A[0 - -1])
        assert_equal(1, A[1 - -1])
    }
    {
        var A = Array1D_int(2, 1)
        A.redimension((2, 4), 2)
        assert_equal(2, A.l())
        assert_equal(4, A.u())
        assert_equal(1, A[2 - 2])
        assert_equal(2, A[3 - 2])
        assert_equal(2, A[4 - 2])
    }
    {  # No moving
        var A = Array1D_int(5, 1, 2, 3, 4, 5)
        A.redimension(4)
        assert_equal(1, A.l())
        assert_equal(4, A.u())
        assert_equal(1, A[0])
        assert_equal(2, A[1])
        assert_equal(3, A[2])
        assert_equal(4, A[3])
        A.redimension(5, 6)
        assert_equal(1, A.l())
        assert_equal(5, A.u())
        assert_equal(1, A[0])
        assert_equal(2, A[1])
        assert_equal(3, A[2])
        assert_equal(4, A[3])
        assert_equal(6, A[4])
        assert_equal(5, A.capacity())
        A.redimension(6, 7)  # Reallocates
        assert_equal(6, A.capacity())
        assert_equal(1, A.l())
        assert_equal(6, A.u())
        assert_equal(1, A[0])
        assert_equal(2, A[1])
        assert_equal(3, A[2])
        assert_equal(4, A[3])
        assert_equal(6, A[4])
        assert_equal(7, A[5])
    }
    {  # No overlap
        var A = Array1D_int(1, 2, 3, 4, 5)
        A.redimension((-5, -1), 3)
        assert_equal(-5, A.l())
        assert_equal(-1, A.u())
        assert_equal(3, A[-5 - -5])
        assert_equal(3, A[-4 - -5])
        assert_equal(3, A[-3 - -5])
        assert_equal(3, A[-2 - -5])
        assert_equal(3, A[-1 - -5])
    }
    {  # No overlap
        var A = Array1D_int(1, 2, 3, 4, 5)
        A.redimension((11, 15), 3)
        assert_equal(11, A.l())
        assert_equal(15, A.u())
        assert_equal(3, A[11 - 11])
        assert_equal(3, A[12 - 11])
        assert_equal(3, A[13 - 11])
        assert_equal(3, A[14 - 11])
        assert_equal(3, A[15 - 11])
    }
    {  # Up 1 overlap
        var A = Array1D_int(1, 2, 3, 4, 5)
        A.redimension((5, 9), 3)
        assert_equal(5, A.l())
        assert_equal(9, A.u())
        assert_equal(5, A[5 - 5])
        assert_equal(3, A[6 - 5])
        assert_equal(3, A[7 - 5])
        assert_equal(3, A[8 - 5])
        assert_equal(3, A[9 - 5])
    }
    {  # Down 1 overlap
        var A = Array1D_int(1, 2, 3, 4, 5)
        A.redimension((-3, 1), 3)
        assert_equal(-3, A.l())
        assert_equal(1, A.u())
        assert_equal(3, A[-3 - -3])
        assert_equal(3, A[-2 - -3])
        assert_equal(3, A[-1 - -3])
        assert_equal(3, A[0 - -3])
        assert_equal(1, A[1 - -3])
    }
    {  # Up 1 overlap with reallocation
        var A = Array1D_int(1, 2, 3, 4, 5)
        A.redimension((5, 10), 3)
        assert_equal(5, A.l())
        assert_equal(10, A.u())
        assert_equal(5, A[5 - 5])
        assert_equal(3, A[6 - 5])
        assert_equal(3, A[7 - 5])
        assert_equal(3, A[8 - 5])
        assert_equal(3, A[9 - 5])
        assert_equal(3, A[10 - 5])
    }
    {  # Down 1 overlap with reallocation
        var A = Array1D_int(1, 2, 3, 4, 5)
        A.redimension((-4, 1), 3)
        assert_equal(-4, A.l())
        assert_equal(1, A.u())
        assert_equal(3, A[-4 - -4])
        assert_equal(3, A[-3 - -4])
        assert_equal(3, A[-2 - -4])
        assert_equal(3, A[-1 - -4])
        assert_equal(3, A[0 - -4])
        assert_equal(1, A[1 - -4])
    }


@test
def append():
    var A = Array1D_int(5, 1, 2, 3, 4, 5)
    A.append(6)
    assert_equal(1, A.l())
    assert_equal(6, A.u())
    assert_equal(6, A.size())
    assert_equal(6, A.capacity())
    assert_equal(1, A[0])
    assert_equal(6, A[5])
    A.reserve(7)  # So next append doesn't reallocate
    A.append(7)
    assert_equal(1, A.l())
    assert_equal(7, A.u())
    assert_equal(7, A.size())
    assert_equal(7, A.capacity())
    assert_equal(1, A[0])
    assert_equal(6, A[5])
    assert_equal(7, A[6])


@test
def front_and_back():
    var A = Array1D_int(5, 1, 2, 3, 4, 5)
    assert_equal(1, A.front())
    assert_equal(5, A.back())


@test
def push_back_copy():
    var A = Array1D_int(5, 1, 2, 3, 4, 5)
    var i6: Int = 6
    var i7: Int = 7
    var i8: Int = 8
    var i9: Int = 9
    A.push_back(i6)
    assert_equal(1, A.l())
    assert_equal(6, A.u())
    assert_equal(6, A.size())
    assert_equal(10, A.capacity())
    assert_equal(1, A[0])
    assert_equal(6, A[5])
    A.push_back(i7)
    A.push_back(i8)
    A.push_back(i9)
    assert_equal(1, A.l())
    assert_equal(9, A.u())
    assert_equal(9, A.size())
    assert_equal(10, A.capacity())
    assert_equal(1, A[0])
    assert_equal(6, A[5])
    assert_equal(7, A[6])
    assert_equal(8, A[7])
    assert_equal(9, A[8])


@test
def push_back_move():
    var A = Array1D_int(5, 1, 2, 3, 4, 5)
    A.push_back(6)
    assert_equal(1, A.l())
    assert_equal(6, A.u())
    assert_equal(6, A.size())
    assert_equal(10, A.capacity())
    assert_equal(1, A[0])
    assert_equal(6, A[5])
    A.push_back(7)
    A.push_back(8)
    A.push_back(9)
    assert_equal(1, A.l())
    assert_equal(9, A.u())
    assert_equal(9, A.size())
    assert_equal(10, A.capacity())
    assert_equal(1, A[0])
    assert_equal(6, A[5])
    assert_equal(7, A[6])
    assert_equal(8, A[7])
    assert_equal(9, A[8])


@test
def push_back_empty():
    var A = Array1D_int()
    A.push_back(1)
    assert_equal(1, A.l())
    assert