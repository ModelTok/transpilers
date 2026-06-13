from tensor import Tensor, TensorEvaluator, DefaultDevice, ColMajor, RowMajor
from testing import assert_equal

def test_simple_chip[DataLayout: Int]():
    var tensor = Tensor[Float32, 5, DataLayout](2, 3, 5, 7, 11)
    tensor.setRandom()
    var chip1 = Tensor[Float32, 4, DataLayout]()
    chip1 = tensor.template chip[0](1)
    assert_equal(chip1.dimension(0), 3)
    assert_equal(chip1.dimension(1), 5)
    assert_equal(chip1.dimension(2), 7)
    assert_equal(chip1.dimension(3), 11)
    for i in range(3):
        for j in range(5):
            for k in range(7):
                for l in range(11):
                    assert_equal(chip1(i, j, k, l), tensor(1, i, j, k, l))

    var chip2 = tensor.template chip[1](1)
    assert_equal(chip2.dimension(0), 2)
    assert_equal(chip2.dimension(1), 5)
    assert_equal(chip2.dimension(2), 7)
    assert_equal(chip2.dimension(3), 11)
    for i in range(2):
        for j in range(3):
            for k in range(7):
                for l in range(11):
                    assert_equal(chip2(i, j, k, l), tensor(i, 1, j, k, l))

    var chip3 = tensor.template chip[2](2)
    assert_equal(chip3.dimension(0), 2)
    assert_equal(chip3.dimension(1), 3)
    assert_equal(chip3.dimension(2), 7)
    assert_equal(chip3.dimension(3), 11)
    for i in range(2):
        for j in range(3):
            for k in range(7):
                for l in range(11):
                    assert_equal(chip3(i, j, k, l), tensor(i, j, 2, k, l))

    var chip4 = Tensor[Float32, 4, DataLayout](tensor.template chip[3](5))
    assert_equal(chip4.dimension(0), 2)
    assert_equal(chip4.dimension(1), 3)
    assert_equal(chip4.dimension(2), 5)
    assert_equal(chip4.dimension(3), 11)
    for i in range(2):
        for j in range(3):
            for k in range(5):
                for l in range(7):
                    assert_equal(chip4(i, j, k, l), tensor(i, j, k, 5, l))

    var chip5 = Tensor[Float32, 4, DataLayout](tensor.template chip[4](7))
    assert_equal(chip5.dimension(0), 2)
    assert_equal(chip5.dimension(1), 3)
    assert_equal(chip5.dimension(2), 5)
    assert_equal(chip5.dimension(3), 7)
    for i in range(2):
        for j in range(3):
            for k in range(5):
                for l in range(7):
                    assert_equal(chip5(i, j, k, l), tensor(i, j, k, l, 7))

def test_dynamic_chip[DataLayout: Int]():
    var tensor = Tensor[Float32, 5, DataLayout](2, 3, 5, 7, 11)
    tensor.setRandom()
    var chip1 = Tensor[Float32, 4, DataLayout]()
    chip1 = tensor.chip(1, 0)
    assert_equal(chip1.dimension(0), 3)
    assert_equal(chip1.dimension(1), 5)
    assert_equal(chip1.dimension(2), 7)
    assert_equal(chip1.dimension(3), 11)
    for i in range(3):
        for j in range(5):
            for k in range(7):
                for l in range(11):
                    assert_equal(chip1(i, j, k, l), tensor(1, i, j, k, l))

    var chip2 = tensor.chip(1, 1)
    assert_equal(chip2.dimension(0), 2)
    assert_equal(chip2.dimension(1), 5)
    assert_equal(chip2.dimension(2), 7)
    assert_equal(chip2.dimension(3), 11)
    for i in range(2):
        for j in range(3):
            for k in range(7):
                for l in range(11):
                    assert_equal(chip2(i, j, k, l), tensor(i, 1, j, k, l))

    var chip3 = tensor.chip(2, 2)
    assert_equal(chip3.dimension(0), 2)
    assert_equal(chip3.dimension(1), 3)
    assert_equal(chip3.dimension(2), 7)
    assert_equal(chip3.dimension(3), 11)
    for i in range(2):
        for j in range(3):
            for k in range(7):
                for l in range(11):
                    assert_equal(chip3(i, j, k, l), tensor(i, j, 2, k, l))

    var chip4 = Tensor[Float32, 4, DataLayout](tensor.chip(5, 3))
    assert_equal(chip4.dimension(0), 2)
    assert_equal(chip4.dimension(1), 3)
    assert_equal(chip4.dimension(2), 5)
    assert_equal(chip4.dimension(3), 11)
    for i in range(2):
        for j in range(3):
            for k in range(5):
                for l in range(7):
                    assert_equal(chip4(i, j, k, l), tensor(i, j, k, 5, l))

    var chip5 = Tensor[Float32, 4, DataLayout](tensor.chip(7, 4))
    assert_equal(chip5.dimension(0), 2)
    assert_equal(chip5.dimension(1), 3)
    assert_equal(chip5.dimension(2), 5)
    assert_equal(chip5.dimension(3), 7)
    for i in range(2):
        for j in range(3):
            for k in range(5):
                for l in range(7):
                    assert_equal(chip5(i, j, k, l), tensor(i, j, k, l, 7))

