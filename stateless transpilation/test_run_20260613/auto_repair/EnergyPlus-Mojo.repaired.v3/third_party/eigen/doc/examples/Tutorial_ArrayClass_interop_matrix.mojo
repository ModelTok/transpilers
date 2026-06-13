from Eigen.Dense import MatrixXf
from iostream import cout
from Eigen.Dense import internal

def main() raises:
    var m = MatrixXf(2, 2)
    var n = MatrixXf(2, 2)
    var result = MatrixXf(2, 2)
    m << 1, 2, 3, 4
    n << 5, 6, 7, 8
    result = m * n
    cout << "-- Matrix m*n: --" << endl << result << endl << endl
    result = m.array() * n.array()
    cout << "-- Array m*n: --" << endl << result << endl << endl
    result = m.cwiseProduct(n)
    cout << "-- With cwiseProduct: --" << endl << result << endl << endl
    result = m.array() + 4
    cout << "-- Array m + 4: --" << endl << result << endl << endl