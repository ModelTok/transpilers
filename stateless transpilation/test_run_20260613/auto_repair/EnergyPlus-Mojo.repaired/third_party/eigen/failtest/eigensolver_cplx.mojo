from ...Eigen.Eigenvalues import EigenSolver, Matrix, Dynamic
from complex import Complex

alias EIGEN_SHOULD_FAIL_TO_BUILD = False

alias SCALAR = Complex[Float64] if EIGEN_SHOULD_FAIL_TO_BUILD else Float32

def main():
    var eig = EigenSolver[Matrix[SCALAR, Dynamic, Dynamic]](Matrix[SCALAR, Dynamic, Dynamic].Random(10, 10))