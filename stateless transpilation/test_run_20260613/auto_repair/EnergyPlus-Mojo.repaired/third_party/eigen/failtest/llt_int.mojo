from ...Eigen.Cholesky import LLT, Matrix
from ...Eigen.Core import Dynamic

alias SCALAR = Int32 if __flag__("EIGEN_SHOULD_FAIL_TO_BUILD") else Float32

def main() raises:
    var llt = LLT[Matrix[SCALAR, Dynamic, Dynamic]](Matrix[SCALAR, Dynamic, Dynamic].Random(10, 10))