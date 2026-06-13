from ...Eigen.SVD import Matrix, BDCSVD, Dynamic

@parameter
if EIGEN_SHOULD_FAIL_TO_BUILD:
    alias SCALAR = Int32
else:
    alias SCALAR = Float32

def main() raises:
    var qr = BDCSVD[Matrix[SCALAR, Dynamic, Dynamic]](Matrix[SCALAR, Dynamic, Dynamic].Random(10, 10))