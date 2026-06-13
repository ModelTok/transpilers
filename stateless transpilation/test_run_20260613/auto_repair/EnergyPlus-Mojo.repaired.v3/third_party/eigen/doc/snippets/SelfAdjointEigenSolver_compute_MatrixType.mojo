from third_party.eigen.Eigen import SelfAdjointEigenSolver, MatrixXf

var es = SelfAdjointEigenSolver[MatrixXf](4)
var X = MatrixXf.Random(4, 4)
var A = X + X.transpose()
es.compute(A)
print("The eigenvalues of A are: ", es.eigenvalues().transpose())
es.compute(A + MatrixXf.Identity(4, 4))  # re-use es to compute eigenvalues of A+I
print("The eigenvalues of A+I are: ", es.eigenvalues().transpose())