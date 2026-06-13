from memory import Pointer
from math import sqrt
from random import random

struct MatrixType:
    var data: Pointer[Float32]
    var rows: Int
    var cols: Int

    def __init__(inout self, n: Int):
        self.rows = 1
        self.cols = n
        self.data = Pointer[Float32].alloc(n)
        for i in range(n):
            self.data[i] = 0.0

    def __del__(owned self):
        self.data.free()

    def __getitem__(self, i: Int) -> Float32:
        return self.data[i]

    def __setitem__(self, i: Int, val: Float32):
        self.data[i] = val

    def setRandom(inout self):
        for i in range(self.cols):
            self.data[i] = random() * 2.0 - 1.0

    def size(self) -> Int:
        return self.cols

    def data_ptr(self) -> Pointer[Float32]:
        return self.data

    def __sub__(self, other: MatrixType) -> MatrixType:
        var result = MatrixType(self.cols)
        for i in range(self.cols):
            result[i] = self[i] - other[i]
        return result

    def squaredNorm(self) -> Float32:
        var s: Float32 = 0.0
        for i in range(self.cols):
            s += self[i] * self[i]
        return s

    def __str__(self) -> String:
        var s = String("")
        for i in range(self.cols):
            s += str(self[i]) + " "
        return s

struct MapType:
    var data: Pointer[Float32]
    var size: Int

    def __init__(inout self, p: Pointer[Float32], n: Int):
        self.data = p
        self.size = n

    def __getitem__(self, i: Int) -> Float32:
        return self.data[i]

    def __setitem__(self, i: Int, val: Float32):
        self.data[i] = val

    def size(self) -> Int:
        return self.size

struct MapTypeConst:
    var data: Pointer[Float32]
    var size: Int

    def __init__(inout self, p: Pointer[Float32], n: Int):
        self.data = p
        self.size = n

    def __getitem__(self, i: Int) -> Float32:
        return self.data[i]

    def size(self) -> Int:
        return self.size

def main():
    const n_dims: Int = 5
    var m1 = MatrixType(n_dims)
    var m2 = MatrixType(n_dims)
    m1.setRandom()
    m2.setRandom()
    var p = m2.data_ptr()  # get the address storing the data for m2
    var m2map = MapType(p, m2.size())   # m2map shares data with m2
    var m2mapconst = MapTypeConst(p, m2.size())  # a read-only accessor for m2
    print("m1: ", m1)
    print("m2: ", m2)
    print("Squared euclidean distance: ", (m1 - m2).squaredNorm())
    print("Squared euclidean distance, using map: ", (m1 - m2map).squaredNorm())
    m2map[3] = 7.0   # this will change m2, since they share the same array
    print("Updated m2: ", m2)
    print("m2 coefficient 2, constant accessor: ", m2mapconst[2])
    # m2mapconst[2] = 5;   # this yields a compile-time error