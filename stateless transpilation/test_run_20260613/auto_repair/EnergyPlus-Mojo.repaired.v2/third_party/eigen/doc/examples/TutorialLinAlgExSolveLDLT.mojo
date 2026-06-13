import sys
from tensor import Tensor
from math import sqrt

# Simulating Eigen's Dense namespace with basic matrix operations
struct Matrix2f:
    var data: Tensor[DType.float32, 2, 2]

    def __init__(inout self):
        self.data = Tensor[DType.float32, 2, 2]()

    def __init__(inout self, *values: Float32) raises:
        if len(values) != 4:
            raise Error("Matrix2f requires exactly 4 values")
        self.data = Tensor[DType.float32, 2, 2](values)

    def __getitem__(self, i: Int, j: Int) -> Float32:
        return self.data[i, j]

    def __setitem__(inout self, i: Int, j: Int, val: Float32):
        self.data[i, j] = val

    def __str__(self) -> String:
        var s = String("[")
        for i in range(2):
            if i > 0:
                s += " "
            s += "["
            for j in range(2):
                if j > 0:
                    s += ", "
                s += str(self.data[i, j])
            s += "]"
            if i < 1:
                s += "\n"
        s += "]"
        return s

    def ldlt(inout self) -> LDLT:
        return LDLT(self)

struct LDLT:
    var A: Matrix2f
    var L: Matrix2f
    var D: Matrix2f
    var P: Matrix2f

    def __init__(inout self, A: Matrix2f):
        self.A = A
        # Basic LDLT decomposition for 2x2 matrix
        self.L = Matrix2f(1.0, 0.0, A[1, 0] / A[0, 0], 1.0)
        self.D = Matrix2f(A[0, 0], 0.0, 0.0, A[1, 1] - (A[1, 0] * A[0, 1]) / A[0, 0])
        self.P = Matrix2f(1.0, 0.0, 0.0, 1.0)

    def solve(inout self, b: Matrix2f) -> Matrix2f:
        # Solve using LDLT decomposition: Ly = b, D z = y, L^T P x = z
        var y = Matrix2f()
        y[0, 0] = b[0, 0]
        y[0, 1] = b[0, 1]
        y[1, 0] = b[1, 0] - self.L[1, 0] * y[0, 0]
        y[1, 1] = b[1, 1] - self.L[1, 0] * y[0, 1]

        var z = Matrix2f()
        z[0, 0] = y[0, 0] / self.D[0, 0]
        z[0, 1] = y[0, 1] / self.D[0, 0]
        z[1, 0] = y[1, 0] / self.D[1, 1]
        z[1, 1] = y[1, 1] / self.D[1, 1]

        var x = Matrix2f()
        x[1, 0] = z[1, 0]
        x[1, 1] = z[1, 1]
        x[0, 0] = z[0, 0] - self.L[1, 0] * x[1, 0]
        x[0, 1] = z[0, 1] - self.L[1, 0] * x[1, 1]

        return x

def main() raises:
    var A = Matrix2f()
    A[0, 0] = 2
    A[0, 1] = -1
    A[1, 0] = -1
    A[1, 1] = 3
    var b = Matrix2f(1, 2, 3, 1)

    print("Here is the matrix A:")
    print(A)
    print("Here is the right hand side b:")
    print(b)

    var x = A.ldlt().solve(b)
    print("The solution is:")
    print(x)