from Eigen.Core import MatrixXi, setRandom, middleCols
from iostream import cout, endl

def main():
    N: Int = 5
    A = MatrixXi(N, N)
    A.setRandom()
    cout << "A =\n" << A << '\n' << endl
    cout << "A(1..3,:) =\n" << A.middleCols(1, 3) << endl
    return 0