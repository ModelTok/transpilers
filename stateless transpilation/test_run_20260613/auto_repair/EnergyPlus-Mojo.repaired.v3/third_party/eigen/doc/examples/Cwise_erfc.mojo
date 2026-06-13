from python import Python
let math = Python.import("math")

struct Array4d:
    var data: SIMD[Float64, 4]

    def __init__(inout self, a: Float64, b: Float64, c: Float64, d: Float64):
        self.data = SIMD[Float64, 4](a, b, c, d)

    def erfc(self) -> Array4d:
        var result = SIMD[Float64, 4]()
        for i in range(4):
            result[i] = math.erfc(self.data[i])
        return Array4d(result[0], result[1], result[2], result[3])

def main():
    var v = Array4d(-0.5, 2, 0, -7)
    print(v.erfc())