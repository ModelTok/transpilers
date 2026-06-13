from Eigen.Dense import Matrix2f, SelfAdjointEigenSolver, Success
from iostream import cout, endl
from cstdlib import abort

def main() raises:
    var A = Matrix2f()
    A << 1, 2, 2, 3
    cout << "Here is the matrix A:\n" << A << endl
    var eigensolver = SelfAdjointEigenSolver[Matrix2f](A)
    if eigensolver.info() != Success:
        abort()
    cout << "The eigenvalues of A are:\n" << eigensolver.eigenvalues() << endl
    cout << "Here's a matrix whose columns are eigenvectors of A \n"
         << "corresponding to these eigenvalues:\n"
         << eigensolver.eigenvectors() << endl