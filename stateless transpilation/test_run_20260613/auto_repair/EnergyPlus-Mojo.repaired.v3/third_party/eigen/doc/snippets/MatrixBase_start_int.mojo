from random import randint
from builtin import Pointer, SIMD

struct RowVector4i:
    var data: SIMD[Int, 4]

    def __init__(inout self, d: SIMD[Int, 4]):
        self.data = d

    @staticmethod
    def Random() -> Self:
        return Self(
            data = SIMD[Int, 4](
                randint(-10, 10),
                randint(-10, 10),
                randint(-10, 10),
                randint(-10, 10),
            )
        )

    def head(inout self, n: Int) -> HeadView:
        return HeadView(self.data.ptr, n)

    def __str__(self) -> String:
        var s: String = ""
        for i in range(4):
            s += " " + str(self.data[i])
        return s

struct HeadView:
    var ptr: Pointer[Int]
    var size: Int

    def setZero(inout self):
        for i in range(self.size):
            self.ptr.store(i, 0)

    def __str__(self) -> String:
        var s: String = ""
        for i in range(self.size):
            s += " " + str(self.ptr.load(i))
        return s

def main():
    var v = RowVector4i.Random()
    print("Here is the vector v:")
    print(v)
    print("Here is v.head(2):")
    print(v.head(2))
    v.head(2).setZero()
    print("Now the vector v is:")
    print(v)