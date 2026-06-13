from ...Eigen import MatrixXd, GeneralizedSelfAdjointEigenSolver, EigenvaluesOnly

var X = MatrixXd.Random(5, 5)
var A = X * X.transpose()
X = MatrixXd.Random(5, 5)
var B = X * X.transpose()
var es = GeneralizedSelfAdjointEigenSolver[MatrixXd](A, B, EigenvaluesOnly)
print("The eigenvalues of the pencil (A,B) are:")
print(es.eigenvalues())
es.compute(B, A, False)
print("The eigenvalues of the pencil (B,A) are:")
print(es.eigenvalues())