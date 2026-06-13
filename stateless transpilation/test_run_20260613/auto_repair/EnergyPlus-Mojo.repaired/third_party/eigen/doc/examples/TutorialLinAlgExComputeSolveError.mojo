from Eigen import MatrixXd

def main():
    var A = MatrixXd.Random(100,100)
    var b = MatrixXd.Random(100,50)
    var x = A.fullPivLu().solve(b)
    var relative_error: Float64 = (A*x - b).norm() / b.norm() # norm() is L2 norm
    print("The relative error is:", relative_error)