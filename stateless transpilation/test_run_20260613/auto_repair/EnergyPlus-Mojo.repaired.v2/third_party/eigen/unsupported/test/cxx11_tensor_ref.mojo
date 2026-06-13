from main import *
from Eigen.CXX11.Tensor import Tensor, RowMajor, TensorRef, TensorMap, DSizes, array

def test_simple_lvalue_ref():
    var input = Tensor[int, 1](6)
    input.setRandom()
    var ref3 = TensorRef[Tensor[int, 1]](input)
    var ref4 = TensorRef[Tensor[int, 1]](input)
    VERIFY_IS_EQUAL(ref3.data(), input.data())
    VERIFY_IS_EQUAL(ref4.data(), input.data())
    for i in range(6):
        VERIFY_IS_EQUAL(ref3(i), input(i))
        VERIFY_IS_EQUAL(ref4(i), input(i))
    for i in range(6):
        ref3.coeffRef(i) = i
    for i in range(6):
        VERIFY_IS_EQUAL(input(i), i)
    for i in range(6):
        ref4.coeffRef(i) = -i * 2
    for i in range(6):
        VERIFY_IS_EQUAL(input(i), -i*2)

def test_simple_rvalue_ref():
    var input1 = Tensor[int, 1](6)
    input1.setRandom()
    var input2 = Tensor[int, 1](6)
    input2.setRandom()
    var ref3 = TensorRef[Tensor[int, 1]](input1 + input2)
    var ref4 = TensorRef[Tensor[int, 1]](input1 + input2)
    VERIFY_IS_NOT_EQUAL(ref3.data(), input1.data())
    VERIFY_IS_NOT_EQUAL(ref4.data(), input1.data())
    VERIFY_IS_NOT_EQUAL(ref3.data(), input2.data())
    VERIFY_IS_NOT_EQUAL(ref4.data(), input2.data())
    for i in range(6):
        VERIFY_IS_EQUAL(ref3(i), input1(i) + input2(i))
        VERIFY_IS_EQUAL(ref4(i), input1(i) + input2(i))

def test_multiple_dims():
    var input = Tensor[float32, 3](3,5,7)
    input.setRandom()
    var ref = TensorRef[Tensor[float32, 3]](input)
    VERIFY_IS_EQUAL(ref.data(), input.data())
    VERIFY_IS_EQUAL(ref.dimension(0), 3)
    VERIFY_IS_EQUAL(ref.dimension(1), 5)
    VERIFY_IS_EQUAL(ref.dimension(2), 7)
    for i in range(3):
        for j in range(5):
            for k in range(7):
                VERIFY_IS_EQUAL(ref(i,j,k), input(i,j,k))

def test_slice():
    var tensor = Tensor[float32, 5](2,3,5,7,11)
    tensor.setRandom()
    var indices = DSizes[ptrdiff_t, 5](1,2,3,4,5)
    var sizes = DSizes[ptrdiff_t, 5](1,1,1,1,1)
    var slice = TensorRef[Tensor[float32, 5]](tensor.slice(indices, sizes))
    VERIFY_IS_EQUAL(slice(0,0,0,0,0), tensor(1,2,3,4,5))
    var indices2 = DSizes[ptrdiff_t, 5](1,1,3,4,5)
    var sizes2 = DSizes[ptrdiff_t, 5](1,1,2,2,3)
    slice = tensor.slice(indices2, sizes2)
    for i in range(2):
        for j in range(2):
            for k in range(3):
                VERIFY_IS_EQUAL(slice(0,0,i,j,k), tensor(1,1,3+i,4+j,5+k))
    var indices3 = DSizes[ptrdiff_t, 5](0,0,0,0,0)
    var sizes3 = DSizes[ptrdiff_t, 5](2,3,1,1,1)
    slice = tensor.slice(indices3, sizes3)
    VERIFY_IS_EQUAL(slice.data(), tensor.data())

