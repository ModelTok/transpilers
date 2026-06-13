from Eigen.Dense import Matrix2d
from memory import Pointer
from sys import int_type

def main() raises:
    var mat = Matrix2d()
    mat << 1, 2,
           3, 4
    print("Here is mat.sum():       ", mat.sum())
    print("Here is mat.prod():      ", mat.prod())
    print("Here is mat.mean():      ", mat.mean())
    print("Here is mat.minCoeff():  ", mat.minCoeff())
    print("Here is mat.maxCoeff():  ", mat.maxCoeff())
    print("Here is mat.trace():     ", mat.trace())