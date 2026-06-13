from memory import memset_zero
from tensor import Tensor, TensorShape
from random import randint

struct Matrix4i:
    var data: Tensor[Int, 4, 4]

    def __init__(inout self):
        self.data = Tensor[Int](4, 4)

    @staticmethod
    def Random() -> Matrix4i:
        var m = Matrix4i()
        for i in range(4):
            for j in range(4):
                m.data[i, j] = randint(-10, 10)
        return m

    def block[rows: Int, cols: Int](inout self, start_row: Int, start_col: Int) -> Tensor[Int, rows, cols]:
        var block_data = Tensor[Int](rows, cols)
        for i in range(rows):
            for j in range(cols):
                block_data[i, j] = self.data[start_row + i, start_col + j]
        return block_data

    def setZero(inout self):
        for i in range(4):
            for j in range(4):
                self.data[i, j] = 0

def cout(s: String):
    print(s, end="")

def endl():
    print()

def main():
    var m = Matrix4i.Random()
    cout("Here is the matrix m:")
    endl()
    for i in range(4):
        for j in range(4):
            print(m.data[i, j], end=" ")
        endl()
    cout("Here is m.block<2,2>(1,1):")
    endl()
    var block_2x2 = m.block[2, 2](1, 1)
    for i in range(2):
        for j in range(2):
            print(block_2x2[i, j], end=" ")
        endl()
    m.block[2, 2](1, 1).setZero()
    cout("Now the matrix m is:")
    endl()
    for i in range(4):
        for j in range(4):
            print(m.data[i, j], end=" ")
        endl()