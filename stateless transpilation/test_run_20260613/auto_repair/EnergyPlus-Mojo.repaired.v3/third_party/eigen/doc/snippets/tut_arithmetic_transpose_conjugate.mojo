from third_party.eigen.Eigen import MatrixXcf, Random, transpose, conjugate, adjoint
from third_party.eigen.Eigen import cout, endl

var a = MatrixXcf.Random(2,2)
cout << "Here is the matrix a\n" << a << endl
cout << "Here is the matrix a^T\n" << a.transpose() << endl
cout << "Here is the conjugate of a\n" << a.conjugate() << endl
cout << "Here is the matrix a^*\n" << a.adjoint() << endl