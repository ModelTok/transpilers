from memory import memset_zero
from random import rand
from math import sqrt
from sys import print

def main() raises:
    var A = MatrixXf.Random(3, 2)
    print("Here is the matrix A:\n", A)
    var b = VectorXf.Random(3)
    print("Here is the right hand side b:\n", b)
    print("The least-squares solution is:\n",
          A.bdcSvd(ComputeThinU | ComputeThinV).solve(b))