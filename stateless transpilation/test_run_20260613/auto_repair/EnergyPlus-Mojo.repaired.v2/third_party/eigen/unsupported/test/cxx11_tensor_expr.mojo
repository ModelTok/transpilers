# Translated from C++ Eigen Tensor test to Mojo
from tensor import Tensor, TensorMap
from math import sqrt as sqrtf, abs, log as logf, exp as expf, pow, max, min, asin as asinf, tanh as tanhf
from testing import verify_is_approx, verify_is_equal

# Helper macros (approximate and exact)
def VERIFY_IS_APPROX(a, b):
    verify_is_approx(a, b, rtol=1e-5)

def VERIFY_IS_EQUAL(a, b):
    verify_is_equal(a, b)

# Test functions
def test_1d():
    var vec1 = Tensor[Float32, 1](6)
    var vec2 = Tensor[Float32, 1, layout=RowMajor](6)
    vec1[0] = 4.0;  vec2[0] = 0.0
    vec1[1] = 8.0;  vec2[1] = 1.0
    vec1[2] = 15.0; vec2[2] = 2.0
    vec1[3] = 16.0; vec2[3] = 3.0
    vec1[4] = 23.0; vec2[4] = 4.0
    vec1[5] = 42.0; vec2[5] = 5.0

    var data3 = Array[Float32](6)
    var vec3 = TensorMap[Float32, 1](data3, 6)
    vec3 = vec1.sqrt()

    var data4 = Array[Float32](6)
    var vec4 = TensorMap[Float32, 1, layout=RowMajor](data4, 6)
    vec4 = vec2.square()

    var data5 = Array[Float32](6)
    var vec5 = TensorMap[Float32, 1, layout=RowMajor](data5, 6)
    vec5 = vec2.cube()

    VERIFY_IS_APPROX(vec3[0], sqrtf(4.0))
    VERIFY_IS_APPROX(vec3[1], sqrtf(8.0))
    VERIFY_IS_APPROX(vec3[2], sqrtf(15.0))
    VERIFY_IS_APPROX(vec3[3], sqrtf(16.0))
    VERIFY_IS_APPROX(vec3[4], sqrtf(23.0))
    VERIFY_IS_APPROX(vec3[5], sqrtf(42.0))

    VERIFY_IS_APPROX(vec4[0], 0.0)
    VERIFY_IS_APPROX(vec4[1], 1.0)
    VERIFY_IS_APPROX(vec4[2], 2.0 * 2.0)
    VERIFY_IS_APPROX(vec4[3], 3.0 * 3.0)
    VERIFY_IS_APPROX(vec4[4], 4.0 * 4.0)
    VERIFY_IS_APPROX(vec4[5], 5.0 * 5.0)

    VERIFY_IS_APPROX(vec5[0], 0.0)
    VERIFY_IS_APPROX(vec5[1], 1.0)
    VERIFY_IS_APPROX(vec5[2], 2.0 * 2.0 * 2.0)
    VERIFY_IS_APPROX(vec5[3], 3.0 * 3.0 * 3.0)
    VERIFY_IS_APPROX(vec5[4], 4.0 * 4.0 * 4.0)
    VERIFY_IS_APPROX(vec5[5], 5.0 * 5.0 * 5.0)

    vec3 = vec1 + vec2
    VERIFY_IS_APPROX(vec3[0], 4.0 + 0.0)
    VERIFY_IS_APPROX(vec3[1], 8.0 + 1.0)
    VERIFY_IS_APPROX(vec3[2], 15.0 + 2.0)
    VERIFY_IS_APPROX(vec3[3], 16.0 + 3.0)
    VERIFY_IS_APPROX(vec3[4], 23.0 + 4.0)
    VERIFY_IS_APPROX(vec3[5], 42.0 + 5.0)

