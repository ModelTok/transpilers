from ...Eigen.Core import *
alias EIGEN_SHOULD_FAIL_TO_BUILD = True

@parameter
if EIGEN_SHOULD_FAIL_TO_BUILD:
    alias CV_QUALIFIER = "const"
    def foo(m: borrowed Matrix3d):
        var b = Diagonal[Matrix3d](m.diagonal())
else:
    alias CV_QUALIFIER = ""
    def foo(m: inout Matrix3d):
        var b = Diagonal[Matrix3d](m.diagonal())

def main(): pass