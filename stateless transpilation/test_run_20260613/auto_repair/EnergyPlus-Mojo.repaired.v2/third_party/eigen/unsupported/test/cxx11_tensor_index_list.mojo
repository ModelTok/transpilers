# Faithful 1:1 translation of cxx11_tensor_index_list.cpp

from Eigen import *

def test_static_index_list():
    var tensor = Tensor[float32, 4](2,3,5,7)
    tensor.setRandom()
    var reduction_axis = make_index_list(0, 1, 2)
    VERIFY_IS_EQUAL(internal.array_get[0](reduction_axis), 0)
    VERIFY_IS_EQUAL(internal.array_get[1](reduction_axis), 1)
    VERIFY_IS_EQUAL(internal.array_get[2](reduction_axis), 2)
    VERIFY_IS_EQUAL(static_cast[DenseIndex](reduction_axis[0]), 0)
    VERIFY_IS_EQUAL(static_cast[DenseIndex](reduction_axis[1]), 1)
    VERIFY_IS_EQUAL(static_cast[DenseIndex](reduction_axis[2]), 2)
    static_assert((internal.array_get[0](reduction_axis) == 0), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((internal.array_get[1](reduction_axis) == 1), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((internal.array_get[2](reduction_axis) == 2), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    var result = tensor.sum(reduction_axis)
    for i in range(result.size()):
        var expected = 0.0f
        for j in range(2):
            for k in range(3):
                for l in range(5):
                    expected += tensor[j,k,l,i]
        VERIFY_IS_APPROX(result[i], expected)

def test_type2index_list():
    var tensor = Tensor[float32, 5](2,3,5,7,11)
    tensor.setRandom()
    tensor += tensor.constant(10.0f)
    var Dims0 = Eigen.IndexList[Eigen.type2index[0]]
    var Dims1 = Eigen.IndexList[Eigen.type2index[0], Eigen.type2index[1]]
    var Dims2 = Eigen.IndexList[Eigen.type2index[0], Eigen.type2index[1], Eigen.type2index[2]]
    var Dims3 = Eigen.IndexList[Eigen.type2index[0], Eigen.type2index[1], Eigen.type2index[2], Eigen.type2index[3]]
    var Dims4 = Eigen.IndexList[Eigen.type2index[0], Eigen.type2index[1], Eigen.type2index[2], Eigen.type2index[3], Eigen.type2index[4]]
#    static_assert((internal.indices_statically_known_to_increase[Dims0]() == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
#    static_assert((internal.indices_statically_known_to_increase[Dims1]() == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
#    static_assert((internal.indices_statically_known_to_increase[Dims2]() == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
#    static_assert((internal.indices_statically_known_to_increase[Dims3]() == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
#    static_assert((internal.indices_statically_known_to_increase[Dims4]() == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((internal.are_inner_most_dims[Dims0, 1, ColMajor]() == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((internal.are_inner_most_dims[Dims1, 2, ColMajor]() == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((internal.are_inner_most_dims[Dims2, 3, ColMajor]() == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((internal.are_inner_most_dims[Dims3, 4, ColMajor]() == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((internal.are_inner_most_dims[Dims4, 5, ColMajor]() == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((internal.are_inner_most_dims[Dims0, 1, RowMajor]() == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((internal.are_inner_most_dims[Dims1, 2, RowMajor]() == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((internal.are_inner_most_dims[Dims2, 3, RowMajor]() == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((internal.are_inner_most_dims[Dims3, 4, RowMajor]() == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((internal.are_inner_most_dims[Dims4, 5, RowMajor]() == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    var reduction_axis0 = Dims0()
    var result0 = tensor.sum(reduction_axis0)
    for m in range(11):
        for l in range(7):
            for k in range(5):
                for j in range(3):
                    var expected = 0.0f
                    for i in range(2):
                        expected += tensor[i,j,k,l,m]
                    VERIFY_IS_APPROX(result0[j,k,l,m], expected)
    var reduction_axis1 = Dims1()
    var result1 = tensor.sum(reduction_axis1)
    for m in range(11):
        for l in range(7):
            for k in range(5):
                var expected = 0.0f
                for j in range(3):
                    for i in range(2):
                        expected += tensor[i,j,k,l,m]
                VERIFY_IS_APPROX(result1[k,l,m], expected)
    var reduction_axis2 = Dims2()
    var result2 = tensor.sum(reduction_axis2)
    for m in range(11):
        for l in range(7):
            var expected = 0.0f
            for k in range(5):
                for j in range(3):
                    for i in range(2):
                        expected += tensor[i,j,k,l,m]
            VERIFY_IS_APPROX(result2[l,m], expected)
    var reduction_axis3 = Dims3()
    var result3 = tensor.sum(reduction_axis3)
    for m in range(11):
        var expected = 0.0f
        for l in range(7):
            for k in range(5):
                for j in range(3):
                    for i in range(2):
                        expected += tensor[i,j,k,l,m]
        VERIFY_IS_APPROX(result3[m], expected)
    var reduction_axis4 = Dims4()
    var result4 = tensor.sum(reduction_axis4)
    var expected = 0.0f
    for m in range(11):
        for l in range(7):
            for k in range(5):
                for j in range(3):
                    for i in range(2):
                        expected += tensor[i,j,k,l,m]
    VERIFY_IS_APPROX(result4(), expected)

def test_type2indexpair_list():
    var tensor = Tensor[float32, 5](2,3,5,7,11)
    tensor.setRandom()
    tensor += tensor.constant(10.0f)
    var Dims0 = Eigen.IndexPairList[Eigen.type2indexpair[0,10]]
    var Dims2_a = Eigen.IndexPairList[Eigen.type2indexpair[0,10], Eigen.type2indexpair[1,11], Eigen.type2indexpair[2,12]]
    var Dims2_b = Eigen.IndexPairList[Eigen.type2indexpair[0,10], Eigen.IndexPair[DenseIndex], Eigen.type2indexpair[2,12]]
    var Dims2_c = Eigen.IndexPairList[Eigen.IndexPair[DenseIndex], Eigen.type2indexpair[1,11], Eigen.IndexPair[DenseIndex]]
    var d0 = Dims0()
    var d2_a = Dims2_a()
    var d2_b = Dims2_b()
    d2_b.set(1, Eigen.IndexPair[DenseIndex](1,11))
    var d2_c = Dims2_c()
    d2_c.set(0, Eigen.IndexPair[DenseIndex](Eigen.IndexPair[DenseIndex](0,10)))
    d2_c.set(1, Eigen.IndexPair[DenseIndex](1,11))
    d2_c.set(2, Eigen.IndexPair[DenseIndex](2,12))
    VERIFY_IS_EQUAL(d2_a[0].first, 0)
    VERIFY_IS_EQUAL(d2_a[0].second, 10)
    VERIFY_IS_EQUAL(d2_a[1].first, 1)
    VERIFY_IS_EQUAL(d2_a[1].second, 11)
    VERIFY_IS_EQUAL(d2_a[2].first, 2)
    VERIFY_IS_EQUAL(d2_a[2].second, 12)
    VERIFY_IS_EQUAL(d2_b[0].first, 0)
    VERIFY_IS_EQUAL(d2_b[0].second, 10)
    VERIFY_IS_EQUAL(d2_b[1].first, 1)
    VERIFY_IS_EQUAL(d2_b[1].second, 11)
    VERIFY_IS_EQUAL(d2_b[2].first, 2)
    VERIFY_IS_EQUAL(d2_b[2].second, 12)
    VERIFY_IS_EQUAL(d2_c[0].first, 0)
    VERIFY_IS_EQUAL(d2_c[0].second, 10)
    VERIFY_IS_EQUAL(d2_c[1].first, 1)
    VERIFY_IS_EQUAL(d2_c[1].second, 11)
    VERIFY_IS_EQUAL(d2_c[2].first, 2)
    VERIFY_IS_EQUAL(d2_c[2].second, 12)
    static_assert((d2_a.value_known_statically(0) == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((d2_a.value_known_statically(1) == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((d2_a.value_known_statically(2) == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((d2_b.value_known_statically(0) == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((d2_b.value_known_statically(1) == False), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((d2_b.value_known_statically(2) == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((d2_c.value_known_statically(0) == False), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((d2_c.value_known_statically(1) == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((d2_c.value_known_statically(2) == False), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_first_statically_eq[Dims0](0, 0) == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_first_statically_eq[Dims0](0, 1) == False), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_first_statically_eq[Dims2_a](0, 0) == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_first_statically_eq[Dims2_a](0, 1) == False), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_first_statically_eq[Dims2_a](1, 1) == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_first_statically_eq[Dims2_a](1, 2) == False), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_first_statically_eq[Dims2_a](2, 2) == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_first_statically_eq[Dims2_a](2, 3) == False), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_first_statically_eq[Dims2_b](0, 0) == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_first_statically_eq[Dims2_b](0, 1) == False), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_first_statically_eq[Dims2_b](1, 1) == False), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_first_statically_eq[Dims2_b](1, 2) == False), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_first_statically_eq[Dims2_b](2, 2) == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_first_statically_eq[Dims2_b](2, 3) == False), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_first_statically_eq[Dims2_c](0, 0) == False), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_first_statically_eq[Dims2_c](0, 1) == False), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_first_statically_eq[Dims2_c](1, 1) == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_first_statically_eq[Dims2_c](1, 2) == False), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_first_statically_eq[Dims2_c](2, 2) == False), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_first_statically_eq[Dims2_c](2, 3) == False), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_second_statically_eq[Dims0](0, 10) == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_second_statically_eq[Dims0](0, 11) == False), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_second_statically_eq[Dims2_a](0, 10) == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_second_statically_eq[Dims2_a](0, 11) == False), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_second_statically_eq[Dims2_a](1, 11) == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_second_statically_eq[Dims2_a](1, 12) == False), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_second_statically_eq[Dims2_a](2, 12) == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_second_statically_eq[Dims2_a](2, 13) == False), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_second_statically_eq[Dims2_b](0, 10) == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_second_statically_eq[Dims2_b](0, 11) == False), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_second_statically_eq[Dims2_b](1, 11) == False), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_second_statically_eq[Dims2_b](1, 12) == False), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_second_statically_eq[Dims2_b](2, 12) == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_second_statically_eq[Dims2_b](2, 13) == False), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_second_statically_eq[Dims2_c](0, 10) == False), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_second_statically_eq[Dims2_c](0, 11) == False), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_second_statically_eq[Dims2_c](1, 11) == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_second_statically_eq[Dims2_c](1, 12) == False), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_second_statically_eq[Dims2_c](2, 12) == False), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((Eigen.internal.index_pair_second_statically_eq[Dims2_c](2, 13) == False), "YOU_MADE_A_PROGRAMMING_MISTAKE")

