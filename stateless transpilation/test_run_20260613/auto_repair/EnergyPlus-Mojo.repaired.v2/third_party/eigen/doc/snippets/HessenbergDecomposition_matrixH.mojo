from Eigen import Matrix4f, MatrixXf, HessenbergDecomposition
from iostream import cout

A = MatrixXf.Random(4,4)
cout << "Here is a random 4x4 matrix:" << endl << A << endl
hessOfA = HessenbergDecomposition[MatrixXf](A)
H = hessOfA.matrixH()
cout << "The Hessenberg matrix H is:" << endl << H << endl
Q = hessOfA.matrixQ()
cout << "The orthogonal matrix Q is:" << endl << Q << endl
cout << "Q H Q^T is:" << endl << Q * H * Q.transpose() << endl