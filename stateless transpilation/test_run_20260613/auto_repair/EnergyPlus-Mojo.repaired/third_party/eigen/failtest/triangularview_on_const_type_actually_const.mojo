from ...Eigen.Core import *

@parameter
if EIGEN_SHOULD_FAIL_TO_BUILD:
    alias CV_QUALIFIER = const MatrixXf
else:
    alias CV_QUALIFIER = MatrixXf

def foo():
    var m = MatrixXf()
    TriangularView[CV_QUALIFIER, Upper](m).coeffRef(0, 0) = 1.0f

def main():