def test_dynamic_index_list():
    var tensor = Tensor[float32, 4](2,3,5,7)
    tensor.setRandom()
    var dim1 = 2
    var dim2 = 1
    var dim3 = 0
    var reduction_axis = make_index_list(dim1, dim2, dim3)
    VERIFY_IS_EQUAL(internal.array_get[0](reduction_axis), 2)
    VERIFY_IS_EQUAL(internal.array_get[1](reduction_axis), 1)
    VERIFY_IS_EQUAL(internal.array_get[2](reduction_axis), 0)
    VERIFY_IS_EQUAL(static_cast[DenseIndex](reduction_axis[0]), 2)
    VERIFY_IS_EQUAL(static_cast[DenseIndex](reduction_axis[1]), 1)
    VERIFY_IS_EQUAL(static_cast[DenseIndex](reduction_axis[2]), 0)
    var result = tensor.sum(reduction_axis)
    for i in range(result.size()):
        var expected = 0.0f
        for j in range(2):
            for k in range(3):
                for l in range(5):
                    expected += tensor[j,k,l,i]
        VERIFY_IS_APPROX(result[i], expected)

def test_mixed_index_list():
    var tensor = Tensor[float32, 4](2,3,5,7)
    tensor.setRandom()
    var dim2 = 1
    var dim4 = 3
    var reduction_axis = make_index_list(0, dim2, 2, dim4)
    VERIFY_IS_EQUAL(internal.array_get[0](reduction_axis), 0)
    VERIFY_IS_EQUAL(internal.array_get[1](reduction_axis), 1)
    VERIFY_IS_EQUAL(internal.array_get[2](reduction_axis), 2)
    VERIFY_IS_EQUAL(internal.array_get[3](reduction_axis), 3)
    VERIFY_IS_EQUAL(static_cast[DenseIndex](reduction_axis[0]), 0)
    VERIFY_IS_EQUAL(static_cast[DenseIndex](reduction_axis[1]), 1)
    VERIFY_IS_EQUAL(static_cast[DenseIndex](reduction_axis[2]), 2)
    VERIFY_IS_EQUAL(static_cast[DenseIndex](reduction_axis[3]), 3)
    var ReductionIndices = IndexList[type2index[0], int, type2index[2], int]
    var reduction_indices = ReductionIndices()
    reduction_indices.set(1, 1)
    reduction_indices.set(3, 3)
    static_assert((internal.array_get[0](reduction_indices) == 0), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((internal.array_get[2](reduction_indices) == 2), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((internal.index_known_statically[ReductionIndices](0) == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((internal.index_known_statically[ReductionIndices](2) == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((internal.index_statically_eq[ReductionIndices](0, 0) == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((internal.index_statically_eq[ReductionIndices](2, 2) == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
#    static_assert((internal.all_indices_known_statically[ReductionIndices]() == False), "YOU_MADE_A_PROGRAMMING_MISTAKE")
#    static_assert((internal.indices_statically_known_to_increase[ReductionIndices]() == False), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    var ReductionList = IndexList[type2index[0], type2index[1], type2index[2], type2index[3]]
    var reduction_list = ReductionList()
    static_assert((internal.index_statically_eq[ReductionList](0, 0) == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((internal.index_statically_eq[ReductionList](1, 1) == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((internal.index_statically_eq[ReductionList](2, 2) == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    static_assert((internal.index_statically_eq[ReductionList](3, 3) == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
#    static_assert((internal.all_indices_known_statically[ReductionList]() == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
#    static_assert((internal.indices_statically_known_to_increase[ReductionList]() == True), "YOU_MADE_A_PROGRAMMING_MISTAKE")
    var result1 = tensor.sum(reduction_axis)
    var result2 = tensor.sum(reduction_indices)
    var result3 = tensor.sum(reduction_list)
    var expected = 0.0f
    for i in range(2):
        for j in range(3):
            for k in range(5):
                for l in range(7):
                    expected += tensor[i,j,k,l]
    VERIFY_IS_APPROX(result1(), expected)
    VERIFY_IS_APPROX(result2(), expected)
    VERIFY_IS_APPROX(result3(), expected)

def test_dim_check():
    var dim1 = Eigen.IndexList[Eigen.type2index[1], int]()
    dim1.set(1, 2)
    var dim2 = Eigen.IndexList[Eigen.type2index[1], int]()
    dim2.set(1, 2)
    VERIFY(dimensions_match(dim1, dim2))

def test_cxx11_tensor_index_list():
    CALL_SUBTEST(test_static_index_list())
    CALL_SUBTEST(test_type2index_list())
    CALL_SUBTEST(test_type2indexpair_list())
    CALL_SUBTEST(test_dynamic_index_list())
    CALL_SUBTEST(test_mixed_index_list())
    CALL_SUBTEST(test_dim_check())