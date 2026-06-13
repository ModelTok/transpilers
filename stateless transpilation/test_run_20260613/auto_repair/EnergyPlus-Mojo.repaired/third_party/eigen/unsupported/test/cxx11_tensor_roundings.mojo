from tensor import Tensor, DType
from random import random
from math import round, floor, ceil

# Minimal substitutes for Eigen test macros
def VERIFY_IS_EQUAL(a: Float32, b: Float32) -> Bool:
    assert a == b
    return True

def CALL_SUBTEST(f: fn() -> None):
    f()

# Numext functions as used in Eigen
struct numext:
    @staticmethod
    def round(x: Float32) -> Float32:
        return round(x)

    @staticmethod
    def floor(x: Float32) -> Float32:
        return floor(x)

    @staticmethod
    def ceil(x: Float32) -> Float32:
        return ceil(x)

def test_float_rounding():
    var ftensor = Tensor[DType.f32, 2](20, 30)
    # Initialize with random * 100
    for i in range(20):
        for j in range(30):
            ftensor[i, j] = random() * 100.0
    var result = ftensor.round()
    for i in range(20):
        for j in range(30):
            VERIFY_IS_EQUAL(result[i, j], numext.round(ftensor[i, j]))

def test_float_flooring():
    var ftensor = Tensor[DType.f32, 2](20, 30)
    for i in range(20):
        for j in range(30):
            ftensor[i, j] = random() * 100.0
    var result = ftensor.floor()
    for i in range(20):
        for j in range(30):
            VERIFY_IS_EQUAL(result[i, j], numext.floor(ftensor[i, j]))

def test_float_ceiling():
    var ftensor = Tensor[DType.f32, 2](20, 30)
    for i in range(20):
        for j in range(30):
            ftensor[i, j] = random() * 100.0
    var result = ftensor.ceil()
    for i in range(20):
        for j in range(30):
            VERIFY_IS_EQUAL(result[i, j], numext.ceil(ftensor[i, j]))

def test_cxx11_tensor_roundings():
    CALL_SUBTEST(test_float_rounding)
    CALL_SUBTEST(test_float_ceiling)
    CALL_SUBTEST(test_float_flooring)

test_cxx11_tensor_roundings()