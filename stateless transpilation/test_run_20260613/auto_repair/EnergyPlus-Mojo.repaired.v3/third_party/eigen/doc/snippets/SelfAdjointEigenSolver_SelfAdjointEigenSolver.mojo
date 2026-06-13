from Eigen import SelfAdjointEigenSolver, Matrix4f
from Eigen import Matrix4f as Matrix4f
from iostream import cout
from Eigen import endl

var es = SelfAdjointEigenSolver[Matrix4f]()
var X = Matrix4f.Random(4,4)
var A = X + X.transpose()
es.compute(A)
cout << "The eigenvalues of A are: " << es.eigenvalues().transpose() << endl
es.compute(A + Matrix4f.Identity(4,4)) # re-use es to compute eigenvalues of A+I
cout << "The eigenvalues of A+I are: " << es.eigenvalues().transpose() << endl