from ......Eigen import MatrixXd, Lower

var ones = MatrixXd.Ones(3, 3)
print("The operator norm of the 3x3 matrix of ones is ", ones.selfadjointView[Lower]().operatorNorm())