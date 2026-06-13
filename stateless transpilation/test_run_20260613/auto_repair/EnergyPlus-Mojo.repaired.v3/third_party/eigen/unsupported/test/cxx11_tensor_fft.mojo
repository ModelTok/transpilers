from main import VERIFY_IS_APPROX, VERIFY_IS_EQUAL, rand
from Eigen.CXX11.Tensor import Tensor, BothParts, FFT_FORWARD, FFT_REVERSE, RealPart, ImagPart, ColMajor, RowMajor, numext, internal, DSizes, array

def test_fft_2D_golden[DataLayout: Int]():
    var input = Tensor[Float32, 2, DataLayout](2, 3)
    input[0, 0] = 1.0
    input[0, 1] = 2.0
    input[0, 2] = 3.0
    input[1, 0] = 4.0
    input[1, 1] = 5.0
    input[1, 2] = 6.0
    var fft: SIMD[Int, 2]
    fft[0] = 0
    fft[1] = 1
    var output = input.fft[BothParts, FFT_FORWARD](fft)
    var output_golden: StaticTuple[Complex[Float32], 6]
    output_golden[0] = Complex[Float32](21, 0)
    output_golden[1] = Complex[Float32](-9, 0)
    output_golden[2] = Complex[Float32](-3, 1.73205)
    output_golden[3] = Complex[Float32](0, 0)
    output_golden[4] = Complex[Float32](-3, -1.73205)
    output_golden[5] = Complex[Float32](0, 0)
    var c_offset = Complex[Float32](1.0, 1.0)
    if DataLayout == ColMajor:
        VERIFY_IS_APPROX(output[0] + c_offset, output_golden[0] + c_offset)
        VERIFY_IS_APPROX(output[1] + c_offset, output_golden[1] + c_offset)
        VERIFY_IS_APPROX(output[2] + c_offset, output_golden[2] + c_offset)
        VERIFY_IS_APPROX(output[3] + c_offset, output_golden[3] + c_offset)
        VERIFY_IS_APPROX(output[4] + c_offset, output_golden[4] + c_offset)
        VERIFY_IS_APPROX(output[5] + c_offset, output_golden[5] + c_offset)
    else:
        VERIFY_IS_APPROX(output[0] + c_offset, output_golden[0] + c_offset)
        VERIFY_IS_APPROX(output[1] + c_offset, output_golden[2] + c_offset)
        VERIFY_IS_APPROX(output[2] + c_offset, output_golden[4] + c_offset)
        VERIFY_IS_APPROX(output[3] + c_offset, output_golden[1] + c_offset)
        VERIFY_IS_APPROX(output[4] + c_offset, output_golden[3] + c_offset)
        VERIFY_IS_APPROX(output[5] + c_offset, output_golden[5] + c_offset)

def test_fft_complex_input_golden():
    var input = Tensor[Complex[Float32], 1, ColMajor](5)
    input[0] = Complex[Float32](1, 1)
    input[1] = Complex[Float32](2, 2)
    input[2] = Complex[Float32](3, 3)
    input[3] = Complex[Float32](4, 4)
    input[4] = Complex[Float32](5, 5)
    var fft: SIMD[Int, 1]
    fft[0] = 0
    var forward_output_both_parts = input.fft[BothParts, FFT_FORWARD](fft)
    var reverse_output_both_parts = input.fft[BothParts, FFT_REVERSE](fft)
    var forward_output_real_part = input.fft[RealPart, FFT_FORWARD](fft)
    var reverse_output_real_part = input.fft[RealPart, FFT_REVERSE](fft)
    var forward_output_imag_part = input.fft[ImagPart, FFT_FORWARD](fft)
    var reverse_output_imag_part = input.fft[ImagPart, FFT_REVERSE](fft)
    VERIFY_IS_EQUAL(forward_output_both_parts.dimension(0), input.dimension(0))
    VERIFY_IS_EQUAL(reverse_output_both_parts.dimension(0), input.dimension(0))
    VERIFY_IS_EQUAL(forward_output_real_part.dimension(0), input.dimension(0))
    VERIFY_IS_EQUAL(reverse_output_real_part.dimension(0), input.dimension(0))
    VERIFY_IS_EQUAL(forward_output_imag_part.dimension(0), input.dimension(0))
    VERIFY_IS_EQUAL(reverse_output_imag_part.dimension(0), input.dimension(0))
    var forward_golden_result: StaticTuple[Complex[Float32], 5]
    var reverse_golden_result: StaticTuple[Complex[Float32], 5]
    forward_golden_result[0] = Complex[Float32](15.000000000000000, +15.000000000000000)
    forward_golden_result[1] = Complex[Float32](-5.940954801177935, +0.940954801177934)
    forward_golden_result[2] = Complex[Float32](-3.312299240582266, -1.687700759417735)
    forward_golden_result[3] = Complex[Float32](-1.687700759417735, -3.312299240582266)
    forward_golden_result[4] = Complex[Float32](0.940954801177934, -5.940954801177935)
    reverse_golden_result[0] = Complex[Float32](3.000000000000000, +3.000000000000000)
    reverse_golden_result[1] = Complex[Float32](0.188190960235587, -1.188190960235587)
    reverse_golden_result[2] = Complex[Float32](-0.337540151883547, -0.662459848116453)
    reverse_golden_result[3] = Complex[Float32](-0.662459848116453, -0.337540151883547)
    reverse_golden_result[4] = Complex[Float32](-1.188190960235587, +0.188190960235587)
    for i in range(5):
        VERIFY_IS_APPROX(forward_output_both_parts[i], forward_golden_result[i])
        VERIFY_IS_APPROX(forward_output_real_part[i], forward_golden_result[i].real())
        VERIFY_IS_APPROX(forward_output_imag_part[i], forward_golden_result[i].imag())
    for i in range(5):
        VERIFY_IS_APPROX(reverse_output_both_parts[i], reverse_golden_result[i])
        VERIFY_IS_APPROX(reverse_output_real_part[i], reverse_golden_result[i].real())
        VERIFY_IS_APPROX(reverse_output_imag_part[i], reverse_golden_result[i].imag())

