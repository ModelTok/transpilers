from ...Eigen.Sparse import SparseMatrix, Ref

alias EIGEN_SHOULD_FAIL_TO_BUILD: Bool = True

def call_ref(a: Ref[SparseMatrix[float32]]):

def main():
    var A = SparseMatrix[float32](10, 10)
    @parameter
    if EIGEN_SHOULD_FAIL_TO_BUILD:
        call_ref(A.row(3))
    else:
        call_ref(A.col(3))
<<<FILE>>>