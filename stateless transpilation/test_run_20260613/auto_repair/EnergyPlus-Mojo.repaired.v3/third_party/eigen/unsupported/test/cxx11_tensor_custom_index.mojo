// #include "main.h"
// #include <limits>
// #include <map>
// #include <Eigen/Dense>
// #include <Eigen/CXX11/Tensor>

alias Tensor = Eigen.Tensor
using Eigen.Tensor  # not needed if alias above

# Simulating preprocessor: assume EIGEN_HAS_SFINAE is defined
# // #ifdef EIGEN_HAS_SFINAE

def test_map_as_index[DataLayout: Int]():
    var tensor = Tensor[Float32, 4, DataLayout](2, 3, 5, 7)
    tensor.setRandom()
    alias NormalIndex = DSizes[Int, 4]
    alias CustomIndex = Dict[Int, Int]
    var coeffC = CustomIndex()
    coeffC[0] = 1
    coeffC[1] = 2
    coeffC[2] = 4
    coeffC[3] = 1
    var coeff = NormalIndex(1, 2, 4, 1)
    VERIFY_IS_EQUAL(tensor.coeff(coeffC), tensor.coeff(coeff))
    VERIFY_IS_EQUAL(tensor.coeffRef(coeffC), tensor.coeffRef(coeff))
# // #endif

def test_matrix_as_index[DataLayout: Int]():
    var tensor = Tensor[Float32, 4, DataLayout](2, 3, 5, 7)
    tensor.setRandom()
    alias NormalIndex = DSizes[Int, 4]
    alias CustomIndex = Matrix[UInt32, 4, 1]
    var coeffC = CustomIndex(1, 2, 4, 1)
    var coeff = NormalIndex(1, 2, 4, 1)
    VERIFY_IS_EQUAL(tensor.coeff(coeffC), tensor.coeff(coeff))
    VERIFY_IS_EQUAL(tensor.coeffRef(coeffC), tensor.coeffRef(coeff))
# // #endif

def test_varlist_as_index[DataLayout: Int]():
    var tensor = Tensor[Float32, 4, DataLayout](2, 3, 5, 7)
    tensor.setRandom()
    var coeff = DSizes[Int, 4](1, 2, 4, 1)
    VERIFY_IS_EQUAL(tensor.coeff({1, 2, 4, 1}), tensor.coeff(coeff))
    VERIFY_IS_EQUAL(tensor.coeffRef({1, 2, 4, 1}), tensor.coeffRef(coeff))
# // #endif

def test_sizes_as_index[DataLayout: Int]():
    var tensor = Tensor[Float32, 4, DataLayout](2, 3, 5, 7)
    tensor.setRandom()
    var coeff = DSizes[Int, 4](1, 2, 4, 1)
    var coeffC = Sizes[1, 2, 4, 1]()
    VERIFY_IS_EQUAL(tensor.coeff(coeffC), tensor.coeff(coeff))
    VERIFY_IS_EQUAL(tensor.coeffRef(coeffC), tensor.coeffRef(coeff))
# // #endif

def test_cxx11_tensor_custom_index():
    test_map_as_index[ColMajor]()
    test_map_as_index[RowMajor]()
    test_matrix_as_index[ColMajor]()
    test_matrix_as_index[RowMajor]()
    test_varlist_as_index[ColMajor]()
    test_varlist_as_index[RowMajor]()
    test_sizes_as_index[ColMajor]()
    test_sizes_as_index[RowMajor]()