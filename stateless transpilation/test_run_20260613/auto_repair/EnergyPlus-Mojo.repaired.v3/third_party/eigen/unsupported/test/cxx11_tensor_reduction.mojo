from main import main, CALL_SUBTEST, VERIFY_IS_EQUAL, VERIFY_IS_APPROX
from memory import memset_zero
from math import sqrt
from limits import numeric_limits
from numeric import iota
from tensor import Tensor, TensorMap, TensorFixedSize, Sizes, array, IndexList, type2index, ColMajor, RowMajor

def test_trivial_reductions[DataLayout: Int]() raises:
    {
        var tensor = Tensor[float32, 0, DataLayout]()
        tensor.setRandom()
        var reduction_axis = array[Int, 0]()
        var result = tensor.sum(reduction_axis)
        VERIFY_IS_EQUAL(result(), tensor())
    }
    {
        var tensor = Tensor[float32, 1, DataLayout](7)
        tensor.setRandom()
        var reduction_axis = array[Int, 0]()
        var result = tensor.sum(reduction_axis)
        VERIFY_IS_EQUAL(result.dimension(0), 7)
        for i in range(7):
            VERIFY_IS_EQUAL(result(i), tensor(i))
    }
    {
        var tensor = Tensor[float32, 2, DataLayout](2, 3)
        tensor.setRandom()
        var reduction_axis = array[Int, 0]()
        var result = tensor.sum(reduction_axis)
        VERIFY_IS_EQUAL(result.dimension(0), 2)
        VERIFY_IS_EQUAL(result.dimension(1), 3)
        for i in range(2):
            for j in range(3):
                VERIFY_IS_EQUAL(result(i, j), tensor(i, j))
    }

