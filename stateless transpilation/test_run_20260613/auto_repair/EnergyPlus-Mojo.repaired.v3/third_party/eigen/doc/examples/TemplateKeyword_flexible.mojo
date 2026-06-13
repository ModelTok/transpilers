// Include equivalent: assume we have Eigen module available
from Eigen import *

def copyUpperTriangularPart[Derived1: AnyType, Derived2: AnyType](inout dst: MatrixBase[Derived1], src: MatrixBase[Derived2]):
    /* Note the 'template' keywords in the following line! */
    dst.triangularView[Upper]() = src.triangularView[Upper]()

def main():
    var m1 = MatrixXi.Ones(5, 5)
    var m2 = MatrixXi.Random(4, 4)
    print("m2 before copy:")
    print(m2)
    print()
    copyUpperTriangularPart(m2, m1.topLeftCorner(4, 4))
    print("m2 after copy:")
    print(m2)
    print()