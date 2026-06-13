from ...Eigen.Cholesky import LDLT, Matrix, Dynamic

alias EIGEN_SHOULD_FAIL_TO_BUILD = False
alias SCALAR = Int if EIGEN_SHOULD_FAIL_TO_BUILD else Float32

def main():
    let ldlt = LDLT[Matrix[SCALAR, Dynamic, Dynamic]](Matrix[SCALAR, Dynamic, Dynamic].Random(10,10))