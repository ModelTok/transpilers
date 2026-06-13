from main import main
from Eigen.CXX11.Tensor import Tensor
from Eigen.CXX11.Tensor import DSizes, Sizes, dimensions_match, internal_array_get, internal_array_prod

def test_dynamic_size() raises:
    var dimensions = DSizes[int, 3](2, 3, 7)
    VERIFY_IS_EQUAL(int(internal_array_get[0, int, 3](dimensions)), 2)
    VERIFY_IS_EQUAL(int(internal_array_get[1, int, 3](dimensions)), 3)
    VERIFY_IS_EQUAL(int(internal_array_get[2, int, 3](dimensions)), 7)
    VERIFY_IS_EQUAL(int(dimensions.TotalSize()), 2 * 3 * 7)
    VERIFY_IS_EQUAL(int(dimensions[0]), 2)
    VERIFY_IS_EQUAL(int(dimensions[1]), 3)
    VERIFY_IS_EQUAL(int(dimensions[2]), 7)

def test_fixed_size() raises:
    var dimensions = Sizes[2, 3, 7]()
    VERIFY_IS_EQUAL(int(internal_array_get[0, int, 3](dimensions)), 2)
    VERIFY_IS_EQUAL(int(internal_array_get[1, int, 3](dimensions)), 3)
    VERIFY_IS_EQUAL(int(internal_array_get[2, int, 3](dimensions)), 7)
    VERIFY_IS_EQUAL(int(dimensions.TotalSize()), 2 * 3 * 7)

def test_match() raises:
    var dyn = DSizes[uint32, 3](uint32(2), uint32(3), uint32(7))
    var stat = Sizes[2, 3, 7]()
    VERIFY_IS_EQUAL(dimensions_match(dyn, stat), True)
    var dyn1 = DSizes[int, 3](2, 3, 7)
    var dyn2 = DSizes[int, 2](2, 3)
    VERIFY_IS_EQUAL(dimensions_match(dyn1, dyn2), False)

def test_rank_zero() raises:
    var scalar = Sizes[]()
    VERIFY_IS_EQUAL(int(scalar.TotalSize()), 1)
    VERIFY_IS_EQUAL(int(scalar.rank()), 0)
    VERIFY_IS_EQUAL(int(internal_array_prod(scalar)), 1)
    var dscalar = DSizes[Int, 0]()
    VERIFY_IS_EQUAL(int(dscalar.TotalSize()), 1)
    VERIFY_IS_EQUAL(int(dscalar.rank()), 0)

def test_cxx11_tensor_dimension() raises:
    CALL_SUBTEST(test_dynamic_size())
    CALL_SUBTEST(test_fixed_size())
    CALL_SUBTEST(test_match())
    CALL_SUBTEST(test_rank_zero())