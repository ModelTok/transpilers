from third_party.eigen.Eigen import MatrixXd, EigenSolver
from third_party.eigen.Eigen import cout

def main():
    var A = MatrixXd.Random(6,6)
    cout << "Here is a random 6x6 matrix, A:" << endl << A << endl << endl
    var es = EigenSolver[MatrixXd](A)
    var D = es.pseudoEigenvalueMatrix()
    var V = es.pseudoEigenvectors()
    cout << "The pseudo-eigenvalue matrix D is:" << endl << D << endl
    cout << "The pseudo-eigenvector matrix V is:" << endl << V << endl
    cout << "Finally, V * D * V^(-1) = " << endl << V * D * V.inverse() << endl