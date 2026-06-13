from main import main, VERIFY_IS_EQUAL, CALL_SUBTEST
from Eigen.CXX11.Tensor import Tensor, ColMajor, RowMajor

def test_simple_striding[DataLayout: Int]() raises:
    var tensor = Tensor[float32, 4, DataLayout](2, 3, 5, 7)
    tensor.setRandom()
    var strides = array[Int, 4](1, 1, 1, 1)
    var no_stride = Tensor[float32, 4, DataLayout]()
    no_stride = tensor.stride(strides)
    VERIFY_IS_EQUAL(no_stride.dimension(0), 2)
    VERIFY_IS_EQUAL(no_stride.dimension(1), 3)
    VERIFY_IS_EQUAL(no_stride.dimension(2), 5)
    VERIFY_IS_EQUAL(no_stride.dimension(3), 7)
    for i in range(2):
        for j in range(3):
            for k in range(5):
                for l in range(7):
                    VERIFY_IS_EQUAL(tensor[i, j, k, l], no_stride[i, j, k, l])
    strides[0] = 2
    strides[1] = 4
    strides[2] = 2
    strides[3] = 3
    var stride = Tensor[float32, 4, DataLayout]()
    stride = tensor.stride(strides)
    VERIFY_IS_EQUAL(stride.dimension(0), 1)
    VERIFY_IS_EQUAL(stride.dimension(1), 1)
    VERIFY_IS_EQUAL(stride.dimension(2), 3)
    VERIFY_IS_EQUAL(stride.dimension(3), 3)
    for i in range(1):
        for j in range(1):
            for k in range(3):
                for l in range(3):
                    VERIFY_IS_EQUAL(tensor[2*i, 4*j, 2*k, 3*l], stride[i, j, k, l])

def test_striding_as_lvalue[DataLayout: Int]() raises:
    var tensor = Tensor[float32, 4, DataLayout](2, 3, 5, 7)
    tensor.setRandom()
    var strides = array[Int, 4](2, 4, 2, 3)
    var result = Tensor[float32, 4, DataLayout](3, 12, 10, 21)
    result.stride(strides) = tensor
    for i in range(2):
        for j in range(3):
            for k in range(5):
                for l in range(7):
                    VERIFY_IS_EQUAL(tensor[i, j, k, l], result[2*i, 4*j, 2*k, 3*l])
    var no_strides = array[Int, 4](1, 1, 1, 1)
    var result2 = Tensor[float32, 4, DataLayout](3, 12, 10, 21)
    result2.stride(strides) = tensor.stride(no_strides)
    for i in range(2):
        for j in range(3):
            for k in range(5):
                for l in range(7):
                    VERIFY_IS_EQUAL(tensor[i, j, k, l], result2[2*i, 4*j, 2*k, 3*l])

def test_cxx11_tensor_striding() raises:
    CALL_SUBTEST(test_simple_striding[ColMajor]())
    CALL_SUBTEST(test_simple_striding[RowMajor]())
    CALL_SUBTEST(test_striding_as_lvalue[ColMajor]())
    CALL_SUBTEST(test_striding_as_lvalue[RowMajor]())