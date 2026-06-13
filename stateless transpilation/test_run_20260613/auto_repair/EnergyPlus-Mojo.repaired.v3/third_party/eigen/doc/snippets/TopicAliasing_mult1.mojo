from memory import memset_zero
from tensor import Tensor
from math import sqrt

alias MatrixXf = Tensor[DType.float32, 2]

def main() raises:
    var matA = MatrixXf(2, 2)
    matA[0, 0] = 2.0
    matA[0, 1] = 0.0
    matA[1, 0] = 0.0
    matA[1, 1] = 2.0
    matA = matA * matA
    print(matA)