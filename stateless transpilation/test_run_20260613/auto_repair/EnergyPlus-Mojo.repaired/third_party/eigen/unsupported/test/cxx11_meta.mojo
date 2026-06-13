# Port of cxx11_meta.cpp

from ......CXX11.src.util.CXX11Meta import (
    is_same, type_list, numeric_list, gen_numeric_list,
    gen_numeric_list_reversed, gen_numeric_list_swapped_pair, gen_numeric_list_repeated,
    concat, mconcat, take, skip, slice, get,
    id_numeric, id_type, is_same_gf,
    apply_op_from_left, apply_op_from_right,
    contained_in_list, contained_in_list_gf,
    arg_prod, arg_sum, sum_op, product_op,
    array_reverse, array_sum, array_prod, array_reduce,
    array_zip, array_zip_and_reduce, array_apply, array_apply_and_reduce,
    repeat, instantiate_by_c_array
)

# Dummy types
struct dummy_a:

struct dummy_b:

struct dummy_c:

struct dummy_d:

struct dummy_e:

# Dummy binary operation (specialized for the test)
struct dummy_op(A: AnyType, B: AnyType):
    alias type: AnyType

# Specializations (using when clauses in Mojo)
when A == dummy_a and B == dummy_b:
    struct dummy_op[A, B]:
        alias type = dummy_c

when A == dummy_b and B == dummy_a:
    struct dummy_op[A, B]:
        alias type = dummy_d

when A == dummy_b and B == dummy_c:
    struct dummy_op[A, B]:
        alias type = dummy_a

when A == dummy_c and B == dummy_b:
    struct dummy_op[A, B]:
        alias type = dummy_d

when A == dummy_c and B == dummy_a:
    struct dummy_op[A, B]:
        alias type = dummy_b

when A == dummy_a and B == dummy_c:
    struct dummy_op[A, B]:
        alias type = dummy_d

when A == dummy_a and B == dummy_a:
    struct dummy_op[A, B]:
        alias type = dummy_e

when A == dummy_b and B == dummy_b:
    struct dummy_op[A, B]:
        alias type = dummy_e

when A == dummy_c and B == dummy_c:
    struct dummy_op[A, B]:
        alias type = dummy_e

# Dummy test trait with global_flags
struct dummy_test(A: AnyType, B: AnyType):
    alias value: Bool = False
    alias global_flags: Int = 0

when A == dummy_a and B == dummy_a:
    struct dummy_test[A, B]:
        alias value: Bool = True
        alias global_flags: Int = 1

when A == dummy_b and B == dummy_b:
    struct dummy_test[A, B]:
        alias value: Bool = True
        alias global_flags: Int = 2

when A == dummy_c and B == dummy_c:
    struct dummy_test[A, B]:
        alias value: Bool = True
        alias global_flags: Int = 4

# Times2 operation struct
struct times2_op:
    alias run = fn[T: AnyType](v: T) -> T:
        return v * 2

# Dummy instance for testing instantiate_by_c_array
struct dummy_inst:
    var c: Int

    def __init__(inout self):
        self.c = 0

    def __init__(inout self, a: Int):
        self.c = 1

    def __init__(inout self, a: Int, b: Int):
        self.c = 2

    def __init__(inout self, a: Int, b: Int, c: Int):
        self.c = 3

    def __init__(inout self, a: Int, b: Int, c: Int, d: Int):
        self.c = 4

    def __init__(inout self, a: Int, b: Int, c: Int, d: Int, e: Int):
        self.c = 5

# Test macros (simplified)
def VERIFY(cond: Bool):
    if not cond:
        print("VERIFY failed")

def VERIFY_IS_EQUAL(a: Int, b: Int):
    if a != b:
        print("VERIFY_IS_EQUAL failed: ", a, " != ", b)

def VERIFY_IS_APPROX(a: Float64, b: Float64):
    if abs(a - b) > 1e-6:
        print("VERIFY_IS_APPROX failed: ", a, " != ", b)

def CALL_SUBTEST(f: fn() -> None):
    f()

