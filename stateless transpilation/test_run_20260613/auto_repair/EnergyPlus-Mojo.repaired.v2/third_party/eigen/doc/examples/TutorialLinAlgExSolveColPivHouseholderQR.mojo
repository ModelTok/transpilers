from memory import memset_zero
from sys import print

def main() raises:
    var A = Matrix3f()
    var b = Vector3f()
    A[0, 0] = 1; A[0, 1] = 2; A[0, 2] = 3
    A[1, 0] = 4; A[1, 1] = 5; A[1, 2] = 6
    A[2, 0] = 7; A[2, 1] = 8; A[2, 2] = 10
    b[0] = 3; b[1] = 3; b[2] = 4
    print("Here is the matrix A:\n", A)
    print("Here is the vector b:\n", b)
    var x = A.colPivHouseholderQr().solve(b)
    print("The solution is:\n", x)