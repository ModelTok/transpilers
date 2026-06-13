from Eigen import Matrix4cd, MatrixPower
from iostream import cout, endl

def main() raises:
    var A = Matrix4cd.Random()
    var Apow = MatrixPower[Matrix4cd](A)
    cout << "The matrix A is:\n" << A << "\n\n" \
         "A^3.1 is:\n" << Apow(3.1) << "\n\n" \
         "A^3.3 is:\n" << Apow(3.3) << "\n\n" \
         "A^3.7 is:\n" << Apow(3.7) << "\n\n" \
         "A^3.9 is:\n" << Apow(3.9) << endl
    return 0