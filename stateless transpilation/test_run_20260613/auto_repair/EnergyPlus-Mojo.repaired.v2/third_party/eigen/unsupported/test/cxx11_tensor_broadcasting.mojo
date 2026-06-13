from main import main
from Eigen.CXX11.Tensor import Tensor
from Eigen.CXX11.Tensor import Eigen
from Eigen.CXX11.Tensor import array
from Eigen.CXX11.Tensor import ptrdiff_t
from Eigen.CXX11.Tensor import ColMajor
from Eigen.CXX11.Tensor import RowMajor
from Eigen.CXX11.Tensor import type2index
from Eigen.CXX11.Tensor import IndexList
from Eigen.CXX11.Tensor import Sizes
from Eigen.CXX11.Tensor import TensorFixedSize
from Eigen.CXX11.Tensor import TensorMap
from Eigen.CXX11.Tensor import VERIFY_IS_EQUAL
from Eigen.CXX11.Tensor import VERIFY_IS_APPROX
from Eigen.CXX11.Tensor import CALL_SUBTEST

def test_simple_broadcasting[DataLayout: Int]() raises:
    var tensor = Tensor[float32, 4, DataLayout](2, 3, 5, 7)
    tensor.setRandom()
    var broadcasts = array[ptrdiff_t, 4]()
    broadcasts[0] = 1
    broadcasts[1] = 1
    broadcasts[2] = 1
    broadcasts[3] = 1
    var no_broadcast = Tensor[float32, 4, DataLayout]()
    no_broadcast = tensor.broadcast(broadcasts)
    VERIFY_IS_EQUAL(no_broadcast.dimension(0), 2)
    VERIFY_IS_EQUAL(no_broadcast.dimension(1), 3)
    VERIFY_IS_EQUAL(no_broadcast.dimension(2), 5)
    VERIFY_IS_EQUAL(no_broadcast.dimension(3), 7)
    for i in range(2):
        for j in range(3):
            for k in range(5):
                for l in range(7):
                    VERIFY_IS_EQUAL(tensor(i, j, k, l), no_broadcast(i, j, k, l))
    broadcasts[0] = 2
    broadcasts[1] = 3
    broadcasts[2] = 1
    broadcasts[3] = 4
    var broadcast = Tensor[float32, 4, DataLayout]()
    broadcast = tensor.broadcast(broadcasts)
    VERIFY_IS_EQUAL(broadcast.dimension(0), 4)
    VERIFY_IS_EQUAL(broadcast.dimension(1), 9)
    VERIFY_IS_EQUAL(broadcast.dimension(2), 5)
    VERIFY_IS_EQUAL(broadcast.dimension(3), 28)
    for i in range(4):
        for j in range(9):
            for k in range(5):
                for l in range(28):
                    VERIFY_IS_EQUAL(tensor(i % 2, j % 3, k % 5, l % 7), broadcast(i, j, k, l))

def test_vectorized_broadcasting[DataLayout: Int]() raises:
    var tensor = Tensor[float32, 3, DataLayout](8, 3, 5)
    tensor.setRandom()
    var broadcasts = array[ptrdiff_t, 3]()
    broadcasts[0] = 2
    broadcasts[1] = 3
    broadcasts[2] = 4
    var broadcast = Tensor[float32, 3, DataLayout]()
    broadcast = tensor.broadcast(broadcasts)
    VERIFY_IS_EQUAL(broadcast.dimension(0), 16)
    VERIFY_IS_EQUAL(broadcast.dimension(1), 9)
    VERIFY_IS_EQUAL(broadcast.dimension(2), 20)
    for i in range(16):
        for j in range(9):
            for k in range(20):
                VERIFY_IS_EQUAL(tensor(i % 8, j % 3, k % 5), broadcast(i, j, k))
    tensor.resize(11, 3, 5)
    tensor.setRandom()
    broadcast = tensor.broadcast(broadcasts)
    VERIFY_IS_EQUAL(broadcast.dimension(0), 22)
    VERIFY_IS_EQUAL(broadcast.dimension(1), 9)
    VERIFY_IS_EQUAL(broadcast.dimension(2), 20)
    for i in range(22):
        for j in range(9):
            for k in range(20):
                VERIFY_IS_EQUAL(tensor(i % 11, j % 3, k % 5), broadcast(i, j, k))

def test_static_broadcasting[DataLayout: Int]() raises:
    var tensor = Tensor[float32, 3, DataLayout](8, 3, 5)
    tensor.setRandom()
    #if EIGEN_HAS_CONSTEXPR
    var broadcasts = IndexList[type2index[2], type2index[3], type2index[4]]()
    #else
    var broadcasts = Eigen.array[int32, 3]()
    broadcasts[0] = 2
    broadcasts[1] = 3
    broadcasts[2] = 4
    #endif
    var broadcast = Tensor[float32, 3, DataLayout]()
    broadcast = tensor.broadcast(broadcasts)
    VERIFY_IS_EQUAL(broadcast.dimension(0), 16)
    VERIFY_IS_EQUAL(broadcast.dimension(1), 9)
    VERIFY_IS_EQUAL(broadcast.dimension(2), 20)
    for i in range(16):
        for j in range(9):
            for k in range(20):
                VERIFY_IS_EQUAL(tensor(i % 8, j % 3, k % 5), broadcast(i, j, k))
    tensor.resize(11, 3, 5)
    tensor.setRandom()
    broadcast = tensor.broadcast(broadcasts)
    VERIFY_IS_EQUAL(broadcast.dimension(0), 22)
    VERIFY_IS_EQUAL(broadcast.dimension(1), 9)
    VERIFY_IS_EQUAL(broadcast.dimension(2), 20)
    for i in range(22):
        for j in range(9):
            for k in range(20):
                VERIFY_IS_EQUAL(tensor(i % 11, j % 3, k % 5), broadcast(i, j, k))

def test_fixed_size_broadcasting[DataLayout: Int]() raises:
    #if 0
    var t1 = Tensor[float32, 1, DataLayout](10)
    t1.setRandom()
    var t2 = TensorFixedSize[float32, Sizes[1], DataLayout]()
    t2 = t2.constant(20.0f)
    var t3 = Tensor[float32, 1, DataLayout](t1 + t2.broadcast(Eigen.array[int32, 1](10)))
    for i in range(10):
        VERIFY_IS_APPROX(t3(i), t1(i) + t2(0))
    var t4 = TensorMap[TensorFixedSize[float32, Sizes[1], DataLayout]](t2.data(), [1])
    var t5 = Tensor[float32, 1, DataLayout](t1 + t4.broadcast(Eigen.array[int32, 1](10)))
    for i in range(10):
        VERIFY_IS_APPROX(t5(i), t1(i) + t2(0))
    #endif

def test_cxx11_tensor_broadcasting() raises:
    CALL_SUBTEST(test_simple_broadcasting[ColMajor]())
    CALL_SUBTEST(test_simple_broadcasting[RowMajor]())
    CALL_SUBTEST(test_vectorized_broadcasting[ColMajor]())
    CALL_SUBTEST(test_vectorized_broadcasting[RowMajor]())
    CALL_SUBTEST(test_static_broadcasting[ColMajor]())
    CALL_SUBTEST(test_static_broadcasting[RowMajor]())
    CALL_SUBTEST(test_fixed_size_broadcasting[ColMajor]())
    CALL_SUBTEST(test_fixed_size_broadcasting[RowMajor]())