from main import VERIFY_IS_EQUAL, VERIFY_IS_APPROX, CALL_SUBTEST
from Eigen import Tensor, Array, BothParts, RealPart, FFT_FORWARD, FFT_REVERSE, ColMajor, RowMajor

# The C++ template parameter DataLayout is represented as a compile-time integer.
# ColMajor and RowMajor are imported above.

def test_1D_fft_ifft_invariant[DataLayout: Int](sequence_length: Int):
    var tensor = Tensor[Float64, 1, DataLayout](sequence_length)
    tensor.setRandom()
    var fft = Array[Int, 1]()
    fft[0] = 0
    var tensor_after_fft: Tensor[ComplexFloat64, 1, DataLayout]
    var tensor_after_fft_ifft: Tensor[ComplexFloat64, 1, DataLayout]
    tensor_after_fft = tensor.fft[BothParts, FFT_FORWARD](fft)
    tensor_after_fft_ifft = tensor_after_fft.fft[BothParts, FFT_REVERSE](fft)
    VERIFY_IS_EQUAL(tensor_after_fft.dimension(0), sequence_length)
    VERIFY_IS_EQUAL(tensor_after_fft_ifft.dimension(0), sequence_length)
    for i in range(sequence_length):
        VERIFY_IS_APPROX(Float32(tensor[i]), Float32(tensor_after_fft_ifft[i].real))

def test_2D_fft_ifft_invariant[DataLayout: Int](dim0: Int, dim1: Int):
    var tensor = Tensor[Float64, 2, DataLayout](dim0, dim1)
    tensor.setRandom()
    var fft = Array[Int, 2]()
    fft[0] = 0
    fft[1] = 1
    var tensor_after_fft: Tensor[ComplexFloat64, 2, DataLayout]
    var tensor_after_fft_ifft: Tensor[ComplexFloat64, 2, DataLayout]
    tensor_after_fft = tensor.fft[BothParts, FFT_FORWARD](fft)
    tensor_after_fft_ifft = tensor_after_fft.fft[BothParts, FFT_REVERSE](fft)
    VERIFY_IS_EQUAL(tensor_after_fft.dimension(0), dim0)
    VERIFY_IS_EQUAL(tensor_after_fft.dimension(1), dim1)
    VERIFY_IS_EQUAL(tensor_after_fft_ifft.dimension(0), dim0)
    VERIFY_IS_EQUAL(tensor_after_fft_ifft.dimension(1), dim1)
    for i in range(dim0):
        for j in range(dim1):
            VERIFY_IS_APPROX(Float32(tensor[i, j]), Float32(tensor_after_fft_ifft[i, j].real))

def test_3D_fft_ifft_invariant[DataLayout: Int](dim0: Int, dim1: Int, dim2: Int):
    var tensor = Tensor[Float64, 3, DataLayout](dim0, dim1, dim2)
    tensor.setRandom()
    var fft = Array[Int, 3]()
    fft[0] = 0
    fft[1] = 1
    fft[2] = 2
    var tensor_after_fft: Tensor[ComplexFloat64, 3, DataLayout]
    var tensor_after_fft_ifft: Tensor[ComplexFloat64, 3, DataLayout]
    tensor_after_fft = tensor.fft[BothParts, FFT_FORWARD](fft)
    tensor_after_fft_ifft = tensor_after_fft.fft[BothParts, FFT_REVERSE](fft)
    VERIFY_IS_EQUAL(tensor_after_fft.dimension(0), dim0)
    VERIFY_IS_EQUAL(tensor_after_fft.dimension(1), dim1)
    VERIFY_IS_EQUAL(tensor_after_fft.dimension(2), dim2)
    VERIFY_IS_EQUAL(tensor_after_fft_ifft.dimension(0), dim0)
    VERIFY_IS_EQUAL(tensor_after_fft_ifft.dimension(1), dim1)
    VERIFY_IS_EQUAL(tensor_after_fft_ifft.dimension(2), dim2)
    for i in range(dim0):
        for j in range(dim1):
            for k in range(dim2):
                VERIFY_IS_APPROX(Float32(tensor[i, j, k]), Float32(tensor_after_fft_ifft[i, j, k].real))

def test_sub_fft_ifft_invariant[DataLayout: Int](dim0: Int, dim1: Int, dim2: Int, dim3: Int):
    var tensor = Tensor[Float64, 4, DataLayout](dim0, dim1, dim2, dim3)
    tensor.setRandom()
    var fft = Array[Int, 2]()
    fft[0] = 2
    fft[1] = 0
    var tensor_after_fft: Tensor[ComplexFloat64, 4, DataLayout]
    var tensor_after_fft_ifft: Tensor[Float64, 4, DataLayout]
    tensor_after_fft = tensor.fft[BothParts, FFT_FORWARD](fft)
    tensor_after_fft_ifft = tensor_after_fft.fft[RealPart, FFT_REVERSE](fft)
    VERIFY_IS_EQUAL(tensor_after_fft.dimension(0), dim0)
    VERIFY_IS_EQUAL(tensor_after_fft.dimension(1), dim1)
    VERIFY_IS_EQUAL(tensor_after_fft.dimension(2), dim2)
    VERIFY_IS_EQUAL(tensor_after_fft.dimension(3), dim3)
    VERIFY_IS_EQUAL(tensor_after_fft_ifft.dimension(0), dim0)
    VERIFY_IS_EQUAL(tensor_after_fft_ifft.dimension(1), dim1)
    VERIFY_IS_EQUAL(tensor_after_fft_ifft.dimension(2), dim2)
    VERIFY_IS_EQUAL(tensor_after_fft_ifft.dimension(3), dim3)
    for i in range(dim0):
        for j in range(dim1):
            for k in range(dim2):
                for l in range(dim3):
                    VERIFY_IS_APPROX(Float32(tensor[i, j, k, l]), Float32(tensor_after_fft_ifft[i, j, k, l]))

def test_cxx11_tensor_ifft():
    CALL_SUBTEST(test_1D_fft_ifft_invariant[ColMajor](4))
    CALL_SUBTEST(test_1D_fft_ifft_invariant[ColMajor](16))
    CALL_SUBTEST(test_1D_fft_ifft_invariant[ColMajor](32))
    CALL_SUBTEST(test_1D_fft_ifft_invariant[ColMajor](1024*1024))
    CALL_SUBTEST(test_2D_fft_ifft_invariant[ColMajor](4, 4))
    CALL_SUBTEST(test_2D_fft_ifft_invariant[ColMajor](8, 16))
    CALL_SUBTEST(test_2D_fft_ifft_invariant[ColMajor](16, 32))
    CALL_SUBTEST(test_2D_fft_ifft_invariant[ColMajor](1024, 1024))
    CALL_SUBTEST(test_3D_fft_ifft_invariant[ColMajor](4, 4, 4))
    CALL_SUBTEST(test_3D_fft_ifft_invariant[ColMajor](8, 16, 32))
    CALL_SUBTEST(test_3D_fft_ifft_invariant[ColMajor](16, 4, 8))
    CALL_SUBTEST(test_3D_fft_ifft_invariant[ColMajor](256, 256, 256))
    CALL_SUBTEST(test_sub_fft_ifft_invariant[ColMajor](4, 4, 4, 4))
    CALL_SUBTEST(test_sub_fft_ifft_invariant[ColMajor](8, 16, 32, 64))
    CALL_SUBTEST(test_sub_fft_ifft_invariant[ColMajor](16, 4, 8, 12))
    CALL_SUBTEST(test_sub_fft_ifft_invariant[ColMajor](64, 64, 64, 64))