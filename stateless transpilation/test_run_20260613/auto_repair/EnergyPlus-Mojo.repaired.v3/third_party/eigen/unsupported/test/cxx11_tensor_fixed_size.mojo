from main import main
from Eigen.CXX11.Tensor import Tensor, RowMajor, TensorFixedSize, TensorMap, Sizes, array_prod
from math import sqrt as sqrtf, pow as powf

@staticmethod
def test_0d():
    var scalar1: TensorFixedSize[float32, Sizes[]]
    var scalar2: TensorFixedSize[float32, Sizes[], RowMajor]
    VERIFY_IS_EQUAL(scalar1.rank(), 0)
    VERIFY_IS_EQUAL(scalar1.size(), 1)
    VERIFY_IS_EQUAL(array_prod(scalar1.dimensions()), 1)
    scalar1() = 7.0
    scalar2() = 13.0
    var copy: TensorFixedSize[float32, Sizes[]] = scalar1
    VERIFY_IS_NOT_EQUAL(scalar1.data(), copy.data())
    VERIFY_IS_APPROX(scalar1(), copy())
    copy = scalar1
    VERIFY_IS_NOT_EQUAL(scalar1.data(), copy.data())
    VERIFY_IS_APPROX(scalar1(), copy())
    var scalar3: TensorFixedSize[float32, Sizes[]] = scalar1.sqrt()
    var scalar4: TensorFixedSize[float32, Sizes[], RowMajor] = scalar2.sqrt()
    VERIFY_IS_EQUAL(scalar3.rank(), 0)
    VERIFY_IS_APPROX(scalar3(), sqrtf(7.0))
    VERIFY_IS_APPROX(scalar4(), sqrtf(13.0))
    scalar3 = scalar1 + scalar2
    VERIFY_IS_APPROX(scalar3(), 7.0f + 13.0f)

@staticmethod
def test_1d():
    var vec1: TensorFixedSize[float32, Sizes[6]]
    var vec2: TensorFixedSize[float32, Sizes[6], RowMajor]
    VERIFY_IS_EQUAL((vec1.size()), 6)
    vec1(0) = 4.0
    vec2(0) = 0.0
    vec1(1) = 8.0
    vec2(1) = 1.0
    vec1(2) = 15.0
    vec2(2) = 2.0
    vec1(3) = 16.0
    vec2(3) = 3.0
    vec1(4) = 23.0
    vec2(4) = 4.0
    vec1(5) = 42.0
    vec2(5) = 5.0
    var copy: TensorFixedSize[float32, Sizes[6]] = vec1
    VERIFY_IS_NOT_EQUAL(vec1.data(), copy.data())
    for i in range(6):
        VERIFY_IS_APPROX(vec1(i), copy(i))
    copy = vec1
    VERIFY_IS_NOT_EQUAL(vec1.data(), copy.data())
    for i in range(6):
        VERIFY_IS_APPROX(vec1(i), copy(i))
    var vec3: TensorFixedSize[float32, Sizes[6]] = vec1.sqrt()
    var vec4: TensorFixedSize[float32, Sizes[6], RowMajor] = vec2.sqrt()
    VERIFY_IS_EQUAL((vec3.size()), 6)
    VERIFY_IS_EQUAL(vec3.rank(), 1)
    VERIFY_IS_APPROX(vec3(0), sqrtf(4.0))
    VERIFY_IS_APPROX(vec3(1), sqrtf(8.0))
    VERIFY_IS_APPROX(vec3(2), sqrtf(15.0))
    VERIFY_IS_APPROX(vec3(3), sqrtf(16.0))
    VERIFY_IS_APPROX(vec3(4), sqrtf(23.0))
    VERIFY_IS_APPROX(vec3(5), sqrtf(42.0))
    VERIFY_IS_APPROX(vec4(0), sqrtf(0.0))
    VERIFY_IS_APPROX(vec4(1), sqrtf(1.0))
    VERIFY_IS_APPROX(vec4(2), sqrtf(2.0))
    VERIFY_IS_APPROX(vec4(3), sqrtf(3.0))
    VERIFY_IS_APPROX(vec4(4), sqrtf(4.0))
    VERIFY_IS_APPROX(vec4(5), sqrtf(5.0))
    vec3 = vec1 + vec2
    VERIFY_IS_APPROX(vec3(0), 4.0f + 0.0f)
    VERIFY_IS_APPROX(vec3(1), 8.0f + 1.0f)
    VERIFY_IS_APPROX(vec3(2), 15.0f + 2.0f)
    VERIFY_IS_APPROX(vec3(3), 16.0f + 3.0f)
    VERIFY_IS_APPROX(vec3(4), 23.0f + 4.0f)
    VERIFY_IS_APPROX(vec3(5), 42.0f + 5.0f)

