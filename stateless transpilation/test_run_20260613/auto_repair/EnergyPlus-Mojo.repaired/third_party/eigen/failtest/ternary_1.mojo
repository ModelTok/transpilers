from ...Eigen.Core import *

def main(argc: Int, argv: Pointer[Pointer[UInt8]]) raises:
    var a = VectorXf(10)
    var b = VectorXf(10)
    #ifdef EIGEN_SHOULD_FAIL_TO_BUILD
    b = argc>1 ? 2*a : -a
    #else
    b = argc>1 ? 2*a : VectorXf(-a)
    #endif