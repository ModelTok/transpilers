from eigen import MatrixXcf, ComplexEigenSolver

def main():
    var ones = MatrixXcf.Ones(3,3)
    var ces = ComplexEigenSolver[MatrixXcf](ones)
    print("The first eigenvector of the 3x3 matrix of ones is:")
    print(ces.eigenvectors().col(1))