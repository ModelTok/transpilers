from third_party.eigen.Eigen import Matrix3f, Matrix3f_Random, Matrix3f_Zero
from third_party.eigen.Eigen import cout

def main():
    var A = Matrix3f_Random(3, 3)
    var B = Matrix3f_Zero(3, 3)
    B[0, 0] = 0; B[0, 1] = 1; B[0, 2] = 0
    B[1, 0] = 0; B[1, 1] = 0; B[1, 2] = 1
    B[2, 0] = 1; B[2, 1] = 0; B[2, 2] = 0
    cout << "At start, A = " << endl << A << endl
    A = A * B
    cout << "After A *= B, A = " << endl << A << endl
    A.applyOnTheRight(B)  # equivalent to A *= B
    cout << "After applyOnTheRight, A = " << endl << A << endl