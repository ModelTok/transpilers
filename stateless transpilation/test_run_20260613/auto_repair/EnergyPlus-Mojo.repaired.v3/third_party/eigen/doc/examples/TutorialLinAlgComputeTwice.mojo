from memory import memset_zero
from sys import print
from Eigen.Dense import Matrix2f, LLT

def main() raises:
    var A = Matrix2f()
    var b = Matrix2f()
    var llt = LLT[Matrix2f]()
    A << 2, -1, -1, 3
    b << 1, 2, 3, 1
    print("Here is the matrix A:\n", A, "\n")
    print("Here is the right hand side b:\n", b, "\n")
    print("Computing LLT decomposition...")
    llt.compute(A)
    print("The solution is:\n", llt.solve(b), "\n")
    A(1,1) += 1
    print("The matrix A is now:\n", A, "\n")
    print("Computing LLT decomposition...")
    llt.compute(A)
    print("The solution is now:\n", llt.solve(b), "\n")