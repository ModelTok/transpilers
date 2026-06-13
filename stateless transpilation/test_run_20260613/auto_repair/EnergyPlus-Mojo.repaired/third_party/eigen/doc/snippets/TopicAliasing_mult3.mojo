from Eigen import MatrixXf, cout

def main():
    var matA = MatrixXf(2, 2)
    matA << 2, 0, 0, 2
    matA.noalias() = matA * matA
    cout << matA