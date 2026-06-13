from Eigen import MatrixXd, RealSchur

def main():
    var A = MatrixXd.Random(6,6)
    print("Here is a random 6x6 matrix, A:")
    print(A)
    print()
    var schur = RealSchur[MatrixXd](A)
    print("The orthogonal matrix U is:")
    print(schur.matrixU())
    print("The quasi-triangular matrix T is:")
    print(schur.matrixT())
    print()
    var U = schur.matrixU()
    var T = schur.matrixT()
    print("U * T * U^T = ")
    print(U * T * U.transpose())