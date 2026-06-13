from main import main, VERIFY_IS_EQUAL, CALL_SUBTEST
from tensor import Tensor, DSizes
from memory import Pointer
from random import randfloat

# Alias for Eigen::Tensor
alias Tensor = Tensor

# Alias for Eigen::DSizes
alias DSizes = DSizes

# Data layout constants
alias ColMajor = 0
alias RowMajor = 1

def test_simple_padding[DataLayout: Int]() raises:
    var tensor = Tensor[float32, 4, DataLayout](2, 3, 5, 7)
    tensor.setRandom()
    var paddings = Pointer[tuple[Int, Int]](4)
    paddings[0] = (0, 0)
    paddings[1] = (2, 1)
    paddings[2] = (3, 4)
    paddings[3] = (0, 0)
    var padded = Tensor[float32, 4, DataLayout]()
    padded = tensor.pad(paddings)
    VERIFY_IS_EQUAL(padded.dimension(0), 2 + 0)
    VERIFY_IS_EQUAL(padded.dimension(1), 3 + 3)
    VERIFY_IS_EQUAL(padded.dimension(2), 5 + 7)
    VERIFY_IS_EQUAL(padded.dimension(3), 7 + 0)
    for i in range(2):
        for j in range(6):
            for k in range(12):
                for l in range(7):
                    if j >= 2 and j < 5 and k >= 3 and k < 8:
                        VERIFY_IS_EQUAL(padded[i, j, k, l], tensor[i, j - 2, k - 3, l])
                    else:
                        VERIFY_IS_EQUAL(padded[i, j, k, l], 0.0)

def test_padded_expr[DataLayout: Int]() raises:
    var tensor = Tensor[float32, 4, DataLayout](2, 3, 5, 7)
    tensor.setRandom()
    var paddings = Pointer[tuple[Int, Int]](4)
    paddings[0] = (0, 0)
    paddings[1] = (2, 1)
    paddings[2] = (3, 4)
    paddings[3] = (0, 0)
    var reshape_dims = DSizes[Int, 2]()
    reshape_dims[0] = 12
    reshape_dims[1] = 84
    var result = Tensor[float32, 2, DataLayout]()
    result = tensor.pad(paddings).reshape(reshape_dims)
    for i in range(2):
        for j in range(6):
            for k in range(12):
                for l in range(7):
                    var result_value: float32
                    if DataLayout == ColMajor:
                        result_value = result[i + 2 * j, k + 12 * l]
                    else:
                        result_value = result[j + 6 * i, l + 7 * k]
                    if j >= 2 and j < 5 and k >= 3 and k < 8:
                        VERIFY_IS_EQUAL(result_value, tensor[i, j - 2, k - 3, l])
                    else:
                        VERIFY_IS_EQUAL(result_value, 0.0)

def test_cxx11_tensor_padding() raises:
    CALL_SUBTEST(test_simple_padding[ColMajor]())
    CALL_SUBTEST(test_simple_padding[RowMajor]())
    CALL_SUBTEST(test_padded_expr[ColMajor]())
    CALL_SUBTEST(test_padded_expr[RowMajor]())