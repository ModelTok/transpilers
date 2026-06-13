var ones = MatrixXd.Ones(3, 3)
var es = SelfAdjointEigenSolver[MatrixXd](ones)
cout << "The eigenvalues of the 3x3 matrix of ones are:" << endl << es.eigenvalues() << endl