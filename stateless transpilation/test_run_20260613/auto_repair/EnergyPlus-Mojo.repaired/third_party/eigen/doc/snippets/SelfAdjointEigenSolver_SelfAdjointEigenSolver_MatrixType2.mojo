from Eigen import MatrixXd, VectorXd, GeneralizedSelfAdjointEigenSolver
from Eigen import Random, transpose, cout, endl

var X = MatrixXd.Random(5,5)
var A = X + X.transpose()
cout << "Here is a random symmetric matrix, A:" << endl << A << endl
X = MatrixXd.Random(5,5)
var B = X * X.transpose()
cout << "and a random postive-definite matrix, B:" << endl << B << endl << endl
var es = GeneralizedSelfAdjointEigenSolver[MatrixXd](A,B)
cout << "The eigenvalues of the pencil (A,B) are:" << endl << es.eigenvalues() << endl
cout << "The matrix of eigenvectors, V, is:" << endl << es.eigenvectors() << endl << endl
var lambda = es.eigenvalues()[0]
cout << "Consider the first eigenvalue, lambda = " << lambda << endl
var v = es.eigenvectors().col(0)
cout << "If v is the corresponding eigenvector, then A * v = " << endl << A * v << endl
cout << "... and lambda * B * v = " << endl << lambda * B * v << endl << endl