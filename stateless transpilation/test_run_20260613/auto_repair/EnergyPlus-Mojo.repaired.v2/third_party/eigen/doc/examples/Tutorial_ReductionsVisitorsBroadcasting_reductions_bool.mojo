from ......Eigen.Dense import ArrayXXf

def main():
    var a = ArrayXXf(2, 2)
    a << 1, 2,
         3, 4
    print("(a > 0).all()   = ", (a > 0).all())
    print("(a > 0).any()   = ", (a > 0).any())
    print("(a > 0).count() = ", (a > 0).count())
    print()
    print("(a > 2).all()   = ", (a > 2).all())
    print("(a > 2).any()   = ", (a > 2).any())
    print("(a > 2).count() = ", (a > 2).count())