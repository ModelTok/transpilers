from Eigen import Tensor, TensorMap, TensorRef, TensorEvaluator, DefaultDevice, DSizes, DenseIndex, MatrixXf, Map, DimPair
from Eigen import ColMajor, RowMajor
from main import VERIFY_IS_EQUAL, VERIFY_IS_APPROX, CALL_SUBTEST_1, CALL_SUBTEST_2, CALL_SUBTEST_3, CALL_SUBTEST_4, CALL_SUBTEST_5, CALL_SUBTEST_6, CALL_SUBTEST_7

def test_simple_reshape[_type: AnyType]():
    var tensor1 = Tensor[float32, 5](2, 3, 1, 7, 1)
    tensor1.setRandom()
    var tensor2 = Tensor[float32, 3](2, 3, 7)
    var tensor3 = Tensor[float32, 2](6, 7)
    var tensor4 = Tensor[float32, 2](2, 21)
    var dim1 = Tensor[float32, 3].Dimensions(2, 3, 7)
    tensor2 = tensor1.reshape(dim1)
    var dim2 = Tensor[float32, 2].Dimensions(6, 7)
    tensor3 = tensor1.reshape(dim2)
    var dim3 = Tensor[float32, 2].Dimensions(2, 21)
    tensor4 = tensor1.reshape(dim1).reshape(dim3)
    for i in range(2):
        for j in range(3):
            for k in range(7):
                VERIFY_IS_EQUAL(tensor1[i, j, 0, k, 0], tensor2[i, j, k])
                VERIFY_IS_EQUAL(tensor1[i, j, 0, k, 0], tensor3[i + 2 * j, k])
                VERIFY_IS_EQUAL(tensor1[i, j, 0, k, 0], tensor4[i, j + 3 * k])

def test_reshape_in_expr[_type: AnyType]():
    var m1 = MatrixXf(2, 3 * 5 * 7 * 11)
    var m2 = MatrixXf(3 * 5 * 7 * 11, 13)
    m1.setRandom()
    m2.setRandom()
    var m3 = m1 * m2
    var tensor1 = TensorMap[Tensor[float32, 5]](m1.data(), 2, 3, 5, 7, 11)
    var tensor2 = TensorMap[Tensor[float32, 5]](m2.data(), 3, 5, 7, 11, 13)
    var newDims1 = Tensor[float32, 2].Dimensions(2, 3 * 5 * 7 * 11)
    var newDims2 = Tensor[float32, 2].Dimensions(3 * 5 * 7 * 11, 13)
    type DimPair = Tensor[float32, 1].DimensionPair
    var contract_along = array[DimPair, 1](DimPair(1, 0))
    var tensor3 = Tensor[float32, 2](2, 13)
    tensor3 = tensor1.reshape(newDims1).contract(tensor2.reshape(newDims2), contract_along)
    var res = Map[MatrixXf](tensor3.data(), 2, 13)
    for i in range(2):
        for j in range(13):
            VERIFY_IS_APPROX(res[i, j], m3[i, j])

def test_reshape_as_lvalue[_type: AnyType]():
    var tensor = Tensor[float32, 3](2, 3, 7)
    tensor.setRandom()
    var tensor2d = Tensor[float32, 2](6, 7)
    var dim = Tensor[float32, 3].Dimensions(2, 3, 7)
    tensor2d.reshape(dim) = tensor
    var scratch = float32(2 * 3 * 1 * 7 * 1)
    var tensor5d = TensorMap[Tensor[float32, 5]](scratch, 2, 3, 1, 7, 1)
    tensor5d.reshape(dim).device(DefaultDevice()) = tensor
    for i in range(2):
        for j in range(3):
            for k in range(7):
                VERIFY_IS_EQUAL(tensor2d[i + 2 * j, k], tensor[i, j, k])
                VERIFY_IS_EQUAL(tensor5d[i, j, 0, k, 0], tensor[i, j, k])

