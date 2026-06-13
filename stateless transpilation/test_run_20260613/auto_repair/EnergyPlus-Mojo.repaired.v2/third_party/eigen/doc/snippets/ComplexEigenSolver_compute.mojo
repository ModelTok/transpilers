from memory import memset_zero
from ctypes import CComplex
from complex import ComplexFloat64 as complex128
from complex import ComplexFloat32 as complex64
from numpy.core.multiarray import ndarray
import utils

# Eigen-like aliases
type MatrixXcf = ndarray  # placeholder
type VectorXcf = ndarray  # placeholder

def main() raises:
    var A = MatrixXcf.Random(4,4)
    print("Here is a random 4x4 matrix, A:")
    print(A)
    print()

    var ces = ComplexEigenSolver[MatrixXcf]()
    ces.compute(A)
    print("The eigenvalues of A are:")
    print(ces.eigenvalues())
    print("The matrix of eigenvectors, V, is:")
    print(ces.eigenvectors())
    print()

    var lambda = complex64(ces.eigenvalues()[0])
    print("Consider the first eigenvalue, lambda = ", lambda)
    var v = VectorXcf(ces.eigenvectors().col(0))
    print("If v is the corresponding eigenvector, then lambda * v = ")
    print(lambda * v)
    print("... and A * v = ")
    print(A * v)
    print()

    print("Finally, V * D * V^(-1) = ")
    print(ces.eigenvectors() * ces.eigenvalues().asDiagonal() * ces.eigenvectors().inverse())