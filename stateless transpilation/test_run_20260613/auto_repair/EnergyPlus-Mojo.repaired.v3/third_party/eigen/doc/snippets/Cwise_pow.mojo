struct Array3d:
    var data: SIMD[DType.float64, 3]

    def __init__(inout self, a: Float64, b: Float64, c: Float64):
        self.data = SIMD[DType.float64, 3](a, b, c)

    def pow(self, exponent: Float64) -> Array3d:
        var result = Array3d(0.0, 0.0, 0.0)
        for i in range(3):
            result.data[i] = self.data[i] ** exponent
        return result

    def __str__(self) -> String:
        return "(" + str(self.data[0]) + ", " + str(self.data[1]) + ", " + str(self.data[2]) + ")"

var v = Array3d(8.0, 27.0, 64.0)
print(v.pow(0.333333))