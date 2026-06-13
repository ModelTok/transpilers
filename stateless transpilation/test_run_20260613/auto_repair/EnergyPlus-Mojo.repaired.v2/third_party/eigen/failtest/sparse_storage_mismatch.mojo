from ...Eigen.Sparse import SparseMatrix

alias Mat1 = SparseMatrix[float64, ColMajor]
alias Mat2 = SparseMatrix[float64, RowMajor]

def main():
    var a = Mat1(10, 10)
    var b = Mat2(10, 10)
    a += b