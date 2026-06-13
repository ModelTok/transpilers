# This file is a faithful translation of tut_arithmetic_transpose_aliasing.cpp to Mojo.
# No refactoring beyond adapting syntax to Mojo.

struct Matrix2i:
    var data: List[List[Int]]

    def __init__(inout self, vals: List[List[Int]]):
        self.data = vals

    def transpose(self) -> Matrix2i:
        # Compute the transpose of a 2x2 matrix
        return Matrix2i([[self.data[0][0], self.data[1][0]], [self.data[0][1], self.data[1][1]]])

    def __str__(self) -> String:
        return ("(" + str(self.data[0]) + " ; " + str(self.data[1]) + ")")

def main():
    # Matrix2i a; a << 1, 2, 3, 4;
    var a = Matrix2i([[1, 2], [3, 4]])

    # cout << "Here is the matrix a:\n" << a << endl;
    print("Here is the matrix a:\n", a)

    # a = a.transpose(); // !!! do NOT do this !!!
    a = a.transpose()  # !!! do NOT do this !!!

    # cout << "and the result of the aliasing effect:\n" << a << endl;
    print("and the result of the aliasing effect:\n", a)