def test_simple_slice[DataLayout: Int]():
    var tensor = Tensor[float32, 5, DataLayout](2, 3, 5, 7, 11)
    tensor.setRandom()
    var slice1 = Tensor[float32, 5, DataLayout](1, 1, 1, 1, 1)
    var indices = DSizes[Int, 5](1, 2, 3, 4, 5)
    var sizes = DSizes[Int, 5](1, 1, 1, 1, 1)
    slice1 = tensor.slice(indices, sizes)
    VERIFY_IS_EQUAL(slice1[0, 0, 0, 0, 0], tensor[1, 2, 3, 4, 5])
    var slice2 = Tensor[float32, 5, DataLayout](1, 1, 2, 2, 3)
    var indices2 = DSizes[Int, 5](1, 1, 3, 4, 5)
    var sizes2 = DSizes[Int, 5](1, 1, 2, 2, 3)
    slice2 = tensor.slice(indices2, sizes2)
    for i in range(2):
        for j in range(2):
            for k in range(3):
                VERIFY_IS_EQUAL(slice2[0, 0, i, j, k], tensor[1, 1, 3 + i, 4 + j, 5 + k])

def test_const_slice[_type: AnyType]():
    var b = float32(1)
    b[0] = 42.0
    var m = TensorMap[Tensor[const float32, 1]](b, 1)
    var offsets = DSizes[DenseIndex, 1]()
    offsets[0] = 0
    var slice_ref = TensorRef[Tensor[const float32, 1]](m.slice(offsets, m.dimensions()))
    VERIFY_IS_EQUAL(slice_ref[0], 42.0)

def test_slice_in_expr[DataLayout: Int]():
    type Mtx = Matrix[float32, Dynamic, Dynamic, DataLayout]
    var m1 = Mtx(7, 7)
    var m2 = Mtx(3, 3)
    m1.setRandom()
    m2.setRandom()
    var m3 = m1.block(1, 2, 3, 3) * m2.block(0, 2, 3, 1)
    var tensor1 = TensorMap[Tensor[float32, 2, DataLayout]](m1.data(), 7, 7)
    var tensor2 = TensorMap[Tensor[float32, 2, DataLayout]](m2.data(), 3, 3)
    var tensor3 = Tensor[float32, 2, DataLayout](3, 1)
    type DimPair = Tensor[float32, 1].DimensionPair
    var contract_along = array[DimPair, 1](DimPair(1, 0))
    var indices1 = DSizes[Int, 2](1, 2)
    var sizes1 = DSizes[Int, 2](3, 3)
    var indices2 = DSizes[Int, 2](0, 2)
    var sizes2 = DSizes[Int, 2](3, 1)
    tensor3 = tensor1.slice(indices1, sizes1).contract(tensor2.slice(indices2, sizes2), contract_along)
    var res = Map[Mtx](tensor3.data(), 3, 1)
    for i in range(3):
        for j in range(1):
            VERIFY_IS_APPROX(res[i, j], m3[i, j])
    var tensor4 = TensorMap[Tensor[const float32, 2, DataLayout]](m1.data(), 7, 7)
    var tensor6 = tensor4.reshape(DSizes[Int, 1](7 * 7)).exp().slice(DSizes[Int, 1](0), DSizes[Int, 1](35))
    for i in range(35):
        VERIFY_IS_APPROX(tensor6[i], expf(tensor4.data()[i]))

def test_slice_as_lvalue[DataLayout: Int]():
    var tensor1 = Tensor[float32, 3, DataLayout](2, 2, 7)
    tensor1.setRandom()
    var tensor2 = Tensor[float32, 3, DataLayout](2, 2, 7)
    tensor2.setRandom()
    var tensor3 = Tensor[float32, 3, DataLayout](4, 3, 5)
    tensor3.setRandom()
    var tensor4 = Tensor[float32, 3, DataLayout](4, 3, 2)
    tensor4.setRandom()
    var tensor5 = Tensor[float32, 3, DataLayout](10, 13, 12)
    tensor5.setRandom()
    var result = Tensor[float32, 3, DataLayout](4, 5, 7)
    var sizes12 = DSizes[Int, 3](2, 2, 7)
    var first_slice = DSizes[Int, 3](0, 0, 0)
    result.slice(first_slice, sizes12) = tensor1
    var second_slice = DSizes[Int, 3](2, 0, 0)
    result.slice(second_slice, sizes12).device(DefaultDevice()) = tensor2
    var sizes3 = DSizes[Int, 3](4, 3, 5)
    var third_slice = DSizes[Int, 3](0, 2, 0)
    result.slice(third_slice, sizes3) = tensor3
    var sizes4 = DSizes[Int, 3](4, 3, 2)
    var fourth_slice = DSizes[Int, 3](0, 2, 5)
    result.slice(fourth_slice, sizes4) = tensor4
    for j in range(2):
        for k in range(7):
            for i in range(2):
                VERIFY_IS_EQUAL(result[i, j, k], tensor1[i, j, k])
                VERIFY_IS_EQUAL(result[i + 2, j, k], tensor2[i, j, k])
    for i in range(4):
        for j in range(2, 5):
            for k in range(5):
                VERIFY_IS_EQUAL(result[i, j, k], tensor3[i, j - 2, k])
            for k in range(5, 7):
                VERIFY_IS_EQUAL(result[i, j, k], tensor4[i, j - 2, k - 5])
    var sizes5 = DSizes[Int, 3](4, 5, 7)
    var fifth_slice = DSizes[Int, 3](0, 0, 0)
    result.slice(fifth_slice, sizes5) = tensor5.slice(fifth_slice, sizes5)
    for i in range(4):
        for j in range(2, 5):
            for k in range(7):
                VERIFY_IS_EQUAL(result[i, j, k], tensor5[i, j, k])

