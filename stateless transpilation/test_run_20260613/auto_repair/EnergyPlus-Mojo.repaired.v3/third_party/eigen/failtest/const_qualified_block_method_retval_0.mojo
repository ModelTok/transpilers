from ...Eigen.Core import *
#ifdef EIGEN_SHOULD_FAIL_TO_BUILD
#define CV_QUALIFIER const
#else
#define CV_QUALIFIER
#endif
def foo(CV_QUALIFIER Matrix3d &m):
    Block[Matrix3d, 3, 3] b(m.block[3, 3](0, 0))

def main() {}