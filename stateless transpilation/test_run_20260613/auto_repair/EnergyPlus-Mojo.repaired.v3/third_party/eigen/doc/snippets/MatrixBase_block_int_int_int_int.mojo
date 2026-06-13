from memory import pointer
import random

struct Matrix4i:
    var data: List[List[Int]]

    def __init__(inout self):
        self.data = List(
            List(0, 0, 0, 0),
            List(0, 0, 0, 0),
            List(0, 0, 0, 0),
            List(0, 0, 0, 0),
        )

    def __str__(self) -> String:
        var s = String()
        for i in range(4):
            for j in range(4):
                s += str(self.data[i][j]) + " "
            s += "\n"
        return s

    @staticmethod
    def Random() -> Self:
        var mat = Self()
        for i in range(4):
            for j in range(4):
                mat.data[i][j] = random.randint(-10, 10)
        return mat

    def block(inout self, startRow: Int, startCol: Int, numRows: Int, numCols: Int) -> Block:
        return Block(pointer(self), startRow, startCol, numRows, numCols)


struct Block:
    var ptr: Pointer[Matrix4i]
    var startRow: Int
    var startCol: Int
    var numRows: Int
    var numCols: Int

    def __init__(inout self, ptr: Pointer[Matrix4i], sr: Int, sc: Int, nr: Int, nc: Int):
        self.ptr = ptr
        self.startRow = sr
        self.startCol = sc
        self.numRows = nr
        self.numCols = nc

    def __str__(self) -> String:
        unsafe:
            var mat_ref = self.ptr[]
            var s = String()
            for i in range(self.numRows):
                for j in range(self.numCols):
                    s += str(mat_ref.data[self.startRow + i][self.startCol + j]) + " "
                s += "\n"
            return s

    def setZero(inout self):
        unsafe:
            var mat_ref = self.ptr[]
            for i in range(self.numRows):
                for j in range(self.numCols):
                    mat_ref.data[self.startRow + i][self.startCol + j] = 0


def main():
    var m = Matrix4i.Random()
    print("Here is the matrix m:")
    print(m)
    print("Here is m.block(1, 1, 2, 2):")
    print(m.block(1, 1, 2, 2))
    m.block(1, 1, 2, 2).setZero()
    print("Now the matrix m is:")
    print(m)