# Test functions
def test_gen_numeric_list():
    VERIFY((is_same[gen_numeric_list[Int, 0].type, numeric_list[Int]].value))
    VERIFY((is_same[gen_numeric_list[Int, 1].type, numeric_list[Int, 0]].value))
    VERIFY((is_same[gen_numeric_list[Int, 2].type, numeric_list[Int, 0, 1]].value))
    VERIFY((is_same[gen_numeric_list[Int, 5].type, numeric_list[Int, 0, 1, 2, 3, 4]].value))
    VERIFY((is_same[gen_numeric_list[Int, 10].type, numeric_list[Int, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9]].value))
    VERIFY((is_same[gen_numeric_list[Int, 0, 42].type, numeric_list[Int]].value))
    VERIFY((is_same[gen_numeric_list[Int, 1, 42].type, numeric_list[Int, 42]].value))
    VERIFY((is_same[gen_numeric_list[Int, 2, 42].type, numeric_list[Int, 42, 43]].value))
    VERIFY((is_same[gen_numeric_list[Int, 5, 42].type, numeric_list[Int, 42, 43, 44, 45, 46]].value))
    VERIFY((is_same[gen_numeric_list[Int, 10, 42].type, numeric_list[Int, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51]].value))
    VERIFY((is_same[gen_numeric_list_reversed[Int, 0].type, numeric_list[Int]].value))
    VERIFY((is_same[gen_numeric_list_reversed[Int, 1].type, numeric_list[Int, 0]].value))
    VERIFY((is_same[gen_numeric_list_reversed[Int, 2].type, numeric_list[Int, 1, 0]].value))
    VERIFY((is_same[gen_numeric_list_reversed[Int, 5].type, numeric_list[Int, 4, 3, 2, 1, 0]].value))
    VERIFY((is_same[gen_numeric_list_reversed[Int, 10].type, numeric_list[Int, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]].value))
    VERIFY((is_same[gen_numeric_list_reversed[Int, 0, 42].type, numeric_list[Int]].value))
    VERIFY((is_same[gen_numeric_list_reversed[Int, 1, 42].type, numeric_list[Int, 42]].value))
    VERIFY((is_same[gen_numeric_list_reversed[Int, 2, 42].type, numeric_list[Int, 43, 42]].value))
    VERIFY((is_same[gen_numeric_list_reversed[Int, 5, 42].type, numeric_list[Int, 46, 45, 44, 43, 42]].value))
    VERIFY((is_same[gen_numeric_list_reversed[Int, 10, 42].type, numeric_list[Int, 51, 50, 49, 48, 47, 46, 45, 44, 43, 42]].value))
    VERIFY((is_same[gen_numeric_list_swapped_pair[Int, 0, 2, 3].type, numeric_list[Int]].value))
    VERIFY((is_same[gen_numeric_list_swapped_pair[Int, 1, 2, 3].type, numeric_list[Int, 0]].value))
    VERIFY((is_same[gen_numeric_list_swapped_pair[Int, 2, 2, 3].type, numeric_list[Int, 0, 1]].value))
    VERIFY((is_same[gen_numeric_list_swapped_pair[Int, 5, 2, 3].type, numeric_list[Int, 0, 1, 3, 2, 4]].value))
    VERIFY((is_same[gen_numeric_list_swapped_pair[Int, 10, 2, 3].type, numeric_list[Int, 0, 1, 3, 2, 4, 5, 6, 7, 8, 9]].value))
    VERIFY((is_same[gen_numeric_list_swapped_pair[Int, 0, 44, 45, 42].type, numeric_list[Int]].value))
    VERIFY((is_same[gen_numeric_list_swapped_pair[Int, 1, 44, 45, 42].type, numeric_list[Int, 42]].value))
    VERIFY((is_same[gen_numeric_list_swapped_pair[Int, 2, 44, 45, 42].type, numeric_list[Int, 42, 43]].value))
    VERIFY((is_same[gen_numeric_list_swapped_pair[Int, 5, 44, 45, 42].type, numeric_list[Int, 42, 43, 45, 44, 46]].value))
    VERIFY((is_same[gen_numeric_list_swapped_pair[Int, 10, 44, 45, 42].type, numeric_list[Int, 42, 43, 45, 44, 46, 47, 48, 49, 50, 51]].value))
    VERIFY((is_same[gen_numeric_list_repeated[Int, 0, 0].type, numeric_list[Int]].value))
    VERIFY((is_same[gen_numeric_list_repeated[Int, 1, 0].type, numeric_list[Int, 0]].value))
    VERIFY((is_same[gen_numeric_list_repeated[Int, 2, 0].type, numeric_list[Int, 0, 0]].value))
    VERIFY((is_same[gen_numeric_list_repeated[Int, 5, 0].type, numeric_list[Int, 0, 0, 0, 0, 0]].value))
    VERIFY((is_same[gen_numeric_list_repeated[Int, 10, 0].type, numeric_list[Int, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]].value))

