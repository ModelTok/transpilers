// Translation of C++ failtest. Expected to fail to build.

from ...Eigen.Core import Map, MatrixXf

alias EIGEN_SHOULD_FAIL_TO_BUILD = True

def foo(ptr: Float32*):
    Map[const MatrixXf](ptr, 1, 1).coeffRef(0,0) = 1.0

def main():
