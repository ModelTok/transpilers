from main import *
from tensor import Tensor
from eigen import array, Tuple, DenseIndex
from internal import ArgMaxTupleReducer, ArgMinTupleReducer

def test_simple_index_tuples[DataLayout: Int]() raises:
    var tensor = Tensor[float32, 4, DataLayout](2, 3, 5, 7)
    tensor.setRandom()
    tensor = (tensor + tensor.constant(0.5)).log()
    var index_tuples = Tensor[Tuple[DenseIndex, float32], 4, DataLayout](2, 3, 5, 7)
    index_tuples = tensor.index_tuples()
    for n in range(2 * 3 * 5 * 7):
        let v = index_tuples.coeff(n)
        VERIFY_IS_EQUAL(v.first, n)
        VERIFY_IS_EQUAL(v.second, tensor.coeff(n))

def test_index_tuples_dim[DataLayout: Int]() raises:
    var tensor = Tensor[float32, 4, DataLayout](2, 3, 5, 7)
    tensor.setRandom()
    tensor = (tensor + tensor.constant(0.5)).log()
    var index_tuples = Tensor[Tuple[DenseIndex, float32], 4, DataLayout](2, 3, 5, 7)
    index_tuples = tensor.index_tuples()
    for n in range(tensor.size()):
        let v = index_tuples(n)
        VERIFY_IS_EQUAL(v.first, n)
        VERIFY_IS_EQUAL(v.second, tensor(n))

def test_argmax_tuple_reducer[DataLayout: Int]() raises:
    var tensor = Tensor[float32, 4, DataLayout](2, 3, 5, 7)
    tensor.setRandom()
    tensor = (tensor + tensor.constant(0.5)).log()
    var index_tuples = Tensor[Tuple[DenseIndex, float32], 4, DataLayout](2, 3, 5, 7)
    index_tuples = tensor.index_tuples()
    var reduced = Tensor[Tuple[DenseIndex, float32], 0, DataLayout]()
    var dims = DimensionList[DenseIndex, 4]()
    reduced = index_tuples.reduce(dims, ArgMaxTupleReducer[Tuple[DenseIndex, float32]]())
    var maxi = Tensor[float32, 0, DataLayout](tensor.maximum())
    VERIFY_IS_EQUAL(maxi(), reduced(0).second)
    var reduce_dims = array[DenseIndex, 3]()
    for d in range(3):
        reduce_dims[d] = d
    var reduced_by_dims = Tensor[Tuple[DenseIndex, float32], 1, DataLayout](7)
    reduced_by_dims = index_tuples.reduce(reduce_dims, ArgMaxTupleReducer[Tuple[DenseIndex, float32]]())
    var max_by_dims = Tensor[float32, 1, DataLayout](tensor.maximum(reduce_dims))
    for l in range(7):
        VERIFY_IS_EQUAL(max_by_dims(l), reduced_by_dims(l).second)

def test_argmin_tuple_reducer[DataLayout: Int]() raises:
    var tensor = Tensor[float32, 4, DataLayout](2, 3, 5, 7)
    tensor.setRandom()
    tensor = (tensor + tensor.constant(0.5)).log()
    var index_tuples = Tensor[Tuple[DenseIndex, float32], 4, DataLayout](2, 3, 5, 7)
    index_tuples = tensor.index_tuples()
    var reduced = Tensor[Tuple[DenseIndex, float32], 0, DataLayout]()
    var dims = DimensionList[DenseIndex, 4]()
    reduced = index_tuples.reduce(dims, ArgMinTupleReducer[Tuple[DenseIndex, float32]]())
    var mini = Tensor[float32, 0, DataLayout](tensor.minimum())
    VERIFY_IS_EQUAL(mini(), reduced(0).second)
    var reduce_dims = array[DenseIndex, 3]()
    for d in range(3):
        reduce_dims[d] = d
    var reduced_by_dims = Tensor[Tuple[DenseIndex, float32], 1, DataLayout](7)
    reduced_by_dims = index_tuples.reduce(reduce_dims, ArgMinTupleReducer[Tuple[DenseIndex, float32]]())
    var min_by_dims = Tensor[float32, 1, DataLayout](tensor.minimum(reduce_dims))
    for l in range(7):
        VERIFY_IS_EQUAL(min_by_dims(l), reduced_by_dims(l).second)

def test_simple_argmax[DataLayout: Int]() raises:
    var tensor = Tensor[float32, 4, DataLayout](2, 3, 5, 7)
    tensor.setRandom()
    tensor = (tensor + tensor.constant(0.5)).log()
    tensor(0, 0, 0, 0) = 10.0
    var tensor_argmax = Tensor[DenseIndex, 0, DataLayout]()
    tensor_argmax = tensor.argmax()
    VERIFY_IS_EQUAL(tensor_argmax(0), 0)
    tensor(1, 2, 4, 6) = 20.0
    tensor_argmax = tensor.argmax()
    VERIFY_IS_EQUAL(tensor_argmax(0), 2 * 3 * 5 * 7 - 1)

