from tensor import Tensor, DSizes
from builtin import Array

alias DenseIndex = Int

struct DimPair:
    var first: Int
    var second: Int
    def __init__(inout self, f: Int, s: Int):
        self.first = f
        self.second = s

struct InsertZeros:
    def dimensions(self, input: Tensor[float, 2]) -> DSizes[DenseIndex, 2]:
        var result: DSizes[DenseIndex, 2]
        result[0] = input.dimension(0) * 2
        result[1] = input.dimension(1) * 2
        return result

    def eval[Output, Device](self, input: Tensor[float, 2], output: Output, device: Device):
        var strides: Array[DenseIndex] = Array[DenseIndex](2, 0)
        strides[0] = 2
        strides[1] = 2
        output.stride(strides).device(device) = input
        var offsets: DSizes[DenseIndex, 2]
        offsets[0] = 1
        offsets[1] = 1
        var extents: DSizes[DenseIndex, 2]
        extents[0] = output.dimension(0) - 1
        extents[1] = output.dimension(1) - 1
        output.slice(offsets, extents).stride(strides).device(device) = input.constant(0.0f)

def test_custom_unary_op():
    var tensor: Tensor[float, 2] = Tensor[float, 2](3, 5)
    tensor.setRandom()
    var result: Tensor[float, 2] = tensor.customOp(InsertZeros())
    VERIFY_IS_EQUAL(result.dimension(0), 6)
    VERIFY_IS_EQUAL(result.dimension(1), 10)
    for i in range(0, 6, 2):
        for j in range(0, 10, 2):
            VERIFY_IS_EQUAL(result(i, j), tensor(i // 2, j // 2))
    for i in range(1, 6, 2):
        for j in range(1, 10, 2):
            VERIFY_IS_EQUAL(result(i, j), 0)

struct BatchMatMul:
    def dimensions(self, input1: Tensor[float, 3], input2: Tensor[float, 3]) -> DSizes[DenseIndex, 3]:
        var result: DSizes[DenseIndex, 3]
        result[0] = input1.dimension(0)
        result[1] = input2.dimension(1)
        result[2] = input2.dimension(2)
        return result

    def eval[Output, Device](self, input1: Tensor[float, 3], input2: Tensor[float, 3], output: Output, device: Device):
        alias DimPair = DimPair  # local alias, but already global
        var dims: Array[DimPair] = Array[DimPair](1, DimPair(0, 0))
        dims[0] = DimPair(1, 0)
        for i in range(0, output.dimension(2)):
            output.template chip[2](i).device(device) = input1.chip[2](i).contract(input2.chip[2](i), dims)

def test_custom_binary_op():
    var tensor1: Tensor[float, 3] = Tensor[float, 3](2, 3, 5)
    tensor1.setRandom()
    var tensor2: Tensor[float, 3] = Tensor[float, 3](3, 7, 5)
    tensor2.setRandom()
    var result: Tensor[float, 3] = tensor1.customOp(tensor2, BatchMatMul())
    for i in range(0, 5):
        alias DimPair = DimPair  # local alias
        var dims: Array[DimPair] = Array[DimPair](1, DimPair(0, 0))
        dims[0] = DimPair(1, 0)
        var reference: Tensor[float, 2] = tensor1.chip[2](i).contract(tensor2.chip[2](i), dims)
        var val: TensorRef[Tensor[float, 2]] = result.chip[2](i)
        for j in range(0, 2):
            for k in range(0, 7):
                VERIFY_IS_APPROX(val(j, k), reference(j, k))

def test_cxx11_tensor_custom_op():
    CALL_SUBTEST(test_custom_unary_op())
    CALL_SUBTEST(test_custom_binary_op())
<<<FILE>>>