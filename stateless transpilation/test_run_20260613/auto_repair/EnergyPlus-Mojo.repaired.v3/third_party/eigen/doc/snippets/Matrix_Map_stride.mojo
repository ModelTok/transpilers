from memory import DTypePointer
from sys import print

def main() raises:
    var A = Matrix4i()
    A[0, 0] = 1; A[0, 1] = 2; A[0, 2] = 3; A[0, 3] = 4
    A[1, 0] = 5; A[1, 1] = 6; A[1, 2] = 7; A[1, 3] = 8
    A[2, 0] = 9; A[2, 1] = 10; A[2, 2] = 11; A[2, 3] = 12
    A[3, 0] = 13; A[3, 1] = 14; A[3, 2] = 15; A[3, 3] = 16
    print(Matrix2i.Map(&A[1, 1], Stride[8, 2]()))