def test_simple_reductions[DataLayout: Int]() raises:
    var tensor = Tensor[float32, 4, DataLayout](2, 3, 5, 7)
    tensor.setRandom()
    var reduction_axis2 = array[Int, 2]()
    reduction_axis2[0] = 1
    reduction_axis2[1] = 3
    var result = tensor.sum(reduction_axis2)
    VERIFY_IS_EQUAL(result.dimension(0), 2)
    VERIFY_IS_EQUAL(result.dimension(1), 5)
    for i in range(2):
        for j in range(5):
            var sum: float32 = 0.0
            for k in range(3):
                for l in range(7):
                    sum += tensor(i, k, j, l)
            VERIFY_IS_APPROX(result(i, j), sum)
    {
        var sum1 = tensor.sum()
        VERIFY_IS_EQUAL(sum1.rank(), 0)
        var reduction_axis4 = array[Int, 4]()
        reduction_axis4[0] = 0
        reduction_axis4[1] = 1
        reduction_axis4[2] = 2
        reduction_axis4[3] = 3
        var sum2 = tensor.sum(reduction_axis4)
        VERIFY_IS_EQUAL(sum2.rank(), 0)
        VERIFY_IS_APPROX(sum1(), sum2())
    }
    reduction_axis2[0] = 0
    reduction_axis2[1] = 2
    result = tensor.prod(reduction_axis2)
    VERIFY_IS_EQUAL(result.dimension(0), 3)
    VERIFY_IS_EQUAL(result.dimension(1), 7)
    for i in range(3):
        for j in range(7):
            var prod: float32 = 1.0
            for k in range(2):
                for l in range(5):
                    prod *= tensor(k, i, l, j)
            VERIFY_IS_APPROX(result(i, j), prod)
    {
        var prod1 = tensor.prod()
        VERIFY_IS_EQUAL(prod1.rank(), 0)
        var reduction_axis4 = array[Int, 4]()
        reduction_axis4[0] = 0
        reduction_axis4[1] = 1
        reduction_axis4[2] = 2
        reduction_axis4[3] = 3
        var prod2 = tensor.prod(reduction_axis4)
        VERIFY_IS_EQUAL(prod2.rank(), 0)
        VERIFY_IS_APPROX(prod1(), prod2())
    }
    reduction_axis2[0] = 0
    reduction_axis2[1] = 2
    result = tensor.maximum(reduction_axis2)
    VERIFY_IS_EQUAL(result.dimension(0), 3)
    VERIFY_IS_EQUAL(result.dimension(1), 7)
    for i in range(3):
        for j in range(7):
            var max_val: float32 = numeric_limits[float32]().lowest()
            for k in range(2):
                for l in range(5):
                    max_val = max(max_val, tensor(k, i, l, j))
            VERIFY_IS_APPROX(result(i, j), max_val)
    {
        var max1 = tensor.maximum()
        VERIFY_IS_EQUAL(max1.rank(), 0)
        var reduction_axis4 = array[Int, 4]()
        reduction_axis4[0] = 0
        reduction_axis4[1] = 1
        reduction_axis4[2] = 2
        reduction_axis4[3] = 3
        var max2 = tensor.maximum(reduction_axis4)
        VERIFY_IS_EQUAL(max2.rank(), 0)
        VERIFY_IS_APPROX(max1(), max2())
    }
    reduction_axis2[0] = 0
    reduction_axis2[1] = 1
    result = tensor.minimum(reduction_axis2)
    VERIFY_IS_EQUAL(result.dimension(0), 5)
    VERIFY_IS_EQUAL(result.dimension(1), 7)
    for i in range(5):
        for j in range(7):
            var min_val: float32 = numeric_limits[float32]().max()
            for k in range(2):
                for l in range(3):
                    min_val = min(min_val, tensor(k, l, i, j))
            VERIFY_IS_APPROX(result(i, j), min_val)
    {
        var min1 = tensor.minimum()
        VERIFY_IS_EQUAL(min1.rank(), 0)
        var reduction_axis4 = array[Int, 4]()
        reduction_axis4[0] = 0
        reduction_axis4[1] = 1
        reduction_axis4[2] = 2
        reduction_axis4[3] = 3
        var min2 = tensor.minimum(reduction_axis4)
        VERIFY_IS_EQUAL(min2.rank(), 0)
        VERIFY_IS_APPROX(min1(), min2())
    }
    reduction_axis2[0] = 0
    reduction_axis2[1] = 1
    result = tensor.mean(reduction_axis2)
    VERIFY_IS_EQUAL(result.dimension(0), 5)
    VERIFY_IS_EQUAL(result.dimension(1), 7)
    for i in range(5):
        for j in range(7):
            var sum: float32 = 0.0
            var count: Int = 0
            for k in range(2):
                for l in range(3):
                    sum += tensor(k, l, i, j)
                    count += 1
            VERIFY_IS_APPROX(result(i, j), sum / count)
    {
        var mean1 = tensor.mean()
        VERIFY_IS_EQUAL(mean1.rank(), 0)
        var reduction_axis4 = array[Int, 4]()
        reduction_axis4[0] = 0
        reduction_axis4[1] = 1
        reduction_axis4[2] = 2
        reduction_axis4[3] = 3
        var mean2 = tensor.mean(reduction_axis4)
        VERIFY_IS_EQUAL(mean2.rank(), 0)
        VERIFY_IS_APPROX(mean1(), mean2())
    }
    {
        var ints = Tensor[Int32, 1](10)
        iota(ints.data(), ints.data() + ints.dimension(0), 0)
        var all = TensorFixedSize[Bool, Sizes[]]()
        all = ints.all()
        VERIFY(!all())
        all = (ints >= ints.constant(0)).all()
        VERIFY(all())
        var any = TensorFixedSize[Bool, Sizes[]]()
        any = (ints > ints.constant(10)).any()
        VERIFY(!any())
        any = (ints < ints.constant(1)).any()
        VERIFY(any())
    }

