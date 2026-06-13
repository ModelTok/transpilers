from Eigen import MatrixXd, VectorXd

def main():
    var m = MatrixXd(2,2)
    m[0,0] = 3
    m[1,0] = 2.5
    m[0,1] = -1
    m[1,1] = m[1,0] + m[0,1]
    print("Here is the matrix m:\n", m)
    var v = VectorXd(2)
    v[0] = 4
    v[1] = v[0] - 1
    print("Here is the vector v:\n", v)