def test_simple_argmin[DataLayout: Int]() raises:
    var tensor = Tensor[float32, 4, DataLayout](2, 3, 5, 7)
    tensor.setRandom()
    tensor = (tensor + tensor.constant(0.5)).log()
    tensor(0, 0, 0, 0) = -10.0
    var tensor_argmin = Tensor[DenseIndex, 0, DataLayout]()
    tensor_argmin = tensor.argmin()
    VERIFY_IS_EQUAL(tensor_argmin(0), 0)
    tensor(1, 2, 4, 6) = -20.0
    tensor_argmin = tensor.argmin()
    VERIFY_IS_EQUAL(tensor_argmin(0), 2 * 3 * 5 * 7 - 1)

def test_argmax_dim[DataLayout: Int]() raises:
    var tensor = Tensor[float32, 4, DataLayout](2, 3, 5, 7)
    var dims = List[Int](2, 3, 5, 7)
    for dim in range(4):
        tensor.setRandom()
        tensor = (tensor + tensor.constant(0.5)).log()
        var tensor_argmax = Tensor[DenseIndex, 3, DataLayout]()
        var ix = array[DenseIndex, 4]()
        for i in range(2):
            for j in range(3):
                for k in range(5):
                    for l in range(7):
                        ix[0] = i
                        ix[1] = j
                        ix[2] = k
                        ix[3] = l
                        if ix[dim] != 0:
                            continue
                        tensor(ix) = 10.0
        tensor_argmax = tensor.argmax(dim)
        VERIFY_IS_EQUAL(tensor_argmax.size(), 2 * 3 * 5 * 7 / tensor.dimension(dim))
        for n in range(tensor_argmax.size()):
            VERIFY_IS_EQUAL(tensor_argmax.data()[n], 0)
        for i in range(2):
            for j in range(3):
                for k in range(5):
                    for l in range(7):
                        ix[0] = i
                        ix[1] = j
                        ix[2] = k
                        ix[3] = l
                        if ix[dim] != tensor.dimension(dim) - 1:
                            continue
                        tensor(ix) = 20.0
        tensor_argmax = tensor.argmax(dim)
        VERIFY_IS_EQUAL(tensor_argmax.size(), 2 * 3 * 5 * 7 / tensor.dimension(dim))
        for n in range(tensor_argmax.size()):
            VERIFY_IS_EQUAL(tensor_argmax.data()[n], tensor.dimension(dim) - 1)

def test_argmin_dim[DataLayout: Int]() raises:
    var tensor = Tensor[float32, 4, DataLayout](2, 3, 5, 7)
    var dims = List[Int](2, 3, 5, 7)
    for dim in range(4):
        tensor.setRandom()
        tensor = (tensor + tensor.constant(0.5)).log()
        var tensor_argmin = Tensor[DenseIndex, 3, DataLayout]()
        var ix = array[DenseIndex, 4]()
        for i in range(2):
            for j in range(3):
                for k in range(5):
                    for l in range(7):
                        ix[0] = i
                        ix[1] = j
                        ix[2] = k
                        ix[3] = l
                        if ix[dim] != 0:
                            continue
                        tensor(ix) = -10.0
        tensor_argmin = tensor.argmin(dim)
        VERIFY_IS_EQUAL(tensor_argmin.size(), 2 * 3 * 5 * 7 / tensor.dimension(dim))
        for n in range(tensor_argmin.size()):
            VERIFY_IS_EQUAL(tensor_argmin.data()[n], 0)
        for i in range(2):
            for j in range(3):
                for k in range(5):
                    for l in range(7):
                        ix[0] = i
                        ix[1] = j
                        ix[2] = k
                        ix[3] = l
                        if ix[dim] != tensor.dimension(dim) - 1:
                            continue
                        tensor(ix) = -20.0
        tensor_argmin = tensor.argmin(dim)
        VERIFY_IS_EQUAL(tensor_argmin.size(), 2 * 3 * 5 * 7 / tensor.dimension(dim))
        for n in range(tensor_argmin.size()):
            VERIFY_IS_EQUAL(tensor_argmin.data()[n], tensor.dimension(dim) - 1)

def test_cxx11_tensor_argmax() raises:
    CALL_SUBTEST(test_simple_index_tuples[RowMajor]())
    CALL_SUBTEST(test_simple_index_tuples[ColMajor]())
    CALL_SUBTEST(test_index_tuples_dim[RowMajor]())
    CALL_SUBTEST(test_index_tuples_dim[ColMajor]())
    CALL_SUBTEST(test_argmax_tuple_reducer[RowMajor]())
    CALL_SUBTEST(test_argmax_tuple_reducer[ColMajor]())
    CALL_SUBTEST(test_argmin_tuple_reducer[RowMajor]())
    CALL_SUBTEST(test_argmin_tuple_reducer[ColMajor]())
    CALL_SUBTEST(test_simple_argmax[RowMajor]())
    CALL_SUBTEST(test_simple_argmax[ColMajor]())
    CALL_SUBTEST(test_simple_argmin[RowMajor]())
    CALL_SUBTEST(test_simple_argmin[ColMajor]())
    CALL_SUBTEST(test_argmax_dim[RowMajor]())
    CALL_SUBTEST(test_argmax_dim[ColMajor]())
    CALL_SUBTEST(test_argmin_dim[RowMajor]())
    CALL_SUBTEST(test_argmin_dim[ColMajor]())