from Eigen.Dense import Matrix2d, FullPivLU
from iostream import cout, endl

def main() raises:
    var A = Matrix2d()
    A << 2, 1,
        2, 0.9999999999
    var lu = FullPivLU[Matrix2d](A)
    cout << "By default, the rank of A is found to be " << lu.rank() << endl
    lu.setThreshold(1e-5)
    cout << "With threshold 1e-5, the rank of A is found to be " << lu.rank() << endl