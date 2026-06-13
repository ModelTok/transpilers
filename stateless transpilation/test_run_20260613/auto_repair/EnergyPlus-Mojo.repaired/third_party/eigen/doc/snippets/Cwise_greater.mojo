struct Array3d:
    var data: SIMD[DType.float64, 3]
    def __init__(inout self, a: Float64, b: Float64, c: Float64):
        self.data = SIMD[DType.float64, 3](a, b, c)
    def __gt__(self, other: Array3d) -> Array3dBool:
        var cmp = self.data > other.data
        return Array3dBool(SIMD[DType.int32, 3](cmp.cast[DType.int32]()))

struct Array3dBool:
    var data: SIMD[DType.int32, 3]
    def __init__(inout self, data: SIMD[DType.int32, 3]):
        self.data = data
    def __str__(self) -> String:
        var res = "["
        for i in range(3):
            if i > 0: res += " "
            res += String(self.data[i])
        res += "]"
        return res

struct Cout:
    def __lshift__[T: AnyType](self, val: T) -> Cout:
        print(val, end="")
        return Self()
    def __lshift__[T: AnyType](self, f: def () -> None) -> Cout:
        f()
        return Self()

def endl():
    print()

var cout = Cout()

Array3d v(1,2,3), w(3,2,1);
cout << (v>w) << endl;