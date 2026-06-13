from linear import Matrix, LLT

alias MatrixXd = Matrix[Float64]

def main() raises:
    var A = MatrixXd(3, 3, [4, -1, 2, -1, 6, 0, 2, 0, 5])
    print("The matrix A is")
    print(A)
    var lltOfA = LLT[MatrixXd](A)  # compute the Cholesky decomposition of A
    var L = lltOfA.matrixL()  # retrieve factor L  in the decomposition
    print("The Cholesky factor L is")
    print(L)
    print("To check this, let us compute L * L.transpose()")
    print(L * L.T)
    print("This should equal the matrix A")