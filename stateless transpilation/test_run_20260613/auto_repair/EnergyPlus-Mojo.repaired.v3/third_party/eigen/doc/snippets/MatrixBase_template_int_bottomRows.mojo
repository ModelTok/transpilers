from random import randint
from memory import Pointer, address_of

struct Array44i:
    var data: List[Int]

    def __init__(inout self):
        self.data = List[Int](capacity=16)
        for i in range(16):
            self.data.append(0)

    @staticmethod
    def Random() -> Array44i:
        var arr = Array44i()
        for i in range(16):
            arr.data[i] = randint(-10, 10)
        return arr

    def bottomRows[rows: Int](inout self) -> BottomRowsView[rows]:
        return BottomRowsView[rows](address_of(self))

    def __str__(self) -> String:
        var s = String()
        for i in range(4):
            for j in range(4):
                if j > 0:
                    s += " "
                s += str(self.data[i * 4 + j])
            if i < 3:
                s += "\n"
        return s

struct BottomRowsView[rows: Int]:
    var arr_ptr: Pointer[Array44i]

    def __init__(inout self, ptr: Pointer[Array44i]):
        self.arr_ptr = ptr

    def setZero(inout self):
        for i in range(4 - rows, 4):
            for j in range(4):
                self.arr_ptr[].data[i * 4 + j] = 0

    def __str__(self) -> String:
        var s = String()
        for i in range(4 - rows, 4):
            for j in range(4):
                if j > 0:
                    s += " "
                s += str(self.arr_ptr[].data[i * 4 + j])
            if i < 3:
                s += "\n"
        return s

def main():
    var a = Array44i.Random()
    print("Here is the array a:")
    print(a)
    print("Here is a.bottomRows<2>():")
    print(a.bottomRows[2]())
    a.bottomRows[2]().setZero()
    print("Now the array a is:")
    print(a)