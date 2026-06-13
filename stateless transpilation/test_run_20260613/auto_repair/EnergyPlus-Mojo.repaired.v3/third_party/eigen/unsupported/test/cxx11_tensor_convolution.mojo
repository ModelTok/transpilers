# This is a 1:1 translation from C++ to Mojo of the Eigen tensor convolution test.
# No refactoring or renaming has been performed.
from Tensor import Tensor, DefaultDevice, ColMajor, RowMajor
from testing import assert_equal, assert_approx_eq, run_test

alias Eigen_array = DynamicList[Int]

def verify_is_equal(a: Int, b: Int) raises:
    assert_equal(a, b)

def verify_is_equal(a: Float32, b: Float32) raises:
    assert_equal(a, b)

def verify_is_approx(a: Float32, b: Float32) raises:
    assert_approx_eq(a, b)

def test_evals[DataLayout: Int]() raises:
    var input = Tensor[Float32, 2, DataLayout](3, 3)
    var kernel = Tensor[Float32, 1, DataLayout](2)
    input.setRandom()
    kernel.setRandom()
    var result = Tensor[Float32, 2, DataLayout](2, 3)
    result.setZero()
    var dims3: Eigen_array
    dims3.append(0)  # Eigen::array<Tensor<float,2>::Index,1> dims3{{0}};
    alias Evaluator = TensorEvaluator[decltype(input.convolve(kernel, dims3)), DefaultDevice]
    var eval = Evaluator(input.convolve(kernel, dims3), DefaultDevice())
    eval.evalTo(result.data())
    @parameter static_assert(Evaluator.NumDims == 2, "YOU_MADE_A_PROGRAMMING_MISTAKE")
    verify_is_equal(eval.dimensions()[0], 2)
    verify_is_equal(eval.dimensions()[1], 3)
    verify_is_approx(result(0,0), input(0,0)*kernel(0) + input(1,0)*kernel(1))  # index 0
    verify_is_approx(result(0,1), input(0,1)*kernel(0) + input(1,1)*kernel(1))  # index 2
    verify_is_approx(result(0,2), input(0,2)*kernel(0) + input(1,2)*kernel(1))  # index 4
    verify_is_approx(result(1,0), input(1,0)*kernel(0) + input(2,0)*kernel(1))  # index 1
    verify_is_approx(result(1,1), input(1,1)*kernel(0) + input(2,1)*kernel(1))  # index 3
    verify_is_approx(result(1,2), input(1,2)*kernel(0) + input(2,2)*kernel(1))  # index 5

def test_expr[DataLayout: Int]() raises:
    var input = Tensor[Float32, 2, DataLayout](3, 3)
    var kernel = Tensor[Float32, 2, DataLayout](2, 2)
    input.setRandom()
    kernel.setRandom()
    var result = Tensor[Float32, 2, DataLayout](2, 2)
    var dims: Eigen_array
    dims.append(0)
    dims.append(1)
    result = input.convolve(kernel, dims)
    verify_is_approx(result(0,0), input(0,0)*kernel(0,0) + input(0,1)*kernel(0,1) +
                                input(1,0)*kernel(1,0) + input(1,1)*kernel(1,1))
    verify_is_approx(result(0,1), input(0,1)*kernel(0,0) + input(0,2)*kernel(0,1) +
                                input(1,1)*kernel(1,0) + input(1,2)*kernel(1,1))
    verify_is_approx(result(1,0), input(1,0)*kernel(0,0) + input(1,1)*kernel(0,1) +
                                input(2,0)*kernel(1,0) + input(2,1)*kernel(1,1))
    verify_is_approx(result(1,1), input(1,1)*kernel(0,0) + input(1,2)*kernel(0,1) +
                                input(2,1)*kernel(1,0) + input(2,2)*kernel(1,1))

def test_modes[DataLayout: Int]() raises:
    var input = Tensor[Float32, 1, DataLayout](3)
    var kernel = Tensor[Float32, 1, DataLayout](3)
    input(0) = 1.0f
    input(1) = 2.0f
    input(2) = 3.0f
    kernel(0) = 0.5f
    kernel(1) = 1.0f
    kernel(2) = 0.0f
    var dims: Eigen_array
    dims.append(0)
    var padding = DynamicList[StdPair[Int, Int]]()
    padding.append(StdPair[Int, Int](0, 0))
    var valid = Tensor[Float32, 1, DataLayout](1)
    valid = input.pad(padding).convolve(kernel, dims)
    verify_is_equal(valid.dimension(0), 1)
    verify_is_approx(valid(0), 2.5f)
    padding[0] = StdPair[Int, Int](1, 1)
    var same = Tensor[Float32, 1, DataLayout](3)
    same = input.pad(padding).convolve(kernel, dims)
    verify_is_equal(same.dimension(0), 3)
    verify_is_approx(same(0), 1.0f)
    verify_is_approx(same(1), 2.5f)
    verify_is_approx(same(2), 4.0f)
    padding[0] = StdPair[Int, Int](2, 2)
    var full = Tensor[Float32, 1, DataLayout](5)
    full = input.pad(padding).convolve(kernel, dims)
    verify_is_equal(full.dimension(0), 5)
    verify_is_approx(full(0), 0.0f)
    verify_is_approx(full(1), 1.0f)
    verify_is_approx(full(2), 2.5f)
    verify_is_approx(full(3), 4.0f)
    verify_is_approx(full(4), 1.5f)

def test_strides[DataLayout: Int]() raises:
    var input = Tensor[Float32, 1, DataLayout](13)
    var kernel = Tensor[Float32, 1, DataLayout](3)
    input.setRandom()
    kernel.setRandom()
    var dims: Eigen_array
    dims.append(0)
    var stride_of_3: Eigen_array
    stride_of_3.append(3)
    var stride_of_2: Eigen_array
    stride_of_2.append(2)
    var result = Tensor[Float32, 1, DataLayout]()
    result = input.stride(stride_of_3).convolve(kernel, dims).stride(stride_of_2)
    verify_is_equal(result.dimension(0), 2)
    verify_is_approx(result(0), (input(0)*kernel(0) + input(3)*kernel(1) +
                               input(6)*kernel(2)))
    verify_is_approx(result(1), (input(6)*kernel(0) + input(9)*kernel(1) +
                               input(12)*kernel(2)))

def main() raises:
    run_test[test_evals[ColMajor]]()
    run_test[test_evals[RowMajor]]()
    run_test[test_expr[ColMajor]]()
    run_test[test_expr[RowMajor]]()
    run_test[test_modes[ColMajor]]()
    run_test[test_modes[RowMajor]]()
    run_test[test_strides[ColMajor]]()
    run_test[test_strides[RowMajor]]()