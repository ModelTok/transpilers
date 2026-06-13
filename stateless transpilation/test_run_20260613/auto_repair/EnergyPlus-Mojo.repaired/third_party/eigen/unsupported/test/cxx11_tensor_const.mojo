from main import main
from Eigen.CXX11.Tensor import Tensor, TensorMap
from Eigen.CXX11.Tensor import Tensor as Tensor
from Eigen.CXX11.Tensor import TensorMap as TensorMap

def test_simple_assign() raises:
    var random = Tensor[Int, 3](2, 3, 7)
    random.setRandom()
    var constant = TensorMap[Tensor[const Int, 3]](random.data(), 2, 3, 7)
    var result = Tensor[Int, 3](2, 3, 7)
    result = constant
    for i in range(0, 2):
        for j in range(0, 3):
            for k in range(0, 7):
                VERIFY_IS_EQUAL(result[i, j, k], random[i, j, k])

def test_assign_of_const_tensor() raises:
    var random = Tensor[Int, 3](2, 3, 7)
    random.setRandom()
    var constant1 = TensorMap[Tensor[const Int, 3]](random.data(), 2, 3, 7)
    var constant2 = TensorMap[const Tensor[Int, 3]](random.data(), 2, 3, 7)
    var constant3 = const TensorMap[Tensor[Int, 3]](random.data(), 2, 3, 7)
    var result1 = constant1.chip(0, 2)
    var result2 = constant2.chip(0, 2)
    var result3 = constant3.chip(0, 2)
    for i in range(0, 2):
        for j in range(0, 3):
            VERIFY_IS_EQUAL(result1[i, j], random[i, j, 0])
            VERIFY_IS_EQUAL(result2[i, j], random[i, j, 0])
            VERIFY_IS_EQUAL(result3[i, j], random[i, j, 0])

def test_cxx11_tensor_const() raises:
    CALL_SUBTEST(test_simple_assign())
    CALL_SUBTEST(test_assign_of_const_tensor())