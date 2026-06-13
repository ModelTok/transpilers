from Eigen import MatrixXi, cout

def main():
    var m = MatrixXi(2, 2)
    m << 1, 0,
         1, 1
    cout << "Comparing m with identity matrix:" << endl
    cout << m.cwiseNotEqual(MatrixXi.Identity(2, 2)) << endl
    var count = m.cwiseNotEqual(MatrixXi.Identity(2, 2)).count()
    cout << "Number of coefficients that are not equal: " << count << endl