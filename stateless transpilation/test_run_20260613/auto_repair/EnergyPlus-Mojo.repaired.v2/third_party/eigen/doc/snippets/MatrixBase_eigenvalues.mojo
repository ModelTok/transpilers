from ...Eigen import MatrixXd, VectorXcd

var ones: MatrixXd = MatrixXd.Ones(3,3)
var eivals: VectorXcd = ones.eigenvalues()
print("The eigenvalues of the 3x3 matrix of ones are:")
print(eivals)