from ...Eigen.Sparse import *
from Eigen.Sparse import Ref, SparseMatrix

def call_ref(a: Ref[SparseMatrix[float32]]):

def main():
    var A = SparseMatrix[float32](10, 10)
    #ifdef EIGEN_SHOULD_FAIL_TO_BUILD
    call_ref(A.transpose())
    #else
    call_ref(A)
    #endif