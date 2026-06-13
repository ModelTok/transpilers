from tensor import Tensor
from math import sqrt as sqrtf, isclose
from sys import exit

def test_simple():
    var vec1 = Tensor[DType.float32](6)
    var vec2 = Tensor[DType.float32](6)
    vec1[0] = 4.0
    vec2[0] = 0.0
    vec1[1] = 8.0
    vec2[1] = 1.0
    vec1[2] = 15.0
    vec2[2] = 2.0
    vec1[3] = 16.0
    vec2[3] = 3.0
    vec1[4] = 23.0
    vec2[4] = 4.0
    vec1[5] = 42.0
    vec2[5] = 5.0

    var data3 = Tensor[DType.float32](6)
    var vec3 = data3
    vec3 = vec1.sqrt()

    var data4 = Tensor[DType.float32](6)
    var vec4 = data4
    vec4 = vec2.square()

    if not isclose(vec3[0], sqrtf(4.0)):
        print("FAIL: vec3[0] not approx")
        exit(1)
    if not isclose(vec3[1], sqrtf(8.0)):
        print("FAIL: vec3[1] not approx")
        exit(1)
    if not isclose(vec3[2], sqrtf(15.0)):
        print("FAIL: vec3[2] not approx")
        exit(1)
    if not isclose(vec3[3], sqrtf(16.0)):
        print("FAIL: vec3[3] not approx")
        exit(1)
    if not isclose(vec3[4], sqrtf(23.0)):
        print("FAIL: vec3[4] not approx")
        exit(1)
    if not isclose(vec3[5], sqrtf(42.0)):
        print("FAIL: vec3[5] not approx")
        exit(1)

    if not isclose(vec4[0], 0.0):
        print("FAIL: vec4[0] not approx")
        exit(1)
    if not isclose(vec4[1], 1.0):
        print("FAIL: vec4[1] not approx")
        exit(1)
    if not isclose(vec4[2], 2.0 * 2.0):
        print("FAIL: vec4[2] not approx")
        exit(1)
    if not isclose(vec4[3], 3.0 * 3.0):
        print("FAIL: vec4[3] not approx")
        exit(1)
    if not isclose(vec4[4], 4.0 * 4.0):
        print("FAIL: vec4[4] not approx")
        exit(1)
    if not isclose(vec4[5], 5.0 * 5.0):
        print("FAIL: vec4[5] not approx")
        exit(1)

def test_cxx11_tensor_mixed_indices():
    test_simple()