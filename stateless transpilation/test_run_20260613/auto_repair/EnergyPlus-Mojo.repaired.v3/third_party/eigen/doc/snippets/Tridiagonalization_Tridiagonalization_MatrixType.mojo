from third_party.eigen.Eigen import MatrixXd, Tridiagonalization
from third_party.eigen.Eigen import cout

var X = MatrixXd.Random(5,5)
var A = X + X.transpose()
cout << "Here is a random symmetric 5x5 matrix:" << endl << A << endl << endl
var triOfA = Tridiagonalization[MatrixXd](A)
var Q = triOfA.matrixQ()
cout << "The orthogonal matrix Q is:" << endl << Q << endl
var T = triOfA.matrixT()
cout << "The tridiagonal matrix T is:" << endl << T << endl << endl
cout << "Q * T * Q^T = " << endl << Q * T * Q.transpose() << endl