def test_2d():
    var data1 = Array[Float32](6)
    var mat1 = TensorMap[Float32, 2](data1, 2, 3)
    var data2 = Array[Float32](6)
    var mat2 = TensorMap[Float32, 2, layout=RowMajor](data2, 2, 3)

    mat1[0,0] = 0.0
    mat1[0,1] = 1.0
    mat1[0,2] = 2.0
    mat1[1,0] = 3.0
    mat1[1,1] = 4.0
    mat1[1,2] = 5.0

    mat2[0,0] = -0.0
    mat2[0,1] = -1.0
    mat2[0,2] = -2.0
    mat2[1,0] = -3.0
    mat2[1,1] = -4.0
    mat2[1,2] = -5.0

    var mat3 = Tensor[Float32, 2](2, 3)
    var mat4 = Tensor[Float32, 2, layout=RowMajor](2, 3)

    mat3 = mat1.abs()
    mat4 = mat2.abs()

    VERIFY_IS_APPROX(mat3[0,0], 0.0)
    VERIFY_IS_APPROX(mat3[0,1], 1.0)
    VERIFY_IS_APPROX(mat3[0,2], 2.0)
    VERIFY_IS_APPROX(mat3[1,0], 3.0)
    VERIFY_IS_APPROX(mat3[1,1], 4.0)
    VERIFY_IS_APPROX(mat3[1,2], 5.0)

    VERIFY_IS_APPROX(mat4[0,0], 0.0)
    VERIFY_IS_APPROX(mat4[0,1], 1.0)
    VERIFY_IS_APPROX(mat4[0,2], 2.0)
    VERIFY_IS_APPROX(mat4[1,0], 3.0)
    VERIFY_IS_APPROX(mat4[1,1], 4.0)
    VERIFY_IS_APPROX(mat4[1,2], 5.0)

def test_3d():
    var mat1 = Tensor[Float32, 3](2, 3, 7)
    var mat2 = Tensor[Float32, 3, layout=RowMajor](2, 3, 7)
    var val: Float32 = 1.0
    for i in range(2):
        for j in range(3):
            for k in range(7):
                mat1[i,j,k] = val
                mat2[i,j,k] = val
                val += 1.0

    var mat3 = Tensor[Float32, 3](2, 3, 7)
    mat3 = mat1 + mat1
    var mat4 = Tensor[Float32, 3, layout=RowMajor](2, 3, 7)
    mat4 = mat2 * 3.14
    var mat5 = Tensor[Float32, 3](2, 3, 7)
    mat5 = mat1.inverse().log()
    var mat6 = Tensor[Float32, 3, layout=RowMajor](2, 3, 7)
    mat6 = mat2.pow(0.5) * 3.14
    var mat7 = Tensor[Float32, 3](2, 3, 7)
    mat7 = mat1.cwiseMax(mat5 * 2.0).exp()
    var mat8 = Tensor[Float32, 3, layout=RowMajor](2, 3, 7)
    mat8 = (-mat2).exp() * 3.14
    var mat9 = Tensor[Float32, 3, layout=RowMajor](2, 3, 7)
    mat9 = mat2 + 3.14
    var mat10 = Tensor[Float32, 3, layout=RowMajor](2, 3, 7)
    mat10 = mat2 - 3.14
    var mat11 = Tensor[Float32, 3, layout=RowMajor](2, 3, 7)
    mat11 = mat2 / 3.14

    val = 1.0
    for i in range(2):
        for j in range(3):
            for k in range(7):
                VERIFY_IS_APPROX(mat3[i,j,k], val + val)
                VERIFY_IS_APPROX(mat4[i,j,k], val * 3.14)
                VERIFY_IS_APPROX(mat5[i,j,k], logf(1.0 / val))
                VERIFY_IS_APPROX(mat6[i,j,k], sqrtf(val) * 3.14)
                VERIFY_IS_APPROX(mat7[i,j,k], expf(max(val, mat5[i,j,k] * 2.0)))
                VERIFY_IS_APPROX(mat8[i,j,k], expf(-val) * 3.14)
                VERIFY_IS_APPROX(mat9[i,j,k], val + 3.14)
                VERIFY_IS_APPROX(mat10[i,j,k], val - 3.14)
                VERIFY_IS_APPROX(mat11[i,j,k], val / 3.14)
                val += 1.0

def test_constants():
    var mat1 = Tensor[Float32, 3](2, 3, 7)
    var mat2 = Tensor[Float32, 3](2, 3, 7)
    var mat3 = Tensor[Float32, 3](2, 3, 7)
    var val: Float32 = 1.0
    for i in range(2):
        for j in range(3):
            for k in range(7):
                mat1[i,j,k] = val
                val += 1.0

    mat2 = mat1.constant(3.14)
    mat3 = mat1.cwiseMax(7.3).exp()

    val = 1.0
    for i in range(2):
        for j in range(3):
            for k in range(7):
                VERIFY_IS_APPROX(mat2[i,j,k], 3.14)
                VERIFY_IS_APPROX(mat3[i,j,k], expf(max(val, 7.3)))
                val += 1.0

