from Eigen import (
    internal,
    EIGEN_ALIGN16,
    EIGEN_UNUSED_VARIABLE,
    VERIFY,
    UIntPtr,
)


struct some_non_vectorizable_type:
    var x: Float32


def test_first_aligned_helper[Scalar: Type](array: Pointer[Scalar], size: Int):
    let packet_size = sizeof[Scalar]() * internal.packet_traits[Scalar]().size
    VERIFY((UIntPtr(array) + sizeof[Scalar]() * internal.first_default_aligned(array, size)) % packet_size == 0)


def test_none_aligned_helper[Scalar: Type](array: Pointer[Scalar], size: Int):
    EIGEN_UNUSED_VARIABLE(array)
    EIGEN_UNUSED_VARIABLE(size)
    VERIFY(internal.packet_traits[Scalar]().size == 1 or internal.first_default_aligned(array, size) == size)


def test_first_aligned():
    EIGEN_ALIGN16 var array_float: Float32[100]
    test_first_aligned_helper(Pointer[Float32](__address_of(array_float[0])), 50)
    test_first_aligned_helper(Pointer[Float32](__address_of(array_float[1])), 50)
    test_first_aligned_helper(Pointer[Float32](__address_of(array_float[2])), 50)
    test_first_aligned_helper(Pointer[Float32](__address_of(array_float[3])), 50)
    test_first_aligned_helper(Pointer[Float32](__address_of(array_float[4])), 50)
    test_first_aligned_helper(Pointer[Float32](__address_of(array_float[5])), 50)

    EIGEN_ALIGN16 var array_double: Float64[100]
    test_first_aligned_helper(Pointer[Float64](__address_of(array_double[0])), 50)
    test_first_aligned_helper(Pointer[Float64](__address_of(array_double[1])), 50)
    test_first_aligned_helper(Pointer[Float64](__address_of(array_double[2])), 50)

    var array_double_plus_4_bytes = Pointer[Float64](UIntPtr(Pointer[Float64](__address_of(array_double[0]))) + 4)
    test_none_aligned_helper(array_double_plus_4_bytes, 50)
    test_none_aligned_helper(array_double_plus_4_bytes + 1, 50)

    var array_nonvec: some_non_vectorizable_type[100]
    test_first_aligned_helper(Pointer[some_non_vectorizable_type](__address_of(array_nonvec[0])), 100)
    test_none_aligned_helper(Pointer[some_non_vectorizable_type](__address_of(array_nonvec[0])), 100)