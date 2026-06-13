from Eigen import MatrixXd, PartialPivLU

def main():
    var A = MatrixXd.Random(3,3)
    var B = MatrixXd.Random(3,2)
    print("Here is the invertible matrix A:")
    print(A)
    print("Here is the matrix B:")
    print(B)
    var X = A.lu().solve(B)
    print("Here is the (unique) solution X to the equation AX=B:")
    print(X)
    print("Relative error: ", (A*X-B).norm() / B.norm())