def test_slice_raw_data[DataLayout: Int]():
    var tensor = Tensor[float32, 4, DataLayout](3, 5, 7, 11)
    tensor.setRandom()
    var offsets = DSizes[Int, 4](1, 2, 3, 4)
    var extents = DSizes[Int, 4](1, 1, 1, 1)
    type SliceEvaluator = TensorEvaluator[decltype(tensor.slice(offsets, extents)), DefaultDevice]
    var slice1 = SliceEvaluator(tensor.slice(offsets, extents), DefaultDevice())
    VERIFY_IS_EQUAL(slice1.dimensions().TotalSize(), 1)
    VERIFY_IS_EQUAL(slice1.data()[0], tensor[1, 2, 3, 4])
    if DataLayout == ColMajor:
        extents = DSizes[Int, 4](2, 1, 1, 1)
        var slice2 = SliceEvaluator(tensor.slice(offsets, extents), DefaultDevice())
        VERIFY_IS_EQUAL(slice2.dimensions().TotalSize(), 2)
        VERIFY_IS_EQUAL(slice2.data()[0], tensor[1, 2, 3, 4])
        VERIFY_IS_EQUAL(slice2.data()[1], tensor[2, 2, 3, 4])
    else:
        extents = DSizes[Int, 4](1, 1, 1, 2)
        var slice2 = SliceEvaluator(tensor.slice(offsets, extents), DefaultDevice())
        VERIFY_IS_EQUAL(slice2.dimensions().TotalSize(), 2)
        VERIFY_IS_EQUAL(slice2.data()[0], tensor[1, 2, 3, 4])
        VERIFY_IS_EQUAL(slice2.data()[1], tensor[1, 2, 3, 5])
    extents = DSizes[Int, 4](1, 2, 1, 1)
    var slice3 = SliceEvaluator(tensor.slice(offsets, extents), DefaultDevice())
    VERIFY_IS_EQUAL(slice3.dimensions().TotalSize(), 2)
    VERIFY_IS_EQUAL(slice3.data(), static_cast[float32*](0))
    if DataLayout == ColMajor:
        offsets = DSizes[Int, 4](0, 2, 3, 4)
        extents = DSizes[Int, 4](3, 2, 1, 1)
        var slice4 = SliceEvaluator(tensor.slice(offsets, extents), DefaultDevice())
        VERIFY_IS_EQUAL(slice4.dimensions().TotalSize(), 6)
        for i in range(3):
            for j in range(2):
                VERIFY_IS_EQUAL(slice4.data()[i + 3 * j], tensor[i, 2 + j, 3, 4])
    else:
        offsets = DSizes[Int, 4](1, 2, 3, 0)
        extents = DSizes[Int, 4](1, 1, 2, 11)
        var slice4 = SliceEvaluator(tensor.slice(offsets, extents), DefaultDevice())
        VERIFY_IS_EQUAL(slice4.dimensions().TotalSize(), 22)
        for l in range(11):
            for k in range(2):
                VERIFY_IS_EQUAL(slice4.data()[l + 11 * k], tensor[1, 2, 3 + k, l])
    if DataLayout == ColMajor:
        offsets = DSizes[Int, 4](0, 0, 0, 4)
        extents = DSizes[Int, 4](3, 5, 7, 2)
        var slice5 = SliceEvaluator(tensor.slice(offsets, extents), DefaultDevice())
        VERIFY_IS_EQUAL(slice5.dimensions().TotalSize(), 210)
        for i in range(3):
            for j in range(5):
                for k in range(7):
                    for l in range(2):
                        var slice_index = i + 3 * (j + 5 * (k + 7 * l))
                        VERIFY_IS_EQUAL(slice5.data()[slice_index], tensor[i, j, k, l + 4])
    else:
        offsets = DSizes[Int, 4](1, 0, 0, 0)
        extents = DSizes[Int, 4](2, 5, 7, 11)
        var slice5 = SliceEvaluator(tensor.slice(offsets, extents), DefaultDevice())
        VERIFY_IS_EQUAL(slice5.dimensions().TotalSize(), 770)
        for l in range(11):
            for k in range(7):
                for j in range(5):
                    for i in range(2):
                        var slice_index = l + 11 * (k + 7 * (j + 5 * i))
                        VERIFY_IS_EQUAL(slice5.data()[slice_index], tensor[i + 1, j, k, l])
    offsets = DSizes[Int, 4](0, 0, 0, 0)
    extents = DSizes[Int, 4](3, 5, 7, 11)
    var slice6 = SliceEvaluator(tensor.slice(offsets, extents), DefaultDevice())
    VERIFY_IS_EQUAL(slice6.dimensions().TotalSize(), 3 * 5 * 7 * 11)
    VERIFY_IS_EQUAL(slice6.data(), tensor.data())

