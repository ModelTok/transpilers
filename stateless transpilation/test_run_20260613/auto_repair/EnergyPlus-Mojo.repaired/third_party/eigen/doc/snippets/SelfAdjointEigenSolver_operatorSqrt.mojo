from Eigen import MatrixXd, SelfAdjointEigenSolver
from iostream import cout, endl

var X = MatrixXd.Random(4, 4)
var A = X * X.transpose()
cout << "Here is a random positive-definite matrix, A:" << endl << A << endl << endl
var es = SelfAdjointEigenSolver[MatrixXd](A)
var sqrtA = es.operatorSqrt()
cout << "The square root of A is: " << endl << sqrtA << endl
cout << "If we square this, we get: " << endl << sqrtA * sqrtA << endl