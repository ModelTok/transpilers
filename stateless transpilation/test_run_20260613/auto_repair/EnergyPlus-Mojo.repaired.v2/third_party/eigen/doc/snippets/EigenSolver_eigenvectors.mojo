from ...Eigen import MatrixXd, EigenSolver

var ones = MatrixXd.Ones(3, 3)
var es = EigenSolver[MatrixXd](ones)
print("The first eigenvector of the 3x3 matrix of ones is:")
print(es.eigenvectors().col(0))