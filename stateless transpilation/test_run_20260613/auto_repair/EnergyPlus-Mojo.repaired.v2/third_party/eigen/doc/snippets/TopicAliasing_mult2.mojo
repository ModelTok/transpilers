from memory import memset_zero
from tensor import Tensor
from sys import print

def main() raises:
    var matA = Tensor[DType.float32](2, 2)
    var matB = Tensor[DType.float32](2, 2)
    matA[0, 0] = 2.0
    matA[0, 1] = 0.0
    matA[1, 0] = 0.0
    matA[1, 1] = 2.0
    matB = matA * matA
    print(matB)
    print()
    print()
    matB.noalias() = matA * matA
    print(matB)