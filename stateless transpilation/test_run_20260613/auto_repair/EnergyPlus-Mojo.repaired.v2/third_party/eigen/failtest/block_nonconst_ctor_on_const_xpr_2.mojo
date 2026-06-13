from ...Eigen.Core import *
# ifdef EIGEN_SHOULD_FAIL_TO_BUILD
# define CV_QUALIFIER const
# else
# define CV_QUALIFIER
# endif
using Eigen:
def foo(CV_QUALIFIER Matrix3d &m):
    Block[Matrix3d, 3, 1](b, m, 0)
def main():