def test_strided_slice[DataLayout: Int]():
    type Tensor5f = Tensor[float32, 5, DataLayout]
    type Index5 = DSizes[DenseIndex, 5]
    type Tensor2f = Tensor[float32, 2, DataLayout]
    type Index2 = DSizes[DenseIndex, 2]
    var tensor = Tensor[float32, 5, DataLayout](2, 3, 5, 7, 11)
    var tensor2 = Tensor[float32, 2, DataLayout](7, 11)
    tensor.setRandom()
    tensor2.setRandom()
    if true:
        var slice = Tensor2f(2, 3)
        var strides = Index2(-2, -1)
        var indicesStart = Index2(5, 7)
        var indicesStop = Index2(0, 4)
        slice = tensor2.stridedSlice(indicesStart, indicesStop, strides)
        for j in range(2):
            for k in range(3):
                VERIFY_IS_EQUAL(slice[j, k], tensor2[5 - 2 * j, 7 - k])
    if true:
        var slice = Tensor2f(0, 1)
        var strides = Index2(1, 1)
        var indicesStart = Index2(5, 4)
        var indicesStop = Index2(5, 5)
        slice = tensor2.stridedSlice(indicesStart, indicesStop, strides)
    if true: # test clamped degenerate intervals
        var slice = Tensor2f(7, 11)
        var strides = Index2(1, -1)
        var indicesStart = Index2(-3, 20) # should become 0,10
        var indicesStop = Index2(20, -11) # should become 11, -1
        slice = tensor2.stridedSlice(indicesStart, indicesStop, strides)
        for j in range(7):
            for k in range(11):
                VERIFY_IS_EQUAL(slice[j, k], tensor2[j, 10 - k])
    if true:
        var slice1 = Tensor5f(1, 1, 1, 1, 1)
        var indicesStart = DSizes[DenseIndex, 5](1, 2, 3, 4, 5)
        var indicesStop = DSizes[DenseIndex, 5](2, 3, 4, 5, 6)
        var strides = DSizes[DenseIndex, 5](1, 1, 1, 1, 1)
        slice1 = tensor.stridedSlice(indicesStart, indicesStop, strides)
        VERIFY_IS_EQUAL(slice1[0, 0, 0, 0, 0], tensor[1, 2, 3, 4, 5])
    if true:
        var slice = Tensor5f(1, 1, 2, 2, 3)
        var start = Index5(1, 1, 3, 4, 5)
        var stop = Index5(2, 2, 5, 6, 8)
        var strides = Index5(1, 1, 1, 1, 1)
        slice = tensor.stridedSlice(start, stop, strides)
        for i in range(2):
            for j in range(2):
                for k in range(3):
                    VERIFY_IS_EQUAL(slice[0, 0, i, j, k], tensor[1, 1, 3 + i, 4 + j, 5 + k])
    if true:
        var slice = Tensor5f(1, 1, 2, 2, 3)
        var strides3 = Index5(1, 1, -2, 1, -1)
        var indices3Start = Index5(1, 1, 4, 4, 7)
        var indices3Stop = Index5(2, 2, 0, 6, 4)
        slice = tensor.stridedSlice(indices3Start, indices3Stop, strides3)
        for i in range(2):
            for j in range(2):
                for k in range(3):
                    VERIFY_IS_EQUAL(slice[0, 0, i, j, k], tensor[1, 1, 4 - 2 * i, 4 + j, 7 - k])
    if false: # tests degenerate interval
        var slice = Tensor5f(1, 1, 2, 2, 3)
        var strides3 = Index5(1, 1, 2, 1, 1)
        var indices3Start = Index5(1, 1, 4, 4, 7)
        var indices3Stop = Index5(2, 2, 0, 6, 4)
        slice = tensor.stridedSlice(indices3Start, indices3Stop, strides3)

