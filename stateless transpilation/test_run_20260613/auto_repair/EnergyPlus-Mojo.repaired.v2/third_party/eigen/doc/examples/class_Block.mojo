from Eigen.Core import *
from MojoStd import print, endl

def topLeftCorner[Derived: type](inout m: MatrixBase[Derived], rows: Int, cols: Int) -> Block[Derived]:
    return Block[Derived](m.derived(), 0, 0, rows, cols)

def topLeftCorner[Derived: type](m: MatrixBase[Derived], rows: Int, cols: Int) -> Block[Derived]:
    return Block[Derived](m.derived(), 0, 0, rows, cols)

def main():
    var m = Matrix4d.identity()
    print(topLeftCorner(4 * m, 2, 3))  # calls the const version
    topLeftCorner(m, 2, 3) *= 5        # calls the non-const version
    print("Now the matrix m is:", m)