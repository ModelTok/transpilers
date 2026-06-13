from Eigen.Dense import Matrix4d
from memory import Pointer
from sys import int64

def main() raises:
    var m = Matrix4d()
    m.resize(4, 4)  # no operation
    print("The matrix m is of size ", m.rows(), "x", m.cols())