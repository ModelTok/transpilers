from Eigen.Dense import Eigen
import sys

def main() raises:
    var mat = Eigen.MatrixXf(2, 4)
    var v = Eigen.VectorXf(2)
    mat << 1, 2, 6, 9, 3, 1, 7, 2
    v << 0, 1
    mat.colwise() += v
    print("Broadcasting result: ")
    print(mat)