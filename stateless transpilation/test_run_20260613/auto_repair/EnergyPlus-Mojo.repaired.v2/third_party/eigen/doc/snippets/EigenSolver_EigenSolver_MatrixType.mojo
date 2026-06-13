from memory import memset_zero
from math import sqrt, cos, sin, abs, max, min, pow, exp, log, pi
from complex import ComplexFloat64 as complex
from eigen import MatrixXd, MatrixXcd, VectorXcd, EigenSolver

def main() raises:
    var A = MatrixXd.Random(6,6)
    print("Here is a random 6x6 matrix, A:")
    print(A)
    print()
    var es = EigenSolver[MatrixXd](A)
    print("The eigenvalues of A are:")
    print(es.eigenvalues())
    print("The matrix of eigenvectors, V, is:")
    print(es.eigenvectors())
    print()
    var lambda = complex(es.eigenvalues()[0])
    print("Consider the first eigenvalue, lambda = ", lambda)
    var v = es.eigenvectors().col(0)
    print("If v is the corresponding eigenvector, then lambda * v = ")
    print(lambda * v)
    print("... and A * v = ")
    print(A.cast[complex]() * v)
    print()
    var D = es.eigenvalues().asDiagonal()
    var V = es.eigenvectors()
    print("Finally, V * D * V^(-1) = ")
    print(V * D * V.inverse())