from Eigen import Matrix3f

def main() raises:
    var A = Matrix3f.Random(3, 3)
    var B = Matrix3f()
    B << 0, 1, 0,
         0, 0, 1,
         1, 0, 0
    print("At start, A = ")
    print(A)
    A.applyOnTheLeft(B)
    print("After applyOnTheLeft, A = ")
    print(A)