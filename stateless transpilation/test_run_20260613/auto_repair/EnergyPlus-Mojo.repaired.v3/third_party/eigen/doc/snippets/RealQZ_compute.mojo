from memory import memset_zero
from random import rand
from math import sqrt
from tensor import Tensor, TensorShape
from sys import print

# MatrixXf alias for Tensor[DType.float32, 2]
alias MatrixXf = Tensor[DType.float32, 2]

def random_matrix(n: Int, m: Int) -> MatrixXf:
    var mat = MatrixXf(TensorShape(n, m))
    for i in range(n):
        for j in range(m):
            mat[i, j] = rand[DType.float32]() * 2.0 - 1.0
    return mat

def main() raises:
    var A = random_matrix(4, 4)
    var B = random_matrix(4, 4)
    var qz = RealQZ[MatrixXf](4)  # preallocate space for 4x4 matrices
    qz.compute(A, B)  # A = Q S Z,  B = Q T Z
    print("A:\n", A, "\nB:\n", B, "\n")
    print("S:\n", qz.matrixS(), "\nT:\n", qz.matrixT(), "\n")
    print("Q:\n", qz.matrixQ(), "\nZ:\n", qz.matrixZ(), "\n")
    print("\nErrors:")
    print("|A-QSZ|: ", (A - qz.matrixQ() * qz.matrixS() * qz.matrixZ()).norm())
    print(", |B-QTZ|: ", (B - qz.matrixQ() * qz.matrixT() * qz.matrixZ()).norm())
    print("\n|QQ* - I|: ", (qz.matrixQ() * qz.matrixQ().adjoint() - MatrixXf.identity(4, 4)).norm())
    print(", |ZZ* - I|: ", (qz.matrixZ() * qz.matrixZ().adjoint() - MatrixXf.identity(4, 4)).norm())
    print("\n")