def test_chip_in_expr[DataLayout: Int]():
    var input1 = Tensor[Float32, 5, DataLayout](2, 3, 5, 7, 11)
    input1.setRandom()
    var input2 = Tensor[Float32, 4, DataLayout](3, 5, 7, 11)
    input2.setRandom()
    var result = input1.template chip[0](0) + input2
    for i in range(3):
        for j in range(5):
            for k in range(7):
                for l in range(11):
                    var expected = input1(0, i, j, k, l) + input2(i, j, k, l)
                    assert_equal(result(i, j, k, l), expected)

    var input3 = Tensor[Float32, 3, DataLayout](3, 7, 11)
    input3.setRandom()
    var result2 = input1.template chip[0](0).template chip[1](2) + input3
    for i in range(3):
        for j in range(7):
            for k in range(11):
                var expected = input1(0, i, 2, j, k) + input3(i, j, k)
                assert_equal(result2(i, j, k), expected)

def test_chip_as_lvalue[DataLayout: Int]():
    var input1 = Tensor[Float32, 5, DataLayout](2, 3, 5, 7, 11)
    input1.setRandom()
    var input2 = Tensor[Float32, 4, DataLayout](3, 5, 7, 11)
    input2.setRandom()
    var tensor = input1
    tensor.template chip[0](1) = input2
    for i in range(2):
        for j in range(3):
            for k in range(5):
                for l in range(7):
                    for m in range(11):
                        if i != 1:
                            assert_equal(tensor(i, j, k, l, m), input1(i, j, k, l, m))
                        else:
                            assert_equal(tensor(i, j, k, l, m), input2(j, k, l, m))

    var input3 = Tensor[Float32, 4, DataLayout](2, 5, 7, 11)
    input3.setRandom()
    tensor = input1
    tensor.template chip[1](1) = input3
    for i in range(2):
        for j in range(3):
            for k in range(5):
                for l in range(7):
                    for m in range(11):
                        if j != 1:
                            assert_equal(tensor(i, j, k, l, m), input1(i, j, k, l, m))
                        else:
                            assert_equal(tensor(i, j, k, l, m), input3(i, k, l, m))

    var input4 = Tensor[Float32, 4, DataLayout](2, 3, 7, 11)
    input4.setRandom()
    tensor = input1
    tensor.template chip[2](3) = input4
    for i in range(2):
        for j in range(3):
            for k in range(5):
                for l in range(7):
                    for m in range(11):
                        if k != 3:
                            assert_equal(tensor(i, j, k, l, m), input1(i, j, k, l, m))
                        else:
                            assert_equal(tensor(i, j, k, l, m), input4(i, j, l, m))

    var input5 = Tensor[Float32, 4, DataLayout](2, 3, 5, 11)
    input5.setRandom()
    tensor = input1
    tensor.template chip[3](4) = input5
    for i in range(2):
        for j in range(3):
            for k in range(5):
                for l in range(7):
                    for m in range(11):
                        if l != 4:
                            assert_equal(tensor(i, j, k, l, m), input1(i, j, k, l, m))
                        else:
                            assert_equal(tensor(i, j, k, l, m), input5(i, j, k, m))

    var input6 = Tensor[Float32, 4, DataLayout](2, 3, 5, 7)
    input6.setRandom()
    tensor = input1
    tensor.template chip[4](5) = input6
    for i in range(2):
        for j in range(3):
            for k in range(5):
                for l in range(7):
                    for m in range(11):
                        if m != 5:
                            assert_equal(tensor(i, j, k, l, m), input1(i, j, k, l, m))
                        else:
                            assert_equal(tensor(i, j, k, l, m), input6(i, j, k, l))

    var input7 = Tensor[Float32, 5, DataLayout](2, 3, 5, 7, 11)
    input7.setRandom()
    tensor = input1
    tensor.chip(0, 0) = input7.chip(0, 0)
    for i in range(2):
        for j in range(3):
            for k in range(5):
                for l in range(7):
                    for m in range(11):
                        if i != 0:
                            assert_equal(tensor(i, j, k, l, m), input1(i, j, k, l, m))
                        else:
                            assert_equal(tensor(i, j, k, l, m), input7(i, j, k, l, m))