def test_strided_slice_write[DataLayout: Int]():
    type Tensor2f = Tensor[float32, 2, DataLayout]
    type Index2 = DSizes[DenseIndex, 2]
    var tensor = Tensor[float32, 2, DataLayout](7, 11)
    var tensor2 = Tensor[float32, 2, DataLayout](7, 11)
    tensor.setRandom()
    tensor2 = tensor
    var slice = Tensor2f(2, 3)
    slice.setRandom()
    var strides = Index2(1, 1)
    var indicesStart = Index2(3, 4)
    var indicesStop = Index2(5, 7)
    var lengths = Index2(2, 3)
    tensor.slice(indicesStart, lengths) = slice
    tensor2.stridedSlice(indicesStart, indicesStop, strides) = slice
    for i in range(7):
        for j in range(11):
            VERIFY_IS_EQUAL(tensor[i, j], tensor2[i, j])

def test_composition[DataLayout: Int]():
    var matrix = Tensor[float32, 2, DataLayout](7, 11)
    matrix.setRandom()
    var newDims = DSizes[Int, 3](1, 1, 11)
    var tensor = matrix.slice(DSizes[Int, 2](2, 0), DSizes[Int, 2](1, 11)).reshape(newDims)
    VERIFY_IS_EQUAL(tensor.dimensions().TotalSize(), 11)
    VERIFY_IS_EQUAL(tensor.dimension(0), 1)
    VERIFY_IS_EQUAL(tensor.dimension(1), 1)
    VERIFY_IS_EQUAL(tensor.dimension(2), 11)
    for i in range(11):
        VERIFY_IS_EQUAL(tensor[0, 0, i], matrix[2, i])

def test_cxx11_tensor_morphing():
    CALL_SUBTEST_1(test_simple_reshape[AnyType]())
    CALL_SUBTEST_1(test_reshape_in_expr[AnyType]())
    CALL_SUBTEST_1(test_reshape_as_lvalue[AnyType]())
    CALL_SUBTEST_1(test_simple_slice[ColMajor]())
    CALL_SUBTEST_1(test_simple_slice[RowMajor]())
    CALL_SUBTEST_1(test_const_slice[AnyType]())
    CALL_SUBTEST_2(test_slice_in_expr[ColMajor]())
    CALL_SUBTEST_3(test_slice_in_expr[RowMajor]())
    CALL_SUBTEST_4(test_slice_as_lvalue[ColMajor]())
    CALL_SUBTEST_4(test_slice_as_lvalue[RowMajor]())
    CALL_SUBTEST_5(test_slice_raw_data[ColMajor]())
    CALL_SUBTEST_5(test_slice_raw_data[RowMajor]())
    CALL_SUBTEST_6(test_strided_slice_write[ColMajor]())
    CALL_SUBTEST_6(test_strided_slice[ColMajor]())
    CALL_SUBTEST_6(test_strided_slice_write[RowMajor]())
    CALL_SUBTEST_6(test_strided_slice[RowMajor]())
    CALL_SUBTEST_7(test_composition[ColMajor]())
    CALL_SUBTEST_7(test_composition[RowMajor]())