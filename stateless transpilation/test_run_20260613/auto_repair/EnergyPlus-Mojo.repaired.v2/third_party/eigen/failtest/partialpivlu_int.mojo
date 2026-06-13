# Equivalent of C++ preprocessor conditional
alias EIGEN_SHOULD_FAIL_TO_BUILD = True  # Defined for fail test

alias SCALAR = Int32 if EIGEN_SHOULD_FAIL_TO_BUILD else Float32

from Eigen import Matrix, PartialPivLU

alias Dynamic = -1  # Eigen constant for dynamic size

def main() raises:
    var lu = PartialPivLU[Matrix[SCALAR, Dynamic, Dynamic]](Matrix[SCALAR, Dynamic, Dynamic].Random(10, 10))