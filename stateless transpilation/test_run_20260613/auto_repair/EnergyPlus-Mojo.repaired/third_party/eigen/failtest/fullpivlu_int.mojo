from ...Eigen.LU import Matrix, Dynamic, FullPivLU

alias EIGEN_SHOULD_FAIL_TO_BUILD = True
@parameter
if EIGEN_SHOULD_FAIL_TO_BUILD:
    alias SCALAR = Int32
else:
    alias SCALAR = Float32

def main():
    var lu = FullPivLU[Matrix[SCALAR, Dynamic, Dynamic]](Matrix[SCALAR, Dynamic, Dynamic].Random(10, 10))