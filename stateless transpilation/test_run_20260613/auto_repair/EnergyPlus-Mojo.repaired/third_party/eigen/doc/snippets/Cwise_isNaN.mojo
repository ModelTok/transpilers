from math import isnan as _isnan_scalar

struct Array3d:
    var data: SIMD[Float64, 3]

    def __init__(out self, a: Float64, b: Float64, c: Float64):
        self.data = SIMD[Float64, 3](a, b, c)

    def __getitem__(self, idx: Int) -> Float64:
        return self.data[idx]

    def __setitem__(mut self, idx: Int, val: Float64):
        self.data[idx] = val

    def __str__(self) -> String:
        return String(self.data[0]) + " " + String(self.data[1]) + " " + String(self.data[2])

struct BoolArray3d:
    var data: SIMD[Int8, 3]

    def __init__(out self, other: SIMD[Int8, 3]):
        self.data = other

    def __getitem__(self, idx: Int) -> Int8:
        return self.data[idx]

    def __str__(self) -> String:
        return String(self.data[0]) + " " + String(self.data[1]) + " " + String(self.data[2])

def isnan(x: Array3d) -> BoolArray3d:
    var result = SIMD[Int8, 3](0, 0, 0)
    for i in range(3):
        result[i] = Int8(_isnan_scalar(x[i]))
    return BoolArray3d(result)

def main():
    var v = Array3d(1.0, 2.0, 3.0)
    v[1] = v[1] * (0.0 / 0.0)
    v[2] = v[2] / 0.0
    print(v)
    print()
    print(isnan(v))