def test_concat():
    VERIFY((is_same[concat[type_list[dummy_a, dummy_a], type_list[]].type, type_list[dummy_a, dummy_a]].value))
    VERIFY((is_same[concat[type_list[], type_list[dummy_a, dummy_a]].type, type_list[dummy_a, dummy_a]].value))
    VERIFY((is_same[concat[type_list[dummy_a, dummy_a], type_list[dummy_a, dummy_a]].type, type_list[dummy_a, dummy_a, dummy_a, dummy_a]].value))
    VERIFY((is_same[concat[type_list[dummy_a, dummy_a], type_list[dummy_b, dummy_c]].type, type_list[dummy_a, dummy_a, dummy_b, dummy_c]].value))
    VERIFY((is_same[concat[type_list[dummy_a], type_list[dummy_b, dummy_c]].type, type_list[dummy_a, dummy_b, dummy_c]].value))
    VERIFY((is_same[concat[numeric_list[Int, 0, 0], numeric_list[Int]].type, numeric_list[Int, 0, 0]].value))
    VERIFY((is_same[concat[numeric_list[Int], numeric_list[Int, 0, 0]].type, numeric_list[Int, 0, 0]].value))
    VERIFY((is_same[concat[numeric_list[Int, 0, 0], numeric_list[Int, 0, 0]].type, numeric_list[Int, 0, 0, 0, 0]].value))
    VERIFY((is_same[concat[numeric_list[Int, 0, 0], numeric_list[Int, 1, 2]].type, numeric_list[Int, 0, 0, 1, 2]].value))
    VERIFY((is_same[concat[numeric_list[Int, 0], numeric_list[Int, 1, 2]].type, numeric_list[Int, 0, 1, 2]].value))
    VERIFY((is_same[mconcat[type_list[dummy_a]].type, type_list[dummy_a]].value))
    VERIFY((is_same[mconcat[type_list[dummy_a], type_list[dummy_b]].type, type_list[dummy_a, dummy_b]].value))
    VERIFY((is_same[mconcat[type_list[dummy_a], type_list[dummy_b], type_list[dummy_c]].type, type_list[dummy_a, dummy_b, dummy_c]].value))
    VERIFY((is_same[mconcat[type_list[dummy_a], type_list[dummy_b, dummy_c]].type, type_list[dummy_a, dummy_b, dummy_c]].value))
    VERIFY((is_same[mconcat[type_list[dummy_a, dummy_b], type_list[dummy_c]].type, type_list[dummy_a, dummy_b, dummy_c]].value))
    VERIFY((is_same[mconcat[numeric_list[Int, 0]].type, numeric_list[Int, 0]].value))
    VERIFY((is_same[mconcat[numeric_list[Int, 0], numeric_list[Int, 1]].type, numeric_list[Int, 0, 1]].value))
    VERIFY((is_same[mconcat[numeric_list[Int, 0], numeric_list[Int, 1], numeric_list[Int, 2]].type, numeric_list[Int, 0, 1, 2]].value))
    VERIFY((is_same[mconcat[numeric_list[Int, 0], numeric_list[Int, 1, 2]].type, numeric_list[Int, 0, 1, 2]].value))
    VERIFY((is_same[mconcat[numeric_list[Int, 0, 1], numeric_list[Int, 2]].type, numeric_list[Int, 0, 1, 2]].value))

