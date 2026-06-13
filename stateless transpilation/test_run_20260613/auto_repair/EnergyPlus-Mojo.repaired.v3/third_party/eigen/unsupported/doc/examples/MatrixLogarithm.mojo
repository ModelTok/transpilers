from unsupported.Eigen.MatrixFunctions import *
from math import sqrt

def main():
    var A = MatrixXd(3, 3)
    A << 0.5*sqrt(2), -0.5*sqrt(2), 0,
         0.5*sqrt(2),  0.5*sqrt(2), 0,
         0,            0,           1
    print("The matrix A is:\n", A, "\n")
    print("The matrix logarithm of A is:\n", A.log(), "\n")