def test_reductions_in_expr[DataLayout: Int]() raises:
    var tensor = Tensor[float32, 4, DataLayout](2, 3, 5, 7)
    tensor.setRandom()
    var reduction_axis2 = array[Int, 2]()
    reduction_axis2[0] = 1
    reduction_axis2[1] = 3
    var result = Tensor[float32, 2, DataLayout](2, 5)
    result = result.constant(1.0) - tensor.sum(reduction_axis2)
    VERIFY_IS_EQUAL(result.dimension(0), 2)
    VERIFY_IS_EQUAL(result.dimension(1), 5)
    for i in range(2):
        for j in range(5):
            var sum: float32 = 0.0
            for k in range(3):
                for l in range(7):
                    sum += tensor(i, k, j, l)
            VERIFY_IS_APPROX(result(i, j), 1.0 - sum)

def test_full_reductions[DataLayout: Int]() raises:
    var tensor = Tensor[float32, 2, DataLayout](2, 3)
    tensor.setRandom()
    var reduction_axis = array[Int, 2]()
    reduction_axis[0] = 0
    reduction_axis[1] = 1
    var result = tensor.sum(reduction_axis)
    VERIFY_IS_EQUAL(result.rank(), 0)
    var sum: float32 = 0.0
    for i in range(2):
        for j in range(3):
            sum += tensor(i, j)
    VERIFY_IS_APPROX(result(0), sum)
    result = tensor.square().sum(reduction_axis).sqrt()
    VERIFY_IS_EQUAL(result.rank(), 0)
    sum = 0.0
    for i in range(2):
        for j in range(3):
            sum += tensor(i, j) * tensor(i, j)
    VERIFY_IS_APPROX(result(), sqrt(sum))

struct UserReducer:
    static const PacketAccess: Bool = False
    var offset_: float32

    def __init__(inout self, offset: float32):
        self.offset_ = offset

    def reduce(self, val: float32, inout accum: float32):
        accum += val * val

    def initialize(self) -> float32:
        return 0.0

    def finalize(self, accum: float32) -> float32:
        return 1.0 / (accum + self.offset_)

def test_user_defined_reductions[DataLayout: Int]() raises:
    var tensor = Tensor[float32, 2, DataLayout](5, 7)
    tensor.setRandom()
    var reduction_axis = array[Int, 1]()
    reduction_axis[0] = 1
    var reducer = UserReducer(10.0)
    var result = tensor.reduce(reduction_axis, reducer)
    VERIFY_IS_EQUAL(result.dimension(0), 5)
    for i in range(5):
        var expected: float32 = 10.0
        for j in range(7):
            expected += tensor(i, j) * tensor(i, j)
        expected = 1.0 / expected
        VERIFY_IS_APPROX(result(i), expected)

def test_tensor_maps[DataLayout: Int]() raises:
    var inputs = Int32(2 * 3 * 5 * 7)
    var tensor_map = TensorMap[Tensor[Int32, 4, DataLayout]](inputs, 2, 3, 5, 7)
    var tensor_map_const = TensorMap[Tensor[Int32, 4, DataLayout]](inputs, 2, 3, 5, 7)
    var tensor_map_const_const = TensorMap[Tensor[Int32, 4, DataLayout]](inputs, 2, 3, 5, 7)
    tensor_map.setRandom()
    var reduction_axis = array[Int, 2]()
    reduction_axis[0] = 1
    reduction_axis[1] = 3
    var result = tensor_map.sum(reduction_axis)
    var result2 = tensor_map_const.sum(reduction_axis)
    var result3 = tensor_map_const_const.sum(reduction_axis)
    for i in range(2):
        for j in range(5):
            var sum: Int32 = 0
            for k in range(3):
                for l in range(7):
                    sum += tensor_map(i, k, j, l)
            VERIFY_IS_EQUAL(result(i, j), sum)
            VERIFY_IS_EQUAL(result2(i, j), sum)
            VERIFY_IS_EQUAL(result3(i, j), sum)

