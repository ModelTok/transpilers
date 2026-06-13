from memory import List
from python import PythonObject  # for potential use, but we'll use List

struct RowVectorXi:
    var data: List[Int]

    def __init__(inout self, size: Int):
        self.data = List[Int](size)

    def __init__(inout self, size: Int, value: Int):
        self.data = List[Int](size, value)

    def __str__(self) -> String:
        var s: String = ""
        for i in range(len(self.data)):
            if i > 0:
                s += " "
            s += String(self.data[i])
        return s

    def __mul__(self, scalar: Int) -> RowVectorXi:
        var res = RowVectorXi(len(self.data))
        for i in range(len(self.data)):
            res.data[i] = self.data[i] * scalar
        return res

    @staticmethod
    def Ones(n: Int) -> RowVectorXi:
        return RowVectorXi(n, 1)

struct VectorXf:
    var data: List[Float32]

    def __init__(inout self, size: Int):
        self.data = List[Float32](size)

    def __init__(inout self, size: Int, value: Float32):
        self.data = List[Float32](size, value)

    def __str__(self) -> String:
        var s: String = ""
        for i in range(len(self.data)):
            if i > 0:
                s += "\n"
            s += String(self.data[i])
        return s

    @staticmethod
    def Ones(n: Int) -> VectorXf:
        return VectorXf(n, Float32(1))

def main():
    print(6 * RowVectorXi.Ones(4))
    print(VectorXf.Ones(2))