def test_fft_real_input_golden():
    var input = Tensor[Float32, 1, ColMajor](5)
    input[0] = 1.0
    input[1] = 2.0
    input[2] = 3.0
    input[3] = 4.0
    input[4] = 5.0
    var fft: SIMD[Int, 1]
    fft[0] = 0
    var forward_output_both_parts = input.fft[BothParts, FFT_FORWARD](fft)
    var reverse_output_both_parts = input.fft[BothParts, FFT_REVERSE](fft)
    var forward_output_real_part = input.fft[RealPart, FFT_FORWARD](fft)
    var reverse_output_real_part = input.fft[RealPart, FFT_REVERSE](fft)
    var forward_output_imag_part = input.fft[ImagPart, FFT_FORWARD](fft)
    var reverse_output_imag_part = input.fft[ImagPart, FFT_REVERSE](fft)
    VERIFY_IS_EQUAL(forward_output_both_parts.dimension(0), input.dimension(0))
    VERIFY_IS_EQUAL(reverse_output_both_parts.dimension(0), input.dimension(0))
    VERIFY_IS_EQUAL(forward_output_real_part.dimension(0), input.dimension(0))
    VERIFY_IS_EQUAL(reverse_output_real_part.dimension(0), input.dimension(0))
    VERIFY_IS_EQUAL(forward_output_imag_part.dimension(0), input.dimension(0))
    VERIFY_IS_EQUAL(reverse_output_imag_part.dimension(0), input.dimension(0))
    var forward_golden_result: StaticTuple[Complex[Float32], 5]
    var reverse_golden_result: StaticTuple[Complex[Float32], 5]
    forward_golden_result[0] = Complex[Float32](15, 0)
    forward_golden_result[1] = Complex[Float32](-2.5, +3.44095480117793)
    forward_golden_result[2] = Complex[Float32](-2.5, +0.81229924058227)
    forward_golden_result[3] = Complex[Float32](-2.5, -0.81229924058227)
    forward_golden_result[4] = Complex[Float32](-2.5, -3.44095480117793)
    reverse_golden_result[0] = Complex[Float32](3.0, 0)
    reverse_golden_result[1] = Complex[Float32](-0.5, -0.688190960235587)
    reverse_golden_result[2] = Complex[Float32](-0.5, -0.162459848116453)
    reverse_golden_result[3] = Complex[Float32](-0.5, +0.162459848116453)
    reverse_golden_result[4] = Complex[Float32](-0.5, +0.688190960235587)
    var c_offset = Complex[Float32](1.0, 1.0)
    var r_offset: Float32 = 1.0
    for i in range(5):
        VERIFY_IS_APPROX(forward_output_both_parts[i] + c_offset, forward_golden_result[i] + c_offset)
        VERIFY_IS_APPROX(forward_output_real_part[i] + r_offset, forward_golden_result[i].real() + r_offset)
        VERIFY_IS_APPROX(forward_output_imag_part[i] + r_offset, forward_golden_result[i].imag() + r_offset)
    for i in range(5):
        VERIFY_IS_APPROX(reverse_output_both_parts[i] + c_offset, reverse_golden_result[i] + c_offset)
        VERIFY_IS_APPROX(reverse_output_real_part[i] + r_offset, reverse_golden_result[i].real() + r_offset)
        VERIFY_IS_APPROX(reverse_output_imag_part[i] + r_offset, reverse_golden_result[i].imag() + r_offset)

