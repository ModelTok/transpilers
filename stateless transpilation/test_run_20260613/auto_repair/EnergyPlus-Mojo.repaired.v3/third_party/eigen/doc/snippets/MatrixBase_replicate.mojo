from ...Eigen import MatrixXi

def main():
    var m = MatrixXi.Random(2, 3)
    print("Here is the matrix m:")
    print(m)
    print("m.replicate<3,2>() = ...")
    print(m.replicate[3, 2]())