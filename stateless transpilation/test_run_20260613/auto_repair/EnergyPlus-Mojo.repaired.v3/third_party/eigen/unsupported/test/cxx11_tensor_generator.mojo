from main import main, VERIFY_IS_EQUAL, CALL_SUBTEST
from Eigen.CXX11.Tensor import Tensor, ColMajor, RowMajor, internal, GaussianGenerator, DenseIndex
from array import array

struct Generator1D:
    def __init__(self):

    def __call__(self, coordinates: array[DenseIndex, 1]) -> Float32:
        return coordinates[0]

def test_1D[DataLayout: Int]():
    var vec = Tensor[Float32, 1](6)
    var result = vec.generate(Generator1D())
    for i in range(6):
        VERIFY_IS_EQUAL(result(i), i)

struct Generator2D:
    def __init__(self):

    def __call__(self, coordinates: array[DenseIndex, 2]) -> Float32:
        return 3 * coordinates[0] + 11 * coordinates[1]

def test_2D[DataLayout: Int]():
    var matrix = Tensor[Float32, 2](5, 7)
    var result = matrix.generate(Generator2D())
    for i in range(5):
        for j in range(5):
            VERIFY_IS_EQUAL(result(i, j), 3*i + 11*j)

def test_gaussian[DataLayout: Int]():
    var rows = 32
    var cols = 48
    var means = array[Float32, 2](0.0, 0.0)
    means[0] = rows / 2.0
    means[1] = cols / 2.0
    var std_devs = array[Float32, 2](0.0, 0.0)
    std_devs[0] = 3.14
    std_devs[1] = 2.7
    var gaussian_gen = internal.GaussianGenerator[Float32, DenseIndex, 2](means, std_devs)
    var matrix = Tensor[Float32, 2](rows, cols)
    var result = matrix.generate(gaussian_gen)
    for i in range(rows):
        for j in range(cols):
            var g_rows = powf(rows/2.0 - i, 2) / (3.14 * 3.14) * 0.5
            var g_cols = powf(cols/2.0 - j, 2) / (2.7 * 2.7) * 0.5
            var gaussian = expf(-g_rows - g_cols)
            VERIFY_IS_EQUAL(result(i, j), gaussian)

def test_cxx11_tensor_generator():
    CALL_SUBTEST(test_1D[ColMajor]())
    CALL_SUBTEST(test_1D[RowMajor]())
    CALL_SUBTEST(test_2D[ColMajor]())
    CALL_SUBTEST(test_2D[RowMajor]())
    CALL_SUBTEST(test_gaussian[ColMajor]())
    CALL_SUBTEST(test_gaussian[RowMajor]())