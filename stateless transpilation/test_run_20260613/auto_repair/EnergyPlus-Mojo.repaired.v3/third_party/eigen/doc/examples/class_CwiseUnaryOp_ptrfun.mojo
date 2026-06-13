from Eigen.Core import *
from iostream import *

def ramp(x: Float64) -> Float64:
    if x > 0:
        return x
    else:
        return 0

def main(argc: Int, argv: Pointer[Pointer[UInt8]]) -> Int:
    var m1: Matrix4d = Matrix4d.Random()
    cout << m1 << endl << "becomes: " << endl << m1.unaryExpr(ptr_fun(ramp)) << endl
    return 0