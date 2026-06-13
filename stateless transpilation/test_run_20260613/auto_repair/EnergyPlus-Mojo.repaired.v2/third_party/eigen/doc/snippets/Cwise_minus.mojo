struct Array3d:
    var data: SIMD[Float64, 3]
    def __init__(inout self, a: Int, b: Int, c: Int):
        self.data = SIMD[Float64, 3](Float64(a), Float64(b), Float64(c))
    def __init__(inout self, a: Float64, b: Float64, c: Float64):
        self.data = SIMD[Float64, 3](a, b, c)
    def __sub__(self, other: Int) -> Array3d:
        return Array3d(self.data[0] - Float64(other), self.data[1] - Float64(other), self.data[2] - Float64(other))
    def __str__(self) -> String:
        return String(self.data[0]) + " " + String(self.data[1]) + " " + String(self.data[2])

var v = Array3d(1, 2, 3)
print(v - 5)