from ...Eigen.Core import *
from Eigen import *
#ifdef EIGEN_SHOULD_FAIL_TO_BUILD
#define CV_QUALIFIER const
#else
#define CV_QUALIFIER
#endif

def foo(CV_QUALIFIER Pointer[float] ptr, DenseIndex rows, DenseIndex cols):
    var m = Map[MatrixXf, Aligned, InnerStride[2]](ptr, rows, cols, InnerStride[2]())

def main() -> Int32:
    return 0