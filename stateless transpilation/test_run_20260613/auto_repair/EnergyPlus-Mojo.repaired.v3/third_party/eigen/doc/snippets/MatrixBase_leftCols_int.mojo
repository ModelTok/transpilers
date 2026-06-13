from memory import Pointer
from random import randint

struct Block:
    var ptr: Pointer[Int32]
    var n: Int

    def __init__(inout self, ptr: Pointer[Int32], n: Int):
        self.ptr = ptr
        self.n = n

    def setZero(inout self):
        for i in range(4):
            for j in range(self.n):
                self.ptr.store(i * 4 + j, 0)

    def __str__(self) -> String:
        var s = String()
        for i in range(4):
            for j in range(self.n):
                s += str(self.ptr.load(i * 4 + j)) + " "
            s += "\n"
        return s

struct Array44i:
    var data: Pointer[Int32]
    var owned: Bool

    def __init__(inout self):
        self.data = Pointer[Int32].alloc(16)
        self.owned = True
        for i in range(16):
            self.data.store(i, 0)

    def __del__(owned self):
        if self.owned:
            self.data.free()

    @staticmethod
    def Random() -> Self:
        var a = Self()
        for i in range(16):
            a.data.store(i, randint(-100, 100))
        return a

    def leftCols(inout self, n: Int) -> Block:
        return Block(self.data, n)

    def __str__(self) -> String:
        var s = String()
        for i in range(4):
            for j in range(4):
                s += str(self.data.load(i * 4 + j)) + " "
            s += "\n"
        return s

var a = Array44i.Random()
print("Here is the array a:")
print(a)
print("Here is a.leftCols(2):")
print(a.leftCols(2))
a.leftCols(2).setZero()
print("Now the array a is:")
print(a)