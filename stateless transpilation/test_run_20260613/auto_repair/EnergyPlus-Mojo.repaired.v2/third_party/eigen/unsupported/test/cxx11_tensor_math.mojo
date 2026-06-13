from math import tanh, exp
from random import random

struct Tensor[type: AnyType, rank: Int]:
    var data: DynamicVector[type]

    def __init__(inout self, size: Int):
        self.data = DynamicVector[type](size)

    def setRandom(inout self):
        for i in range(len(self.data)):
            self.data[i] = type(random())

    def tanh(self) -> Tensor[type, rank]:
        var result = Tensor[type, rank](len(self.data))
        for i in range(len(self.data)):
            result.data[i] = tanh(self.data[i])
        return result

    def sigmoid(self) -> Tensor[type, rank]:
        var result = Tensor[type, rank](len(self.data))
        for i in range(len(self.data)):
            result.data[i] = 1.0 / (1.0 + exp(-self.data[i]))
        return result

    def __getitem__(self, idx: Int) -> type:
        return self.data[idx]

def VERIFY_IS_APPROX(a: Float32, b: Float32):
    var tol: Float32 = 1e-5
    assert abs(a - b) < tol, "Values not approximately equal"

def CALL_SUBTEST(test_fn: fn() -> None):
    test_fn()

def test_tanh():
    var vec1 = Tensor[Float32, 1](6)
    vec1.setRandom()
    var vec2 = vec1.tanh()
    for i in range(6):
        VERIFY_IS_APPROX(vec2[i], tanh(vec1[i]))

def test_sigmoid():
    var vec1 = Tensor[Float32, 1](6)
    vec1.setRandom()
    var vec2 = vec1.sigmoid()
    for i in range(6):
        VERIFY_IS_APPROX(vec2[i], 1.0 / (1.0 + exp(-vec1[i])))

def test_cxx11_tensor_math():
    CALL_SUBTEST(test_tanh)
    CALL_SUBTEST(test_sigmoid)