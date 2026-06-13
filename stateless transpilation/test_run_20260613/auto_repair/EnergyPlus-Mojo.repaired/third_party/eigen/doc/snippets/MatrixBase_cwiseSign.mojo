from third_party.eigen.Eigen import MatrixXd, Matrix

def main():
    var m = MatrixXd(2, 3)
    m << 2, -4, 6, -5, 1, 0
    print(m.cwiseSign())