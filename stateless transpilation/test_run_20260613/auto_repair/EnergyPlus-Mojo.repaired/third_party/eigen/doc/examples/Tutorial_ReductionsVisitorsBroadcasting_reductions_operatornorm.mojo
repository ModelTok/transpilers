from eigen import MatrixXf
from memory import Pointer
from io import cout, endl
from eigen.Dense import *

def main():
    var m = MatrixXf(2, 2)
    m << 1, -2,
         -3, 4
    cout << "1-norm(m)     = " << m.cwiseAbs().colwise().sum().maxCoeff()
         << " == "             << m.colwise().lpNorm[1]().maxCoeff() << endl
    cout << "infty-norm(m) = " << m.cwiseAbs().rowwise().sum().maxCoeff()
         << " == "             << m.rowwise().lpNorm[1]().maxCoeff() << endl