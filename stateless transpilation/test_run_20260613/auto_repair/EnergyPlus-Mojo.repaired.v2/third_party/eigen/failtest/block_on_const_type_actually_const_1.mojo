from ...Eigen.Core import *
# ifdef EIGEN_SHOULD_FAIL_TO_BUILD
# define CV_QUALIFIER const
# else
# define CV_QUALIFIER
# endif
using Eigen:
def foo():
    var m: MatrixXf
    Block[CV_QUALIFIER MatrixXf, 3, 3](m, 0, 0).coeffRef(0, 0) = 1.0f
def main():
