from builtin import print
from memory import stack
from random import rand
from complex import ComplexFloat64

struct MakeComplexOp:
    alias result_type = ComplexFloat64

    def __call__(self, a: Float64, b: Float64) -> ComplexFloat64:
        return ComplexFloat64(a, b)

struct Matrix4d:
    var data: StaticTuple[StaticTuple[Float64, 4], 4]

    def __init__(self):
        self.data = StaticTuple[StaticTuple[Float64, 4], 4]()

    @staticmethod
    def Random() -> Self:
        var m = Self()
        for i in range(4):
            var row = StaticTuple[Float64, 4]()
            for j in range(4):
                row.set(j, rand[Float64]())
            m.data.set(i, row)
        return m

    def binaryExpr(self, other: Self, op: MakeComplexOp) -> MatrixC4d:
        var result = MatrixC4d()
        for i in range(4):
            var row = StaticTuple[ComplexFloat64, 4]()
            for j in range(4):
                row.set(j, op(self.data[i][j], other.data[i][j]))
            result.data.set(i, row)
        return result

struct MatrixC4d:
    var data: StaticTuple[StaticTuple[ComplexFloat64, 4], 4]

    def __init__(self):
        self.data = StaticTuple[StaticTuple[ComplexFloat64, 4], 4]()

    def __str__(self) -> String:
        var s = String()
        for i in range(4):
            s += "["
            for j in range(4):
                s += str(self.data[i][j])
                if j != 3:
                    s += ", "
            s += "]\n"
        return s

def main() raises:
    var m1 = Matrix4d.Random()
    var m2 = Matrix4d.Random()
    print(m1.binaryExpr(m2, MakeComplexOp()))
    return