struct Array3d:
    var d0: Float64
    var d1: Float64
    var d2: Float64

    def __init__(inout self, a: Float64, b: Float64, c: Float64):
        self.d0 = a
        self.d1 = b
        self.d2 = c

    def __ge__(self, other: Array3d) -> Array3dBool:
        return Array3dBool(
            self.d0 >= other.d0,
            self.d1 >= other.d1,
            self.d2 >= other.d2
        )

struct Array3dBool:
    var d0: Bool
    var d1: Bool
    var d2: Bool

    def __init__(inout self, a: Bool, b: Bool, c: Bool):
        self.d0 = a
        self.d1 = b
        self.d2 = c

    def __str__(self) -> String:
        return (str(self.d0) + " " + str(self.d1) + " " + str(self.d2))

def main():
    var v = Array3d(1.0, 2.0, 3.0)
    var w = Array3d(3.0, 2.0, 1.0)
    print(v >= w)