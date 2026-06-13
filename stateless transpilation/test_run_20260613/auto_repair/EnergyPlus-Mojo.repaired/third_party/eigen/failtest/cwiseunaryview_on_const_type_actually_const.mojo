from ...Eigen.Core import *
# ifdef EIGEN_SHOULD_FAIL_TO_BUILD
# define CV_QUALIFIER const
# else
# define CV_QUALIFIER
# endif
using Eigen:
def foo():
    var m: MatrixXf
    CwiseUnaryView[internal.scalar_real_ref_op[float64], CV_QUALIFIER MatrixXf](m).coeffRef(0, 0) = 1.0f
def main():
