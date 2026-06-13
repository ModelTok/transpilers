from Eigen import Matrix3d

def main():
    var m = Matrix3d.Random()
    print("Here is the matrix m:")
    print(m)
    print("Here is the product of all the coefficients:")
    print(m.prod())