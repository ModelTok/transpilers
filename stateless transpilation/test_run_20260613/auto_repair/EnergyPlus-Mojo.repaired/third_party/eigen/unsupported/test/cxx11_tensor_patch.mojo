from ......Eigen.CXX11.Tensor import Tensor
from testing import assert_eq as VERIFY_IS_EQUAL

const ColMajor: Int = 0
const RowMajor: Int = 1

def CALL_SUBTEST(test_fn: fn() -> None):
    test_fn()

def test_simple_patch[DataLayout: Int]():
    var tensor = Tensor[Float32, 4, DataLayout](2, 3, 5, 7)
    tensor.setRandom()
    var patch_dims = (0, 0, 0, 0)
    patch_dims[0] = 1
    patch_dims[1] = 1
    patch_dims[2] = 1
    patch_dims[3] = 1
    var no_patch = Tensor[Float32, 5, DataLayout]()
    no_patch = tensor.extract_patches(patch_dims)
    if DataLayout == ColMajor:
        VERIFY_IS_EQUAL(no_patch.dimension(0), 1)
        VERIFY_IS_EQUAL(no_patch.dimension(1), 1)
        VERIFY_IS_EQUAL(no_patch.dimension(2), 1)
        VERIFY_IS_EQUAL(no_patch.dimension(3), 1)
        VERIFY_IS_EQUAL(no_patch.dimension(4), tensor.size())
    else:
        VERIFY_IS_EQUAL(no_patch.dimension(0), tensor.size())
        VERIFY_IS_EQUAL(no_patch.dimension(1), 1)
        VERIFY_IS_EQUAL(no_patch.dimension(2), 1)
        VERIFY_IS_EQUAL(no_patch.dimension(3), 1)
        VERIFY_IS_EQUAL(no_patch.dimension(4), 1)
    for i in range(tensor.size()):
        VERIFY_IS_EQUAL(tensor.data()[i], no_patch.data()[i])
    patch_dims[0] = 2
    patch_dims[1] = 3
    patch_dims[2] = 5
    patch_dims[3] = 7
    var single_patch = Tensor[Float32, 5, DataLayout]()
    single_patch = tensor.extract_patches(patch_dims)
    if DataLayout == ColMajor:
        VERIFY_IS_EQUAL(single_patch.dimension(0), 2)
        VERIFY_IS_EQUAL(single_patch.dimension(1), 3)
        VERIFY_IS_EQUAL(single_patch.dimension(2), 5)
        VERIFY_IS_EQUAL(single_patch.dimension(3), 7)
        VERIFY_IS_EQUAL(single_patch.dimension(4), 1)
    else:
        VERIFY_IS_EQUAL(single_patch.dimension(0), 1)
        VERIFY_IS_EQUAL(single_patch.dimension(1), 2)
        VERIFY_IS_EQUAL(single_patch.dimension(2), 3)
        VERIFY_IS_EQUAL(single_patch.dimension(3), 5)
        VERIFY_IS_EQUAL(single_patch.dimension(4), 7)
    for i in range(tensor.size()):
        VERIFY_IS_EQUAL(tensor.data()[i], single_patch.data()[i])
    patch_dims[0] = 1
    patch_dims[1] = 2
    patch_dims[2] = 2
    patch_dims[3] = 1
    var twod_patch = Tensor[Float32, 5, DataLayout]()
    twod_patch = tensor.extract_patches(patch_dims)
    if DataLayout == ColMajor:
        VERIFY_IS_EQUAL(twod_patch.dimension(0), 1)
        VERIFY_IS_EQUAL(twod_patch.dimension(1), 2)
        VERIFY_IS_EQUAL(twod_patch.dimension(2), 2)
        VERIFY_IS_EQUAL(twod_patch.dimension(3), 1)
        VERIFY_IS_EQUAL(twod_patch.dimension(4), 2*2*4*7)
    else:
        VERIFY_IS_EQUAL(twod_patch.dimension(0), 2*2*4*7)
        VERIFY_IS_EQUAL(twod_patch.dimension(1), 1)
        VERIFY_IS_EQUAL(twod_patch.dimension(2), 2)
        VERIFY_IS_EQUAL(twod_patch.dimension(3), 2)
        VERIFY_IS_EQUAL(twod_patch.dimension(4), 1)
    for i in range(2):
        for j in range(2):
            for k in range(4):
                for l in range(7):
                    var patch_loc: Int
                    if DataLayout == ColMajor:
                        patch_loc = i + 2 * (j + 2 * (k + 4 * l))
                    else:
                        patch_loc = l + 7 * (k + 4 * (j + 2 * i))
                    for x in range(2):
                        for y in range(2):
                            if DataLayout == ColMajor:
                                VERIFY_IS_EQUAL(tensor[i, j+x, k+y, l], twod_patch[0, x, y, 0, patch_loc])
                            else:
                                VERIFY_IS_EQUAL(tensor[i, j+x, k+y, l], twod_patch[patch_loc, 0, x, y, 0])
    patch_dims[0] = 1
    patch_dims[1] = 2
    patch_dims[2] = 3
    patch_dims[3] = 5
    var threed_patch = Tensor[Float32, 5, DataLayout]()
    threed_patch = tensor.extract_patches(patch_dims)
    if DataLayout == ColMajor:
        VERIFY_IS_EQUAL(threed_patch.dimension(0), 1)
        VERIFY_IS_EQUAL(threed_patch.dimension(1), 2)
        VERIFY_IS_EQUAL(threed_patch.dimension(2), 3)
        VERIFY_IS_EQUAL(threed_patch.dimension(3), 5)
        VERIFY_IS_EQUAL(threed_patch.dimension(4), 2*2*3*3)
    else:
        VERIFY_IS_EQUAL(threed_patch.dimension(0), 2*2*3*3)
        VERIFY_IS_EQUAL(threed_patch.dimension(1), 1)
        VERIFY_IS_EQUAL(threed_patch.dimension(2), 2)
        VERIFY_IS_EQUAL(threed_patch.dimension(3), 3)
        VERIFY_IS_EQUAL(threed_patch.dimension(4), 5)
    for i in range(2):
        for j in range(2):
            for k in range(3):
                for l in range(3):
                    var patch_loc: Int
                    if DataLayout == ColMajor:
                        patch_loc = i + 2 * (j + 2 * (k + 3 * l))
                    else:
                        patch_loc = l + 3 * (k + 3 * (j + 2 * i))
                    for x in range(2):
                        for y in range(3):
                            for z in range(5):
                                if DataLayout == ColMajor:
                                    VERIFY_IS_EQUAL(tensor[i, j+x, k+y, l+z], threed_patch[0, x, y, z, patch_loc])
                                else:
                                    VERIFY_IS_EQUAL(tensor[i, j+x, k+y, l+z], threed_patch[patch_loc, 0, x, y, z])

def test_cxx11_tensor_patch():
    CALL_SUBTEST(test_simple_patch[ColMajor]())
    CALL_SUBTEST(test_simple_patch[RowMajor]())

def main():
    test_cxx11_tensor_patch()