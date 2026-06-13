from main import main, VERIFY_IS_EQUAL, CALL_SUBTEST
from Eigen.CXX11.Tensor import Tensor, array, ColMajor, RowMajor, internal

def test_simple_shuffling[DataLayout: Int]() raises:
    var tensor = Tensor[float32, 4, DataLayout](2, 3, 5, 7)
    tensor.setRandom()
    var shuffles = array[Int, 4]()
    shuffles[0] = 0
    shuffles[1] = 1
    shuffles[2] = 2
    shuffles[3] = 3
    var no_shuffle = Tensor[float32, 4, DataLayout]()
    no_shuffle = tensor.shuffle(shuffles)
    VERIFY_IS_EQUAL(no_shuffle.dimension(0), 2)
    VERIFY_IS_EQUAL(no_shuffle.dimension(1), 3)
    VERIFY_IS_EQUAL(no_shuffle.dimension(2), 5)
    VERIFY_IS_EQUAL(no_shuffle.dimension(3), 7)
    for i in range(2):
        for j in range(3):
            for k in range(5):
                for l in range(7):
                    VERIFY_IS_EQUAL(tensor(i, j, k, l), no_shuffle(i, j, k, l))
    shuffles[0] = 2
    shuffles[1] = 3
    shuffles[2] = 1
    shuffles[3] = 0
    var shuffle = Tensor[float32, 4, DataLayout]()
    shuffle = tensor.shuffle(shuffles)
    VERIFY_IS_EQUAL(shuffle.dimension(0), 5)
    VERIFY_IS_EQUAL(shuffle.dimension(1), 7)
    VERIFY_IS_EQUAL(shuffle.dimension(2), 3)
    VERIFY_IS_EQUAL(shuffle.dimension(3), 2)
    for i in range(2):
        for j in range(3):
            for k in range(5):
                for l in range(7):
                    VERIFY_IS_EQUAL(tensor(i, j, k, l), shuffle(k, l, j, i))

def test_expr_shuffling[DataLayout: Int]() raises:
    var tensor = Tensor[float32, 4, DataLayout](2, 3, 5, 7)
    tensor.setRandom()
    var shuffles = array[Int, 4]()
    shuffles[0] = 2
    shuffles[1] = 3
    shuffles[2] = 1
    shuffles[3] = 0
    var expected = Tensor[float32, 4, DataLayout]()
    expected = tensor.shuffle(shuffles)
    var result = Tensor[float32, 4, DataLayout](5, 7, 3, 2)
    var src_slice_dim = array[Int, 4](2, 3, 1, 7)
    var src_slice_start = array[Int, 4](0, 0, 0, 0)
    var dst_slice_dim = array[Int, 4](1, 7, 3, 2)
    var dst_slice_start = array[Int, 4](0, 0, 0, 0)
    for i in range(5):
        result.slice(dst_slice_start, dst_slice_dim) = tensor.slice(src_slice_start, src_slice_dim).shuffle(shuffles)
        src_slice_start[2] += 1
        dst_slice_start[0] += 1
    VERIFY_IS_EQUAL(result.dimension(0), 5)
    VERIFY_IS_EQUAL(result.dimension(1), 7)
    VERIFY_IS_EQUAL(result.dimension(2), 3)
    VERIFY_IS_EQUAL(result.dimension(3), 2)
    for i in range(expected.dimension(0)):
        for j in range(expected.dimension(1)):
            for k in range(expected.dimension(2)):
                for l in range(expected.dimension(3)):
                    VERIFY_IS_EQUAL(result(i, j, k, l), expected(i, j, k, l))
    dst_slice_start[0] = 0
    result.setRandom()
    for i in range(5):
        result.slice(dst_slice_start, dst_slice_dim) = tensor.shuffle(shuffles).slice(dst_slice_start, dst_slice_dim)
        dst_slice_start[0] += 1
    for i in range(expected.dimension(0)):
        for j in range(expected.dimension(1)):
            for k in range(expected.dimension(2)):
                for l in range(expected.dimension(3)):
                    VERIFY_IS_EQUAL(result(i, j, k, l), expected(i, j, k, l))

def test_shuffling_as_value[DataLayout: Int]() raises:
    var tensor = Tensor[float32, 4, DataLayout](2, 3, 5, 7)
    tensor.setRandom()
    var shuffles = array[Int, 4]()
    shuffles[2] = 0
    shuffles[3] = 1
    shuffles[1] = 2
    shuffles[0] = 3
    var shuffle = Tensor[float32, 4, DataLayout](5, 7, 3, 2)
    shuffle.shuffle(shuffles) = tensor
    VERIFY_IS_EQUAL(shuffle.dimension(0), 5)
    VERIFY_IS_EQUAL(shuffle.dimension(1), 7)
    VERIFY_IS_EQUAL(shuffle.dimension(2), 3)
    VERIFY_IS_EQUAL(shuffle.dimension(3), 2)
    for i in range(2):
        for j in range(3):
            for k in range(5):
                for l in range(7):
                    VERIFY_IS_EQUAL(tensor(i, j, k, l), shuffle(k, l, j, i))
    var no_shuffle = array[Int, 4]()
    no_shuffle[0] = 0
    no_shuffle[1] = 1
    no_shuffle[2] = 2
    no_shuffle[3] = 3
    var shuffle2 = Tensor[float32, 4, DataLayout](5, 7, 3, 2)
    shuffle2.shuffle(shuffles) = tensor.shuffle(no_shuffle)
    for i in range(5):
        for j in range(7):
            for k in range(3):
                for l in range(2):
                    VERIFY_IS_EQUAL(shuffle2(i, j, k, l), shuffle(i, j, k, l))

def test_shuffle_unshuffle[DataLayout: Int]() raises:
    var tensor = Tensor[float32, 4, DataLayout](2, 3, 5, 7)
    tensor.setRandom()
    var shuffles = array[Int, 4]()
    for i in range(4):
        shuffles[i] = i
    var shuffles_inverse = array[Int, 4]()
    for i in range(4):
        var index = internal.random[Int](i, 3)
        shuffles_inverse[shuffles[index]] = i
        var tmp = shuffles[i]
        shuffles[i] = shuffles[index]
        shuffles[index] = tmp
    var shuffle = Tensor[float32, 4, DataLayout]()
    shuffle = tensor.shuffle(shuffles).shuffle(shuffles_inverse)
    VERIFY_IS_EQUAL(shuffle.dimension(0), 2)
    VERIFY_IS_EQUAL(shuffle.dimension(1), 3)
    VERIFY_IS_EQUAL(shuffle.dimension(2), 5)
    VERIFY_IS_EQUAL(shuffle.dimension(3), 7)
    for i in range(2):
        for j in range(3):
            for k in range(5):
                for l in range(7):
                    VERIFY_IS_EQUAL(tensor(i, j, k, l), shuffle(i, j, k, l))

def test_cxx11_tensor_shuffling() raises:
    CALL_SUBTEST(test_simple_shuffling[ColMajor]())
    CALL_SUBTEST(test_simple_shuffling[RowMajor]())
    CALL_SUBTEST(test_expr_shuffling[ColMajor]())
    CALL_SUBTEST(test_expr_shuffling[RowMajor]())
    CALL_SUBTEST(test_shuffling_as_value[ColMajor]())
    CALL_SUBTEST(test_shuffling_as_value[RowMajor]())
    CALL_SUBTEST(test_shuffle_unshuffle[ColMajor]())
    CALL_SUBTEST(test_shuffle_unshuffle[RowMajor]())