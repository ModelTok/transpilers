from random import randint
from memory import Pointer
from builtin import print, Int, String, List

struct Array44iSlice:
    var parent: Pointer[Array44i]
    var rows: Int
    var cols: Int
    var col_offset: Int

    def __init__(inout self, parent: Pointer[Array44i], rows: Int, cols: Int):
        self.parent = parent
        self.rows = rows
        self.cols = cols
        self.col_offset = 4 - cols

    def setZero(inout self):
        for i in range(self.rows):
            for j in range(self.cols):
                self.parent.data[(i * 4) + self.col_offset + j] = 0

    def __str__(self) -> String:
        var s = String()
        for i in range(self.rows):
            for j in range(self.cols):
                s += str(self.parent.data[(i * 4) + self.col_offset + j]) + " "
            s += "\n"
        return s

struct Array44i:
    var data: List[Int]

    def __init__(inout self):
        self.data = List[Int]()
        for i in range(16):
            self.data.append(0)

    @staticmethod
    def Random() -> Self:
        var a = Self()
        for i in range(16):
            a.data[i] = randint(-100, 100)
        return a

    def __str__(self) -> String:
        var s = String()
        for i in range(4):
            for j in range(4):
                s += str(self.data[i * 4 + j]) + " "
            s += "\n"
        return s

    def rightCols[cols: Int](self) -> Array44iSlice:
        return Array44iSlice(Pointer(self), 4, cols)

var a = Array44i.Random()
print("Here is the array a:")
print(a)
print("Here is a.rightCols<2>():")
print(a.rightCols[2]())
a.rightCols[2]().setZero()
print("Now the array a is:")
print(a)