from ...Eigen.Core import *
# ifdef EIGEN_SHOULD_FAIL_TO_BUILD
# define CV_QUALIFIER const
# else
# define CV_QUALIFIER
# endif
using Eigen:
    def foo(m: CV_QUALIFIER Matrix3d &):
        Transpose[Matrix3d] t(m)
def main() raises:
