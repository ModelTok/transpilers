from _eigen import MatrixXf, VectorXf
from _iostream import cout, endl

def main():
    var A = MatrixXf.Random(3, 2)
    var b = VectorXf.Random(3)
    cout << "The solution using the QR decomposition is:\n" << A.colPivHouseholderQr().solve(b) << endl