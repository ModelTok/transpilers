from memory import memset_zero
from math import sqrt
from random import random
from tensor import Tensor, TensorShape
from tensor.matrix import Matrix

alias MatrixXd = Matrix[Float64]

def main() raises:
    var X = MatrixXd.Random(4, 4)
    var A = X * X.transpose()
    print("Here is a random positive-definite matrix, A:")
    print(A)
    print()
    var es = SelfAdjointEigenSolver[MatrixXd](A)
    print("The inverse square root of A is: ")
    print(es.operatorInverseSqrt())
    print("We can also compute it with operatorSqrt() and inverse(). That yields: ")
    print(es.operatorSqrt().inverse())