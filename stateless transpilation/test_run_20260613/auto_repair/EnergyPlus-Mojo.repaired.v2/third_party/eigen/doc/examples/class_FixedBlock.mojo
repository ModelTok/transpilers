from Eigen.Core import *
from iostream import *
using Eigen
using std

def topLeft2x2Corner[Derived: AnyType](m: MatrixBase[Derived]^) -> Block[Derived, 2, 2]:
    return Block[Derived, 2, 2](m.derived(), 0, 0)

def topLeft2x2Corner[Derived: AnyType](m: MatrixBase[Derived]^) -> Block[const Derived, 2, 2]:
    return Block[const Derived, 2, 2](m.derived(), 0, 0)

def main(argc: Int, argv: Pointer[Pointer[Int8]]^) -> Int:
    var m: Matrix3d = Matrix3d.Identity()
    cout << topLeft2x2Corner(4*m) << endl # calls the const version
    topLeft2x2Corner(m) *= 2              # calls the non-const version
    cout << "Now the matrix m is:" << endl << m << endl
    return 0