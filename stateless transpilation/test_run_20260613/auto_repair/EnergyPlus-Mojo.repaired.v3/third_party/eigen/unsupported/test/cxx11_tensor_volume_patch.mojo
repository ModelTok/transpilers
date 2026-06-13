from ......CXX11.Tensor import Tensor

# Define test helper functions to mimic VERIFY_IS_EQUAL and CALL_SUBTEST from main.h
def VERIFY_IS_EQUAL(a: __origin.__type_of(a), b: __origin.__type_of(a)) -> Bool:
    assert(a == b)
    return True

def CALL_SUBTEST(test_fn: fn()) -> None:
    test_fn()

def test_single_voxel_patch():
    var tensor = Tensor[Float32, 5](4, 2, 3, 5, 7)
    tensor.setRandom()
    var tensor_row_major = tensor.swap_layout()
    var single_voxel_patch = Tensor[Float32, 6]()
    single_voxel_patch = tensor.extract_volume_patches(1, 1, 1)
    VERIFY_IS_EQUAL(single_voxel_patch.dimension(0), 4)
    VERIFY_IS_EQUAL(single_voxel_patch.dimension(1), 1)
    VERIFY_IS_EQUAL(single_voxel_patch.dimension(2), 1)
    VERIFY_IS_EQUAL(single_voxel_patch.dimension(3), 1)
    VERIFY_IS_EQUAL(single_voxel_patch.dimension(4), 2 * 3 * 5)
    VERIFY_IS_EQUAL(single_voxel_patch.dimension(5), 7)
    var single_voxel_patch_row_major = Tensor[Float32, 6, RowMajor]()
    single_voxel_patch_row_major = tensor_row_major.extract_volume_patches(1, 1, 1)
    VERIFY_IS_EQUAL(single_voxel_patch_row_major.dimension(0), 7)
    VERIFY_IS_EQUAL(single_voxel_patch_row_major.dimension(1), 2 * 3 * 5)
    VERIFY_IS_EQUAL(single_voxel_patch_row_major.dimension(2), 1)
    VERIFY_IS_EQUAL(single_voxel_patch_row_major.dimension(3), 1)
    VERIFY_IS_EQUAL(single_voxel_patch_row_major.dimension(4), 1)
    VERIFY_IS_EQUAL(single_voxel_patch_row_major.dimension(5), 4)
    for i in range(tensor.size()):
        VERIFY_IS_EQUAL(tensor.data()[i], single_voxel_patch.data()[i])
        VERIFY_IS_EQUAL(tensor_row_major.data()[i], single_voxel_patch_row_major.data()[i])
        VERIFY_IS_EQUAL(tensor.data()[i], tensor_row_major.data()[i])

def test_entire_volume_patch():
    let depth: Int = 4
    let patch_z: Int = 2
    let patch_y: Int = 3
    let patch_x: Int = 5
    let batch: Int = 7
    var tensor = Tensor[Float32, 5](depth, patch_z, patch_y, patch_x, batch)
    tensor.setRandom()
    var tensor_row_major = tensor.swap_layout()
    var entire_volume_patch = Tensor[Float32, 6]()
    entire_volume_patch = tensor.extract_volume_patches(patch_z, patch_y, patch_x)
    VERIFY_IS_EQUAL(entire_volume_patch.dimension(0), depth)
    VERIFY_IS_EQUAL(entire_volume_patch.dimension(1), patch_z)
    VERIFY_IS_EQUAL(entire_volume_patch.dimension(2), patch_y)
    VERIFY_IS_EQUAL(entire_volume_patch.dimension(3), patch_x)
    VERIFY_IS_EQUAL(entire_volume_patch.dimension(4), patch_z * patch_y * patch_x)
    VERIFY_IS_EQUAL(entire_volume_patch.dimension(5), batch)
    var entire_volume_patch_row_major = Tensor[Float32, 6, RowMajor]()
    entire_volume_patch_row_major = tensor_row_major.extract_volume_patches(patch_z, patch_y, patch_x)
    VERIFY_IS_EQUAL(entire_volume_patch_row_major.dimension(0), batch)
    VERIFY_IS_EQUAL(entire_volume_patch_row_major.dimension(1), patch_z * patch_y * patch_x)
    VERIFY_IS_EQUAL(entire_volume_patch_row_major.dimension(2), patch_x)
    VERIFY_IS_EQUAL(entire_volume_patch_row_major.dimension(3), patch_y)
    VERIFY_IS_EQUAL(entire_volume_patch_row_major.dimension(4), patch_z)
    VERIFY_IS_EQUAL(entire_volume_patch_row_major.dimension(5), depth)
    let dz: Int = patch_z - 1
    let dy: Int = patch_y - 1
    let dx: Int = patch_x - 1
    let forward_pad_z: Int = dz - dz // 2
    let forward_pad_y: Int = dy - dy // 2
    let forward_pad_x: Int = dx - dx // 2
    for pz in range(patch_z):
        for py in range(patch_y):
            for px in range(patch_x):
                let patchId: Int = pz + patch_z * (py + px * patch_y)
                for z in range(patch_z):
                    for y in range(patch_y):
                        for x in range(patch_x):
                            for b in range(batch):
                                for d in range(depth):
                                    var expected: Float32 = Float32(0.0)
                                    var expected_row_major: Float32 = Float32(0.0)
                                    let eff_z: Int = z - forward_pad_z + pz
                                    let eff_y: Int = y - forward_pad_y + py
                                    let eff_x: Int = x - forward_pad_x + px
                                    if eff_z >= 0 and eff_y >= 0 and eff_x >= 0 and eff_z < patch_z and eff_y < patch_y and eff_x < patch_x:
                                        expected = tensor[d, eff_z, eff_y, eff_x, b]
                                        expected_row_major = tensor_row_major[b, eff_x, eff_y, eff_z, d]
                                    VERIFY_IS_EQUAL(entire_volume_patch[d, z, y, x, patchId, b], expected)
                                    VERIFY_IS_EQUAL(entire_volume_patch_row_major[b, patchId, x, y, z, d], expected_row_major)

def test_cxx11_tensor_volume_patch():
    CALL_SUBTEST(test_single_voxel_patch)
    CALL_SUBTEST(test_entire_volume_patch)