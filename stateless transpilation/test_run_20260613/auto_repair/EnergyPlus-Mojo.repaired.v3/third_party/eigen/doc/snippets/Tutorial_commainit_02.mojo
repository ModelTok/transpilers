from Eigen import MatrixXf, Matrix3f
from Eigen import cout

def main():
    var rows = 5
    var cols = 5
    var m = MatrixXf(rows, cols)
    m << (Matrix3f() << 1, 2, 3, 4, 5, 6, 7, 8, 9).finished(),
         MatrixXf.Zero(3, cols - 3),
         MatrixXf.Zero(rows - 3, 3),
         MatrixXf.Identity(rows - 3, cols - 3)
    cout << m