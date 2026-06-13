from Eigen.Core import *

@parameter
alias EIGEN_SHOULD_FAIL_TO_BUILD: Bool = True

alias CV_QUALIFIER = "const" if EIGEN_SHOULD_FAIL_TO_BUILD else ""

def foo(ptr: DTypePointer[DType.float32] if not EIGEN_SHOULD_FAIL_TO_BUILD else Pointer[float32, mut=False]):
    _ = Map[Matrix3f](ptr)

def main():
