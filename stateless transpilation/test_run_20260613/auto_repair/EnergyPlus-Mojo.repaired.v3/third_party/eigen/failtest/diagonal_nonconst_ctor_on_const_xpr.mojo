from ...Eigen.Core import *
# ifdef EIGEN_SHOULD_FAIL_TO_BUILD
# define CV_QUALIFIER const
# else
# define CV_QUALIFIER
# endif
using Eigen:
def foo(owned CV_QUALIFIER Matrix3d &m):
    Diagonal<Matrix3d> d(m)
def main() raises:
