from third_party.eigen.Eigen import MatrixXi, cout

def main():
    var m = MatrixXi.Random(2, 3)
    cout << "Here is the matrix m:" << endl << m << endl
    cout << "m.colwise().replicate<3>() = ..." << endl
    cout << m.colwise().replicate[3]() << endl