def test_fft_real_input_energy[DataLayout: Int, RealScalar: AnyType, isComplexInput: Bool, FFTResultType: Int, FFTDirection: Int, TensorRank: Int]():
    var dimensions: DSizes[Int, TensorRank]
    var total_size: Int = 1
    for i in range(TensorRank):
        dimensions[i] = rand() % 20 + 1
        total_size *= dimensions[i]
    let arr: DSizes[Int, TensorRank] = dimensions
    @parameter
    if isComplexInput:
        type InputScalar = Complex[RealScalar]
    else:
        type InputScalar = RealScalar
    var input = Tensor[InputScalar, TensorRank, DataLayout]()
    input.resize(arr)
    input.setRandom()
    var fft: SIMD[Int, TensorRank]
    for i in range(TensorRank):
        fft[i] = i
    @parameter
    if FFTResultType == BothParts:
        type OutputScalar = Complex[RealScalar]
    else:
        type OutputScalar = RealScalar
    var output = Tensor[OutputScalar, TensorRank, DataLayout]()
    output = input.fft[FFTResultType, FFTDirection](fft)
    for i in range(TensorRank):
        VERIFY_IS_EQUAL(output.dimension(i), input.dimension(i))
    var energy_original: RealScalar = 0.0
    var energy_after_fft: RealScalar = 0.0
    for i in range(total_size):
        energy_original += numext.abs2(input[i])
    for i in range(total_size):
        energy_after_fft += numext.abs2(output[i])
    if FFTDirection == FFT_FORWARD:
        VERIFY_IS_APPROX(energy_original, energy_after_fft / total_size)
    else:
        VERIFY_IS_APPROX(energy_original, energy_after_fft * total_size)

def test_cxx11_tensor_fft():
    test_fft_complex_input_golden()
    test_fft_real_input_golden()
    test_fft_2D_golden[ColMajor]()
    test_fft_2D_golden[RowMajor]()
    test_fft_real_input_energy[ColMajor, Float32, True, BothParts, FFT_FORWARD, 1]()
    test_fft_real_input_energy[ColMajor, Float64, True, BothParts, FFT_FORWARD, 1]()
    test_fft_real_input_energy[ColMajor, Float32, False, BothParts, FFT_FORWARD, 1]()
    test_fft_real_input_energy[ColMajor, Float64, False, BothParts, FFT_FORWARD, 1]()
    test_fft_real_input_energy[ColMajor, Float32, True, BothParts, FFT_FORWARD, 2]()
    test_fft_real_input_energy[ColMajor, Float64, True, BothParts, FFT_FORWARD, 2]()
    test_fft_real_input_energy[ColMajor, Float32, False, BothParts, FFT_FORWARD, 2]()
    test_fft_real_input_energy[ColMajor, Float64, False, BothParts, FFT_FORWARD, 2]()
    test_fft_real_input_energy[ColMajor, Float32, True, BothParts, FFT_FORWARD, 3]()
    test_fft_real_input_energy[ColMajor, Float64, True, BothParts, FFT_FORWARD, 3]()
    test_fft_real_input_energy[ColMajor, Float32, False, BothParts, FFT_FORWARD, 3]()
    test_fft_real_input_energy[ColMajor, Float64, False, BothParts, FFT_FORWARD, 3]()
    test_fft_real_input_energy[ColMajor, Float32, True, BothParts, FFT_FORWARD, 4]()
    test_fft_real_input_energy[ColMajor, Float64, True, BothParts, FFT_FORWARD, 4]()
    test_fft_real_input_energy[ColMajor, Float32, False, BothParts, FFT_FORWARD, 4]()
    test_fft_real_input_energy[ColMajor, Float64, False, BothParts, FFT_FORWARD, 4]()
    test_fft_real_input_energy[RowMajor, Float32, True, BothParts, FFT_FORWARD, 1]()
    test_fft_real_input_energy[RowMajor, Float64, True, BothParts, FFT_FORWARD, 1]()
    test_fft_real_input_energy[RowMajor, Float32, False, BothParts, FFT_FORWARD, 1]()
    test_fft_real_input_energy[RowMajor, Float64, False, BothParts, FFT_FORWARD, 1]()
    test_fft_real_input_energy[RowMajor, Float32, True, BothParts, FFT_FORWARD, 2]()
    test_fft_real_input_energy[RowMajor, Float64, True, BothParts, FFT_FORWARD, 2]()
    test_fft_real_input_energy[RowMajor, Float32, False, BothParts, FFT_FORWARD, 2]()
    test_fft_real_input_energy[RowMajor, Float64, False, BothParts, FFT_FORWARD, 2]()
    test_fft_real_input_energy[RowMajor, Float32, True, BothParts, FFT_FORWARD, 3]()
    test_fft_real_input_energy[RowMajor, Float64, True, BothParts, FFT_FORWARD, 3]()
    test_fft_real_input_energy[RowMajor, Float32, False, BothParts, FFT_FORWARD, 3]()
    test_fft_real_input_energy[RowMajor, Float64, False, BothParts, FFT_FORWARD, 3]()
    test_fft_real_input_energy[RowMajor, Float32, True, BothParts, FFT_FORWARD, 4]()
    test_fft_real_input_energy[RowMajor, Float64, True, BothParts, FFT_FORWARD, 4]()
    test_fft_real_input_energy[RowMajor, Float32, False, BothParts, FFT_FORWARD, 4]()
    test_fft_real_input_energy[RowMajor, Float64, False, BothParts, FFT_FORWARD, 4]()