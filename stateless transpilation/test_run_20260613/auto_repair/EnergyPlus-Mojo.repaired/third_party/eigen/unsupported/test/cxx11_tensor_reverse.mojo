# Mojo translation of third_party/eigen/unsupported/test/cxx11_tensor_reverse.cpp

from tensor import Tensor
from memory import Array

# DataLayout constants (replicating ColMajor and RowMajor)
let ColMajor: Int = 0
let RowMajor: Int = 1

# Helper macro replacements (VERIFY_IS_EQUAL -> assert)
def assert(condition: Bool, message: String = "") -> None:
    if not condition:
        print("Assertion failed: " + message)
        # In a real test framework, this would abort.

def VERIFY_IS_EQUAL(a: Float32, b: Float32) -> None:
    assert(a == b, "Values not equal")
def VERIFY_IS_EQUAL(a: Int, b: Int) -> None:
    assert(a == b, "Dimensions not equal")

# Template function test_simple_reverse
def test_simple_reverse[DataLayout: Int]() -> None:
    var tensor = Tensor[Float32, 4, DataLayout](2, 3, 5, 7)
    tensor.setRandom()
    
    var dim_rev: Array[Bool, 4] = Array[Bool, 4](false, true, true, false)
    
    var reversed_tensor = Tensor[Float32, 4, DataLayout]()
    reversed_tensor = tensor.reverse(dim_rev)
    
    VERIFY_IS_EQUAL(reversed_tensor.dimension(0), 2)
    VERIFY_IS_EQUAL(reversed_tensor.dimension(1), 3)
    VERIFY_IS_EQUAL(reversed_tensor.dimension(2), 5)
    VERIFY_IS_EQUAL(reversed_tensor.dimension(3), 7)
    
    for i in range(2):
        for j in range(3):
            for k in range(5):
                for l in range(7):
                    VERIFY_IS_EQUAL(tensor(i, j, k, l), reversed_tensor(i, 2 - j, 4 - k, l))
    
    dim_rev[0] = true
    dim_rev[1] = false
    dim_rev[2] = false
    dim_rev[3] = false
    reversed_tensor = tensor.reverse(dim_rev)
    
    VERIFY_IS_EQUAL(reversed_tensor.dimension(0), 2)
    VERIFY_IS_EQUAL(reversed_tensor.dimension(1), 3)
    VERIFY_IS_EQUAL(reversed_tensor.dimension(2), 5)
    VERIFY_IS_EQUAL(reversed_tensor.dimension(3), 7)
    
    for i in range(2):
        for j in range(3):
            for k in range(5):
                for l in range(7):
                    VERIFY_IS_EQUAL(tensor(i, j, k, l), reversed_tensor(1 - i, j, k, l))
    
    dim_rev[0] = true
    dim_rev[1] = false
    dim_rev[2] = false
    dim_rev[3] = true
    reversed_tensor = tensor.reverse(dim_rev)
    
    VERIFY_IS_EQUAL(reversed_tensor.dimension(0), 2)
    VERIFY_IS_EQUAL(reversed_tensor.dimension(1), 3)
    VERIFY_IS_EQUAL(reversed_tensor.dimension(2), 5)
    VERIFY_IS_EQUAL(reversed_tensor.dimension(3), 7)
    
    for i in range(2):
        for j in range(3):
            for k in range(5):
                for l in range(7):
                    VERIFY_IS_EQUAL(tensor(i, j, k, l), reversed_tensor(1 - i, j, k, 6 - l))


# Template function test_expr_reverse
def test_expr_reverse[DataLayout: Int](LValue: Bool) -> None:
    var tensor = Tensor[Float32, 4, DataLayout](2, 3, 5, 7)
    tensor.setRandom()
    
    var dim_rev: Array[Bool, 4] = Array[Bool, 4](false, true, false, true)
    
    var expected = Tensor[Float32, 4, DataLayout](2, 3, 5, 7)
    if LValue:
        expected.reverse(dim_rev).assign(tensor)   # assign equivalent of = operator
    else:
        expected = tensor.reverse(dim_rev)
    
    var result = Tensor[Float32, 4, DataLayout](2, 3, 5, 7)
    
    var src_slice_dim: Array[Int, 4] = Array[Int, 4](2, 3, 1, 7)
    var src_slice_start: Array[Int, 4] = Array[Int, 4](0, 0, 0, 0)
    var dst_slice_dim: Array[Int, 4] = src_slice_dim
    var dst_slice_start: Array[Int, 4] = src_slice_start
    
    for i in range(5):
        if LValue:
            result.slice(dst_slice_start, dst_slice_dim).reverse(dim_rev).assign(
                tensor.slice(src_slice_start, src_slice_dim))
        else:
            result.slice(dst_slice_start, dst_slice_dim).assign(
                tensor.slice(src_slice_start, src_slice_dim).reverse(dim_rev))
        src_slice_start[2] += 1
        dst_slice_start[2] += 1
    
    VERIFY_IS_EQUAL(result.dimension(0), 2)
    VERIFY_IS_EQUAL(result.dimension(1), 3)
    VERIFY_IS_EQUAL(result.dimension(2), 5)
    VERIFY_IS_EQUAL(result.dimension(3), 7)
    
    for i in range(expected.dimension(0)):
        for j in range(expected.dimension(1)):
            for k in range(expected.dimension(2)):
                for l in range(expected.dimension(3)):
                    VERIFY_IS_EQUAL(result(i, j, k, l), expected(i, j, k, l))
    
    dst_slice_start[2] = 0
    result.setRandom()
    
    for i in range(5):
        if LValue:
            result.slice(dst_slice_start, dst_slice_dim).reverse(dim_rev).assign(
                tensor.slice(dst_slice_start, dst_slice_dim))
        else:
            result.slice(dst_slice_start, dst_slice_dim).assign(
                tensor.reverse(dim_rev).slice(dst_slice_start, dst_slice_dim))
        dst_slice_start[2] += 1
    
    for i in range(expected.dimension(0)):
        for j in range(expected.dimension(1)):
            for k in range(expected.dimension(2)):
                for l in range(expected.dimension(3)):
                    VERIFY_IS_EQUAL(result(i, j, k, l), expected(i, j, k, l))


# Main test function
def test_cxx11_tensor_reverse() -> None:
    test_simple_reverse[ColMajor]()
    test_simple_reverse[RowMajor]()
    test_expr_reverse[ColMajor](true)
    test_expr_reverse[RowMajor](true)
    test_expr_reverse[ColMajor](false)
    test_expr_reverse[RowMajor](false)