# Mojo translation of Tutorial_solve_singular.cpp
# Faithful 1:1 translation, no refactoring

struct Matrix3f:
    var data: SIMD[float32, 9]

    def __init__(inout self, *vals: float32):
        self.data = SIMD[float32, 9](*vals)

    def __str__(self) -> String:
        var s = String()
        for i in range(3):
            for j in range(3):
                s += str(self.data[i*3 + j]) + " "
            s += "\n"
        return s

    def lu(self) -> LUDecomposition:
        return LUDecomposition(self)

struct Vector3f:
    var data: SIMD[float32, 3]

    def __init__(inout self, *vals: float32):
        self.data = SIMD[float32, 3](*vals)

    def __str__(self) -> String:
        var s = String()
        for i in range(3):
            s += str(self.data[i]) + "\n"
        return s

struct LUDecomposition:
    var A: Matrix3f

    def __init__(inout self, A: Matrix3f):
        self.A = A

    def solve(self, b: Vector3f) -> Vector3f:
        # Gaussian elimination with partial pivoting (3x3)
        var a = self.A.data
        var bb = b.data
        # Forward elimination
        for k in range(2):
            # Find pivot
            var max_val = abs(a[k*3 + k])
            var max_row = k
            for i in range(k+1, 3):
                if abs(a[i*3 + k]) > max_val:
                    max_val = abs(a[i*3 + k])
                    max_row = i
            if max_row != k:
                # Swap rows
                for j in range(k, 3):
                    var tmp = a[k*3 + j]
                    a[k*3 + j] = a[max_row*3 + j]
                    a[max_row*3 + j] = tmp
                var tmpb = bb[k]
                bb[k] = bb[max_row]
                bb[max_row] = tmpb
            # Eliminate below
            for i in range(k+1, 3):
                var factor = a[i*3 + k] / a[k*3 + k]
                for j in range(k, 3):
                    a[i*3 + j] -= factor * a[k*3 + j]
                bb[i] -= factor * bb[k]
        # Back substitution
        var x = SIMD[float32, 3](0.0)
        for i in range(2, -1, -1):
            var sum = bb[i]
            for j in range(i+1, 3):
                sum -= a[i*3 + j] * x[j]
            x[i] = sum / a[i*3 + i]
        return Vector3f(x[0], x[1], x[2])

def main():
    var A = Matrix3f(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0)
    var b = Vector3f(3.0, 3.0, 4.0)
    print("Here is the matrix A:"); print(A)
    print("Here is the vector b:"); print(b)
    var x = A.lu().solve(b)
    print("The solution is:"); print(x)