def test_static_dims[DataLayout: Int]() raises:
    var in_ = Tensor[float32, 4, DataLayout](72, 53, 97, 113)
    var out_ = Tensor[float32, 2, DataLayout](72, 97)
    in_.setRandom()
    var reduction_axis = array[Int, 2]()
    reduction_axis[0] = 1
    reduction_axis[1] = 3
    out_ = in_.maximum(reduction_axis)
    for i in range(72):
        for j in range(97):
            var expected: float32 = -1e10
            for k in range(53):
                for l in range(113):
                    expected = max(expected, in_(i, k, j, l))
            VERIFY_IS_APPROX(out_(i, j), expected)

def test_innermost_last_dims[DataLayout: Int]() raises:
    var in_ = Tensor[float32, 4, DataLayout](72, 53, 97, 113)
    var out_ = Tensor[float32, 2, DataLayout](97, 113)
    in_.setRandom()
    var reduction_axis = array[Int, 2]()
    reduction_axis[0] = 0
    reduction_axis[1] = 1
    out_ = in_.maximum(reduction_axis)
    for i in range(97):
        for j in range(113):
            var expected: float32 = -1e10
            for k in range(53):
                for l in range(72):
                    expected = max(expected, in_(l, k, i, j))
            VERIFY_IS_APPROX(out_(i, j), expected)

def test_innermost_first_dims[DataLayout: Int]() raises:
    var in_ = Tensor[float32, 4, DataLayout](72, 53, 97, 113)
    var out_ = Tensor[float32, 2, DataLayout](72, 53)
    in_.setRandom()
    var reduction_axis = array[Int, 2]()
    reduction_axis[0] = 2
    reduction_axis[1] = 3
    out_ = in_.maximum(reduction_axis)
    for i in range(72):
        for j in range(53):
            var expected: float32 = -1e10
            for k in range(97):
                for l in range(113):
                    expected = max(expected, in_(i, j, k, l))
            VERIFY_IS_APPROX(out_(i, j), expected)

def test_reduce_middle_dims[DataLayout: Int]() raises:
    var in_ = Tensor[float32, 4, DataLayout](72, 53, 97, 113)
    var out_ = Tensor[float32, 2, DataLayout](72, 53)
    in_.setRandom()
    var reduction_axis = array[Int, 2]()
    reduction_axis[0] = 1
    reduction_axis[1] = 2
    out_ = in_.maximum(reduction_axis)
    for i in range(72):
        for j in range(113):
            var expected: float32 = -1e10
            for k in range(53):
                for l in range(97):
                    expected = max(expected, in_(i, k, l, j))
            VERIFY_IS_APPROX(out_(i, j), expected)

def test_cxx11_tensor_reduction() raises:
    CALL_SUBTEST(test_trivial_reductions[ColMajor]())
    CALL_SUBTEST(test_trivial_reductions[RowMajor]())
    CALL_SUBTEST(test_simple_reductions[ColMajor]())
    CALL_SUBTEST(test_simple_reductions[RowMajor]())
    CALL_SUBTEST(test_reductions_in_expr[ColMajor]())
    CALL_SUBTEST(test_reductions_in_expr[RowMajor]())
    CALL_SUBTEST(test_full_reductions[ColMajor]())
    CALL_SUBTEST(test_full_reductions[RowMajor]())
    CALL_SUBTEST(test_user_defined_reductions[ColMajor]())
    CALL_SUBTEST(test_user_defined_reductions[RowMajor]())
    CALL_SUBTEST(test_tensor_maps[ColMajor]())
    CALL_SUBTEST(test_tensor_maps[RowMajor]())
    CALL_SUBTEST(test_static_dims[ColMajor]())
    CALL_SUBTEST(test_static_dims[RowMajor]())
    CALL_SUBTEST(test_innermost_last_dims[ColMajor]())
    CALL_SUBTEST(test_innermost_last_dims[RowMajor]())
    CALL_SUBTEST(test_innermost_first_dims[ColMajor]())
    CALL_SUBTEST(test_innermost_first_dims[RowMajor]())
    CALL_SUBTEST(test_reduce_middle_dims[ColMajor]())
    CALL_SUBTEST(test_reduce_middle_dims[RowMajor]())