def test_ref_of_ref():
    var input = Tensor[float32, 3](3,5,7)
    input.setRandom()
    var ref = TensorRef[Tensor[float32, 3]](input)
    var ref_of_ref = TensorRef[Tensor[float32, 3]](ref)
    var ref_of_ref2 = TensorRef[Tensor[float32, 3]]()
    ref_of_ref2 = ref
    VERIFY_IS_EQUAL(ref_of_ref.data(), input.data())
    VERIFY_IS_EQUAL(ref_of_ref.dimension(0), 3)
    VERIFY_IS_EQUAL(ref_of_ref.dimension(1), 5)
    VERIFY_IS_EQUAL(ref_of_ref.dimension(2), 7)
    VERIFY_IS_EQUAL(ref_of_ref2.data(), input.data())
    VERIFY_IS_EQUAL(ref_of_ref2.dimension(0), 3)
    VERIFY_IS_EQUAL(ref_of_ref2.dimension(1), 5)
    VERIFY_IS_EQUAL(ref_of_ref2.dimension(2), 7)
    for i in range(3):
        for j in range(5):
            for k in range(7):
                VERIFY_IS_EQUAL(ref_of_ref(i,j,k), input(i,j,k))
                VERIFY_IS_EQUAL(ref_of_ref2(i,j,k), input(i,j,k))

def test_ref_in_expr():
    var input = Tensor[float32, 3](3,5,7)
    input.setRandom()
    var input_ref = TensorRef[Tensor[float32, 3]](input)
    var result = Tensor[float32, 3](3,5,7)
    result.setRandom()
    var result_ref = TensorRef[Tensor[float32, 3]](result)
    var bias = Tensor[float32, 3](3,5,7)
    bias.setRandom()
    result_ref = input_ref + bias
    for i in range(3):
        for j in range(5):
            for k in range(7):
                VERIFY_IS_EQUAL(result_ref(i,j,k), input(i,j,k) + bias(i,j,k))
                VERIFY_IS_NOT_EQUAL(result(i,j,k), input(i,j,k) + bias(i,j,k))
    result = result_ref
    for i in range(3):
        for j in range(5):
            for k in range(7):
                VERIFY_IS_EQUAL(result(i,j,k), input(i,j,k) + bias(i,j,k))

def test_coeff_ref():
    var tensor = Tensor[float32, 5](2,3,5,7,11)
    tensor.setRandom()
    var original = tensor
    var slice = TensorRef[Tensor[float32, 4]](tensor.chip(7, 4))
    slice.coeffRef(0, 0, 0, 0) = 1.0
    slice.coeffRef(1, 0, 0, 0) += 2.0
    VERIFY_IS_EQUAL(tensor(0,0,0,0,7), 1.0)
    VERIFY_IS_EQUAL(tensor(1,0,0,0,7), original(1,0,0,0,7) + 2.0)

def test_nested_ops_with_ref():
    var t = Tensor[float32, 4](2, 3, 5, 7)
    t.setRandom()
    var m = TensorMap[Tensor[const float32, 4]](t.data(), 2, 3, 5, 7)
    var paddings = array[std_pair[ptrdiff_t, ptrdiff_t], 4]()
    paddings[0] = std_make_pair(0, 0)
    paddings[1] = std_make_pair(2, 1)
    paddings[2] = std_make_pair(3, 4)
    paddings[3] = std_make_pair(0, 0)
    var shuffle_dims = DSizes[Eigen_DenseIndex, 4](0, 1, 2, 3)
    var ref = TensorRef[Tensor[const float32, 4]](m.pad(paddings))
    var trivial = array[std_pair[ptrdiff_t, ptrdiff_t], 4]()
    trivial[0] = std_make_pair(0, 0)
    trivial[1] = std_make_pair(0, 0)
    trivial[2] = std_make_pair(0, 0)
    trivial[3] = std_make_pair(0, 0)
    var padded = ref.shuffle(shuffle_dims).pad(trivial)
    VERIFY_IS_EQUAL(padded.dimension(0), 2+0)
    VERIFY_IS_EQUAL(padded.dimension(1), 3+3)
    VERIFY_IS_EQUAL(padded.dimension(2), 5+7)
    VERIFY_IS_EQUAL(padded.dimension(3), 7+0)
    for i in range(2):
        for j in range(6):
            for k in range(12):
                for l in range(7):
                    if j >= 2 and j < 5 and k >= 3 and k < 8:
                        VERIFY_IS_EQUAL(padded(i,j,k,l), t(i,j-2,k-3,l))
                    else:
                        VERIFY_IS_EQUAL(padded(i,j,k,l), 0.0)

def test_cxx11_tensor_ref():
    CALL_SUBTEST(test_simple_lvalue_ref())
    CALL_SUBTEST(test_simple_rvalue_ref())
    CALL_SUBTEST(test_multiple_dims())
    CALL_SUBTEST(test_slice())
    CALL_SUBTEST(test_ref_of_ref())
    CALL_SUBTEST(test_ref_in_expr())
    CALL_SUBTEST(test_coeff_ref())
    CALL_SUBTEST(test_nested_ops_with_ref())