def test_slice():
    alias tl = type_list[dummy_a, dummy_a, dummy_b, dummy_b, dummy_c, dummy_c]
    alias il = numeric_list[Int, 0, 1, 2, 3, 4, 5]
    VERIFY((is_same[take[0, tl].type, type_list[]].value))
    VERIFY((is_same[take[1, tl].type, type_list[dummy_a]].value))
    VERIFY((is_same[take[2, tl].type, type_list[dummy_a, dummy_a]].value))
    VERIFY((is_same[take[3, tl].type, type_list[dummy_a, dummy_a, dummy_b]].value))
    VERIFY((is_same[take[4, tl].type, type_list[dummy_a, dummy_a, dummy_b, dummy_b]].value))
    VERIFY((is_same[take[5, tl].type, type_list[dummy_a, dummy_a, dummy_b, dummy_b, dummy_c]].value))
    VERIFY((is_same[take[6, tl].type, type_list[dummy_a, dummy_a, dummy_b, dummy_b, dummy_c, dummy_c]].value))
    VERIFY((is_same[take[0, il].type, numeric_list[Int]].value))
    VERIFY((is_same[take[1, il].type, numeric_list[Int, 0]].value))
    VERIFY((is_same[take[2, il].type, numeric_list[Int, 0, 1]].value))
    VERIFY((is_same[take[3, il].type, numeric_list[Int, 0, 1, 2]].value))
    VERIFY((is_same[take[4, il].type, numeric_list[Int, 0, 1, 2, 3]].value))
    VERIFY((is_same[take[5, il].type, numeric_list[Int, 0, 1, 2, 3, 4]].value))
    VERIFY((is_same[take[6, il].type, numeric_list[Int, 0, 1, 2, 3, 4, 5]].value))
    VERIFY((is_same[skip[0, tl].type, type_list[dummy_a, dummy_a, dummy_b, dummy_b, dummy_c, dummy_c]].value))
    VERIFY((is_same[skip[1, tl].type, type_list[dummy_a, dummy_b, dummy_b, dummy_c, dummy_c]].value))
    VERIFY((is_same[skip[2, tl].type, type_list[dummy_b, dummy_b, dummy_c, dummy_c]].value))
    VERIFY((is_same[skip[3, tl].type, type_list[dummy_b, dummy_c, dummy_c]].value))
    VERIFY((is_same[skip[4, tl].type, type_list[dummy_c, dummy_c]].value))
    VERIFY((is_same[skip[5, tl].type, type_list[dummy_c]].value))
    VERIFY((is_same[skip[6, tl].type, type_list[]].value))
    VERIFY((is_same[skip[0, il].type, numeric_list[Int, 0, 1, 2, 3, 4, 5]].value))
    VERIFY((is_same[skip[1, il].type, numeric_list[Int, 1, 2, 3, 4, 5]].value))
    VERIFY((is_same[skip[2, il].type, numeric_list[Int, 2, 3, 4, 5]].value))
    VERIFY((is_same[skip[3, il].type, numeric_list[Int, 3, 4, 5]].value))
    VERIFY((is_same[skip[4, il].type, numeric_list[Int, 4, 5]].value))
    VERIFY((is_same[skip[5, il].type, numeric_list[Int, 5]].value))
    VERIFY((is_same[skip[6, il].type, numeric_list[Int]].value))
    VERIFY((is_same[slice[0, 3, tl].type, take[3, tl].type].value))
    VERIFY((is_same[slice[0, 3, il].type, take[3, il].type].value))
    VERIFY((is_same[slice[1, 3, tl].type, type_list[dummy_a, dummy_b, dummy_b]].value))
    VERIFY((is_same[slice[1, 3, il].type, numeric_list[Int, 1, 2, 3]].value))

