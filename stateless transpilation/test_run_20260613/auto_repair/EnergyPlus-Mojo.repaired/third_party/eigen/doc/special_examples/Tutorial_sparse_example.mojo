from Eigen import SparseMatrix, Triplet, VectorXd, SimplicialCholesky
from sys import stderr

alias SpMat = SparseMatrix[Float64]  # declares a column-major sparse matrix type of double
alias T = Triplet[Float64]           # declares a column-major sparse matrix type of double

def buildProblem(inout coefficients: List[T], inout b: VectorXd, n: Int32):
    ...

def saveAsBitmap(borrowed x: VectorXd, n: Int32, filename: Pointer[Int8]):
    ...

def main(argc: Int32, argv: Pointer[Pointer[Int8]]) -> Int32:
    if argc != 2:
        print("Error: expected one and only one argument.", file=stderr)
        return -1

    let n: Int32 = 300  # size of the image
    let m: Int32 = n * n  # number of unknowns (=number of pixels)

    var coefficients = List[T]()  # list of non-zeros coefficients
    var b = VectorXd(m)           # the right hand side-vector resulting from the constraints

    buildProblem(coefficients, b, n)

    var A = SpMat(m, m)
    A.setFromTriplets(coefficients.begin(), coefficients.end())

    var chol = SimplicialCholesky[SpMat](A)  # performs a Cholesky factorization of A
    var x = chol.solve(b)                    # use the factorization to solve for the given right hand side

    saveAsBitmap(x, n, argv[1])

    return 0