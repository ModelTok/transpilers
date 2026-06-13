from third_party.eigen.Eigen import MatrixXd, EigenSolver

var ones = MatrixXd.Ones(3, 3)
var es = EigenSolver[MatrixXd](ones, False)
print("The eigenvalues of the 3x3 matrix of ones are:")
print(es.eigenvalues())