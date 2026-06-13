from ...Eigen.SVD import *

alias EIGEN_SHOULD_FAIL_TO_BUILD = True
alias SCALAR = int if EIGEN_SHOULD_FAIL_TO_BUILD else float

def main() -> Int:
    var qr = JacobiSVD[Matrix[SCALAR, Dynamic, Dynamic]](Matrix[SCALAR, Dynamic, Dynamic].Random(10, 10))
    return 0