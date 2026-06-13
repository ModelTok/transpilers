from ...Eigen.Core import *

@parameter
var EIGEN_SHOULD_FAIL_TO_BUILD: Bool = False

def call_ref(a: Ref[VectorXf]):

def main():
    var A = MatrixXf(10, 10)
    @parameter
    if EIGEN_SHOULD_FAIL_TO_BUILD:
        call_ref(A.row(3))
    else:
        call_ref(A.col(3))