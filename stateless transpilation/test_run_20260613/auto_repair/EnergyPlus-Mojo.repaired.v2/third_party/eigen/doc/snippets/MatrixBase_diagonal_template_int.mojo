from Eigen import Matrix4i

def main():
    var m = Matrix4i.Random()
    print("Here is the matrix m:")
    print(m)
    print("Here are the coefficients on the 1st super-diagonal and 2nd sub-diagonal of m:")
    print(m.diagonal[1]().transpose())
    print(m.diagonal[-2]().transpose())