@staticmethod
def test_tensor_map():
    var vec1: TensorFixedSize[float32, Sizes[6]]
    var vec2: TensorFixedSize[float32, Sizes[6], RowMajor]
    vec1(0) = 4.0
    vec2(0) = 0.0
    vec1(1) = 8.0
    vec2(1) = 1.0
    vec1(2) = 15.0
    vec2(2) = 2.0
    vec1(3) = 16.0
    vec2(3) = 3.0
    vec1(4) = 23.0
    vec2(4) = 4.0
    vec1(5) = 42.0
    vec2(5) = 5.0
    var data3: FloatMemoryRef[float32, 6] = FloatMemoryRef[float32, 6]()
    var vec3: TensorMap[TensorFixedSize[float32, Sizes[6]]] = TensorMap[TensorFixedSize[float32, Sizes[6]]](data3, 6)
    vec3 = vec1.sqrt() + vec2
    VERIFY_IS_APPROX(vec3(0), sqrtf(4.0))
    VERIFY_IS_APPROX(vec3(1), sqrtf(8.0) + 1.0f)
    VERIFY_IS_APPROX(vec3(2), sqrtf(15.0) + 2.0f)
    VERIFY_IS_APPROX(vec3(3), sqrtf(16.0) + 3.0f)
    VERIFY_IS_APPROX(vec3(4), sqrtf(23.0) + 4.0f)
    VERIFY_IS_APPROX(vec3(5), sqrtf(42.0) + 5.0f)

@staticmethod
def test_2d():
    var data1: FloatMemoryRef[float32, 6] = FloatMemoryRef[float32, 6]()
    var mat1: TensorMap[TensorFixedSize[float32, Sizes[2, 3]]] = TensorMap[TensorFixedSize[float32, Sizes[2, 3]]](data1, 2, 3)
    var data2: FloatMemoryRef[float32, 6] = FloatMemoryRef[float32, 6]()
    var mat2: TensorMap[TensorFixedSize[float32, Sizes[2, 3], RowMajor]] = TensorMap[TensorFixedSize[float32, Sizes[2, 3], RowMajor]](data2, 2, 3)
    VERIFY_IS_EQUAL((mat1.size()), 2 * 3)
    VERIFY_IS_EQUAL(mat1.rank(), 2)
    mat1(0, 0) = 0.0
    mat1(0, 1) = 1.0
    mat1(0, 2) = 2.0
    mat1(1, 0) = 3.0
    mat1(1, 1) = 4.0
    mat1(1, 2) = 5.0
    mat2(0, 0) = -0.0
    mat2(0, 1) = -1.0
    mat2(0, 2) = -2.0
    mat2(1, 0) = -3.0
    mat2(1, 1) = -4.0
    mat2(1, 2) = -5.0
    var mat3: TensorFixedSize[float32, Sizes[2, 3]]
    var mat4: TensorFixedSize[float32, Sizes[2, 3], RowMajor]
    mat3 = mat1.abs()
    mat4 = mat2.abs()
    VERIFY_IS_EQUAL((mat3.size()), 2 * 3)
    VERIFY_IS_APPROX(mat3(0, 0), 0.0f)
    VERIFY_IS_APPROX(mat3(0, 1), 1.0f)
    VERIFY_IS_APPROX(mat3(0, 2), 2.0f)
    VERIFY_IS_APPROX(mat3(1, 0), 3.0f)
    VERIFY_IS_APPROX(mat3(1, 1), 4.0f)
    VERIFY_IS_APPROX(mat3(1, 2), 5.0f)
    VERIFY_IS_APPROX(mat4(0, 0), 0.0f)
    VERIFY_IS_APPROX(mat4(0, 1), 1.0f)
    VERIFY_IS_APPROX(mat4(0, 2), 2.0f)
    VERIFY_IS_APPROX(mat4(1, 0), 3.0f)
    VERIFY_IS_APPROX(mat4(1, 1), 4.0f)
    VERIFY_IS_APPROX(mat4(1, 2), 5.0f)

@staticmethod
def test_3d():
    var mat1: TensorFixedSize[float32, Sizes[2, 3, 7]]
    var mat2: TensorFixedSize[float32, Sizes[2, 3, 7], RowMajor]
    VERIFY_IS_EQUAL((mat1.size()), 2 * 3 * 7)
    VERIFY_IS_EQUAL(mat1.rank(), 3)
    var val: float32 = 0.0f
    for i in range(2):
        for j in range(3):
            for k in range(7):
                mat1(i, j, k) = val
                mat2(i, j, k) = val
                val += 1.0f
    var mat3: TensorFixedSize[float32, Sizes[2, 3, 7]]
    mat3 = mat1.sqrt()
    var mat4: TensorFixedSize[float32, Sizes[2, 3, 7], RowMajor]
    mat4 = mat2.sqrt()
    VERIFY_IS_EQUAL((mat3.size()), 2 * 3 * 7)
    val = 0.0f
    for i in range(2):
        for j in range(3):
            for k in range(7):
                VERIFY_IS_APPROX(mat3(i, j, k), sqrtf(val))
                VERIFY_IS_APPROX(mat4(i, j, k), sqrtf(val))
                val += 1.0f

@staticmethod
def test_array():
    var mat1: TensorFixedSize[float32, Sizes[2, 3, 7]]
    var val: float32 = 0.0f
    for i in range(2):
        for j in range(3):
            for k in range(7):
                mat1(i, j, k) = val
                val += 1.0f
    var mat3: TensorFixedSize[float32, Sizes[2, 3, 7]]
    mat3 = mat1.pow(3.5f)
    val = 0.0f
    for i in range(2):
        for j in range(3):
            for k in range(7):
                VERIFY_IS_APPROX(mat3(i, j, k), powf(val, 3.5f))
                val += 1.0f

def test_cxx11_tensor_fixed_size():
    CALL_SUBTEST(test_0d())
    CALL_SUBTEST(test_1d())
    CALL_SUBTEST(test_tensor_map())
    CALL_SUBTEST(test_2d())
    CALL_SUBTEST(test_3d())
    CALL_SUBTEST(test_array())