def test_chip_raw_data_col_major():
    var tensor = Tensor[Float32, 5, ColMajor](2, 3, 5, 7, 11)
    tensor.setRandom()
    alias Evaluator4 = TensorEvaluator[decltype(tensor.chip[4](3)), DefaultDevice]
    var chip = Evaluator4(tensor.chip[4](3), DefaultDevice())
    for i in range(2):
        for j in range(3):
            for k in range(5):
                for l in range(7):
                    var chip_index = i + 2 * (j + 3 * (k + 5 * l))
                    assert_equal(chip.data()[chip_index], tensor(i, j, k, l, 3))

    alias Evaluator1 = TensorEvaluator[decltype(tensor.chip[1](0)), DefaultDevice]
    var chip1 = Evaluator1(tensor.chip[1](0), DefaultDevice())
    assert_equal(chip1.data(), __mlir_type.`!kgen.pointer<f32>`(0))  # placeholder for null pointer

    alias Evaluator2 = TensorEvaluator[decltype(tensor.chip[2](0)), DefaultDevice]
    var chip2 = Evaluator2(tensor.chip[2](0), DefaultDevice())
    assert_equal(chip2.data(), __mlir_type.`!kgen.pointer<f32>`(0))

    alias Evaluator3 = TensorEvaluator[decltype(tensor.chip[3](0)), DefaultDevice]
    var chip3 = Evaluator3(tensor.chip[3](0), DefaultDevice())
    assert_equal(chip3.data(), __mlir_type.`!kgen.pointer<f32>`(0))

def test_chip_raw_data_row_major():
    var tensor = Tensor[Float32, 5, RowMajor](11, 7, 5, 3, 2)
    tensor.setRandom()
    alias Evaluator0 = TensorEvaluator[decltype(tensor.chip[0](3)), DefaultDevice]
    var chip = Evaluator0(tensor.chip[0](3), DefaultDevice())
    for i in range(7):
        for j in range(5):
            for k in range(3):
                for l in range(2):
                    var chip_index = l + 2 * (k + 3 * (j + 5 * i))
                    assert_equal(chip.data()[chip_index], tensor(3, i, j, k, l))

    alias Evaluator1 = TensorEvaluator[decltype(tensor.chip[1](0)), DefaultDevice]
    var chip1 = Evaluator1(tensor.chip[1](0), DefaultDevice())
    assert_equal(chip1.data(), __mlir_type.`!kgen.pointer<f32>`(0))

    alias Evaluator2 = TensorEvaluator[decltype(tensor.chip[2](0)), DefaultDevice]
    var chip2 = Evaluator2(tensor.chip[2](0), DefaultDevice())
    assert_equal(chip2.data(), __mlir_type.`!kgen.pointer<f32>`(0))

    alias Evaluator3 = TensorEvaluator[decltype(tensor.chip[3](0)), DefaultDevice]
    var chip3 = Evaluator3(tensor.chip[3](0), DefaultDevice())
    assert_equal(chip3.data(), __mlir_type.`!kgen.pointer<f32>`(0))

    alias Evaluator4 = TensorEvaluator[decltype(tensor.chip[4](0)), DefaultDevice]
    var chip4 = Evaluator4(tensor.chip[4](0), DefaultDevice())
    assert_equal(chip4.data(), __mlir_type.`!kgen.pointer<f32>`(0))

def test_cxx11_tensor_chipping():
    test_simple_chip[ColMajor]()
    test_simple_chip[RowMajor]()
    test_dynamic_chip[ColMajor]()
    test_dynamic_chip[RowMajor]()
    test_chip_in_expr[ColMajor]()
    test_chip_in_expr[RowMajor]()
    test_chip_as_lvalue[ColMajor]()
    test_chip_as_lvalue[RowMajor]()
    test_chip_raw_data_col_major()
    test_chip_raw_data_row_major()
<<<FILE>>>