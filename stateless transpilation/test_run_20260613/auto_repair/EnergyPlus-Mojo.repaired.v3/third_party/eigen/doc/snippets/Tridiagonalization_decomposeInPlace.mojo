from Eigen import MatrixXd, VectorXd, internal

let X = MatrixXd.Random(5,5)
let A = X + X.transpose()
print("Here is a random symmetric 5x5 matrix:\n", A, "\n")

let diag = VectorXd(5)
let subdiag = VectorXd(4)
internal.tridiagonalization_inplace(A, diag, subdiag, True)
print("The orthogonal matrix Q is:\n", A, "\n")
print("The diagonal of the tridiagonal matrix T is:\n", diag, "\n")
print("The subdiagonal of the tridiagonal matrix T is:\n", subdiag, "\n")