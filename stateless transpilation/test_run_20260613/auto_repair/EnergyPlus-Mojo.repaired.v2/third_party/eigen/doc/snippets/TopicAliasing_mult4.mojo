from memory import memset_zero
from tensor import Tensor, TensorShape
from math import abs

alias MatrixXf = Tensor[DType.float32]

def main() raises:
    var A = MatrixXf(2, 2)
    var B = MatrixXf(3, 2)
    B[0, 0] = 2.0
    B[0, 1] = 0.0
    B[1, 0] = 0.0
    B[1, 1] = 3.0
    B[2, 0] = 1.0
    B[2, 1] = 1.0
    A[0, 0] = 2.0
    A[0, 1] = 0.0
    A[1, 0] = 0.0
    A[1, 1] = -2.0
    A = (B * A).cwiseAbs()
    print(A)