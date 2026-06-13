from sys import print

struct Array3d:
    var data: SIMD[f64, 3]

    def __init__(inout self, x: f64, y: f64, z: f64):
        self.data = SIMD[f64, 3](x, y, z)

    def __add__(self, scalar: f64) -> Array3d:
        return Array3d(self.data[0] + scalar, self.data[1] + scalar, self.data[2] + scalar)

    def __str__(self) -> String:
        return "(" + str(self.data[0]) + ", " + str(self.data[1]) + ", " + str(self.data[2]) + ")"

struct Endl:

struct OStream:
    def __lshift__[T: AnyType](inout self, value: T) -> Self:
        if __type_of(value) == Endl:
            print()
        else:
            print(value)
        return self

    alias endl = Endl()

var cout = OStream()

def main():
    var v = Array3d(1, 2, 3)
    cout << v + 5 << OStream.endl