def test_boolean():
    var vec = Tensor[Int32, 1](6)
    # Simulate copy_n from initializer list
    var init_vals = [0, 1, 2, 3, 4, 5]
    for i in range(6):
        vec[i] = init_vals[i]

    var bool1 = Tensor[Bool, 1](6)
    bool1 = vec < vec.constant(1) or vec > vec.constant(4)
    VERIFY_IS_EQUAL(bool1[0], True)
    VERIFY_IS_EQUAL(bool1[1], False)
    VERIFY_IS_EQUAL(bool1[2], False)
    VERIFY_IS_EQUAL(bool1[3], False)
    VERIFY_IS_EQUAL(bool1[4], False)
    VERIFY_IS_EQUAL(bool1[5], True)

    var bool2 = Tensor[Bool, 1](6)
    bool2 = vec.cast[Bool]() and vec < vec.constant(4)
    VERIFY_IS_EQUAL(bool2[0], False)
    VERIFY_IS_EQUAL(bool2[1], True)
    VERIFY_IS_EQUAL(bool2[2], True)
    VERIFY_IS_EQUAL(bool2[3], True)
    VERIFY_IS_EQUAL(bool2[4], False)
    VERIFY_IS_EQUAL(bool2[5], False)

    var bool3 = Tensor[Bool, 1](6)
    bool3 = vec.cast[Bool]() and bool2
    bool3 = vec < vec.constant(4) and bool2

def test_functors():
    var mat1 = Tensor[Float32, 3](2, 3, 7)
    var mat2 = Tensor[Float32, 3](2, 3, 7)
    var mat3 = Tensor[Float32, 3](2, 3, 7)
    var val: Float32 = 1.0
    for i in range(2):
        for j in range(3):
            for k in range(7):
                mat1[i,j,k] = val
                val += 1.0

    mat2 = mat1.inverse().unaryExpr(&asinf)
    mat3 = mat1.unaryExpr(&tanhf)

    val = 1.0
    for i in range(2):
        for j in range(3):
            for k in range(7):
                VERIFY_IS_APPROX(mat2[i,j,k], asinf(1.0 / mat1[i,j,k]))
                VERIFY_IS_APPROX(mat3[i,j,k], tanhf(mat1[i,j,k]))
                val += 1.0

def test_type_casting():
    var mat1 = Tensor[Bool, 3](2, 3, 7)
    var mat2 = Tensor[Float32, 3](2, 3, 7)
    var mat3 = Tensor[Float64, 3](2, 3, 7)
    mat1.setRandom()
    mat2.setRandom()
    mat3 = mat1.cast[Float64]()

    for i in range(2):
        for j in range(3):
            for k in range(7):
                VERIFY_IS_APPROX(mat3[i,j,k], mat1[i,j,k] ? 1.0 : 0.0)

    mat3 = mat2.cast[Float64]()
    for i in range(2):
        for j in range(3):
            for k in range(7):
                VERIFY_IS_APPROX(mat3[i,j,k], Float64(mat2[i,j,k]))

def test_select():
    var selector = Tensor[Float32, 3](2, 3, 7)
    var mat1 = Tensor[Float32, 3](2, 3, 7)
    var mat2 = Tensor[Float32, 3](2, 3, 7)
    var result = Tensor[Float32, 3](2, 3, 7)
    selector.setRandom()
    mat1.setRandom()
    mat2.setRandom()
    result = (selector > selector.constant(0.5)).select(mat1, mat2)

    for i in range(2):
        for j in range(3):
            for k in range(7):
                VERIFY_IS_APPROX(result[i,j,k], (selector[i,j,k] > 0.5) ? mat1[i,j,k] : mat2[i,j,k])

def test_cxx11_tensor_expr():
    test_1d()
    test_2d()
    test_3d()
    test_constants()
    test_boolean()
    test_functors()
    test_type_casting()
    test_select()