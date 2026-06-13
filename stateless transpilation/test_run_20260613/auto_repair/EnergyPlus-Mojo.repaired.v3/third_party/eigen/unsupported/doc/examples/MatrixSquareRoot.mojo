from memory import memset_zero
from math import acos, cos, sin
from tensor import Tensor, TensorShape
from sys import print

def main() raises:
    let pi: Float64 = acos(-1.0)
    var A = Tensor[DType.float64](2, 2)
    A[0, 0] = cos(pi/3)
    A[0, 1] = -sin(pi/3)
    A[1, 0] = sin(pi/3)
    A[1, 1] = cos(pi/3)
    print("The matrix A is:")
    print(A)
    print()
    print("The matrix square root of A is:")
    print(A.sqrt())
    print()
    print("The square of the last matrix is:")
    print(A.sqrt() * A.sqrt())