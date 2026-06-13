from Eigen.Dense import Matrix2d, Vector3d
from memory import Pointer
from IO import print

def main():
    var a = Matrix2d()
    a << (1, 2,
          3, 4)
    var v = Vector3d(1, 2, 3)
    print("a * 2.5 =\n", a * 2.5)
    print("0.1 * v =\n", 0.1 * v)
    print("Doing v *= 2;")
    v *= 2
    print("Now v =\n", v)