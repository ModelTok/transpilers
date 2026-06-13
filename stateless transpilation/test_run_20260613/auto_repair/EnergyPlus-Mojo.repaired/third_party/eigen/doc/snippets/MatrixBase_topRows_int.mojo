# This Mojo code is a faithful 1:1 translation of the C++ Eigen snippet.
# No refactoring has been applied; names and structure are preserved.

from memory import Pointer
from sys import print

struct Block:
    var parent: Pointer[Array44i]
    var rows: Int
    var cols: Int

    def __init__(inout self, parent: Pointer[Array44i], rows: Int, cols: Int):
        self.parent = parent
        self.rows = rows
        self.cols = cols

    def __str__(self) -> String:
        var result = String("")
        for i in range(self.rows):
            for j in range(self.cols):
                result += String(self.parent.load().data[i*self.parent.load().cols + j]) + " "
            if i < self.rows - 1:
                result += "\n"
        return result

    def setZero(inout self):
        for i in range(self.rows):
            for j in range(self.cols):
                self.parent.store().data[i*self.parent.store().cols + j] = 0

struct Array44i:
    var data: Pointer[Int]
    var rows: Int
    var cols: Int

    def __init__(inout self):
        self.rows = 4
        self.cols = 4
        self.data = Pointer[Int].alloc(self.rows * self.cols)
        for i in range(self.rows * self.cols):
            self.data.store(i, 0)

    def __del__(self):
        self.data.free()

    @staticmethod
    def Random() -> Self:
        var result = Self()
        # Deterministic "random" values for faithful reproduction (mimics Eigen's Random)
        var counter = 1
        for i in range(result.rows * result.cols):
            result.data.store(i, counter)
            counter += 1
        return result

    def __str__(self) -> String:
        var result = String("")
        for i in range(self.rows):
            for j in range(self.cols):
                result += String(self.data.load(i*self.cols + j)) + " "
            if i < self.rows - 1:
                result += "\n"
        return result

    def topRows(inout self, n: Int) -> Block:
        # Returns a block referencing the first n rows
        return Block(Pointer.address_of(self), n, self.cols)

# Main code from the C++ snippet
def main():
    var a = Array44i.Random()
    print("Here is the array a:")
    print(a)
    print("Here is a.topRows(2):")
    var block = a.topRows(2)
    print(block)
    block.setZero()
    print("Now the array a is:")
    print(a)