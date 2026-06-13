from ...Eigen.Core import *
from Eigen.Core import Ref, MatrixXf, OuterStride

def call_ref(a: Ref[MatrixXf, 0, OuterStride[]]):

def main():
    var A = MatrixXf(10, 10)
    #ifdef EIGEN_SHOULD_FAIL_TO_BUILD
    call_ref(A.transpose())
    #else
    call_ref(A)
    #endif