def test_get():
    alias tl = type_list[dummy_a, dummy_a, dummy_b, dummy_b, dummy_c, dummy_c]
    alias il = numeric_list[Int, 4, 8, 15, 16, 23, 42]
    VERIFY((is_same[get[0, tl].type, dummy_a].value))
    VERIFY((is_same[get[1, tl].type, dummy_a].value))
    VERIFY((is_same[get[2, tl].type, dummy_b].value))
    VERIFY((is_same[get[3, tl].type, dummy_b].value))
    VERIFY((is_same[get[4, tl].type, dummy_c].value))
    VERIFY((is_same[get[5, tl].type, dummy_c].value))
    VERIFY_IS_EQUAL(Int(get[0, il].value), 4)
    VERIFY_IS_EQUAL(Int(get[1, il].value), 8)
    VERIFY_IS_EQUAL(Int(get[2, il].value), 15)
    VERIFY_IS_EQUAL(Int(get[3, il].value), 16)
    VERIFY_IS_EQUAL(Int(get[4, il].value), 23)
    VERIFY_IS_EQUAL(Int(get[5, il].value), 42)

def test_id_helper(a: dummy_a, b: dummy_a, c: dummy_a):
    _ = a
    _ = b
    _ = c

def test_id_numeric[..ii: Int]():
    # Using id_numeric to create dummy_a instances with given indices
    test_id_helper(id_numeric[Int, ii, dummy_a].type() ...)

def test_id_type[..tt: AnyType]():
    # Using id_type to create dummy_a instances from types
    test_id_helper(id_type[tt, dummy_a].type() ...)

def test_id():
    test_id_numeric[1, 4, 6]()
    test_id_type[dummy_a, dummy_b, dummy_c]()

def test_is_same_gf():
    VERIFY((!is_same_gf[dummy_a, dummy_b].value))
    VERIFY((!!is_same_gf[dummy_a, dummy_a].value))
    VERIFY_IS_EQUAL(Int(!!is_same_gf[dummy_a, dummy_b].global_flags), 0)
    VERIFY_IS_EQUAL(Int(!!is_same_gf[dummy_a, dummy_a].global_flags), 0)

def test_apply_op():
    alias tl = type_list[dummy_a, dummy_b, dummy_c]
    VERIFY((!!is_same[apply_op_from_left[dummy_op, dummy_a, tl].type, type_list[dummy_e, dummy_c, dummy_d]].value))
    VERIFY((!!is_same[apply_op_from_right[dummy_op, dummy_a, tl].type, type_list[dummy_e, dummy_d, dummy_b]].value))

def test_contained_in_list():
    alias tl = type_list[dummy_a, dummy_b, dummy_c]
    VERIFY((!!contained_in_list[is_same, dummy_a, tl].value))
    VERIFY((!!contained_in_list[is_same, dummy_b, tl].value))
    VERIFY((!!contained_in_list[is_same, dummy_c, tl].value))
    VERIFY((!contained_in_list[is_same, dummy_d, tl].value))
    VERIFY((!contained_in_list[is_same, dummy_e, tl].value))
    VERIFY((!!contained_in_list_gf[dummy_test, dummy_a, tl].value))
    VERIFY((!!contained_in_list_gf[dummy_test, dummy_b, tl].value))
    VERIFY((!!contained_in_list_gf[dummy_test, dummy_c, tl].value))
    VERIFY((!contained_in_list_gf[dummy_test, dummy_d, tl].value))
    VERIFY((!contained_in_list_gf[dummy_test, dummy_e, tl].value))
    VERIFY_IS_EQUAL(Int(contained_in_list_gf[dummy_test, dummy_a, tl].global_flags), 1)
    VERIFY_IS_EQUAL(Int(contained_in_list_gf[dummy_test, dummy_b, tl].global_flags), 2)
    VERIFY_IS_EQUAL(Int(contained_in_list_gf[dummy_test, dummy_c, tl].global_flags), 4)
    VERIFY_IS_EQUAL(Int(contained_in_list_gf[dummy_test, dummy_d, tl].global_flags), 0)
    VERIFY_IS_EQUAL(Int(contained_in_list_gf[dummy_test, dummy_e, tl].global_flags), 0)

