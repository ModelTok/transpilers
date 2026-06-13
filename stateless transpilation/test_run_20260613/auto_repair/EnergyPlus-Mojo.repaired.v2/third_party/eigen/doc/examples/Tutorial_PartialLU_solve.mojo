# Mojo translation of Tutorial_PartialLU_solve.cpp
# Faithful 1:1 translation, no refactoring

from memory import Pointer
from math import abs

struct Vector3f:
    var data: Pointer[Float32, 3]

    def __init__(inout self, x: Float32, y: Float32, z: Float32):
        self.data = Pointer[Float32].alloc(3)
        self.data[0] = x
        self.data[1] = y
        self.data[2] = z

    def __getitem__(self, i: Int) -> Float32:
        return self.data[i]

    def __setitem__(inout self, i: Int, val: Float32):
        self.data[i] = val

    def __str__(self) -> String:
        return "(" + str(self.data[0]) + ",\n " + str(self.data[1]) + ",\n " + str(self.data[2]) + ")"

    def __del__(owned self):
        self.data.free()

struct Matrix3f:
    var data: Pointer[Float32, 9]

    def __init__(inout self, a11: Float32, a12: Float32, a13: Float32,
                          a21: Float32, a22: Float32, a23: Float32,
                          a31: Float32, a32: Float32, a33: Float32):
        self.data = Pointer[Float32].alloc(9)
        self.data[0] = a11
        self.data[1] = a12
        self.data[2] = a13
        self.data[3] = a21
        self.data[4] = a22
        self.data[5] = a23
        self.data[6] = a31
        self.data[7] = a32
        self.data[8] = a33

    def __getitem__(self, i: Int, j: Int) -> Float32:
        return self.data[i * 3 + j]

    def __setitem__(inout self, i: Int, j: Int, val: Float32):
        self.data[i * 3 + j] = val

    def __str__(self) -> String:
        var s = String("")
        for i in range(3):
            s += "("
            for j in range(3):
                s += str(self[i, j])
                if j < 2:
                    s += ", "
            s += ")"
            if i < 2:
                s += "\n"
        return s

    def lu(self) -> PartialPivLU:
        return PartialPivLU(self)

    def __del__(owned self):
        self.data.free()

struct PartialPivLU:
    var lu: Matrix3f
    var piv: Pointer[Int, 3]

    def __init__(inout self, A: Matrix3f):
        # Copy A into lu
        self.lu = Matrix3f(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
        for i in range(3):
            for j in range(3):
                self.lu[i, j] = A[i, j]
        self.piv = Pointer[Int].alloc(3)
        for i in range(3):
            self.piv[i] = i

        # LU decomposition with partial pivoting (3x3)
        for k in range(2):
            # Find pivot
            var max_val = abs(self.lu[k, k])
            var max_row = k
            for i in range(k+1, 3):
                if abs(self.lu[i, k]) > max_val:
                    max_val = abs(self.lu[i, k])
                    max_row = i
            if max_row != k:
                # Swap rows
                for j in range(3):
                    var tmp = self.lu[k, j]
                    self.lu[k, j] = self.lu[max_row, j]
                    self.lu[max_row, j] = tmp
                var tmp_piv = self.piv[k]
                self.piv[k] = self.piv[max_row]
                self.piv[max_row] = tmp_piv
            # Compute multipliers and eliminate
            for i in range(k+1, 3):
                var mult = self.lu[i, k] / self.lu[k, k]
                self.lu[i, k] = mult
                for j in range(k+1, 3):
                    self.lu[i, j] -= mult * self.lu[k, j]

    def solve(self, b: Vector3f) -> Vector3f:
        # Apply permutation to b
        var pb = Vector3f(0.0, 0.0, 0.0)
        for i in range(3):
            pb[i] = b[self.piv[i]]

        # Forward substitution (L * y = pb)
        var y = Vector3f(0.0, 0.0, 0.0)
        for i in range(3):
            var sum = 0.0
            for j in range(i):
                sum += self.lu[i, j] * y[j]
            y[i] = pb[i] - sum

        # Back substitution (U * x = y)
        var x = Vector3f(0.0, 0.0, 0.0)
        for i in range(2, -1, -1):
            var sum = 0.0
            for j in range(i+1, 3):
                sum += self.lu[i, j] * x[j]
            x[i] = (y[i] - sum) / self.lu[i, i]

        return x

    def __del__(owned self):
        self.piv.free()

def main():
    var A = Matrix3f(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 10.0)
    var b = Vector3f(3.0, 3.0, 4.0)
    print("Here is the matrix A:")
    print(A)
    print("Here is the vector b:")
    print(b)
    var x = A.lu().solve(b)
    print("The solution is:")
    print(x)