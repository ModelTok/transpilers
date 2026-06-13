from Eigen import MatrixXd, SelfAdjointEigenSolver

var ones = MatrixXd.Ones(3, 3)
var es = SelfAdjointEigenSolver[MatrixXd](ones)
print("The first eigenvector of the 3x3 matrix of ones is:")
print(es.eigenvectors().col(1))