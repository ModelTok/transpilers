from math import sqrt, asin

struct Array3d:
    var data: SIMD[DType.float64, 3]

    def __init__(inout self, a: Float64, b: Float64, c: Float64):
        self.data = SIMD[DType.float64, 3](a, b, c)

    def asin(self) -> Array3d:
        return Array3d(asin(self.data[0]), asin(self.data[1]), asin(self.data[2]))

    def __str__(self) -> String:
        return "(" + str(self.data[0]) + ", " + str(self.data[1]) + ", " + str(self.data[2]) + ")"

var v = Array3d(0, sqrt(2.0)/2.0, 1)
print(v.asin())