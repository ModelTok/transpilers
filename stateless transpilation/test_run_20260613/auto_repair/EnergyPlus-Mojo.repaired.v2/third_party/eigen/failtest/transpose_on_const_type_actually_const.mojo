// #include "../Eigen/Core"
// #ifdef EIGEN_SHOULD_FAIL_TO_BUILD
// #define CV_QUALIFIER const
// #else
// #define CV_QUALIFIER
// #endif
from ...Eigen.Core import *
def foo():
    var m: MatrixXf
    Transpose[CV_QUALIFIER MatrixXf](m).coeffRef(0, 0) = 1.0
def main(): pass