def test_arg_reductions():
    VERIFY_IS_EQUAL(arg_sum(1, 2, 3, 4), 10)
    VERIFY_IS_EQUAL(arg_prod(1, 2, 3, 4), 24)
    VERIFY_IS_APPROX(arg_sum(0.5, 2, 5), 7.5)
    VERIFY_IS_APPROX(arg_prod(0.5, 2, 5), 5.0)

def test_array_reverse_and_reduce():
    var a = array[Int, 6](4, 8, 15, 16, 23, 42)
    var b = array[Int, 6](42, 23, 16, 15, 8, 4)
    VERIFY((array_reverse(a) == b))
    VERIFY((array_reverse(b) == a))
    VERIFY_IS_EQUAL(Int(array_sum(a)), 108)
    VERIFY_IS_EQUAL(Int(array_sum(b)), 108)
    VERIFY_IS_EQUAL(Int(array_prod(a)), 7418880)
    VERIFY_IS_EQUAL(Int(array_prod(b)), 7418880)

def test_array_zip_and_apply():
    var a = array[Int, 6](4, 8, 15, 16, 23, 42)
    var b = array[Int, 6](0, 1, 2, 3, 4, 5)
    var c = array[Int, 6](4, 9, 17, 19, 27, 47)
    var d = array[Int, 6](0, 8, 30, 48, 92, 210)
    var e = array[Int, 6](0, 2, 4, 6, 8, 10)
    VERIFY((array_zip[sum_op](a, b) == c))
    VERIFY((array_zip[product_op](a, b) == d))
    VERIFY((array_apply[times2_op](b) == e))
    VERIFY_IS_EQUAL(Int(array_apply_and_reduce[sum_op, times2_op](a)), 216)
    VERIFY_IS_EQUAL(Int(array_apply_and_reduce[sum_op, times2_op](b)), 30)
    VERIFY_IS_EQUAL(Int(array_zip_and_reduce[product_op, sum_op](a, b)), 14755932)
    VERIFY_IS_EQUAL(Int(array_zip_and_reduce[sum_op, product_op](a, b)), 388)

def test_array_misc():
    var a3 = array[Int, 3](1, 1, 1)
    var a6 = array[Int, 6](2, 2, 2, 2, 2, 2)
    VERIFY((repeat[3, Int](1) == a3))
    VERIFY((repeat[6, Int](2) == a6))
    var data: StaticArray[Int, 5] = [0, 1, 2, 3, 4]
    VERIFY_IS_EQUAL(Int(instantiate_by_c_array[dummy_inst, Int, 0](data).c), 0)
    VERIFY_IS_EQUAL(Int(instantiate_by_c_array[dummy_inst, Int, 1](data).c), 1)
    VERIFY_IS_EQUAL(Int(instantiate_by_c_array[dummy_inst, Int, 2](data).c), 2)
    VERIFY_IS_EQUAL(Int(instantiate_by_c_array[dummy_inst, Int, 3](data).c), 3)
    VERIFY_IS_EQUAL(Int(instantiate_by_c_array[dummy_inst, Int, 4](data).c), 4)
    VERIFY_IS_EQUAL(Int(instantiate_by_c_array[dummy_inst, Int, 5](data).c), 5)

def test_cxx11_meta():
    CALL_SUBTEST(test_gen_numeric_list)
    CALL_SUBTEST(test_concat)
    CALL_SUBTEST(test_slice)
    CALL_SUBTEST(test_get)
    CALL_SUBTEST(test_id)
    CALL_SUBTEST(test_is_same_gf)
    CALL_SUBTEST(test_apply_op)
    CALL_SUBTEST(test_contained_in_list)
    CALL_SUBTEST(test_arg_reductions)
    CALL_SUBTEST(test_array_reverse_and_reduce)
    CALL_SUBTEST(test_array_zip_and_apply)
    CALL_SUBTEST(test_array_misc)

# End of translation