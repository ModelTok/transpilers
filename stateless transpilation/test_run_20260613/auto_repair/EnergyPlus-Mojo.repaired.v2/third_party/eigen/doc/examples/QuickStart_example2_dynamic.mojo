from Eigen.Dense import MatrixXd, VectorXd

def main() raises:
    var m = MatrixXd.Random(3, 3)
    m = (m + MatrixXd.Constant(3, 3, 1.2)) * 50
    print("m =")
    print(m)
    var v = VectorXd(3)
    v << 1, 2, 3
    print("m * v =")
    print(m * v)