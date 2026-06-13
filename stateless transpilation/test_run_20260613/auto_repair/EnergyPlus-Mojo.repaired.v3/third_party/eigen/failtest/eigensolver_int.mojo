from ...Eigen.Eigenvalues import *
# ifdef EIGEN_SHOULD_FAIL_TO_BUILD
# define SCALAR int
# else
# define SCALAR float
# endif
using Eigen
def main():
    var eig = EigenSolver[Matrix[SCALAR, Dynamic, Dynamic]](Matrix[SCALAR, Dynamic, Dynamic].Random(10, 10))