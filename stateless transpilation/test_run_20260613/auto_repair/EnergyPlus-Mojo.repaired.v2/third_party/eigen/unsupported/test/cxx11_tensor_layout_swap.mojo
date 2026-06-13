from main import main, VERIFY_IS_EQUAL, CALL_SUBTEST
from Eigen.CXX11.Tensor import Tensor

def test_simple_swap() raises:
    var tensor = Tensor[float32, 3, ColMajor](2, 3, 7)
    tensor.setRandom()
    var tensor2 = Tensor[float32, 3, RowMajor](tensor.swap_layout())
    VERIFY_IS_EQUAL(tensor.dimension(0), tensor2.dimension(2))
    VERIFY_IS_EQUAL(tensor.dimension(1), tensor2.dimension(1))
    VERIFY_IS_EQUAL(tensor.dimension(2), tensor2.dimension(0))
    for i in range(2):
        for j in range(3):
            for k in range(7):
                VERIFY_IS_EQUAL(tensor[i, j, k], tensor2[k, j, i])

def test_swap_as_lvalue() raises:
    var tensor = Tensor[float32, 3, ColMajor](2, 3, 7)
    tensor.setRandom()
    var tensor2 = Tensor[float32, 3, RowMajor](7, 3, 2)
    tensor2.swap_layout() = tensor
    VERIFY_IS_EQUAL(tensor.dimension(0), tensor2.dimension(2))
    VERIFY_IS_EQUAL(tensor.dimension(1), tensor2.dimension(1))
    VERIFY_IS_EQUAL(tensor.dimension(2), tensor2.dimension(0))
    for i in range(2):
        for j in range(3):
            for k in range(7):
                VERIFY_IS_EQUAL(tensor[i, j, k], tensor2[k, j, i])

def test_cxx11_tensor_layout_swap() raises:
    CALL_SUBTEST(test_simple_swap())
    CALL_SUBTEST(test_swap_as_lvalue())