from main import main, CALL_SUBTEST, VERIFY_IS_EQUAL
from Eigen.CXX11.Tensor import Tensor, TensorMap, ColMajor, RowMajor
from math import *
from memory import *
from random import *
from sys import *
from tensor import *

def test_1d_scan[DataLayout: Int, Type: DType = DType.float32, Exclusive: Bool = False]() raises:
    var size: Int = 50
    var tensor = Tensor[Type, 1, DataLayout](size)
    tensor.setRandom()
    var result = tensor.cumsum(0, Exclusive)
    VERIFY_IS_EQUAL(tensor.dimension(0), result.dimension(0))
    var accum: Float32 = 0
    for i in range(size):
        if Exclusive:
            VERIFY_IS_EQUAL(result(i), accum)
            accum += tensor(i)
        else:
            accum += tensor(i)
            VERIFY_IS_EQUAL(result(i), accum)
    accum = 1
    result = tensor.cumprod(0, Exclusive)
    for i in range(size):
        if Exclusive:
            VERIFY_IS_EQUAL(result(i), accum)
            accum *= tensor(i)
        else:
            accum *= tensor(i)
            VERIFY_IS_EQUAL(result(i), accum)

def test_4d_scan[DataLayout: Int, Type: DType = DType.float32]() raises:
    var size: Int = 5
    var tensor = Tensor[Type, 4, DataLayout](size, size, size, size)
    tensor.setRandom()
    var result = Tensor[Type, 4, DataLayout](size, size, size, size)
    result = tensor.cumsum(0)
    var accum: Float32 = 0
    for i in range(size):
        accum += tensor(i, 1, 2, 3)
        VERIFY_IS_EQUAL(result(i, 1, 2, 3), accum)
    result = tensor.cumsum(1)
    accum = 0
    for i in range(size):
        accum += tensor(1, i, 2, 3)
        VERIFY_IS_EQUAL(result(1, i, 2, 3), accum)
    result = tensor.cumsum(2)
    accum = 0
    for i in range(size):
        accum += tensor(1, 2, i, 3)
        VERIFY_IS_EQUAL(result(1, 2, i, 3), accum)
    result = tensor.cumsum(3)
    accum = 0
    for i in range(size):
        accum += tensor(1, 2, 3, i)
        VERIFY_IS_EQUAL(result(1, 2, 3, i), accum)

def test_tensor_maps[DataLayout: Int]() raises:
    var inputs = Int[20]()
    var tensor_map = TensorMap[Int, 1, DataLayout](inputs, 20)
    tensor_map.setRandom()
    var result = tensor_map.cumsum(0)
    var accum: Int = 0
    for i in range(20):
        accum += tensor_map(i)
        VERIFY_IS_EQUAL(result(i), accum)

def test_cxx11_tensor_scan() raises:
    CALL_SUBTEST(test_1d_scan[ColMajor, DType.float32, True]())
    CALL_SUBTEST(test_1d_scan[ColMajor, DType.float32, False]())
    CALL_SUBTEST(test_1d_scan[RowMajor, DType.float32, True]())
    CALL_SUBTEST(test_1d_scan[RowMajor, DType.float32, False]())
    CALL_SUBTEST(test_4d_scan[ColMajor]())
    CALL_SUBTEST(test_4d_scan[RowMajor]())
    CALL_SUBTEST(test_tensor_maps[ColMajor]())
    CALL_SUBTEST(test_tensor_maps[RowMajor]())