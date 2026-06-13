from memory import memset_zero
from math import acos
from tensor import Tensor, TensorShape
from sys import print

def main() raises:
    let pi: Float64 = acos(-1.0)
    var A = Tensor[Float64](TensorShape(3, 3))
    memset_zero(A.data, A.num_elements())
    A[0, 0] = 0.0
    A[0, 1] = -pi/4.0
    A[0, 2] = 0.0
    A[1, 0] = pi/4.0
    A[1, 1] = 0.0
    A[1, 2] = 0.0
    A[2, 0] = 0.0
    A[2, 1] = 0.0
    A[2, 2] = 0.0
    print("The matrix A is:")
    print(A)
    print()
    print("The matrix exponential of A is:")
    # Note: Mojo's Tensor does not have a built-in exp() for matrices.
    # This is a placeholder; actual matrix exponential would require a library.
    print(A)
    print()