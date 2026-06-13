from memory import Pointer

struct MatrixXi:

struct OuterStride:
    var stride: Int
    def __init__(inout self, s: Int):
        self.stride = s

struct Map[MatrixType: AnyType, Options: Int, StrideType: AnyType]:
    var data: Pointer[Int]
    var rows: Int
    var cols: Int
    var outer_stride: StrideType
    def __init__(inout self, ptr: Pointer[Int], r: Int, c: Int, os: StrideType):
        self.data = ptr
        self.rows = r
        self.cols = c
        self.outer_stride = os
    def __str__(self) -> String:
        var s = String()
        for i in range(self.rows):
            for j in range(self.cols):
                idx = i * self.outer_stride.stride + j
                s += str(self.data.load(idx))
                if j < self.cols - 1:
                    s += " "
            if i < self.rows - 1:
                s += "\n"
        return s

def main():
    var array = List[Int]()
    for i in range(12):
        array.append(i)
    var ptr = Pointer[Int].address_of(array[0])
    print(Map[MatrixXi, 0, OuterStride](ptr, 3, 3, OuterStride(4)))