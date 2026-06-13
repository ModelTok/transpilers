from ...Eigen.Core import *

# ifdef EIGEN_SHOULD_FAIL_TO_BUILD
# define CV_QUALIFIER const
# else
# define CV_QUALIFIER
# endif

alias CV_QUALIFIER = const  # EIGEN_SHOULD_FAIL_TO_BUILD is defined

using Eigen = Eigen

def foo(m: CV_QUALIFIER Matrix3d &):
    var t = TriangularView[Matrix3d, Upper](m)

def main():
