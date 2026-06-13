from main import main, VERIFY_IS_EQUAL, CALL_SUBTEST
from Eigen.CXX11.Tensor import Tensor, ColMajor, RowMajor

def test_simple_inflation[DataLayout: Int]() raises:
    var tensor = Tensor[float32, 4, DataLayout](2, 3, 5, 7)
    tensor.setRandom()
    var strides = array[Int, 4](1, 1, 1, 1)
    var no_stride = Tensor[float32, 4, DataLayout]()
    no_stride = tensor.inflate(strides)
    VERIFY_IS_EQUAL(no_stride.dimension(0), 2)
    VERIFY_IS_EQUAL(no_stride.dimension(1), 3)
    VERIFY_IS_EQUAL(no_stride.dimension(2), 5)
    VERIFY_IS_EQUAL(no_stride.dimension(3), 7)
    for i in range(2):
        for j in range(3):
            for k in range(5):
                for l in range(7):
                    VERIFY_IS_EQUAL(tensor(i, j, k, l), no_stride(i, j, k, l))
    strides[0] = 2
    strides[1] = 4
    strides[2] = 2
    strides[3] = 3
    var inflated = Tensor[float32, 4, DataLayout]()
    inflated = tensor.inflate(strides)
    VERIFY_IS_EQUAL(inflated.dimension(0), 3)
    VERIFY_IS_EQUAL(inflated.dimension(1), 9)
    VERIFY_IS_EQUAL(inflated.dimension(2), 9)
    VERIFY_IS_EQUAL(inflated.dimension(3), 19)
    for i in range(3):
        for j in range(9):
            for k in range(9):
                for l in range(19):
                    if i % 2 == 0 and j % 4 == 0 and k % 2 == 0 and l % 3 == 0:
                        VERIFY_IS_EQUAL(inflated(i, j, k, l), tensor(i // 2, j // 4, k // 2, l // 3))
                    else:
                        VERIFY_IS_EQUAL(0, inflated(i, j, k, l))

def test_cxx11_tensor_inflation() raises:
    CALL_SUBTEST(test_simple_inflation[ColMajor]())
    CALL_SUBTEST(test_simple_inflation[RowMajor]())