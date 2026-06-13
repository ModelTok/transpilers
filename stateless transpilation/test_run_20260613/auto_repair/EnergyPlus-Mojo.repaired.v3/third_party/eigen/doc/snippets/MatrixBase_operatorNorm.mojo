from third_party.eigen.Eigen import MatrixXd, Ones

var ones = MatrixXd.Ones(3, 3)
print("The operator norm of the 3x3 matrix of ones is ", ones.operatorNorm())