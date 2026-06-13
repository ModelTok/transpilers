from Eigen.Dense import MatrixXf
from iostream import cout, endl

def main() raises:
    var m = MatrixXf(2, 2)
    var n = MatrixXf(2, 2)
    var result = MatrixXf(2, 2)
    m << 1, 2,
         3, 4
    n << 5, 6,
         7, 8
    result = (m.array() + 4).matrix() * m
    cout << "-- Combination 1: --" << endl << result << endl << endl
    result = (m.array() * n.array()).matrix() * m
    cout << "-- Combination 2: --" << endl << result << endl << endl